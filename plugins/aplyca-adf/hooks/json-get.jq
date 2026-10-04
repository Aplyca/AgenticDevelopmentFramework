# The string at a dotted path ($path) in a hook's event, or nothing — json_get in _lib.sh.
getpath($path | ltrimstr(".") | split(".")) | strings
