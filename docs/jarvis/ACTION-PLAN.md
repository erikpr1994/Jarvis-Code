# Jarvis Action Plan

> 1:1 mapping of each spec document to remaining work

**Created**: 2026-01-06 (Audit Session)

---

## Overview

| # | Spec Document | Status | Action Required |
|---|---------------|--------|-----------------|
| 01 | vision-and-goals.md | ✅ | None |
| 02 | architecture.md | ✅ | None |
| 03 | claude-md-system.md | ✅ | None |
| 04 | agents.md | ✅ | None (n8n removed from spec) |
| 05 | skills.md | ✅ | None |
| 06 | commands.md | ✅ | None |
| 07 | hooks.md | ✅ | None (coderabbit-review.sh created) |
| 08 | rules-and-patterns.md | ✅ | None |
| 09 | session.md | ✅ | None |
| 10 | context-optimization.md | ✅ | None |
| 11 | learning-system.md | ✅ | None |
| 12 | initialization.md | ⚠️ | Add symlinks, verification |
| 13 | verification.md | ⚠️ | Automate pipeline |
| 14 | metrics.md | ✅ | None |
| 15 | testing.md | ✅ | Optional: agent tests |
| 16 | error-recovery.md | ✅ | Optional: notifications |
| 17 | distribution.md | ✅ | Optional: GH Actions |
| 18 | appendices.md | ✅ | None |

---

## 01-vision-and-goals.md

**Status**: ✅ Complete
**Action**: None

Reference document. No implementation needed.

---

## 02-architecture.md

**Status**: ✅ Complete
**Action**: None

All directories and structures exist as specified.

---

## 03-claude-md-system.md

**Status**: ✅ Complete
**Action**: None

All templates (9 project types, 13 folder types, lib docs) exist.

---

## 04-agents.md

**Status**: ✅ Complete
**Action**: None

### Completed (Session 9)
- [x] Removed n8n-builder from Section 5.4 (Specialized Domain Agents)
- [x] Removed n8n-builder from Section 5.5.2 (Consolidation Decisions)
- [x] Updated Section 5.5.3 (Final Agent Count): 8 → 7 domain agents, 23 → 22 total

### Final Count
- 5 Core agents
- 10 Review agents
- 7 Domain agent templates (was 8, n8n removed)
- **22 total** (was 23)

---

## 05-skills.md

**Status**: ✅ Complete
**Action**: None

47 skills exist, exceeding the ~44 specified. skill-rules.json has 34 triggers.

---

## 06-commands.md

**Status**: ✅ Complete
**Action**: None

All 24 commands exist and are functional.

---

## 07-hooks.md

**Status**: ✅ Complete
**Action**: None

### Completed (Session 9)
- [x] Created `global/hooks/coderabbit-review.sh` (93 lines)
- [x] Registered in `hooks.json` under PreToolUse > Bash
- [x] Added settings: runInBackground, timeout (2000ms), bypass (SKIP_CODERABBIT)

### What It Does
- Detects `gt submit` and `gh pr create` commands
- Adds context about CodeRabbit's automatic review
- Provides helpful commands (`@coderabbitai full review`, etc.)
- Checks for `.coderabbit.yaml` config
- Bypass with `SKIP_CODERABBIT=1`

---

## 08-rules-and-patterns.md

**Status**: ✅ Complete
**Action**: None

5 rules, 24 patterns, index.json updated.

---

## 09-session.md

**Status**: ✅ Complete
**Action**: None

Session templates, hooks, and commands all exist.

---

## 10-context-optimization.md

**Status**: ✅ Complete
**Action**: None

6 wrapper scripts (1500+ lines), compress-output.sh hook registered.

---

## 11-learning-system.md

**Status**: ✅ Complete
**Action**: None

capture.sh, auto-update.sh, archival-scheduler.sh, memory tiers all exist.

---

## 12-initialization.md

**Status**: ⚠️ Partial (85%)
**Action**: Add symlinks and post-init verification

### Task 1: Add Symlink Support to init.sh

```bash
# Add to init/init.sh after .claude/ folder creation

# Create symlinks to global resources (optional)
create_symlinks() {
    local project_dir="$1"
    local jarvis_root="${JARVIS_ROOT:-$HOME/.jarvis}"

    # Only if user opts in
    if [[ "${JARVIS_SYMLINK_GLOBALS:-0}" == "1" ]]; then
        ln -sf "$jarvis_root/global/skills" "$project_dir/.claude/skills"
        ln -sf "$jarvis_root/global/agents" "$project_dir/.claude/agents"
        echo "Created symlinks to global skills and agents"
    fi
}
```

### Task 2: Add Post-Init Verification

