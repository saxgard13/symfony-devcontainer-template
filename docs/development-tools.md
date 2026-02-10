# Development Tools

This document covers optional development tools that enhance your Symfony development experience: debugging, profiling, code generation, and testing.

## Overview

| Tool | Package | Purpose | Use Case |
|------|---------|---------|----------|
| **Debug Bundle** | `symfony/debug-bundle` | Interactive debugging toolbar | Inspecting requests, queries, performance |
| **Profiler Pack** | `symfony/profiler-pack` | Performance profiling & analysis | Analyzing slow queries, memory usage |
| **Maker Bundle** | `symfony/maker-bundle` | Code scaffolding & generation | Create entities, controllers, forms quickly |
| **Test Pack** | `symfony/test-pack` | Complete testing framework | Writing unit & functional tests |

---

## Installation

### All Tools at Once

```bash
cd backend/
composer require --dev symfony/debug-bundle
composer require --dev symfony/profiler-pack
composer require --dev symfony/maker-bundle
composer require --dev symfony/test-pack
```

### Individual Packages

Install only what you need:

```bash
# Debug & Profiling
composer require --dev symfony/debug-bundle
composer require --dev symfony/profiler-pack

# Code Generation
composer require --dev symfony/maker-bundle

# Testing
composer require --dev symfony/test-pack
composer require --dev symfony/browser-kit
composer require --dev symfony/css-selector
```

**Note:** `symfony/test-pack` automatically includes `symfony/browser-kit` and `symfony/css-selector`, so the additional commands above are optional but shown for clarity if you prefer explicit installation.

---

## Debug Bundle & Profiler Pack

### What They Do

**Debug Bundle:**
- Displays a toolbar at the bottom of every page in development
- Shows request/response information
- Lists all database queries
- Displays logs and errors
- Links to the Profiler for detailed analysis

**Profiler Pack:**
- Stores detailed metrics about every request
- Analyzes performance bottlenecks
- Tracks memory usage
- Monitors database performance
- Identifies slow queries

### Usage

**No configuration needed!** Both activate automatically in development mode.

**Access the Debug Toolbar:**
1. Run your Symfony server: `symfony server:start --no-tls`
2. Visit your app in browser: `http://localhost:8000`
3. Look for the **Symfony debug toolbar** at the bottom of the page (black bar)

**View Profiler Details:**
- Click any token (timestamp) in the debug toolbar
- Opens detailed profiler page
- Shows requests, database queries, memory, etc.

### Profiler URL

```
http://localhost:8000/_profiler/
```

Access all recorded profiler data from this admin page.

### Common Inspection Tasks

**Find slow database queries:**
1. Open debug toolbar
2. Click on "Database" section
3. Look for high execution times

**Check memory usage:**
1. Open profiler page
2. View "Memory" tab
3. Identify leaks or high consumption

**Debug Twig rendering:**
1. Open profiler
2. View "Twig" tab
3. See all rendered templates & variables

---

## Maker Bundle

### What It Does

Generates boilerplate code for common Symfony patterns:

```bash
# Create an Entity with database mapper
symfony console make:entity User

# Create a Controller with CRUD actions
symfony console make:controller PostController

# Create a Form type
symfony console make:form PostType

# Create an Event Subscriber
symfony console make:subscriber UserSubscriber

# Create a Command
symfony console make:command SendReminders
```

### Available Commands

```bash
symfony console make:entity              # Create a Doctrine entity
symfony console make:controller          # Create a controller
symfony console make:form                # Create a form type
symfony console make:event-subscriber    # Create an event listener
symfony console make:command             # Create a console command
symfony console make:migration           # Create a database migration
symfony console make:seeder              # Create database fixtures
symfony console make:test                # Create a test class
symfony console make:validator           # Create a custom validator
```

### Example: Create an Entity

```bash
symfony console make:entity Product

# Questions:
# New property name (blank to stop adding fields)? name
# Field type (enter ? to see all types): string
# Field length (for string fields): 255
# Is nullable (no): no
# Unique (no): no
```

**Generated:**
- `src/Entity/Product.php` - Entity class
- `src/Repository/ProductRepository.php` - Repository for queries
- Migration file ready to run

