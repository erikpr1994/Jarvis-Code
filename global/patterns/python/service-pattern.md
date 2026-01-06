---
name: service-pattern
category: pattern
language: python
description: Python service layer pattern with dependency injection, error handling, and testing
keywords: [python, service, dependency-injection, repository, clean-architecture]
---

# Python Service Pattern

## Overview

A clean service layer pattern for Python applications with:
- Clear separation of concerns
- Dependency injection for testability
- Structured error handling
- Type hints throughout
- Easy unit testing

## Directory Structure

```
src/
├── services/              # Business logic layer
│   ├── __init__.py
│   ├── base.py            # Base service class
│   ├── user_service.py
│   └── order_service.py
├── repositories/          # Data access layer
│   ├── __init__.py
│   ├── base.py            # Base repository
│   └── user_repository.py
├── models/                # Domain models
│   ├── __init__.py
│   └── user.py
├── schemas/               # Pydantic schemas
│   ├── __init__.py
│   └── user.py
└── exceptions/            # Custom exceptions
    ├── __init__.py
    └── service.py
```

## Custom Exceptions

```python
# exceptions/service.py
from typing import Any, Optional


class ServiceError(Exception):
    """Base exception for service layer errors."""

    def __init__(
        self,
        message: str,
        code: str = "SERVICE_ERROR",
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        self.message = message
        self.code = code
        self.details = details or {}
        super().__init__(self.message)


class NotFoundError(ServiceError):
    """Resource not found."""

    def __init__(
        self,
        resource: str,
        identifier: Any,
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        super().__init__(
            message=f"{resource} not found: {identifier}",
            code="NOT_FOUND",
            details={"resource": resource, "identifier": str(identifier), **(details or {})},
        )


class ValidationError(ServiceError):
    """Validation failed."""

    def __init__(
        self,
        message: str,
        field: Optional[str] = None,
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        super().__init__(
            message=message,
            code="VALIDATION_ERROR",
            details={"field": field, **(details or {})},
        )


class AuthorizationError(ServiceError):
    """Authorization failed."""

    def __init__(
        self,
        message: str = "Insufficient permissions",
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        super().__init__(
            message=message,
            code="AUTHORIZATION_ERROR",
            details=details,
        )


class ConflictError(ServiceError):
    """Resource conflict (e.g., duplicate)."""

    def __init__(
        self,
        message: str,
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        super().__init__(
            message=message,
            code="CONFLICT",
            details=details,
        )
```

## Base Repository

```python
# repositories/base.py
from abc import ABC, abstractmethod
from typing import Generic, TypeVar, Optional, Sequence
from uuid import UUID

T = TypeVar("T")


class BaseRepository(ABC, Generic[T]):
    """Abstract base repository with common CRUD operations."""

    @abstractmethod
    async def get_by_id(self, id: UUID) -> Optional[T]:
        """Get entity by ID."""
        ...

    @abstractmethod
    async def get_all(
        self,
        skip: int = 0,
        limit: int = 100,
    ) -> Sequence[T]:
        """Get all entities with pagination."""
        ...

    @abstractmethod
    async def create(self, entity: T) -> T:
        """Create new entity."""
        ...

    @abstractmethod
    async def update(self, id: UUID, entity: T) -> Optional[T]:
        """Update existing entity."""
        ...

    @abstractmethod
    async def delete(self, id: UUID) -> bool:
        """Delete entity by ID."""
        ...

    @abstractmethod
    async def count(self) -> int:
        """Count total entities."""
        ...
```

## User Repository Implementation

```python
# repositories/user_repository.py
from typing import Optional, Sequence
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from models.user import User
from repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    """Repository for User entity operations."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, id: UUID) -> Optional[User]:
        result = await self._session.execute(
            select(User).where(User.id == id)
        )
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> Optional[User]:
        result = await self._session.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()

    async def get_all(
        self,
        skip: int = 0,
        limit: int = 100,
    ) -> Sequence[User]:
        result = await self._session.execute(
            select(User)
            .offset(skip)
            .limit(limit)
            .order_by(User.created_at.desc())
        )
        return result.scalars().all()

    async def create(self, user: User) -> User:
        self._session.add(user)
        await self._session.flush()
        await self._session.refresh(user)
        return user

    async def update(self, id: UUID, user: User) -> Optional[User]:
        existing = await self.get_by_id(id)
        if not existing:
            return None

        for key, value in user.__dict__.items():
            if not key.startswith("_") and value is not None:
                setattr(existing, key, value)

        await self._session.flush()
        await self._session.refresh(existing)
        return existing

    async def delete(self, id: UUID) -> bool:
        user = await self.get_by_id(id)
        if not user:
            return False

        await self._session.delete(user)
        await self._session.flush()
        return True

    async def count(self) -> int:
        result = await self._session.execute(
            select(func.count()).select_from(User)
        )
        return result.scalar_one()
```

## Base Service

