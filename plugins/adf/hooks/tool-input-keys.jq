# The top-level field names of a tool call's input, one per line — tool_input_keys in _lib.sh.
(.tool_input // {}) | if type == "object" then keys_unsorted[] else empty end
