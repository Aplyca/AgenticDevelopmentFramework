# The text of the assistant's replies in a session transcript — triage-first.sh.
select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text
