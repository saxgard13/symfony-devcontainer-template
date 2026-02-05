# CI/CD Pipeline with GitHub Actions

This template includes an automated **Docker Build CI pipeline** using GitHub Actions to validate Dockerfiles and ensure quality on every push and pull request.

## Overview

The pipeline automatically runs on every push to main branches and on all pull requests to validate that:
- All Docker images build successfully
- Dockerfiles follow best practices (Hadolint linting)
- Lock files (composer.lock, package-lock.json) are valid
- All frameworks (PHP, Node.js, etc.) are properly supported

## Workflow File

Location: `.github/workflows/docker-build.yml`

This file is automatically included when you clone this template and requires **no setup** - it starts working immediately.

## Triggered Events

The pipeline runs automatically on:

| Event | Branches | Condition |
|-------|----------|-----------|
| **Push** | `main`, `dev`, `develop` | Every commit |
| **Pull Request** | `main`, `dev`, `develop` | On PR creation or update |

## Jobs

The pipeline includes **5 parallel jobs** that validate your Docker setup:

### 1. Build Development Image
- **File**: `.devcontainer/Dockerfile.dev`
- **Validates**: PHP 8.3 + Node.js 22 development environment
- **What it does**: Builds the image used in VS Code DevContainer

### 2. Build Apache Production Image
- **File**: `.devcontainer/Dockerfile.apache.prod`
- **Validates**: Symfony/PHP backend with optional Webpack Encore
- **What it does**: Tests multi-stage build with Composer dependencies
- **Special**: Auto-detects Webpack Encore (optional)

### 3. Build Node.js Production Image
- **File**: `.devcontainer/Dockerfile.node.prod`
- **Validates**: Server-side rendered JavaScript applications
- **Supports**: Next.js, Nuxt, Vite, and other Node.js frameworks
- **What it does**: Multi-stage build with npm/yarn/pnpm support

### 4. Build SPA Production Image
- **File**: `.devcontainer/Dockerfile.spa.prod`
- **Validates**: Static front-end applications
- **What it does**: Builds with any package manager, serves with Nginx

### 5. Lint Dockerfiles
- **Tool**: Hadolint (Dockerfile linter)
- **Validates**: All 4 Dockerfiles for best practices and security
- **What it does**: Checks Docker syntax, security issues, and optimization tips

## Docker Build Cache

The pipeline uses **Docker Layer Caching** via GitHub Actions to speed up builds:

- First run: Full build (slower)
- Subsequent runs: Reuse layers (faster ⚡)
- Cache resets: Only when Dockerfile or dependencies change

## Status Badges

After the first workflow run, you can add a status badge to your README:

```markdown
![Docker Build CI](https://github.com/your-user/your-repo/actions/workflows/docker-build.yml/badge.svg)
```

Shows: ✅ All tests passing or ❌ Build failed

## How to Use

### For Developers

When you push to `main`, `dev`, or `develop`:

1. GitHub automatically runs the pipeline
2. Check the **"Actions"** tab in your repo to see:
   - ✅ All jobs passed → Safe to merge
   - ❌ One job failed → Fix the issue (see error details)

### For Pull Requests

When creating a PR:

1. The pipeline runs automatically
2. A badge appears on the PR showing status
3. ✅ Green → PR can be merged (after review)
4. ❌ Red → Fix the Docker issue before merging

## Framework-Specific Notes

### Symfony (Apache)

The pipeline auto-detects your setup:

```dockerfile
# If backend/package.json exists → Builds Webpack Encore
# If it doesn't exist → PHP only (faster)
```

No configuration needed!

### JavaScript Apps (Node.js)

The pipeline supports multiple frameworks:

| Framework | What to do |
|-----------|-----------|
| **Next.js** | Default (no changes needed) |
| **Nuxt** | Edit Dockerfile.node.prod (see production.md) |
| **Vite + Backend** | Use Dockerfile.spa.prod for frontend |

See [Production Guide → Full JavaScript](production.md#full-javascript-nextjs-nuxt-vite-etc) for details.

## Customizing the Pipeline

### Add More Validations

Edit `.github/workflows/docker-build.yml` to add:

- Security scanning (Trivy, Snyk)
- Test execution
- Push to registry (Docker Hub, ghcr.io)
- Notifications (Slack, Email)

### Ignore Specific Warnings

Some Hadolint warnings are acceptable. Currently ignored:

| Code | Reason | Ignored By Default |
|------|--------|-------------------|
| **DL3003** | Using `cd` in RUN | ✅ Yes |
| **DL3008** | Packages not pinned to version | ✅ Yes |
| **DL3009** | Delete package manager caches | ✅ Yes |
| **DL3022** | COPY --from external image | ✅ Yes |
| **DL4006** | Set -o pipefail in RUN | ✅ Yes |
| **SC3040** | Bash-specific syntax in sh | ✅ Yes |

To add more ignored warnings, edit the `ignore:` line in `.github/workflows/docker-build.yml`.

### Restrict to Specific Branches

Edit the `on:` section to run only on certain branches:

```yaml
on:
  push:
    branches:
      - main          # Only main branch
  pull_request:
    branches:
      - main
```

## Troubleshooting

### Pipeline Failed: "failed to build"

1. Check the error message in GitHub Actions
2. Run the same Docker build locally:
   ```bash
   docker build -f .devcontainer/Dockerfile.dev -t test:dev .
   ```
3. Fix the issue and push again

### Pipeline Failed: Hadolint Warning

1. Review the warning in GitHub Actions
2. Either:
   - Fix the Dockerfile (recommended)
   - Add the warning code to `ignore:` in docker-build.yml

### Cache Not Working

The cache resets automatically if:
- Dockerfile changes
- Dependencies (composer.json, package.json) change
- More than 7 days elapsed

Force refresh: Push an empty commit
```bash
git commit --allow-empty -m "Refresh Docker cache"
git push
```

## Environment

The pipeline runs on:

- **Runner**: `ubuntu-latest` (GitHub-hosted)
- **Docker**: Docker Buildx (latest)
- **Resources**: 2 CPU cores, 7 GB RAM

## Next Steps

- ✅ Pipeline is set up and working
- 📝 Consider adding a badges to your README
- 🚀 Optional: Configure auto-push to Docker registry
- 📚 See [Production Guide](production.md) for deployment

---

## Related Documentation

- [Production Builds](production.md) - Deploy your images
- [Dockerfile Overview](.devcontainer/Dockerfile.dev) - Image details
- [GitHub Actions Docs](https://docs.github.com/actions) - Advanced setup