```python
# services/base.py
from typing import Generic, TypeVar, Optional, Sequence
from uuid import UUID

from repositories.base import BaseRepository
from exceptions.service import NotFoundError

T = TypeVar("T")
R = TypeVar("R", bound=BaseRepository)


class BaseService(Generic[T, R]):
    """Base service with common CRUD operations."""

    def __init__(self, repository: R, resource_name: str = "Resource") -> None:
        self._repository = repository
        self._resource_name = resource_name

    async def get_by_id(self, id: UUID) -> T:
        """Get entity by ID or raise NotFoundError."""
        entity = await self._repository.get_by_id(id)
        if not entity:
            raise NotFoundError(self._resource_name, id)
        return entity

    async def get_by_id_optional(self, id: UUID) -> Optional[T]:
        """Get entity by ID or return None."""
        return await self._repository.get_by_id(id)

    async def get_all(
        self,
        skip: int = 0,
        limit: int = 100,
    ) -> Sequence[T]:
        """Get all entities with pagination."""
        return await self._repository.get_all(skip=skip, limit=limit)

    async def delete(self, id: UUID) -> bool:
        """Delete entity by ID."""
        deleted = await self._repository.delete(id)
        if not deleted:
            raise NotFoundError(self._resource_name, id)
        return True

    async def count(self) -> int:
        """Count total entities."""
        return await self._repository.count()
```

## User Service Implementation

```python
# services/user_service.py
from typing import Optional, Sequence
from uuid import UUID

from models.user import User
from schemas.user import UserCreate, UserUpdate
from repositories.user_repository import UserRepository
from services.base import BaseService
from exceptions.service import (
    ConflictError,
    ValidationError,
    AuthorizationError,
)


class UserService(BaseService[User, UserRepository]):
    """Service for user-related business logic."""

    def __init__(self, repository: UserRepository) -> None:
        super().__init__(repository, "User")

    async def create_user(self, data: UserCreate) -> User:
        """Create a new user with validation."""
        # Check for existing email
        existing = await self._repository.get_by_email(data.email)
        if existing:
            raise ConflictError(
                "User with this email already exists",
                details={"email": data.email},
            )

        # Validate password strength
        if len(data.password) < 8:
            raise ValidationError(
                "Password must be at least 8 characters",
                field="password",
            )

        # Create user entity
        user = User(
            email=data.email,
            name=data.name,
            hashed_password=self._hash_password(data.password),
        )

        return await self._repository.create(user)

    async def update_user(
        self,
        id: UUID,
        data: UserUpdate,
        current_user_id: UUID,
    ) -> User:
        """Update user with authorization check."""
        # Get existing user
        user = await self.get_by_id(id)

        # Authorization check
        if user.id != current_user_id:
            raise AuthorizationError(
                "Cannot update another user's profile",
                details={"user_id": str(id)},
            )

        # Check email uniqueness if changing
        if data.email and data.email != user.email:
            existing = await self._repository.get_by_email(data.email)
            if existing:
                raise ConflictError(
                    "Email already in use",
                    details={"email": data.email},
                )

        # Update fields
        if data.email:
            user.email = data.email
        if data.name:
            user.name = data.name

        return await self._repository.update(id, user)

    async def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email address."""
        return await self._repository.get_by_email(email)

    async def search_users(
        self,
        query: str,
        skip: int = 0,
        limit: int = 20,
    ) -> Sequence[User]:
        """Search users by name or email."""
        # Implementation would use repository method with search
        pass

    async def deactivate_user(
        self,
        id: UUID,
        current_user_id: UUID,
        is_admin: bool = False,
    ) -> User:
        """Deactivate a user account."""
        user = await self.get_by_id(id)

        # Only admins or the user themselves can deactivate
        if not is_admin and user.id != current_user_id:
            raise AuthorizationError(
                "Cannot deactivate another user's account",
            )

        user.is_active = False
        return await self._repository.update(id, user)

    def _hash_password(self, password: str) -> str:
        """Hash password for storage."""
        # Use proper password hashing library
        import hashlib
        return hashlib.sha256(password.encode()).hexdigest()
```

## Pydantic Schemas

```python
# schemas/user.py
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    """Base user schema with common fields."""

    email: EmailStr
    name: str = Field(..., min_length=1, max_length=100)


class UserCreate(UserBase):
    """Schema for creating a new user."""

    password: str = Field(..., min_length=8, max_length=100)


class UserUpdate(BaseModel):
    """Schema for updating a user."""

    email: Optional[EmailStr] = None
    name: Optional[str] = Field(None, min_length=1, max_length=100)


class UserResponse(UserBase):
    """Schema for user response."""

    id: UUID
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class UserListResponse(BaseModel):
    """Schema for paginated user list."""

    items: list[UserResponse]
    total: int
    page: int
    page_size: int
    total_pages: int
```

## Dependency Injection

```python
# dependencies.py
from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession

from database import async_session_maker
from repositories.user_repository import UserRepository
from services.user_service import UserService


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """Get database session."""
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def get_user_repository(
    session: AsyncSession = Depends(get_session),
) -> UserRepository:
    """Get user repository instance."""
    return UserRepository(session)


async def get_user_service(
    repository: UserRepository = Depends(get_user_repository),
) -> UserService:
    """Get user service instance."""
    return UserService(repository)
```

