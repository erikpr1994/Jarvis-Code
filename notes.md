# Notes and improvements

## General

We didn't use a plan for each docs so there's missing stuff? 1 doc one plan with small steps? Use sub-agents to build stuff.
Compatibility with other libraries? Some stuff in our tools are opinionated, should alert the user and delete the rest?

Antigravity vs zed vs Cursor? Gemini CLI?
Claude code vs Open Code?

## Commands

Should commands connect with their respective or similar agents (Or multiple agents): debug commands with debug agent, review with review agents, etc?
When to run install.sh vs init? Can we run /init so it runs automatically install.sh? Can we make it a markplace for Claude Code so it automatically does everything? Does /init collides with claude code init?

## Learning system

Learnings.md can become huge. Should we search for a better system? Are learnings local to the project or it lives in the Claude folder root?
It's possible to use Claude Plan mode with what we have build in Jarvis?
Auto learning on Claude Code errors?
Auto suggestion on updates of Jarvis code?

## Docs, dependencies and libraries

Should dependency reviewer agent has access to webFetch or an MCP to get latest dependency docs?
If we use an MCP server to get docs and cache them, should we use it in the init? How do we update docs if they are cached? Docs vs context vs rules?
Let's integrate usage of MCPs like context7, EXA or hyperdocs
Remove patterns so we use the usage of MCPs to get docs and info? If not, api error handling patterns is wrong. Why we need a success field? This is already explicit with the HTTP status code. This pattern is a code smell. We MUST use HTTP codes.

Rules = user preferences? Should they be configurable instead of fixed ones?

## Skills

Why testing pyramid? Configurable between testing pyramid or testing trophy?
Shouldn't skills go into it's folder and be named SKILLS.md? Can we move templates and not needed data from the beginning into it's own file and be referenced in the skill? Does type and priority works with Claude Code? Or does it work with our system?
TDD vs tdd-workflow. What's the difference?
Missing the plan skill?
