# renex
Simple regex rename utility.

## Usage
```renex [arguments] [path(s)]```

## Arguments
```
-m, --match         Regex pattern to match.
-r, --replace       Text to replace pattern with.
-R, --recursive     Traverse all subdirectories.
-p, --pattern       Glob pattern to use when scanning a directory. (e.g: -p *.txt)
```

## Example
```renex -M "(\d+)-(\d+)-(\d+)" -R "$3-$1-$2" -p *.txt --recursive "../My Awesome Path"```
