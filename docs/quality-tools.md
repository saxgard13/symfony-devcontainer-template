# Code Quality Tools

This document explains how to set up and use PHP-CS-Fixer and PHPStan for maintaining code quality in your Symfony project.

## Overview

| Tool | Purpose | Installation | Extension |
|------|---------|--------------|-----------|
| **PHP-CS-Fixer** | Auto-fixes code style (PSR-12) | Composer | ✅ Pre-installed in devcontainer.json |
| **PHPStan** | Detects logical errors & type issues | Composer | ❌ Optional (CLI works without it) |

---

## Installation

### Step 1: Add Packages to composer.json

Inside your `backend/` folder:

```bash
composer require --dev php-cs-fixer/php-cs-fixer
composer require --dev phpstan/phpstan
composer require --dev phpstan/extension-installer
```

This adds:
- **php-cs-fixer/php-cs-fixer** - Fixes code style automatically (official package)
- **phpstan** - Analyzes code for logical errors
- **phpstan/extension-installer** - Enables Symfony-specific rules for PHPStan

### Step 2: Verify devcontainer.json

The **junstyle.php-cs-fixer** extension is already configured in `.devcontainer/devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "junstyle.php-cs-fixer"
      ]
    }
  }
}
```

This extension automatically:
- ✅ Fixes code on save (configurable)
- ✅ Shows fixes in real-time
- ✅ Integrates with VS Code command palette

---

## Configuration Files

### PHP-CS-Fixer: `.php-cs-fixer.php`

Create `.php-cs-fixer.php` in your `backend/` folder:

```php
<?php

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__)
    ->exclude(['var', 'vendor', 'node_modules', 'tests/fixtures'])
    ->notPath('bin/console')
;

return (new PhpCsFixer\Config())
    ->setRiskyAllowed(true)
    ->setRules([
        '@PSR12' => true,
        'array_syntax' => ['syntax' => 'short'],
        'ordered_imports' => [
            'sort_algorithm' => 'alpha',
            'imports_order' => ['class', 'function', 'const'],
        ],
        'no_unused_imports' => true,
        'single_line_throw' => false,
        'multiline_whitespace_before_semicolons' => true,
        'blank_line_before_statement' => [
            'statements' => ['return', 'throw', 'exit'],
        ],
    ])
    ->setFinder($finder)
;
```

**What this config does:**
- ✅ Enforces PSR-12 standard
- ✅ Uses short array syntax (`[]` instead of `array()`)
- ✅ Removes unused imports
- ✅ Organizes imports alphabetically
- ✅ Adds blank lines before return statements

### PHPStan: `phpstan.neon`

Create `phpstan.neon` in your `backend/` folder:

```neon
parameters:
    level: 6
    paths:
        - src
        - tests
    excludePaths:
        - tests/fixtures
        - var/*
    reportUnmatchedIgnoredErrors: false

includes:
    - vendor/phpstan/extension-installer/config/extension-installer.neon
```

**PHPStan Levels (0-9):**
- **Level 6** (Recommended) - Catches most errors without being too strict
- Level 0 - Very loose
- Level 9 - Very strict (may require many type annotations)

**What this config does:**
- ✅ Analyzes `src/` and `tests/`
- ✅ Loads Symfony-specific rules via extension-installer
- ✅ Ignores fixtures and temporary files
- ✅ Sets error reporting level

---

## VS Code Extension Settings vs PHP-CS-Fixer Configuration

### ⚠️ Important Distinction

There are **TWO separate configuration layers**:

| Layer | Location | Controls | Scope |
|-------|----------|----------|-------|
| **VSCode Extension** | `.devcontainer/devcontainer.json` | **WHEN** formatting happens | Local dev only (VSCode) |
| **PHP-CS-Fixer** | `.php-cs-fixer.php` | **WHAT** gets formatted | Everywhere (local + CI/CD) |

### Example: VSCode Settings

```json
// In devcontainer.json - Extension behavior
"php-cs-fixer.onsave": true,                    // Auto-fix when you save
"php-cs-fixer.autoFixByBracket": false,         // Don't auto-fix when typing }
"php-cs-fixer.autoFixBySemicolon": false,       // Don't auto-fix when typing ;
"php-cs-fixer.exclude": ["vendor", ...],        // Skip these dirs in VSCode
```

