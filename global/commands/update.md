---
name: update
description: Update Jarvis from local repo - syncs global ~/.claude and project .claude folder
disable-model-invocation: false
---

# /update - Jarvis Update Command

Update Jarvis components from the local claude-code-tools repository.

## What It Does

1. **Checks versions** - Compares installed vs available versions
2. **Creates backups** - Preserves existing configuration before changes
3. **Syncs global** - Updates ~/.claude (hooks, skills, commands, agents, lib)
4. **Updates project** - Refreshes current project's .claude folder and CLAUDE.md
5. **Preserves customizations** - Files with `# JARVIS-USER-MODIFIED` marker are never overwritten
6. **Validates** - Verifies all hooks and configs work after update

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `$ARGUMENTS` | Update scope | `all` |

## Scopes

| Scope | Description |
|-------|-------------|
| `all` | Update global + current project (default) |
| `global` | Only update ~/.claude installation |
| `project` | Only update current project's .claude |
| `skills` | Only update skills |
| `hooks` | Only update hooks |
| `commands` | Only update commands |
| `agents` | Only update agents |

## Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would change without applying |
| `--force` | Update even if files have user-modified marker |
| `--no-backup` | Skip backup creation |

## Process

### Phase 1: Version Check

1. Read installed version from `~/.claude/.jarvis-version`
2. Read available version from `claude-code-tools/VERSION`
3. Compare versions to determine if update is needed
4. If up-to-date and not forced, exit early

### Phase 2: Backup Creation

1. Create timestamped backup of `~/.claude` folder
2. Create timestamped backup of project's `.claude` folder
3. Store backup paths for rollback if needed

### Phase 3: Global Update

For each component type (hooks, skills, commands, agents, lib):

1. Compare source and destination files
2. Skip files with `# JARVIS-USER-MODIFIED` marker (unless --force)
3. Create new files that don't exist
4. Update files that have changed
5. Report: created, updated, skipped, unchanged

### Phase 4: Project Update

1. Check if current directory has `.claude` folder
2. If using symlinks, skip (already pointing to global)
3. If local files:
   - Sync hooks from global
   - Sync commands from global
   - Update settings.json (merge new fields, preserve existing)
   - Update CLAUDE.md (preserve `<!-- USER CUSTOMIZATIONS -->` section)

### Phase 5: Validation

1. Syntax check all hook scripts (`bash -n`)
2. Validate settings.json is valid JSON
3. Verify required directories exist
4. Report any errors found

## Output Format

```
╔══════════════════════════════════════════════════════════════╗
║                    Jarvis Update System                      ║
╚══════════════════════════════════════════════════════════════╝

=== Updating Global Installation ===
Source: /Users/erik/Documents/claude-code-tools
Target: /Users/erik/.claude

Installed version: 1.0.0
Available version: 1.1.0

Creating backup...
Backup: /Users/erik/.claude.backup.20260106_195000

--- Hooks ---
updated: hooks/block-direct-submit.sh
created: hooks/new-hook.sh
skipped (user-modified): hooks/custom-hook.sh

Sync summary: 2 synced, 1 skipped, 5 unchanged, 0 errors

...

=== Validating Installation ===
Checking hook syntax...
Checking settings.json...
Checking directory structure...

Validation passed!
```

## Examples

**Update everything (most common):**
```
/update
```

**Preview what would change:**
```
/update --dry-run
```

**Update only global installation:**
```
/update global
```

**Update only current project:**
```
/update project
```

**Update skills only:**
```
/update skills
```

**Force update (overwrite user-modified files):**
```
/update --force
```

**Update without backup:**
```
/update --no-backup
```

## User Customization Preservation

### File-Level Protection

Add this marker to the first line of any file you've customized:

```bash
# JARVIS-USER-MODIFIED
# Your custom hook code...
```

Files with this marker will be skipped during updates unless `--force` is used.

### CLAUDE.md Section Protection

Wrap your custom sections in CLAUDE.md:

```markdown
<!-- USER CUSTOMIZATIONS -->
## My Custom Section

Your custom content here...
<!-- END USER CUSTOMIZATIONS -->
```

This section will be preserved during CLAUDE.md regeneration.

## Troubleshooting

### "Already up to date"
Use `--force` to reinstall even when versions match.

### "Backup failed"
Check disk space and permissions in home directory.

### "Validation failed"
Check the specific errors reported. Common fixes:
- Hook syntax errors: Fix the shell script syntax
- Invalid settings.json: Fix JSON formatting
- Missing directories: Run `/init` to recreate structure

### Rollback
Backups are stored as `.claude.backup.{timestamp}`. To rollback:
```bash
rm -rf ~/.claude
mv ~/.claude.backup.{timestamp} ~/.claude
```

## Notes

- Updates sync from your local `claude-code-tools` repo
- To get latest features, first `git pull` in the repo
- Project updates require the project to have been initialized with `/init`
- Symlinked .claude folders skip sync (already point to global)
