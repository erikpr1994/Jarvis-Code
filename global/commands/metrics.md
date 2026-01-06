---
name: metrics
description: View development metrics, productivity stats, and weekly summaries
disable-model-invocation: false
---

# /metrics - View Development Metrics

Display productivity metrics, code quality stats, learning progress, and context usage.

## What It Does

1. **Shows daily metrics** - Displays today's development statistics
2. **Generates summaries** - Creates weekly aggregated reports
3. **Tracks trends** - Identifies patterns over time
4. **Provides insights** - Offers recommendations based on data

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Optional date, period, or filter | "weekly", "2026-01-05", "productivity" |

## Usage Modes

### View Today's Metrics
```
/metrics
```
Shows current day's statistics across all categories.

### View Weekly Summary
```
/metrics weekly
```
Generates and displays aggregated weekly statistics with trends.

### View Specific Date
```
/metrics 2026-01-05
```
Shows metrics for a specific date.

### View Category
```
/metrics productivity
/metrics quality
/metrics learning
/metrics context
```
Shows only the specified category of metrics.

## Process

### Phase 1: Data Collection

1. **Locate metrics files**
   - Check `~/.claude/metrics/daily/` for daily files
   - Check `[project]/.claude/metrics/` for project metrics

2. **Load requested data**
   - For today: Load or generate current day's metrics
   - For weekly: Aggregate last 7 days
   - For specific date: Load that day's file

3. **Validate data**
   - Check against schema.json
   - Fill missing fields with defaults
   - Flag any data inconsistencies

### Phase 2: Processing

4. **Calculate derived metrics**
   - Daily averages
   - Week-over-week changes
   - Trend indicators (up/down/stable)

5. **Generate insights**
   - Compare to historical averages
   - Identify anomalies
   - Flag notable achievements

### Phase 3: Output

6. **Format output**

```markdown
## Daily Metrics - 2026-01-05

### Productivity
| Metric | Value | Trend |
|--------|-------|-------|
| Features Completed | 2 | ^ |
| Commits | 15 | ^ |
| PRs Merged | 3 | = |

### Quality
| Metric | Value | Trend |
|--------|-------|-------|
| Test Coverage | 85% | ^ |
| Review Score Avg | 8.5/10 | ^ |
| Bugs Found | 2 | v |

### Learning
| Metric | Value |
|--------|-------|
| Skills Invoked | git-expert, tdd, debugging |
| Patterns Matched | 8 |

### Context
| Metric | Value | Trend |
|--------|-------|-------|
| Tokens Used | 45,000 | v |
| Compactions | 0 | = |
```

## Weekly Summary Output

```markdown
## Weekly Summary (Dec 29 - Jan 5)

### Highlights
- 12 features completed (+20% vs last week)
- Test coverage improved 5%
- Most used skill: git-expert (23 invocations)

### Productivity
| Metric | Total | Daily Avg | Trend |
|--------|-------|-----------|-------|
| Features | 12 | 1.7 | ^ |
| Commits | 89 | 12.7 | ^ |
| PRs | 8 | 1.1 | = |

### Quality
- Average test coverage: 82%
- Average review score: 8.2/10
- Bugs found: 5 (4 in dev, 1 in prod)

### Learning
| Skill | Invocations |
|-------|-------------|
| git-expert | 23 |
| tdd | 15 |
| debugging | 8 |

### Recommendations
- Consider breaking work into smaller commits
- Test coverage trending up - great progress!
- Token usage is efficient, keep it up
```

## Examples

**View today's metrics:**
```
/metrics
```

**View weekly summary:**
```
/metrics weekly
```

**View specific date:**
```
/metrics 2026-01-03
```

**View only productivity:**
```
/metrics productivity
```

**View quality trends:**
```
/metrics quality --trend
```

**Export as JSON:**
```
/metrics --json
```

**Run collection script:**
```
/metrics --collect
```
Triggers manual collection of metrics from git, tests, etc.

## Metric Categories

### Productivity
| Metric | Description | Source |
|--------|-------------|--------|
| features_completed | Features/tasks done | Git commits (feat/add) |
| commits | Total commits | Git log |
| prs_merged | Pull requests merged | Git/GitHub |
| time_to_first_commit | Minutes to first commit | Session tracking |

### Quality
| Metric | Description | Source |
|--------|-------------|--------|
| test_coverage | Code coverage % | Coverage reports |
| review_score_avg | Average review score | Manual/Code review |
| bugs_found | Bugs caught in dev | Issue tracking |
| bugs_found_in_prod | Bugs in production | Issue tracking |

### Learning
| Metric | Description | Source |
|--------|-------------|--------|
| skills_invoked | Skills used | Skill system |
| patterns_matched | Pattern applications | Pattern system |
| auto_updates | System improvements | Learning system |

### Context
| Metric | Description | Source |
|--------|-------------|--------|
| tokens_used | Tokens consumed | Claude usage |
| compactions | Context compactions | Session tracking |
| memory_retrievals | Memory accesses | Memory system |

## Configuration

Metrics collection can be configured in `settings.json`:

```json
{
  "metrics": {
    "auto_collect": true,
    "collection_interval": "daily",
    "retention_days": 90,
    "categories": ["productivity", "quality", "learning", "context"]
  }
}
```

## File Locations

| File | Purpose |
|------|---------|
| `~/.claude/metrics/daily/` | Daily metric files |
| `~/.claude/metrics/schema.json` | Data schema |
| `~/.claude/metrics/collect.sh` | Collection script |
| `~/.claude/metrics/weekly-summary.sh` | Weekly report generator |

## Notes

- Metrics are collected automatically via hooks
- Manual entry supported for review scores and bug counts
- Weekly summaries are generated on demand
- Historical data retained for 90 days by default
- Project-specific metrics override global metrics
- Use `/metrics --collect` to force collection