**These only affect the VSCode extension experience.** They don't change what PHP-CS-Fixer does.

### Example: PHP-CS-Fixer Config

```php
// In .php-cs-fixer.php - Tool behavior
->setRules(['@PSR12' => true])                  // What rules apply
->exclude(['vendor', 'node_modules', ...])      // Which dirs to skip
->setRiskyAllowed(false)                        // Allow risky rules?
```

**These apply everywhere:** Local + CLI + CI/CD pipeline.

### Real-World Impact

**Scenario: You're coding locally**

```php
function test()
{
    $arr = array(1, 2, 3);  // Old syntax
}
```

**With VSCode settings:**
- If `onsave: true` → Auto-fixes when you save
- If `autoFixByBracket: false` → Won't auto-fix when you type `}`

**BUT** → If you run `php-cs-fixer fix src/` manually:
- The `.php-cs-fixer.php` rules apply (short array syntax `[]`)
- VSCode settings are ignored

**In CI/CD:**
```bash
php-cs-fixer fix --dry-run
# Only uses .php-cs-fixer.php rules
# VSCode settings completely ignored
```

### For Code Consistency (Local ↔ CI/CD)

**The `.php-cs-fixer.php` file is what matters.**

VSCode settings can be different on each developer's machine without breaking consistency, because CI/CD uses the `.php-cs-fixer.php` config:

```
Developer A: autoFixByBracket: true
Developer B: autoFixByBracket: false
CI/CD: Uses .php-cs-fixer.php
↓
All produce identical results ✅
```

### Configuration Best Practices

**Understanding the Two Layers:**

| File | Controls | Purpose | Example |
|------|----------|---------|---------|
| **devcontainer.json** | **WHEN** formatting happens | Extension behavior | `"php-cs-fixer.onsave": true` |
| **.php-cs-fixer.php** | **WHAT** gets formatted | Actual formatting rules | `->setRules(['@PSR12' => true])` |

**Real-world example:**

```
User types code in VSCode
    ↓
devcontainer.json says: "onsave": true (WHEN)
    ↓
User saves file (Ctrl+S)
    ↓
.php-cs-fixer.php applies rules: @PSR12 (WHAT)
    ↓
Code is formatted according to PSR-12
```