---

## Test Pack

### What's Included

```bash
composer require --dev symfony/test-pack
```

Installs:
- **PHPUnit** - Testing framework
- **symfony/test** - Symfony testing utilities
- **symfony/browser-kit** - HTTP client for testing
- **symfony/css-selector** - DOM navigation in tests

### Writing Tests

**Create a test class:**

```bash
symfony console make:test UserControllerTest
```

**Example: Functional Test**

```php
<?php
// tests/Controller/UserControllerTest.php

namespace App\Tests\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class UserControllerTest extends WebTestCase
{
    public function testUserListPageLoads(): void
    {
        $client = static::createClient();
        $crawler = $client->request('GET', '/users');

        $this->assertResponseIsSuccessful();
        $this->assertSelectorTextContains('h1', 'Users');
    }

    public function testUserCanBeCreated(): void
    {
        $client = static::createClient();

        $client->request('POST', '/users', [
            'name' => 'John Doe',
            'email' => 'john@example.com'
        ]);

        $this->assertResponseStatusCodeSame(201);
    }
}
```

### Running Tests

```bash
# Run all tests
php bin/phpunit

# Run specific test file
php bin/phpunit tests/Controller/UserControllerTest.php

# Run specific test method
php bin/phpunit tests/Controller/UserControllerTest.php --filter testUserListPageLoads

# Watch mode (requires phpunit-watcher)
phpunit-watcher watch
```

### Test Coverage

```bash
# Generate coverage report
php bin/phpunit --coverage-html var/coverage

# View in browser
open var/coverage/index.html
```

---

## Frontend Development Tools

Optional tools to enhance your JavaScript/TypeScript frontend development experience.

### Overview

| Tool | Package | Purpose | Use Case |
|------|---------|---------|-------------|
| **Jest** or **Vitest** | `jest`, `vitest` | Unit & component testing | Testing React/Vue/Svelte logic |
| **Testing Library** | `@testing-library/react`, etc. | Component testing utilities | Testing user interactions |
| **Storybook** | `storybook` | Component development & documentation | Building & documenting UI components |
| **Prettier** | `prettier` | Code formatting | Auto-formatting JavaScript/TypeScript |

### Installation

#### Testing Framework (Choose One)

**Option 1: Jest** (More mature, common in Create React App)
```bash
cd frontend
npm install --save-dev jest @testing-library/react @testing-library/jest-dom
npx jest --init
```

**Option 2: Vitest** (Faster, modern, recommended for Vite projects)
```bash
cd frontend
npm install --save-dev vitest @testing-library/react @testing-library/jest-dom
```

#### Storybook (Optional)

```bash
cd frontend
npx storybook@latest init
```

Automatically detects your framework (React, Vue, etc.) and installs dependencies.

#### Prettier (Code Formatting)

```bash
cd frontend
npm install --save-dev prettier
```

> **Note:** Most JS frameworks (Next.js, Vite, Create React App) include Prettier in their initial setup. Check `package.json` first.

### Jest

**What it does:**
- Runs unit tests for JavaScript/TypeScript code
- Tests React/Vue/Svelte component logic
- Generates code coverage reports
- Runs with built-in mocking and async support

**Quick Start:**

```bash
# Create a test file
touch src/components/Button.test.jsx

# Add a simple test
cat > src/components/Button.test.jsx << 'EOF'
import { render, screen } from '@testing-library/react';
import Button from './Button';

test('renders button with text', () => {
  render(<Button>Click me</Button>);
  expect(screen.getByText('Click me')).toBeInTheDocument();
});
EOF

# Run tests
npm test

# Watch mode
npm test -- --watch

# Coverage report
npm test -- --coverage
```

**Configuration** (`.jest.config.js`):
```javascript
export default {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/src/setupTests.js'],
  moduleNameMapper: {
    '\\.(css|less|scss)$': 'identity-obj-proxy',
  },
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.{js,jsx,ts,tsx}',
    '<rootDir>/src/**/*.{spec,test}.{js,jsx,ts,tsx}',
  ],
};
```

### Vitest

**What it does:**
- Modern unit testing framework (faster than Jest)
- Same API as Jest (drop-in replacement)
- Works great with Vite, Next.js 13+
- Built-in TypeScript support