```bash
# Add to init/init.sh at end

verify_init() {
    local errors=0

    # Check CLAUDE.md exists
    [[ -f "CLAUDE.md" ]] || { echo "ERROR: CLAUDE.md not created"; ((errors++)); }

    # Check .claude/ structure
    [[ -d ".claude" ]] || { echo "ERROR: .claude/ not created"; ((errors++)); }

    # Test a hook can execute
    if ! bash "$JARVIS_ROOT/global/hooks/session-start.sh" < /dev/null &>/dev/null; then
        echo "WARNING: session-start.sh hook failed to execute"
    fi

    if [[ $errors -eq 0 ]]; then
        echo "✅ Initialization verified successfully"
    else
        echo "❌ Initialization had $errors error(s)"
        return 1
    fi
}
```

---

## 13-verification.md

**Status**: ⚠️ Partial (70%)
**Action**: Automate multi-stage verification pipeline

### Task: Create Automated Verification Pipeline

The `/verify` command exists but doesn't orchestrate the full pipeline automatically.

```bash
# Enhance global/commands/verify.md to support:

## Verification Levels

### Quick (default)
- TypeScript compilation
- Linting
- Formatting check

### Standard (--standard)
- All quick checks
- Unit tests

### Full (--full)
- All standard checks
- Integration tests
- E2E tests
- Parallel review agents:
  - code-reviewer
  - spec-reviewer
  - security-reviewer (if security-sensitive files changed)
  - accessibility-auditor (if UI files changed)

### Release (--release)
- All full checks
- Performance audit
- Security scan
- Manual approval gate
```

### Implementation Notes
This is enhancement work - the commands exist, they just need orchestration logic.

---

## 14-metrics.md

**Status**: ✅ Complete
**Action**: None

schema.json, collect.sh, weekly-summary.sh, daily/ with actual data, /metrics command, metrics-capture.sh hook - all exist and functional.

---

## 15-testing.md

**Status**: ✅ Complete (95%)
**Action**: Optional - Add agent testing

### Optional Task: Agent Test Framework

```
tests/jarvis/agents/
├── test-agent-framework.sh    # Runner
├── prompts/
│   ├── code-reviewer/
│   │   ├── input-1.md         # Sample code to review
│   │   └── expected-1.md      # Expected review output patterns
│   └── implementer/
│       ├── input-1.md
│       └── expected-1.md
└── lib/
    └── agent-test-helpers.sh  # Scoring/comparison utilities
```

This is nice-to-have, not blocking.

---

## 16-error-recovery.md

**Status**: ✅ Complete (95%)
**Action**: Optional - Add desktop notifications

### Optional Task: Desktop Notification Support

```bash
# Add to global/lib/error-handler.sh

notify_user() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"  # low, normal, critical

    # macOS
    if command -v osascript &>/dev/null; then
        osascript -e "display notification \"$message\" with title \"$title\""
    # Linux
    elif command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" "$title" "$message"
    # Fallback
    else
        echo "[$title] $message" >&2
    fi
}
```

This is nice-to-have for alerting on critical errors.

---

## 17-distribution.md

**Status**: ✅ Complete (95%)
**Action**: Optional - Add GitHub Actions release workflow

### Optional Task: GitHub Release Automation

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Generate changelog
        run: ./scripts/generate-changelog.sh > RELEASE_NOTES.md

      - name: Create release
        uses: softprops/action-gh-release@v1
        with:
          body_path: RELEASE_NOTES.md
          files: |
            install.sh
            VERSION
```

This is nice-to-have for automated releases.

---

## 18-appendices.md

**Status**: ✅ Complete
**Action**: None

Reference document with interview summary and sources.

---

## Priority Summary

### Must Do (Core Gaps)
✅ All core gaps resolved! (`coderabbit-review.sh` created)

### Should Do (Polish)
1. **12-initialization**: Add post-init verification (1 hr)
2. **13-verification**: Enhance /verify with pipeline orchestration (2-3 hr)

### Nice to Have
3. **15-testing**: Agent prompt/response tests (4+ hr)
4. **16-error-recovery**: Desktop notifications (30 min)
5. **17-distribution**: GitHub Actions release (1 hr)

---

## Estimated Effort

| Task | Effort | Impact | Status |
|------|--------|--------|--------|
| ~~Create coderabbit hook~~ | ~~30 min~~ | ~~Feature completeness~~ | ✅ Done |
| ~~Remove n8n from spec~~ | ~~5 min~~ | ~~Documentation cleanup~~ | ✅ Done |
| Post-init verification | 1 hr | User confidence | Pending |
| Verification pipeline | 2-3 hr | Quality automation | Pending |
| Agent tests | 4+ hr | Testing completeness | Optional |
| Desktop notifications | 30 min | UX improvement | Optional |
| GitHub Actions | 1 hr | Release automation | Optional |

---

*Last updated: 2026-01-06 (Session 9)*
*Use this document to track what remains and prioritize work.*
