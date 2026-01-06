# Integration Tests

End-to-end tests for the complete Jarvis system.

## Test Files

- `test-full-flow.sh` - Complete system integration tests
  - Fresh installation
  - Directory structure validation
  - Settings file validation
  - Hook execution
  - Safe reinstallation
  - Project initialization
  - Command availability
  - Version tracking
  - System integration

## Running Tests

```bash
# Run all integration tests
./tests/jarvis/test-jarvis.sh integration

# Run specific test
./tests/jarvis/integration/test-full-flow.sh
```

## Test Environment

Tests run in an isolated HOME directory to avoid modifying the user's actual configuration.
