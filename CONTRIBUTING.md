# Contributing to Patience

Thank you for your interest in contributing to Patience! This document provides guidelines and instructions for contributing.

## Getting Started

### Prerequisites

- Node.js 16+ and npm
- TypeScript knowledge
- Git

### Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/patience.git
   cd patience
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. Build the project:
   ```bash
   npm run build
   ```
5. Run tests:
   ```bash
   npm test
   ```

## Development Workflow

### Branch Naming

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or updates

Example: `feature/add-custom-connector`

### Making Changes

1. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following our coding standards

3. Write or update tests for your changes

4. Ensure all tests pass:
   ```bash
   npm test
   ```

5. Build the project:
   ```bash
   npm run build
   ```

6. Commit your changes:
   ```bash
   git commit -m "feat: add custom connector support"
   ```

### Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Test additions or updates
- `chore:` - Build process or auxiliary tool changes

Examples:
```
feat: add OpenAI connector for adversarial testing
fix: resolve validation error in CSV parser
docs: update README with adversarial testing examples
test: add integration tests for conversation manager
```

### Pull Request Process

1. Update documentation if needed
2. Add tests for new functionality
3. Ensure all tests pass
4. Update CHANGELOG.md with your changes
5. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
6. Create a Pull Request from your fork to the main repository
7. Fill out the PR template completely
8. Wait for review and address any feedback

## Coding Standards

### TypeScript

- Use TypeScript for all code
- Enable strict mode
- Provide type definitions for all functions
- Avoid `any` types when possible
- Use interfaces for object shapes

### Code Style

- Use 2 spaces for indentation
- Use single quotes for strings
- Add semicolons
- Use meaningful variable and function names
- Keep functions small and focused
- Add JSDoc comments for public APIs

Example:
```typescript
/**
 * Validates a bot response against criteria
 * @param response - The bot's response
 * @param criteria - Validation criteria to apply
 * @returns Validation result with pass/fail status
 */
export function validateResponse(
  response: BotResponse,
  criteria: ValidationCriteria
): ValidationResult {
  // Implementation
}
```

### Testing

- Write unit tests for all new functionality
- Use descriptive test names
- Follow the Arrange-Act-Assert pattern
- Mock external dependencies
- Aim for high test coverage

Example:
```typescript
describe('ConversationFilter', () => {
  test('should filter conversations by date range', () => {
    // Arrange
    const conversations = createTestConversations();
    const filter = new ConversationFilter();
    
    // Act
    const filtered = filter.filterByDateRange(
      conversations,
      startDate,
      endDate
    );
    
    // Assert
    expect(filtered).toHaveLength(2);
    expect(filtered[0].timestamp).toBeGreaterThanOrEqual(startDate);
  });
});
```

## Project Structure

```
src/
├── types/           # Type definitions
├── config/          # Configuration management
├── execution/       # Test execution
├── communication/   # Protocol adapters
├── validation/      # Response validation
├── reporting/       # Report generation
├── analysis/        # Log analysis
└── adversarial/     # Adversarial testing
    ├── types/
    ├── connectors/  # LLM provider connectors
    ├── strategies/  # Testing strategies
    └── ...
```

## Adding New Features

### Adding a New LLM Connector

1. Create a new file in `src/adversarial/connectors/`
2. Extend `BaseConnector`
3. Implement required methods:
   - `initialize()`
   - `generateMessage()`
   - `disconnect()`
   - `getName()`
4. Add error handling and rate limiting
5. Update `AdversarialTestOrchestrator` to support the new provider
6. Add configuration example in `examples/`
7. Update documentation

### Adding a New Testing Strategy

1. Create a new class in `src/adversarial/strategies/PromptStrategy.ts`
2. Extend `BaseStrategy`
3. Implement `getSystemPrompt()` and `getName()`
4. Add to the strategy factory function
5. Document the strategy in README and ADVERSARIAL_TESTING.md

### Adding a New Log Format Parser

1. Create a new parser in `src/analysis/parsers/`
2. Implement the `FormatParser` interface
3. Add format detection logic to `LogLoader`
4. Add tests with sample data
5. Update documentation

## Documentation

### What to Document

- All public APIs
- Configuration options
- CLI commands
- Examples and use cases
- Architecture decisions

### Where to Document

- **README.md** - Overview, quick start, main features
- **Code comments** - Implementation details, complex logic
- **examples/** - Working examples and guides
- **ADVERSARIAL_TESTING.md** - Detailed adversarial testing guide
- **API docs** - Generated from JSDoc comments

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test -- src/__tests__/analysis/LogLoader.test.ts

# Run tests in watch mode
npm test -- --watch

# Run tests with coverage
npm test -- --coverage
```

### Writing Tests

- Place tests in `src/__tests__/` directory
- Mirror the source structure
- Use descriptive test names
- Test both success and error cases
- Mock external dependencies (APIs, file system)

## Getting Help

- Open an issue for bugs or feature requests
- Join discussions in existing issues
- Ask questions in pull requests
- Check existing documentation first

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the project
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Personal or political attacks
- Publishing others' private information
- Other unprofessional conduct

## Recognition

Contributors will be recognized in:
- CHANGELOG.md for their contributions
- GitHub contributors page
- Release notes for significant contributions

## Questions?

If you have questions about contributing, please:
1. Check existing documentation
2. Search closed issues
3. Open a new issue with the "question" label

Thank you for contributing to Patience! 🎉
