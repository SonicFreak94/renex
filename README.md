# renex
Simple regex rename utility.

## Usage
```renex [arguments [path(s)]```

## Arguments
```
-M, --match     Regex pattern to match.
-R, --replace   Text to replace pattern with.
-p, --pattern   Glob pattern to use when scanning a directory. (e.g: -p *.txt)
--recursive     Traverse all subdirectories.
```

## Example
```renex -M "(\d+)-(\d+)-(\d+)" -R "$3-$1-$2" -p *.txt --recursive "../My Awesome Path"```
