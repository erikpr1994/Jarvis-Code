# Notes and improvements

## General

Compatibility with other libraries? Some stuff in our tools are opinionated, should alert the user and delete the rest?

Antigravity vs zed vs Cursor? Gemini CLI?
Claude code vs Open Code?

Is the approval hook system built? Is it working?

## Commands

Should commands connect with their respective or similar agents (Or multiple agents): debug commands with the debug agent, review with review agents, etc?
When to run install.sh vs init? Can we run /init so it runs automatically install.sh? Can we make it a marketplace for Claude Code so it automatically does everything? Does /init collides with claude code init? (✅)

## Learning system

Learnings.md can become huge. Should we search for a better system? Are learnings local to the project or it lives in the Claude folder root?
It's possible to use Claude Plan mode with what we have build in Jarvis?
Auto learning on Claude Code errors?
Auto-suggestion on updates to the Jarvis code?

## Docs, dependencies and libraries

Should the dependency reviewer agent have access to webFetch or an MCP to get the latest dependency docs?
If we use an MCP server to get docs and cache them, should we use it in the init? How do we update docs if they are cached? Docs vs context vs rules?
Let's integrate usage of MCPs like context7, EXA or hyperdocs
Remove patterns so we use the usage of MCPs to get docs and info? If not, api error handling patterns is wrong. Why we need a success field? This is already explicit with the HTTP status code. This pattern is a code smell. We MUST use HTTP codes.

https://github.com/vercel-labs/opensrc

Rules = user preferences? Should they be configurable instead of fixed ones? (✅)

## Skills

Why testing pyramid? Configurable between testing pyramid or testing trophy?
Shouldn't skills go into it's folder and be named SKILLS.md? Can we move templates and not needed data from the beginning into it's own file and be referenced in the skill? Does type and priority works with Claude Code? Or does it work with our system? (✅)
TDD vs tdd-workflow. What's the difference? (✅)

## Rules

Add a rule like: https://x.com/jarrodwatts/status/2008761427805544674

## Statusline
Use 
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/claude-hud:setup

## Agent Guidelines / Architecture

Analyze the current CLAUDE.md and any agent instruction files. For every "soft rule" or behavioral instruction you find (e.g., "use conventional commits", "validate inputs", "use ripgrep over grep"), propose a technical enforcement mechanism—a linter rule, git hook, CLI wrapper, or automated script—that makes the rule impossible to break.

The goal: remove text-based instructions from the agent's context window entirely. If something can be enforced by a tool, it shouldn't be in the prompt. This saves context, increases reliability, and turns "please do X" into "X is the only option."

Reference: https://x.com/i/status/2008596745622589922