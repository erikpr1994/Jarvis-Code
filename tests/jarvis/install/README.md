# Install Tests

Tests for the Jarvis installation system.

## Test Files

- `test-install.sh` - Main installation tests
  - Prerequisites check
  - Directory creation
  - File copying
  - Backup creation
  - Idempotent re-installation
  - User modification preservation

## Running Tests

```bash
# Run all install tests
./tests/jarvis/test-jarvis.sh install

# Run specific test
./tests/jarvis/install/test-install.sh
```

## Test Environment

Tests run in an isolated HOME directory (`$TMPDIR/jarvis-test-xxx/home`) to avoid modifying the user's actual `~/.claude` directory.
