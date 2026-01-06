# Patterns

Indexed library of reusable patterns.

## Structure

```
patterns/
├── index.json          # Quick lookup with summaries
├── full/               # Complete pattern documentation
│   ├── architecture/   # Architecture patterns
│   ├── design/         # Design patterns
│   ├── process/        # Process patterns
│   └── integration/    # Integration patterns
└── README.md           # This file
```

## Pattern Categories

### Architecture Patterns
High-level system structure patterns:
- Microservices
- Event-driven architecture
- CQRS
- Hexagonal architecture

### Design Patterns
Object-oriented and functional patterns:
- Creational (Factory, Builder, Singleton)
- Structural (Adapter, Decorator, Facade)
- Behavioral (Strategy, Observer, Command)

### Process Patterns
Development workflow patterns:
- TDD workflow
- Code review process
- CI/CD patterns
- Feature flag patterns

### Integration Patterns
System integration patterns:
- API gateway
- Message queue patterns
- Circuit breaker
- Saga pattern

## Index Format

The `index.json` provides quick lookup:

```json
{
  "patterns": [
    {
      "id": "factory-pattern",
      "name": "Factory Pattern",
      "category": "design",
      "summary": "Creates objects without specifying exact class",
      "file": "full/design/factory.md",
      "tags": ["creational", "oop"]
    }
  ]
}
```

## Adding Patterns

1. Create the full pattern file in `full/<category>/`
2. Add an entry to `index.json`
3. The learning system can auto-add patterns

See `domain/patterns` skill for pattern usage.
