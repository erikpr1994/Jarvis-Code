# Python Project Additions

> Inherits from: global-claude.md + CLAUDE.md.template
> Override: {{OVERRIDE_PARENT}} (set to true for complete override, false for merge)
> Token budget: ~800 tokens

This template extends the base CLAUDE.md with Python-specific patterns.

## Tech Stack Additions

```yaml
languages:
  - Python {{PYTHON_VERSION}}

tooling:
  - {{PACKAGE_MANAGER}} (package manager)
  - {{TYPE_CHECKER}} (type checking)
  - {{LINTER}} (linting)
  - {{FORMATTER}} (formatting)
  - {{TEST_FRAMEWORK}} (testing)
```

## Python Configuration

### pyproject.toml Settings

```toml
[project]
name = "{{PROJECT_NAME}}"
version = "{{PROJECT_VERSION}}"
requires-python = ">={{PYTHON_MIN_VERSION}}"

[tool.{{TYPE_CHECKER}}]
{{TYPE_CHECKER_CONFIG}}

[tool.{{LINTER}}]
{{LINTER_CONFIG}}

[tool.{{FORMATTER}}]
{{FORMATTER_CONFIG}}
```

## Key Patterns

### Type Hints

- Use type hints for all function signatures
- Use `typing` module for complex types
- Prefer `|` union syntax (Python 3.10+) over `Union`
- Use `TypedDict` for structured dictionaries

```python
from typing import TypedDict

class UserData(TypedDict):
    id: str
    name: str
    email: str | None

def process_user(user: UserData) -> str:
    return user["name"].upper()
```

### Imports

- Use absolute imports over relative imports
- Group imports: stdlib -> third-party -> local
- Use `from __future__ import annotations` for forward references

```python
from __future__ import annotations

import os
from pathlib import Path

import httpx
from pydantic import BaseModel

from app.models import User
from app.utils import helpers
```

### Error Handling

- Use specific exception types
- Create custom exceptions inheriting from base classes
- Use context managers for resource cleanup

```python
class AppError(Exception):
    """Base exception for application errors."""
    pass

class ValidationError(AppError):
    """Raised when validation fails."""
    def __init__(self, field: str, message: str):
        self.field = field
        self.message = message
        super().__init__(f"{field}: {message}")

# Usage with context manager
from contextlib import contextmanager

@contextmanager
def managed_resource():
    resource = acquire_resource()
    try:
        yield resource
    finally:
        release_resource(resource)
```

### Async Patterns

- Use `asyncio` for concurrent I/O operations
- Prefer `async with` for async context managers
- Use `asyncio.gather` for parallel execution

```python
import asyncio
import httpx

async def fetch_all(urls: list[str]) -> list[dict]:
    async with httpx.AsyncClient() as client:
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks)
        return [r.json() for r in responses]
```

### Data Classes & Models

```python
from dataclasses import dataclass, field
from pydantic import BaseModel, Field

# Use dataclass for simple data containers
@dataclass
class Point:
    x: float
    y: float
    label: str = ""

# Use Pydantic for validation
class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: str
    age: int = Field(ge=0, le=150)
```

## Testing Patterns

### Test Framework: {{TEST_FRAMEWORK}}

```python
# Test file structure
import pytest
from {{PROJECT_NAME}}.module import function_under_test

class TestFunctionUnderTest:
    """Tests for function_under_test."""

    def test_expected_case(self):
        """Test the happy path."""
        # Arrange
        input_data = "test"

        # Act
        result = function_under_test(input_data)

        # Assert
        assert result == "expected"

    def test_edge_case(self):
        """Test edge case handling."""
        with pytest.raises(ValueError):
            function_under_test(None)

    @pytest.fixture
    def sample_data(self):
        """Fixture for test data."""
        return {"key": "value"}

    @pytest.mark.parametrize("input,expected", [
        ("a", 1),
        ("b", 2),
    ])
    def test_parameterized(self, input, expected):
        """Test multiple inputs."""
        assert function_under_test(input) == expected
```

### Async Testing

```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    result = await async_function_under_test()
    assert result is not None
```

## Common Commands

```bash
# Run application
{{RUN_CMD}}

# Type checking
{{TYPE_CHECK_CMD}}

# Linting
{{LINT_CMD}}

# Formatting
{{FORMAT_CMD}}

# Testing
{{TEST_CMD}}

# Test with coverage
{{TEST_COVERAGE_CMD}}
```

## Virtual Environment

### Environment Management: {{ENV_MANAGER}}

```bash
# Create environment
{{CREATE_ENV_CMD}}

# Activate environment
{{ACTIVATE_ENV_CMD}}

# Install dependencies
{{INSTALL_DEPS_CMD}}

# Install dev dependencies
{{INSTALL_DEV_DEPS_CMD}}

# Update dependencies
{{UPDATE_DEPS_CMD}}
```

## DO NOT

- Use mutable default arguments (`def f(x=[]): ...`)
- Ignore type checker errors without `# type: ignore[specific-error]`
- Use bare `except:` clauses (catch specific exceptions)
- Mix tabs and spaces (use 4 spaces consistently)
- Use `from module import *` (explicit imports only)
- Forget to close file handles (use context managers)
- Use `eval()` or `exec()` with untrusted input

## File Conventions

| Pattern | Purpose |
|---------|---------|
| `*.py` | Python source files |
| `*_test.py` or `test_*.py` | Test files |
| `conftest.py` | pytest fixtures and configuration |
| `__init__.py` | Package initialization |
| `py.typed` | PEP 561 marker for typed packages |

## Project Structure

```
{{PROJECT_NAME}}/
{{PROJECT_STRUCTURE}}
```

## Dependency Management

### Lock Files

- `requirements.txt` - pip freeze output
- `pyproject.toml` - PEP 621 project metadata
- `poetry.lock` / `uv.lock` / `pdm.lock` - dependency lock files

### Security

```bash
# Audit dependencies
{{AUDIT_CMD}}

# Update vulnerable packages
{{UPDATE_VULNERABLE_CMD}}
```
