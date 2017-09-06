import std.algorithm;
import std.array;
import std.file;
import std.getopt;
import std.path;
import std.regex;
import std.stdio;
import std.string;

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
	try
	{
		bool noArgs = argv.length < 2;

		auto opt = getopt(argv,
			   config.caseSensitive,
			   "match|m",
			   "Regex pattern to match.",
			   &textMatch,

			   "replace|r",
			   "Text to replace pattern with.",
			   &textReplace,

			   "recursive|R",
			   "Traverse all subdirectories.",
			   &recursive,

			   "pattern|p",
			   "Glob pattern to use when scanning a directory (e.g: *.txt)",
			   &pattern);

		if (noArgs || opt.helpWanted)
		{
			auto formatted = appender!string;
			defaultGetoptFormatter(formatted, null, opt.options);

			stdout.writeln("Regular expression rename utility.");

			stdout.writeln();
			stdout.writeln("Usage:");

			formatted.data.splitLines()
				.filter!(x => !x.empty)
				.each!(x => stdout.writefln("\t%s", x));

			stdout.writeln();
			stdout.writeln(`Example:`);
			stdout.write('\t');
			stdout.writeln(`renex -M "(\d+)-(\d+)-(\d+)" -R "$3-$1-$2" -p *.txt --recursive "../My Awesome Path"`);

			return ErrorCode.none;
		}

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
	size_t renameCount;

	foreach (string s; argv[1..$])
	{
		if (!exists(s))
		{
			continue;
		}

		// If this string is a file, let's just rename it now and move on.
		if (s.isFile() || !recursive && s.isDir())
		{
			if (checkMatch(baseName(s), regexMatch))
			{
				if (doRename(DirEntry(s), regexMatch, textReplace))
				{
					++renameCount;
				}
			}

			continue;
		}

		DirEntry[] directoryIndex;

		foreach (DirEntry entry; dirEntries(s, pattern, spanMode))
		{
			if (checkMatch(baseName(entry), regexMatch))
			{
				// If this entry is a directory, add to the directory index.
				// Otherwise, rename immediately.
				if (entry.isDir)
				{
					directoryIndex ~= entry;
				}
				else if (doRename(entry, regexMatch, textReplace))
				{
					++renameCount;
				}
			}
		}

		if (directoryIndex.length > 0)
		{
			foreach (DirEntry entry; directoryIndex)
			{
				if (doRename(entry, regexMatch, textReplace))
				{
					++renameCount;
				}
			}
		}
	}

	stdout.writefln("Renamed %d items.", renameCount);
	return ErrorCode.none;
}

bool checkMatch(T)(in string text, T regex)
{
	return !matchAll(text, regex).empty;
}

void regexRename(T)(in string path, T regex, in string replace)
{
	// These are split to avoid replacing accidental matches in the path to the target.
	string name = baseName(path);
	string dir = dirName(path);
	string result = replaceAll(name, regex, replace);

	rename(path, buildNormalizedPath(dir, result));
}

bool doRename(T)(DirEntry entry, T regex, in string replace)
{
	try
	{
		regexRename(entry.name, regex, replace);
	}
	catch (Exception ex)
	{
		stdout.writefln(`Error renaming %s: %s`, (entry.isFile) ? "file" : "directory", ex.msg);
		return false;
	}

	return true;
}
