# The text of the assistant's replies in a session transcript — triage-first.sh and session-title.sh.
select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text
