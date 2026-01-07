# Jarvis Global Configuration

## Skill Activation (MANDATORY)

When you see `SKILL ACTIVATION CHECK` in your context, you MUST:

1. **Read the recommended skills** - Look for CRITICAL, RECOMMENDED, and SUGGESTED skills
2. **Invoke skills using the Skill tool** - Use `skill: "skill-name"` for each critical/recommended skill
3. **Follow the skill instructions** - The skill content will guide your response

**Example:**
```
SKILL ACTIVATION CHECK

CRITICAL SKILLS (REQUIRED):
  -> test-driven-development
  -> session-management
```

**Required action:** Use the Skill tool twice:
- `skill: "tdd"` (or `test-driven-development`)
- `skill: "session-management"`

**DO NOT** ignore skill recommendations. They exist to ensure quality and consistency.

## Hook Blocking

When a hook blocks an action with "Use the X skill instead":
1. **DO NOT** just add bypass variables
2. **DO** invoke the skill using the Skill tool
3. **THEN** follow the skill's process

---

<!-- USER CUSTOMIZATIONS -->
<!-- Add your personal configurations below this line -->
<!-- END USER CUSTOMIZATIONS -->