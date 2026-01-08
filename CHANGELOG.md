# Changelog

All notable changes to Jarvis will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.0 (2026-01-08)


### Features

* add automatic version bumping on merge to main ([e143e21](https://github.com/erikpr1994/Jarvis-Code/commit/e143e210558d063c107b328fda3e513841e102b2))
* add configurable rules and /config command ([d3ac7bc](https://github.com/erikpr1994/Jarvis-Code/commit/d3ac7bcfce4a634be979bf859bb88f3c968b157f))
* add missing commands and verification system ([9a90d5d](https://github.com/erikpr1994/Jarvis-Code/commit/9a90d5da81ce1dca2b79ac77528c846bdc3f95bb))
* add per-directory testing strategy and /update command ([4bae006](https://github.com/erikpr1994/Jarvis-Code/commit/4bae0067a3c674a22eb0c8ba2d2d77466f36a617))
* complete Jarvis implementation to 100% ([b522ff2](https://github.com/erikpr1994/Jarvis-Code/commit/b522ff23b2026fe027426f4658f716f93847cb28))
* **hooks:** add git-safety-guard for destructive command protection ([77c14cb](https://github.com/erikpr1994/Jarvis-Code/commit/77c14cb78ef398fd2d1c735965e99cf301cc00d2))
* implement Jarvis AI assistant system ([272e645](https://github.com/erikpr1994/Jarvis-Code/commit/272e6451f3ca43bab23c21e25b923108c5f26567))
* interactive preferences setup and bash improvements ([36d1b25](https://github.com/erikpr1994/Jarvis-Code/commit/36d1b2513e81a0d7c2b47e99e918324df9917a4d))
* restructure skills to native SKILL.md format and fix hooks ([d2ee17b](https://github.com/erikpr1994/Jarvis-Code/commit/d2ee17b494d9a2c96adae2209a0b66cf630a6d23))
* unified preferences system for rules and hooks ([#1](https://github.com/erikpr1994/Jarvis-Code/issues/1)) ([d14ec0b](https://github.com/erikpr1994/Jarvis-Code/commit/d14ec0bc289edb540f9ffdb88996ed38d32b67bc))


### Bug Fixes

* address PR review feedback ([013b795](https://github.com/erikpr1994/Jarvis-Code/commit/013b795266ed5b6aea0814eb076bf524dfb48e7c))
* address remaining CodeRabbit feedback ([a4adbb5](https://github.com/erikpr1994/Jarvis-Code/commit/a4adbb55d805fd0c23b65a20b7e650bca05b38f9))
* bash 3.2 compatibility across all scripts ([38a9265](https://github.com/erikpr1994/Jarvis-Code/commit/38a9265dc026b23ef2a309998c1eeea012e53773))
* **ci:** remove deprecated package-name from release-please ([a76f887](https://github.com/erikpr1994/Jarvis-Code/commit/a76f88787f50e7ae32ae5e2030abad3386ed9289))
* **hooks:** bash 3.2 compatibility for skill-activation hook ([92f28d8](https://github.com/erikpr1994/Jarvis-Code/commit/92f28d86041e10702af140be391069afac560b41))
* **hooks:** clarify how to invoke skills when blocked ([6192cf5](https://github.com/erikpr1994/Jarvis-Code/commit/6192cf581465673ea2a57d1183a58a937cea4046))
* **hooks:** support inline bypass variables in all hooks ([4279f2c](https://github.com/erikpr1994/Jarvis-Code/commit/4279f2c95e2f461ac617bb0657d07aa33ac3e814))
* **hooks:** support inline bypass variables in block-direct-submit ([df545c6](https://github.com/erikpr1994/Jarvis-Code/commit/df545c6ca7cdfdaccade0d2c0881e01c46cb61ca))
* **install:** bash 3.2 compatibility for arithmetic operations ([1259b64](https://github.com/erikpr1994/Jarvis-Code/commit/1259b64c74483f53a43ff8632adb5d9795bcff48))
* limit version commit lookup to current branch ([1491c54](https://github.com/erikpr1994/Jarvis-Code/commit/1491c543099b820b3aa189658922738c4b128113))
* register require-isolation hook for Edit/Write tools ([2e039df](https://github.com/erikpr1994/Jarvis-Code/commit/2e039df251ff4d4cc18082a7a3aed58442e90d84))
* register require-isolation hook for Edit/Write/NotebookEdit tools ([02c1f0a](https://github.com/erikpr1994/Jarvis-Code/commit/02c1f0aaa5871069d4040e4b740b5c1d726e1e82))
* rename colliding commands to avoid Claude Code conflicts ([016eec5](https://github.com/erikpr1994/Jarvis-Code/commit/016eec52bd59d7d86e8bb85b309bf3404ef22d94))
* rename colliding commands to avoid Claude Code conflicts ([4cd32bd](https://github.com/erikpr1994/Jarvis-Code/commit/4cd32bdd3f6d30e5a894a056ef521c83604ab391))
* replace custom auto-version with release-please ([#3](https://github.com/erikpr1994/Jarvis-Code/issues/3)) ([254d27b](https://github.com/erikpr1994/Jarvis-Code/commit/254d27b97208099195bae8db84ee820eb8365868))
* separate Claude Code settings from Jarvis config ([aa54775](https://github.com/erikpr1994/Jarvis-Code/commit/aa5477581b8e978b9a8b918ac1395f8725e4af56))
* **tests:** update skill tests to match actual directory structure ([0d29a45](https://github.com/erikpr1994/Jarvis-Code/commit/0d29a45e91031f0746c199cf75e7d6f43f2e18db))
* **update:** resolve path computation and set -e issues ([9a0a363](https://github.com/erikpr1994/Jarvis-Code/commit/9a0a363d0ec80d8b6f7453538c1b9d0cc83d5d04))

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
