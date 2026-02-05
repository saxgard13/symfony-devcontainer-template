# GitHub Workflow Guide

This document explains the GitHub Flow workflow implemented for this project, including pull request management, main branch protection, and feature branch management.

---

## Table of Contents

1. [Overview](#overview)
2. [GitHub Flow Workflow](#github-flow-workflow)
3. [Pull Request Management](#pull-request-management)
4. [Main Branch Protection](#main-branch-protection)
5. [Feature Branch Management](#feature-branch-management)
6. [Pre-merge Checklist](#pre-merge-checklist)

---

## Overview

This project uses **GitHub Flow**, a simplified workflow designed for continuous deployment projects:

```
main (production) ← Features ← Merges after review and tests
```

**Benefits:**

- Simple and clear
- Continuous deployment possible
- Automated CI/CD
- Fewer permanent branches to manage

---

## GitHub Flow Workflow

### 1. Create a new feature branch

Before starting work, create a branch from `main`:

```bash
# Ensure you're on main and up to date
git switch main
git pull origin main

# Create a new branch for your feature
git switch -c feature/your-feature-name
```

**Naming convention:**

- `feature/add-authentication` - for a new feature
- `fix/login-bug` - for bug fixes
- `docs/update-readme` - for documentation
- `refactor/simplify-component` - for code refactoring

### 2. Make changes and commit

```bash
# Make your changes
# ...

# Stage the changes
git add .

# Create a commit with a clear message
git commit -m "feat: add user authentication system"

# Push the branch to GitHub
git push origin feature/your-feature-name
```

**Commit message format:**

- `feat:` for a new feature
- `fix:` for a bug fix
- `docs:` for documentation
- `refactor:` for refactoring
- `test:` for tests

### 3. Create a Pull Request

Once you've pushed your branch:

1. Go to GitHub
2. You'll see a "Compare & pull request" banner → click it
3. Or go to **Pull requests** → **New pull request** → select your branch

**PR description:**

```markdown
## Description

Brief explanation of what this PR does

## Changes

- Change 1
- Change 2

## Testing

- [ ] Tested locally
- [ ] No regressions
- [ ] CI/CD passes
```

### 4. Review and feedback

- Someone reviews your PR
- Discuss changes if necessary
- Make modifications if requested:
  ```bash
  git add .
  git commit -m "fix: address feedback on authentication"
  git push
  ```

### 5. Merge the PR

Once approved and tests pass:

1. Click **"Merge pull request"** on GitHub
2. Confirm the merge
3. The branch is deleted automatically (thanks to "Automatically delete head branches")

Or if auto-delete is not enabled:

- Click **"Delete branch"** to clean up manually

---

## Pull Request Management

### Before creating a PR

✅ **Do:**

- Ensure your branch is up to date with `main`
- Test your changes locally
- Verify CI/CD passes
- Write a clear description

### During review

✅ **Do:**

- Respond to comments
- Make requested modifications
- Push changes (commits are automatically added to the PR)
- Respect constructive suggestions

❌ **Avoid:**

- Force push after creating a PR (creates conflicts)
- Merge without review
- Merge with failing tests

### After merge

✅ **Do:**

- Delete the branch locally: `git branch -D feature/name`
- Sync your local branch: `git switch main && git pull origin main`

---

## Main Branch Protection

### Current configuration

The `main` branch is protected with the following rules:

| Rule | Status | Description |
|------|--------|-------------|
| **Require a pull request before merging** | ✅ Enabled | Cannot push directly to `main` |
| **Require status checks to pass** | ⚠️ Limited | See "Status Checks Configuration" section |
| **Restrict deletions** | ✅ Enabled | Cannot delete `main` |
| **Block force pushes** | ✅ Enabled | Cannot force push to `main` |

### What this means

1. **You cannot push directly to main**

   ```bash
   git push origin main
   # ❌ Error: Branch is protected
   ```

2. **All merges must go through a PR**

   ```bash
   # ✅ Correct workflow:
   git push origin feature/my-feature  # Push the feature
   # Create a PR on GitHub
   # Review → Approve → Merge
   ```

3. **CI/CD must pass before merge**
   - The GitHub Actions workflow checks:
     - Docker image builds
     - Hadolint linting
   - If a job fails, merge is blocked

4. **No accidental main branch deletion**

### Status Checks Configuration

#### Require a pull request before merging

This option is enabled without additional settings:

- ✅ All changes must go through a PR
- ✅ No additional configuration needed

#### Require status checks to pass

This option has 2 possible configurations:

**Option 1: Add CI/CD pipelines (recommended)**

1. Go to the branch rule
2. Click "Require status checks to pass"
3. Click "Add checks"
4. GitHub displays available workflows:
   - ✅ If GitHub finds them: select them
   - ❌ If GitHub shows "Any source": see problem section below

**Option 2: Leave unchecked and verify manually (current solution)**

- ❌ Status checks don't prevent merge automatically
- ✅ But you must verify all tests pass before merging
- ✅ CI/CD still runs on every PR

### How to bypass (if really necessary)

In case of critical emergency, an admin can temporarily disable protections via:

- GitHub Settings → Rules → Edit → Temporarily disable

(Avoid as much as possible!)

### ⚠️ Problem: Status Checks not found ("Any source")

**Situation encountered:**

When you click "Add checks" to add the CI/CD pipeline, GitHub might display "Any source" instead of recognizing the actual workflow:

```
Status: "Docker Build CI" — Expected — Any source
```

This means GitHub can't find the workflow with that exact name.

**Possible causes:**

1. Workflow name is not recognized by GitHub
2. Workflow hasn't been executed yet
3. GitHub has limitations with compound workflow names
4. GitHub doesn't list workflows without a "root" job (all jobs must depend on a single one)

**Solutions:**

1. **Create a parent job grouping all others** (recommended if you want automation)

   ```yaml
   check-all:
     needs:
       [
         build-dev,
         build-apache-prod,
         build-node-prod,
         build-spa-prod,
         lint-dockerfiles,
       ]
     runs-on: ubuntu-latest
     steps:
       - run: echo "All checks passed"
   ```

   - This job depends on all others
   - GitHub then recognizes this job as a status check
   - Merge is blocked if any job fails
   - See [ci-cd.md](ci-cd.md) for full implementation

2. **Don't add status check** (current solution for this project ✅)
   - Leave "Require status checks to pass" **unchecked**
   - Keep "Require a pull request before merging" **checked**
   - CI/CD still runs on every PR
   - You manually verify tests pass
   - No automatic merge blocking, but you can't merge without a PR

3. **Search for other workflow names**
   - Check "Add checks" if GitHub recognizes other workflows
   - Try different or simpler names

**What we do in this project:**

We use **Solution 2** because:

✅ Simple and functional
✅ CI/CD tests run automatically on every PR
✅ You must manually verify the 5 jobs before merging:

- Build Development Image
- Build Apache Production Image
- Build Node.js Production Image
- Build SPA Production Image
- Lint Dockerfiles

❌ Merge is not blocked automatically if a test fails (but you must go through a PR anyway)

**How to verify before merging:**

1. On the PR, scroll to the "Checks" section
2. Verify all jobs show ✅ (all green)
3. If a job is ❌, fix the error locally and push
4. Once all ✅, you can merge
5. Never merge if there are ❌ in red

**If you want to enable automation later:**

1. Modify the workflow to add a parent job
2. Run the workflow once
3. Go back to branch rule → "Require status checks to pass"
4. Click "Add checks"
5. The new job should now be found

---

## Feature Branch Management

### Create a feature branch

```bash
# From main
git switch main
git pull origin main

# Create the branch
git switch -c feature/my-new-feature

# Push
git push origin feature/my-new-feature
```

### Update a feature with main changes

If main has been updated while you were working:

**⚠️ Important:** First switch to your feature branch:

```bash
git switch feature/my-feature
```

Then execute the commands:

```bash
# Option 1: Rebase (linear, preferred)
git fetch origin
git rebase origin/main
git push --force-with-lease origin feature/my-feature

# Option 2: Merge (preserves history)
git fetch origin
git merge origin/main
git push origin feature/my-feature
```

### Delete a feature branch

**On GitHub:**

- The branch is deleted automatically after merge if you've enabled "Automatically delete head branches"

**Locally:**

```bash
# If the branch is fully merged
git branch -d feature/my-feature

# If you want to force delete (after verification)
git branch -D feature/my-feature

# Clean up deleted remote branches
git fetch --prune
```

### Delete a feature branch without merging

If you want to cancel a feature:

```bash
# On GitHub: Settings → Branches → Delete branch
# Or via command line:
git push origin --delete feature/my-feature

# Locally:
git branch -D feature/my-feature
```

---

## Pre-merge Checklist

### Code

- [ ] Code follows project conventions
- [ ] No unnecessary duplication
- [ ] Clear comments where needed
- [ ] No debug logs

### Tests

- [ ] Tested locally
- [ ] CI/CD passes ✅
- [ ] No known regressions
- [ ] Unit tests added (if applicable)

### Documentation

- [ ] README updated if necessary
- [ ] Comments added for complex code
- [ ] Clear commit messages

### Mergeable

- [ ] ✅ Branch up to date with `main`
- [ ] ✅ No conflicts
- [ ] ✅ At least one approved review
- [ ] ✅ All status checks pass

---

## Complete Process: Example

### Step 1: Create a feature branch

```bash
git switch main
git pull origin main
git switch -c feature/add-ci-cd
```

### Step 2: Develop and commit

```bash
# Make your changes...
git add .
git commit -m "feat: add GitHub Actions workflow for Docker builds"
git push -u origin feature/add-ci-cd
```

### Step 3: Create a PR

- On GitHub: "Compare & pull request"
- Describe what you did
- Request a review

### Step 4: Continuous integration

- GitHub Actions runs automatically
- Tests pass (or fail)
- You receive feedback

### Step 5: Review and feedback

- Someone reviews your PR
- Make modifications if requested
- `git commit -m "fix: address review feedback"`
- `git push`

### Step 6: Merge

- Once approved and tests pass
- Click "Merge pull request"
- Branch is automatically deleted on GitHub

### Step 7: Clean up locally

```bash
git branch -D feature/add-ci-cd
git switch main
git pull origin main
```

---

## Common Issues

### "Branch is not mergeable"

**Cause:** Conflicts with `main`

**Solution:**

First, switch to your feature branch:

```bash
git switch feature/my-feature
```

Then:

```bash
git fetch origin
git rebase origin/main
# Resolve conflicts
git add .
git rebase --continue
git push --force-with-lease origin feature/...
```

### "I cannot push to main"

**Cause:** `main` is protected

**Solution:** Create a PR from a feature branch

### "My branch is out of sync"

**Cause:** `main` has been merged several times since your feature

**Solution:**

First, switch to your feature branch:

```bash
git switch feature/my-feature
```

Then:

```bash
git fetch origin
git rebase origin/main
```

### "I want to delete my PR"

**On GitHub:**

- Click "Close pull request" (at the top)
- The PR stays in history

### "I pushed to the wrong branch"

```bash
# Create a new branch with your changes
git switch -c feature/new-branch

# Go back to main
git switch main
git reset --hard origin/main
```

---

## Resources

- [GitHub Flow (Official)](https://guides.github.com/introduction/flow/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Documentation](https://git-scm.com/doc)

---

**Need help?** Check the CI/CD documentation: [CI/CD Pipeline](ci-cd.md)
