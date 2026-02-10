# GitHub Actions Workflows

This guide explains how to organize and structure GitHub Actions workflows for your Symfony project. You can create multiple independent workflows for quality checks, testing, building, deployment, and more.

## Workflow Architecture

The recommended setup uses **separate workflow files** for different purposes. Each workflow runs independently but can depend on others.

```
.github/workflows/
├── quality.yml          # PHP-CS-Fixer + PHPStan code quality checks
├── tests.yml            # PHPUnit backend tests
├── build.yml            # Frontend build & lint (ESLint, etc.)
├── security.yml         # Dependency scanning & security audits
└── deploy.yml           # Production deployment (manual trigger)
```

### When Each Workflow Runs

| Workflow | Trigger | Purpose | Duration |
|----------|---------|---------|----------|
| **quality.yml** | Every push & PR | Check code style & detect errors | ~2-3 min |
| **tests.yml** | Every push & PR | Run PHPUnit tests | ~5-10 min |
| **build.yml** | Every push & PR | Build frontend, check lint | ~3-5 min |
| **security.yml** | Daily or on push | Scan dependencies & code | ~5-10 min |
| **deploy.yml** | Manual trigger | Deploy to production | ~10-20 min |

---

## 1. Quality Checks Workflow

File: `.github/workflows/quality.yml`

Runs PHP-CS-Fixer and PHPStan checks on every push.

```yaml
name: Code Quality

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          tools: composer

      - name: Cache Composer dependencies
        uses: actions/cache@v3
        with:
          path: backend/vendor
          key: composer-${{ hashFiles('backend/composer.lock') }}

      - name: Install dependencies
        run: cd backend && composer install --no-interaction

      - name: PHP-CS-Fixer (check style)
        run: cd backend && vendor/bin/php-cs-fixer fix src/ --dry-run --diff

      - name: PHPStan (analyze)
        run: cd backend && vendor/bin/phpstan analyse src/
```

**What it checks:**
- ✅ Code follows PSR-12 standard
- ✅ No logical errors or type issues
- ✅ Fails the build if violations found

---

## 2. Tests Workflow

File: `.github/workflows/tests.yml`

Runs PHPUnit tests to ensure your code works as expected.

```yaml
name: Tests

on: [push, pull_request]

jobs:
  tests:
    runs-on: ubuntu-latest

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: symfony_test
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3
        ports:
          - 3306:3306

    steps:
      - uses: actions/checkout@v3

      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          tools: composer
          extensions: mysql

      - name: Cache Composer dependencies
        uses: actions/cache@v3
        with:
          path: backend/vendor
          key: composer-${{ hashFiles('backend/composer.lock') }}

      - name: Install dependencies
        run: cd backend && composer install --no-interaction

      - name: Setup test database
        run: cd backend && php bin/console doctrine:database:create --env=test
        env:
          DATABASE_URL: mysql://root:root@127.0.0.1:3306/symfony_test

      - name: Run migrations
        run: cd backend && php bin/console doctrine:migrations:migrate --env=test --no-interaction
        env:
          DATABASE_URL: mysql://root:root@127.0.0.1:3306/symfony_test

      - name: Run tests
        run: cd backend && php bin/phpunit
        env:
          DATABASE_URL: mysql://root:root@127.0.0.1:3306/symfony_test

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: backend/var/coverage/coverage.xml
          flags: backend
```

**What it checks:**
- ✅ All unit tests pass
- ✅ All functional tests pass
- ✅ Database migrations work
- 📊 Generates code coverage reports

---

## 3. Frontend Build & Lint Workflow

File: `.github/workflows/build.yml`

Builds the frontend and checks for lint errors.

```yaml
name: Frontend Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        run: cd frontend && npm install

      - name: Run ESLint
        run: cd frontend && npm run lint
        continue-on-error: true  # Report errors but don't fail

      - name: Build frontend
        run: cd frontend && npm run build

      - name: Check bundle size
        run: cd frontend && npm run analyze
        continue-on-error: true
```

**What it checks:**
- ✅ No ESLint violations
- ✅ Frontend builds successfully
- ✅ Bundle size is reasonable
- 💡 Optional: Flag large dependencies

---

## 4. Security Workflow

File: `.github/workflows/security.yml`

Scans dependencies for known vulnerabilities.

```yaml
name: Security Scan

on:
  push:
  pull_request:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  security:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: 'backend'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

**What it checks:**
- ✅ Known vulnerabilities in dependencies
- ✅ Outdated packages
- ⚠️ Warns about security issues in PRs

---

## 5. Deployment Workflow

File: `.github/workflows/deploy.yml`

Manual deployment to production. Triggers only when requested.

```yaml
name: Deploy to Production

on:
  workflow_dispatch:  # Manual trigger only
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'production'
        type: choice
        options:
          - staging
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}

    steps:
      - uses: actions/checkout@v3

      - name: Deploy to ${{ github.event.inputs.environment }}
        run: |
          echo "Deploying to ${{ github.event.inputs.environment }}"
          # Add your deployment script here
          # Examples:
          # - ssh to server and pull latest code
          # - run database migrations
          # - restart services
        env:
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
          SERVER_URL: ${{ secrets.SERVER_URL }}

      - name: Notify Slack
        if: always()
        uses: slackapi/slack-github-action@v1
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK }}
          payload: |
            {
              "text": "Deployment to ${{ github.event.inputs.environment }} ${{ job.status }}"
            }