**Quick Start:**

```bash
# Already installed via npm install --save-dev vitest

# Create a test file
touch src/components/Button.test.jsx

# Run tests
npm run test

# Watch mode
npm run test -- --watch

# Coverage
npm run test -- --coverage
```

**Configuration** (`vitest.config.ts`):
```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/setupTests.ts'],
  },
});
```

### Testing Library

**What it does:**
- Provides utilities to test React/Vue/Svelte components
- Tests behavior from a user's perspective (not implementation details)
- Works with Jest, Vitest, or any testing framework

**Common Methods:**

```javascript
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('user interaction', async () => {
  const user = userEvent.setup();
  render(<LoginForm />);

  // Find elements like a user would
  await user.type(screen.getByLabelText(/username/i), 'john');
  await user.type(screen.getByLabelText(/password/i), 'secret');
  await user.click(screen.getByRole('button', { name: /login/i }));

  expect(screen.getByText(/welcome/i)).toBeInTheDocument();
});
```

### Storybook

**What it does:**
- Isolated component development environment
- Auto-generates component documentation
- Tests component variations (stories)
- Works with React, Vue, Svelte, Angular, etc.

**Quick Start:**

```bash
# Initialize Storybook (auto-detects your framework)
npx storybook@latest init

# Start Storybook server
npm run storybook

# Build static site
npm run build-storybook
```

**Example Story** (`src/components/Button.stories.jsx`):

```jsx
import Button from './Button';

export default {
  title: 'Components/Button',
  component: Button,
  args: { children: 'Click me' },
};

export const Primary = {};
export const Disabled = { args: { disabled: true } };
export const Large = { args: { size: 'large' } };
```

Access at `http://localhost:6006`

### Prettier

**What it does:**
- Auto-formats JavaScript/TypeScript/CSS/HTML
- Enforces consistent code style
- Integrates with VSCode (auto-format on save)

**Quick Start:**

```bash
# Format all files
npm run format

# Check formatting (dry run)
npm run format:check
```

**Configuration** (`.prettierrc.json`):

```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2
}
```

**VS Code Integration:**

Add to `.vscode/settings.json` (in `frontend/` folder):
```json
{
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  }
}
```

---

## Best Practices

### When to Install Each Tool

| Situation | Install | Reason |
|-----------|---------|--------|
| **First project** | All | Learn best practices |
| **Debugging issues** | Debug + Profiler | Fast problem identification |
| **Building features** | Maker | Speed up development |
| **Production app** | Test pack | Ensure quality |
| **Simple prototype** | None | Keep dependencies minimal |

### Development Workflow

```bash
# 1. Generate entity
symfony console make:entity

# 2. Create migration
symfony console make:migration
symfony console doctrine:migrations:migrate

# 3. Generate controller
symfony console make:controller

# 4. Use debug toolbar to test
# http://localhost:8000/your-endpoint

# 5. Write tests
symfony console make:test YourControllerTest

# 6. Run tests
php bin/phpunit
```

### Tips

- **Debug toolbar not showing?** Check you're in `dev` environment and not using API-only routes
- **Profiler data not recording?** Make sure `profiler: true` in `config/packages/framework.yaml`
- **Maker asking too many questions?** Use `--no-interaction` flag for defaults
- **Tests running slow?** Use `--stop-on-failure` to fail fast during development

---

## Removing Tools

If you don't need these packages:

```bash
# Remove individually
composer remove --dev symfony/debug-bundle
composer remove --dev symfony/profiler-pack

# Or remove all at once
composer remove --dev \
  symfony/debug-bundle \
  symfony/profiler-pack \
  symfony/maker-bundle \
  symfony/test-pack
```

> **Note:** Removing development tools doesn't affect your application—they're only active in `dev` environment.

---

## References

- [Symfony Debug Bundle Documentation](https://symfony.com/doc/current/profiler.html)
- [Symfony Maker Bundle Commands](https://symfony.com/doc/current/bundles/SymfonyMakerBundle/index.html)
- [PHPUnit Documentation](https://phpunit.de/)
- [Symfony Testing Documentation](https://symfony.com/doc/current/testing.html)
