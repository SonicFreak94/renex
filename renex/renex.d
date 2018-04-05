import std.algorithm;
import std.array;
import std.exception : enforce;
import std.file;
import std.getopt;
import std.path;
import std.regex;
import std.stdio;
import std.string;

int main(string[] args)
{
	SpanMode spanMode;

	bool   dryRun;
	string textMatch;
	string textReplace;
	string globPattern = "*";
	bool   recursive;

	try
	{
		const bool noArgs = args.length < 2;

		auto opt = getopt(args, config.caseSensitive,
			   "dry|d",
			   "Performs a dry run, skipping the actual rename step. " ~
			   "Matches and replacement results will be displayed.",
			   &dryRun,

			   "match|m",
			   "Regex pattern to match.",
			   &textMatch,

			   "replace|r",
			   "Text to replace the pattern with.",
			   &textReplace,

			   "recursive|R",
			   "Traverse all subdirectories.",
			   &recursive,

			   "pattern|p",
			   "Glob pattern to use when scanning a directory (e.g: *.txt)",
			   &globPattern);

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
			stdout.writeln("\t", `renex -m "(\d+)-(\d+)-(\d+)" -r "$3-$1-$2" -p *.txt --recursive "../some path"`);

			return 0;
		}

		enforce(args.length >= 2, "Insufficient arguments");
		enforce(!textMatch.empty, "Match text cannot be empty.");

		spanMode = (recursive) ? SpanMode.depth : SpanMode.shallow;
	}
	catch (Exception ex)
	{
		stderr.writeln(ex.msg);
		return -1;
	}

	Regex!char regexMatch = regex(textMatch);
	size_t renameCount;

	foreach (string s; args[1 .. $])
	{
		if (!exists(s))
		{
			continue;
		}

		auto e = DirEntry(s);

		// If this is a file (or a directory in non-recursive mode),
		// let's just rename it now and move on.
		if (e.isFile || !recursive)
		{
			if (regexRename(e, regexMatch, textReplace, dryRun))
			{
				++renameCount;
			}

			continue;
		}

		Appender!(DirEntry[]) directories;

		foreach (DirEntry entry; dirEntries(s, globPattern, spanMode))
		{
			if (entry.isDir)
			{
				directories.put(entry);
			}
			else if (regexRename(entry, regexMatch, textReplace, dryRun))
			{
				++renameCount;
			}
		}

		if (!directories.data.empty)
		{
			foreach (DirEntry entry; directories.data)
			{
				if (regexRename(entry, regexMatch, textReplace, dryRun))
				{
					++renameCount;
				}
			}
		}
	}

	if (dryRun)
	{
		stdout.writeln("Total matches: ", renameCount);
	}
	else
	{
		stdout.writeln("Renamed items: ", renameCount);
	}

	return 0;
}

/// Renames a file or directory according to the given regular expression.
bool regexRename(in DirEntry entry, in Regex!char regex, in string replace, bool dry)
{
	try
	{
		// These are split to avoid replacing accidental matches in the path to the target.
		string name   = baseName(entry.name);
		string dir    = dirName(entry.name);
		string result = replaceAll(name, regex, replace);

		if (result == name)
		{
			return false;
		}

		if (dry)
		{
			stdout.writeln(entry.name ~ " -> " ~ buildNormalizedPath(dir, result));
		}
		else
		{
			rename(entry.name, buildNormalizedPath(dir, result));
		}
	}
	catch (Exception ex)
	{
		stderr.writefln("Error renaming %s: %s", (entry.isFile) ? "file" : "directory", ex.msg);
		return false;
	}

	return true;
}