```

**How to use:**
1. Go to GitHub → Your Repo → Actions
2. Select "Deploy to Production"
3. Click "Run workflow"
4. Choose environment (staging/production)
5. Watch deployment progress

---

## Workflow Dependencies & Order

You can make workflows depend on each other. For example:

**Deploy only after quality and tests pass:**

```yaml
# In deploy.yml
name: Deploy to Production

on:
  workflow_run:
    workflows:
      - Code Quality
      - Tests
    types:
      - completed
    branches:
      - main

jobs:
  check:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    steps:
      - name: Deploy
        run: echo "Deploying..."
```

---

## Monorepo Configuration

If you use separate `backend/` and `frontend/` folders, adjust paths:

**Quality workflow (backend only):**
```yaml
- name: Install dependencies
  run: cd backend && composer install

- name: PHP-CS-Fixer
  run: cd backend && vendor/bin/php-cs-fixer fix src/ --dry-run --diff
```

**Build workflow (frontend only):**
```yaml
- name: Install dependencies
  run: cd frontend && npm install

- name: ESLint
  run: cd frontend && npm run lint
```

---

## Secrets & Environment Variables

Store sensitive data in GitHub Secrets, not in code.

**Adding a Secret:**
1. Go to Repo Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add `DEPLOY_KEY`, `SERVER_URL`, `SLACK_WEBHOOK`, etc.

**Using in Workflow:**
```yaml
- name: Deploy
  env:
    DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
    SERVER_URL: ${{ secrets.SERVER_URL }}
  run: ./deploy.sh
```

---

## Performance Tips

### 1. Cache Dependencies

```yaml
- name: Cache Composer
  uses: actions/cache@v3
  with:
    path: backend/vendor
    key: composer-${{ hashFiles('backend/composer.lock') }}
```

### 2. Use Matrix for Multiple PHP Versions

```yaml
strategy:
  matrix:
    php-version: ['8.1', '8.2', '8.3']

steps:
  - uses: shivammathur/setup-php@v2
    with:
      php-version: ${{ matrix.php-version }}
```

### 3. Fail Fast with `continue-on-error`

```yaml
- name: Non-critical check
  run: ./check.sh
  continue-on-error: true  # Doesn't fail the build
```

### 4. Run Jobs in Parallel

Jobs run in parallel by default. Sequential jobs:

```yaml
jobs:
  quality:
    runs-on: ubuntu-latest
    steps: ...

  tests:
    needs: quality  # Wait for quality to pass
    runs-on: ubuntu-latest
    steps: ...
```

---

## Common Patterns

### Pattern 1: Skip Deployment on Tag

```yaml
jobs:
  deploy:
    if: ${{ !startsWith(github.ref, 'refs/tags/') }}
```

### Pattern 2: Run Only on Main Branch

```yaml
on:
  push:
    branches:
      - main
      - develop
```

### Pattern 3: Run on Pull Request

```yaml
on:
  pull_request:
    paths:
      - 'backend/**'  # Only if backend files changed
      - 'composer.lock'
```

### Pattern 4: Scheduled Runs (Daily, Weekly)

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
```

---

## Viewing Workflow Results

### In GitHub UI

1. Go to Repo → Actions tab
2. Click on workflow name
3. Click on the run
4. View logs for each job
5. Check "Annotations" for errors

### Check PR Status

- Green ✅ = All workflows passed
- Red ❌ = At least one workflow failed
- Yellow ⏳ = Workflow in progress

Click "Details" to see which step failed.

---

## Troubleshooting

### Issue: Workflow doesn't run

**Solutions:**
- Check the `on:` trigger matches your action (push, PR, schedule, etc.)
- Verify branch name in workflow matches your repo
- Check YAML syntax (spaces, colons, quotes)

### Issue: "Composer not found"

**Solution:**
```yaml
- uses: shivammathur/setup-php@v2
  with:
    php-version: '8.3'
    tools: composer  # Installs Composer
```

### Issue: "npm install fails"

**Solutions:**
- Check `package-lock.json` is committed
- Use `npm ci` instead of `npm install` in CI:
```yaml
- run: cd frontend && npm ci
```

### Issue: Database connection error

**Solution:** Ensure `DATABASE_URL` env var is set:
```yaml
- name: Run tests
  env:
    DATABASE_URL: mysql://root:root@127.0.0.1:3306/test_db
  run: php bin/phpunit
```

---

## Best Practices

1. **Keep workflows focused** - One workflow = one purpose (quality, tests, deploy)
2. **Use caching** - Cache Composer, npm to speed up builds
3. **Parallel execution** - Jobs run in parallel by default (faster)
4. **Fail fast** - Stop on first error for quick feedback
5. **Secrets management** - Use GitHub Secrets for sensitive data
6. **Documentation** - Comment your workflows for team clarity
7. **Status badges** - Add workflow status to README.md
8. **Notifications** - Slack/email alerts for failures

---

## Example: Complete Setup

**Create these files:**

```bash
mkdir -p .github/workflows
```

1. `.github/workflows/quality.yml` - Quality checks
2. `.github/workflows/tests.yml` - Run tests
3. `.github/workflows/build.yml` - Frontend build
4. `.github/workflows/deploy.yml` - Production deployment

**Add to `README.md`:**

```markdown
## CI/CD Status

![Code Quality](https://github.com/your-org/your-repo/actions/workflows/quality.yml/badge.svg)
![Tests](https://github.com/your-org/your-repo/actions/workflows/tests.yml/badge.svg)
![Build](https://github.com/your-org/your-repo/actions/workflows/build.yml/badge.svg)
```

---

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Runner Environment](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)
- [Secrets Management](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
