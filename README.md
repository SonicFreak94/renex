# renex
Simple regex rename utility.

## Usage
```renex [arguments] [path(s)]```

## Arguments
```
-d, --dry           Performs a dry run, skipping the actual rename step. Matches and replacement results will be displayed.
-m, --match         Regex pattern to match.
-r, --replace       Text to replace the pattern with.
-R, --recursive     Traverse all subdirectories.
-p, --pattern       Glob pattern to use when scanning a directory (e.g: *.txt)
```

## Example
```renex -m "(\d+)-(\d+)-(\d+)" -r "$3-$1-$2" -p *.txt --recursive "../some path"```
