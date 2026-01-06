# Shared Libraries

Shared JavaScript/TypeScript utilities used by hooks and other components.

## Structure

```
lib/
├── skills-core.js      # Skill discovery and loading
├── patterns-core.js    # Pattern matching and lookup
├── session-core.js     # Session management utilities
└── hooks-core.js       # Hook execution utilities
```

## Core Libraries

### skills-core.js
Skill discovery, loading, and activation:
- `discoverSkills(settings)` - Find all available skills
- `loadSkillRules(settings)` - Load activation rules
- `matchSkills(prompt, rules)` - Match prompt to skills
- `loadSkill(skillPath)` - Load skill content

### patterns-core.js (planned)
Pattern library operations:
- `searchPatterns(query)` - Search pattern index
- `loadPattern(patternId)` - Load full pattern
- `addPattern(pattern)` - Add new pattern

### session-core.js (planned)
Session management:
- `startSession()` - Initialize new session
- `resumeSession()` - Resume previous session
- `saveSession()` - Persist session state
- `archiveSession()` - Archive completed session

### hooks-core.js (planned)
Hook utilities:
- `executeHook(hookName, context)` - Run a hook
- `validateHookResult(result)` - Validate hook output
- `chainHooks(hooks, context)` - Run hooks in sequence

## Usage

Libraries can be imported in hooks and other scripts:

```javascript
const { discoverSkills, matchSkills } = require('./lib/skills-core');

const skills = discoverSkills(settings);
const matches = matchSkills(userPrompt, skillRules);
```

## Adding Libraries

New libraries should:
1. Export named functions
2. Include JSDoc documentation
3. Handle errors gracefully
4. Support both global and project contexts
