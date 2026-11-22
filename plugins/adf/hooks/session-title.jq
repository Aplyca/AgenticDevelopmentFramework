# The hook output that sets the session title to the text on stdin, at most 80 characters —
# session-title.sh.
{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: (if length > 80 then .[0:79] + "…" else . end)}}
