#!/usr/bin/env bash
# Hook: post-edit-suggest
# Event: PostToolUse
# Tools: Edit, Write
# Status: DISABLED
#
# KNOWN LIMITATIONS (as of 2026-01-14):
# 1. Claude Code does not pass file_path via stdin for Edit/Write PostToolUse
# 2. File writes from hooks don't persist when run by Claude Code (sandboxing)
# 3. Plain text output is captured but not displayed in conversation
# 4. Hook matcher counts don't align with expected behavior
#
# This hook has been disabled in settings.json due to these limitations.
# The react-best-practices skill and code-simplifier agent should be
# invoked manually or through other mechanisms.
#
# For future consideration:
# - UserPromptSubmit hook could suggest based on conversation context
# - Status line could display suggestions
# - PreToolUse for Edit could suggest before the edit (wrong timing)

echo "post-edit-suggest hook is disabled due to Claude Code PostToolUse limitations"
exit 0
