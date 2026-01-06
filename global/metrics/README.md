# Jarvis Metrics System

Track and analyze your development productivity, code quality, learning progress, and context usage.

## Overview

The metrics system automatically collects and aggregates data about your development workflow to help identify trends, improvements, and areas for optimization.

## Metrics Categories

### Productivity
- **features_completed**: Number of features/tasks completed
- **commits**: Total commits made
- **prs_merged**: Pull requests merged
- **time_to_first_commit_minutes**: Time from session start to first commit

### Quality
- **test_coverage**: Current test coverage percentage
- **review_score_avg**: Average code review score (1-10)
- **bugs_found**: Bugs identified during development
- **bugs_found_in_prod**: Bugs that reached production

### Learning
- **skills_invoked**: List of skills used during the session
- **patterns_matched**: Number of times patterns were applied
- **auto_updates**: Automatic system updates triggered

### Context
- **tokens_used**: Total tokens consumed
- **compactions**: Number of context compactions
- **memory_retrievals**: Times memory/context was retrieved

## Directory Structure

```
metrics/
├── README.md           # This file
├── schema.json         # JSON schema for metrics data
├── collect.sh          # Daily metrics collection script
├── weekly-summary.sh   # Weekly summary generator
└── daily/              # Daily metric files (YYYY-MM-DD.json)
```

## Usage

### View Current Metrics
```
/metrics          # Show today's metrics
/metrics weekly   # Show weekly summary
/metrics [date]   # Show metrics for specific date
```

### Manual Collection
Run the collection script to gather metrics:
```bash
./global/metrics/collect.sh
```

### Weekly Summary
Generate a weekly summary report:
```bash
./global/metrics/weekly-summary.sh
```

## Data Storage

Daily metrics are stored in `daily/YYYY-MM-DD.json` files following the schema defined in `schema.json`.

### Example Daily File
```json
{
  "date": "2026-01-05",
  "productivity": {
    "features_completed": 2,
    "commits": 15,
    "prs_merged": 3
  },
  "quality": {
    "test_coverage": 85,
    "review_score_avg": 8.5,
    "bugs_found": 2
  },
  "learning": {
    "skills_invoked": ["git-expert", "tdd"],
    "patterns_matched": 8
  },
  "context": {
    "tokens_used": 45000,
    "compactions": 0
  }
}
```

## Automatic Collection

The `metrics-capture.sh` hook runs in the background after tool usage to:
- Track skill invocations
- Count pattern matches
- Monitor context usage

## Best Practices

1. **Review weekly**: Check weekly summaries to identify trends
2. **Set goals**: Use metrics to set realistic improvement targets
3. **Track anomalies**: Investigate unusual spikes or drops
4. **Correlate quality**: Compare productivity with quality metrics

## Integration

Metrics integrate with:
- **Learning system**: Tracks skill development
- **Memory system**: Records context patterns
- **Git hooks**: Captures commit and PR data