## API Usage

```python
# api/users.py
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from schemas.user import UserCreate, UserUpdate, UserResponse, UserListResponse
from services.user_service import UserService
from dependencies import get_user_service
from exceptions.service import ServiceError, NotFoundError, ConflictError

router = APIRouter(prefix="/users", tags=["users"])


def handle_service_error(error: ServiceError) -> HTTPException:
    """Convert service errors to HTTP exceptions."""
    status_map = {
        "NOT_FOUND": status.HTTP_404_NOT_FOUND,
        "CONFLICT": status.HTTP_409_CONFLICT,
        "VALIDATION_ERROR": status.HTTP_422_UNPROCESSABLE_ENTITY,
        "AUTHORIZATION_ERROR": status.HTTP_403_FORBIDDEN,
    }
    return HTTPException(
        status_code=status_map.get(error.code, status.HTTP_500_INTERNAL_SERVER_ERROR),
        detail={"message": error.message, "code": error.code, "details": error.details},
    )


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    data: UserCreate,
    service: UserService = Depends(get_user_service),
) -> UserResponse:
    """Create a new user."""
    try:
        user = await service.create_user(data)
        return UserResponse.model_validate(user)
    except ServiceError as e:
        raise handle_service_error(e)


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: UUID,
    service: UserService = Depends(get_user_service),
) -> UserResponse:
    """Get user by ID."""
    try:
        user = await service.get_by_id(user_id)
        return UserResponse.model_validate(user)
    except ServiceError as e:
        raise handle_service_error(e)


@router.get("", response_model=UserListResponse)
async def list_users(
    page: int = 1,
    page_size: int = 20,
    service: UserService = Depends(get_user_service),
) -> UserListResponse:
    """List users with pagination."""
    skip = (page - 1) * page_size
    users = await service.get_all(skip=skip, limit=page_size)
    total = await service.count()

    return UserListResponse(
        items=[UserResponse.model_validate(u) for u in users],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )
```

## Testing

```python
# tests/services/test_user_service.py
import pytest
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

from services.user_service import UserService
from schemas.user import UserCreate
from exceptions.service import ConflictError, NotFoundError


@pytest.fixture
def mock_repository() -> AsyncMock:
    """Create mock user repository."""
    return AsyncMock()


@pytest.fixture
def user_service(mock_repository: AsyncMock) -> UserService:
    """Create user service with mock repository."""
    return UserService(mock_repository)


class TestUserService:
    """Tests for UserService."""

    async def test_create_user_success(
        self,
        user_service: UserService,
        mock_repository: AsyncMock,
    ) -> None:
        """Test creating a new user successfully."""
        # Arrange
        mock_repository.get_by_email.return_value = None
        mock_repository.create.return_value = MagicMock(
            id=uuid4(),
            email="test@example.com",
            name="Test User",
        )

        data = UserCreate(
            email="test@example.com",
            name="Test User",
            password="password123",
        )

        # Act
        result = await user_service.create_user(data)

        # Assert
        mock_repository.get_by_email.assert_called_once_with("test@example.com")
        mock_repository.create.assert_called_once()
        assert result.email == "test@example.com"

    async def test_create_user_duplicate_email(
        self,
        user_service: UserService,
        mock_repository: AsyncMock,
    ) -> None:
        """Test creating user with duplicate email raises ConflictError."""
        # Arrange
        mock_repository.get_by_email.return_value = MagicMock(
            email="test@example.com"
        )

        data = UserCreate(
            email="test@example.com",
            name="Test User",
            password="password123",
        )

        # Act & Assert
        with pytest.raises(ConflictError) as exc_info:
            await user_service.create_user(data)

        assert exc_info.value.code == "CONFLICT"
        assert "already exists" in exc_info.value.message

    async def test_get_by_id_not_found(
        self,
        user_service: UserService,
        mock_repository: AsyncMock,
    ) -> None:
        """Test getting non-existent user raises NotFoundError."""
        # Arrange
        mock_repository.get_by_id.return_value = None
        user_id = uuid4()

        # Act & Assert
        with pytest.raises(NotFoundError) as exc_info:
            await user_service.get_by_id(user_id)

        assert exc_info.value.code == "NOT_FOUND"
```

## Best Practices

### Do

- Use dependency injection for testability
- Define clear interfaces (abstract base classes)
- Handle errors at appropriate layers
- Use type hints everywhere
- Keep services focused on business logic
- Use Pydantic for validation
- Write comprehensive tests

### Don't

- Put database logic in services
- Put business logic in repositories
- Catch and ignore exceptions
- Use `Any` type
- Skip validation
- Mix concerns between layers
- Create god services

## Service Layer Checklist

- [ ] Clear separation from data access layer
- [ ] Custom exceptions for error handling
- [ ] Dependency injection for repositories
- [ ] Pydantic schemas for validation
- [ ] Type hints on all methods
- [ ] Authorization checks where needed
- [ ] Unit tests with mocked dependencies
- [ ] Integration tests with real database
