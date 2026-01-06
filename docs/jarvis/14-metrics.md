# Metrics & Tracking

> Part of the [Jarvis Specification](./README.md)

## 16. Metrics & Tracking

### 16.1 Metrics Categories

| Category | Metrics |
|----------|---------|
| **Productivity** | Time per feature, commits per day, PR throughput |
| **Quality** | Review scores, bug rate, test coverage |
| **Learning** | Skills created, patterns captured, auto-updates |
| **Context** | Token usage, compaction frequency, memory retrievals |

### 16.2 Metrics Storage

```json
{
  "metrics": {
    "2026-01-04": {
      "productivity": {
        "features_completed": 2,
        "commits": 15,
        "prs_merged": 3,
        "time_to_first_commit_minutes": 12
      },
      "quality": {
        "review_score_avg": 8.5,
        "bugs_found_in_review": 2,
        "bugs_found_in_prod": 0,
        "test_coverage_delta": "+5%"
      },
      "learning": {
        "skills_invoked": ["git-expert", "tdd", "debugging"],
        "patterns_matched": 8,
        "auto_updates": 1
      },
      "context": {
        "tokens_used": 45000,
        "compactions": 0,
        "memory_retrievals": 12
      }
    }
  }
}
```

### 16.3 Weekly Summary

Generated automatically, includes:
- Productivity trends
- Quality improvements
- Skills used most
- Patterns discovered
- Recommendations for next week