**❌ Conflicting rulesets (Don't do this):**

```php
->setRules([
    '@PSR12' => true,      // Use PSR-12 rules
    '@Symfony' => true     // BUT ALSO use Symfony rules (conflicts!)
])
```

This is bad because @PSR12 and @Symfony might have conflicting rules. You'll get unpredictable behavior.

**✅ Single, clear ruleset (Do this):**

```php
return (new PhpCsFixer\Config())
    ->setRules(['@PSR12' => true])  // ONE standard, clear choice
    ->setFinder($finder)
;
```

**Summary:**
- Each file has its own responsibility
- `devcontainer.json` = extension preferences (auto-fix timing, etc.)
- `.php-cs-fixer.php` = formatting rules (choose ONE clear standard)
- Don't mix conflicting rulesets in `.php-cs-fixer.php`

---

## Usage

### Local Development

#### PHP-CS-Fixer

**Auto-fix on save** (via junstyle.php-cs-fixer extension):
- Open any PHP file
- Edit code
- Save (Ctrl+S)
- ✅ Code is automatically formatted

**Manual fix from CLI:**
```bash
# Fix all files
php-cs-fixer fix src/

# Dry run (preview changes without applying)
php-cs-fixer fix src/ --dry-run --diff
```

#### PHPStan

**Analyze code:**
```bash
# Quick analysis
phpstan analyse src/

# Verbose output
phpstan analyse src/ --verbose

# Generate baseline (for legacy code with existing issues)
phpstan analyse src/ --generate-baseline
```

---

### CI/CD Pipeline

This template includes automatic code quality checks in your GitHub Actions workflows.

**Quick Setup:**

1. **Create workflow directory:**
   ```bash
   mkdir -p .github/workflows
   ```

2. **Create `.github/workflows/quality.yml`:**

   See the complete workflow examples in [**GitHub Actions Workflows**](workflows.md#1-quality-checks-workflow).

3. **Commit and push:**
   ```bash
   git add .github/
   git commit -m "ci: add code quality checks"
   git push
   ```

#### How It Works

**On every push or pull request:**

1. ✅ **PHP-CS-Fixer checks** - Verifies code follows PSR-12 standard (doesn't modify, just reports)
2. ✅ **PHPStan analyzes** - Detects logical errors and type issues
3. ❌ **Build fails** if either tool finds violations
4. 💡 **Developers fix locally** before pushing again

#### View Results

- **GitHub UI:** Go to your PR → "Checks" tab → See quality results
- **Details:** Click on a failed check to see exact violations

#### Multiple Workflows

You can create separate workflows for different purposes (quality, tests, deployment, etc.). See [**GitHub Actions Workflows**](workflows.md) for complete examples and best practices.

**Common Setup:**
```
.github/workflows/
├── quality.yml    # PHP-CS-Fixer + PHPStan
├── tests.yml      # PHPUnit tests
├── build.yml      # Frontend build
└── deploy.yml     # Production deployment
```

#### Troubleshooting CI Failures

**"php-cs-fixer not found"**
- Check `composer install` ran successfully
- Verify `php-cs-fixer/php-cs-fixer` is in `composer.json`

**"PHPStan says error that works locally"**
- CI might use different PHP version
- Check `php-version: '8.3'` matches your `.versions.json`
- Verify `phpstan.neon` is committed to git

**"Build keeps failing on my PR"**
- Run locally: `php-cs-fixer fix src/ --dry-run --diff`
- Run locally: `phpstan analyse src/`
- Fix issues, commit, push again

---

## Common Issues & Solutions

### Issue: "php-cs-fixer not found"

**Solution:** Install the package:
```bash
composer require --dev php-cs-fixer/php-cs-fixer
```

### Issue: PHPStan reports false positives

**Solution:** Add ignoring rules to `phpstan.neon`:
```neon
parameters:
    ignoreErrors:
        - '#Call to an undefined method#'
        - '#Access to an undefined property#'
```

### Issue: Extension doesn't auto-fix on save

**Solution:** Check VS Code settings (in `.vscode/settings.json`):
```json
{
  "[php]": {
    "editor.defaultFormatter": "junstyle.php-cs-fixer",
    "editor.formatOnSave": true
  }
}
```

### Issue: PHPStan baseline errors

**Solution:** Generate a baseline to ignore existing issues:
```bash
phpstan analyse src/ --generate-baseline
```

Then commit `phpstan-baseline.neon` to Git. Future violations will still fail.

---

## Tips & Best Practices

### 1. Run Both Tools Locally Before Committing

```bash
# Fix style
php-cs-fixer fix src/

# Check for logical errors
phpstan analyse src/
```

### 2. Use Pre-commit Hooks (Optional)

Install Husky for automatic checks on commit:

```bash
composer require --dev symfony/flex
composer recipes:install husky --force
```

### 3. PHPStan Levels for Teams

- **Starting out:** Level 4-5 (not too strict)
- **Established team:** Level 6-7 (standard)
- **Strict team:** Level 8-9 (requires more annotations)

### 4. Update Baseline When Upgrading

When you upgrade dependencies:
```bash
# Re-generate baseline to catch new issues
phpstan analyse src/ --generate-baseline --force
```

---

## VS Code Settings for Multi-Root Workspace

When using `project.code-workspace`, configure per-folder settings in `.vscode/settings.json` (inside `backend/` folder):

```json
{
  "[php]": {
    "editor.defaultFormatter": "junstyle.php-cs-fixer",
    "editor.formatOnSave": true,
    "editor.rulers": [120]
  },
  "php-cs-fixer.onsave": true,
  "php-cs-fixer.rules": "@PSR12"
}
```

**Result:**
- ✅ PHP-CS-Fixer runs only in `backend/` folder
- ✅ Frontend code unaffected
- ✅ Auto-fix on save enabled

---

## References

- [PHP-CS-Fixer Documentation](https://cs.symfony.com/)
- [PHPStan Documentation](https://phpstan.org/)
- [PSR-12 Standard](https://www.php-fig.org/psr/psr-12/)
- [GitHub Actions Workflows](workflows.md) - Complete guide for CI/CD setup
