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
```

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
