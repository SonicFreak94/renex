import std.stdio, std.getopt;
import std.file, std.path;
import std.algorithm, std.regex;

string textMatch;
string textReplace;
string pattern = "*";
bool recursive = false;

SpanMode spanMode;

enum ErrorCode : int
{
	none,
	invalidArgs,
	nullPattern,
}

int main(string[] argv)
{
	if (argv.length < 2)
	{
		string binary = stripExtension(baseName(argv[0]));
		stdout.writeln(
`Usage:
	renex [arguments] [path(s)]

Arguments:
	-m, --match         Regex pattern to match.
	-r, --replace       Text to replace pattern with.
	-R, --recursive     Traverse all subdirectories.
	-p, --pattern       Glob pattern to use when scanning a directory. (e.g: -p *.txt)

Example:
	renex -M "(\d+)-(\d+)-(\d+)" -R "$3-$1-$2" -p *.txt --recursive "../My Awesome Path"`);

		return ErrorCode.none;
	}

	try
	{
		// Argument setup
		getopt(argv,
			   config.caseSensitive,
			   "match|m",		&textMatch,
			   "replace|r",		&textReplace,
			   "recursive|R",	&recursive,
			   "pattern|p",		&pattern);

		if (argv.length < 2)
		{
			stdout.writeln("Insufficient arguments.");
			return ErrorCode.invalidArgs;
		}
		if (textMatch == null)
		{
			stdout.writeln("Match text cannot be empty.");
			return ErrorCode.nullPattern;
		}

		spanMode = (recursive) ? SpanMode.depth : SpanMode.shallow;
	}
	catch (Exception ex)
	{
		stdout.writeln(ex.msg);
		return ErrorCode.invalidArgs;
	}

	auto regexMatch = regex(textMatch);
	uint renameCount = 0;

	foreach (string s; argv[1..$])
	{
		if (!exists(s))
			continue;

		// If this string is a file, let's just rename it now and move on.
		if (s.isFile() || !recursive && s.isDir())
		{
			if (CheckMatch(baseName(s), regexMatch))
			{
				if (PerformRename(DirEntry(s), regexMatch, textReplace))
					++renameCount;
			}

			continue;
		}

		DirEntry[] directoryIndex;

		foreach (DirEntry entry; dirEntries(s, pattern, spanMode))
		{
			if (CheckMatch(baseName(entry), regexMatch))
			{
				// If this entry is a directory, add to the directory index,
				// otherwise rename immediately.
				if (entry.isDir)
					directoryIndex ~= entry;
				else if (PerformRename(entry, regexMatch, textReplace))
					++renameCount;
			}
		}

		if (directoryIndex.length > 0)
		{
			foreach (DirEntry entry; directoryIndex)
			{
				if (PerformRename(entry, regexMatch, textReplace))
					++renameCount;
			}
		}
	}

	stdout.writefln("Renamed %d items.", renameCount);
	return ErrorCode.none;
}

bool CheckMatch(T)(in string text, T regex)
{
	return !matchAll(text, regex).empty;
}

void RegexRename(T)(in string path, T regex, in string replace)
{
	// These are split to avoid replacing accidental matches in the path to the target.
	string name = baseName(path);
	string dir = dirName(path);
	string result = replaceAll(name, regex, replace);

	rename(path, buildNormalizedPath(dir, result));
}

bool PerformRename(T)(DirEntry entry, T regex, in string replace)
{
	try
	{
		RegexRename(entry.name, regex, replace);
	}
	catch (Exception ex)
	{
		stdout.writefln(`Error renaming %s: %s`, (entry.isFile) ? "file" : "directory", ex.msg);
		return false;
	}

	return true;
}
