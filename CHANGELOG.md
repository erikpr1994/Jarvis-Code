# Changelog

All notable changes to Jarvis will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-06

### Features

- **Learning System**: Auto-archival scheduler for hot/warm/cold memory tiers
- **Learning System**: User correction detection in learning-capture hook
- **Error Recovery**: Integrated error-handler into all hooks with degradation levels
- **Distribution**: Version management with semver and update checking
- **Distribution**: Changelog generation script
- **Documentation**: QUICK-START.md for 5-minute onboarding

### Core System

- **Skills**: Smart skill activation based on context and keywords
- **Agents**: Code review, test generation, and specialized agents
- **Hooks**: Session start, learning capture, metrics, compaction preservation
- **Commands**: /init, /plan, /execute, /status, /inbox, /learnings
- **Patterns**: Indexed pattern library for common solutions

### Installation

- Idempotent installer with backup preservation
- User modification detection (JARVIS-USER-MODIFIED marker)
- Prerequisite checking (git, bash 4+, node optional)

### Testing

- 14/14 tests passing
- Hook tests for learning-capture and metrics-capture
- Installation verification tests

---

**Full Changelog**: Initial release
