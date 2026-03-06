# Playwright — Tests E2E & Accès Navigateur avec Claude Code

Ce document couvre deux usages de Playwright dans ce projet :

1. **Tests E2E classiques** — automatiser et tester l'interface dans un vrai navigateur
2. **MCP Playwright** — permettre à Claude Code de piloter le navigateur directement

---

## Aperçu

| Usage | Outil | Quand l'utiliser |
|-------|-------|-----------------|
| Tests automatisés | `@playwright/test` | CI/CD, tests de régression |
| Pilotage via Claude | `@playwright/mcp` | Debug visuel, exploration rapide |

---

## 1. Tests E2E avec Playwright

### Installation

```bash
cd project/frontend/
npx playwright install
```

> Installe les navigateurs (Chromium, Firefox, WebKit) et le CLI Playwright.

### Écrire un test

```typescript
// tests/e2e/home.spec.ts
import { test, expect } from '@playwright/test';

test('la page d\'accueil se charge', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await expect(page).toHaveTitle(/Mon App/);
});

test('le formulaire de connexion fonctionne', async ({ page }) => {
  await page.goto('http://localhost:3000/login');
  await page.fill('input[name="email"]', 'user@example.com');
  await page.fill('input[name="password"]', 'secret');
  await page.click('button[type="submit"]');
  await expect(page).toHaveURL('/dashboard');
});
```

### Lancer les tests

```bash
# Tous les tests
npx playwright test

# Un fichier spécifique
npx playwright test tests/e2e/home.spec.ts

# Mode UI interactif (recommandé pour le développement)
npx playwright test --ui

# Avec rapport HTML
npx playwright test --reporter=html
npx playwright show-report
```

### Configuration (`playwright.config.ts`)

```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

---

## 2. MCP Playwright — Pilotage via Claude Code

Le MCP (Model Context Protocol) Playwright permet à Claude Code de piloter un navigateur directement pendant une conversation, sans écrire de code de test.

### Ce que Claude peut faire

- Ouvrir une URL et prendre un screenshot
- Cliquer, remplir des formulaires, naviguer
- Lire le contenu de la page et l'analyser
- Vérifier qu'une UI se comporte correctement
- Déboguer visuellement une interface

### Activation

Le serveur MCP est défini dans [`~/.claude/mcp/playwright.optional.json`](/home/saxgard/.claude/mcp/playwright.optional.json) — il est **optionnel** et n'est pas activé par défaut sur tous les projets.

**Pour l'activer sur ce projet**, copier son contenu dans `.mcp.json` à la racine :

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

> **Prérequis :** avoir exécuté `npx playwright install` au moins une fois.

### Utilisation

Une fois activé, dans une conversation Claude Code :

```
→ "Ouvre localhost:3000 et dis-moi ce que tu vois"
→ "Remplis le formulaire de connexion avec admin@test.com et teste la connexion"
→ "Prends un screenshot de la page /dashboard"
→ "Vérifie que le bouton 'Créer' est bien présent sur la page /products"
```

Claude pilote le navigateur, prend des screenshots, et t'explique ce qu'il observe.

### Différence avec les tests classiques

| | Tests Playwright | MCP Playwright |
|---|---|---|
| **Code requis** | Oui | Non |
| **Reproductible** | Oui (CI/CD) | Non (interactif) |
| **Feedback visuel** | Rapport HTML | Screenshots en temps réel |
| **Usage** | Régression, CI | Debug rapide, exploration |

---

## Bonnes pratiques

- Utiliser le **MCP** pour explorer et déboguer rapidement pendant le développement
- Utiliser les **tests E2E classiques** pour valider les flux critiques (connexion, paiement, etc.) en CI
- Ne pas versionner `.mcp.json` s'il contient des configs locales — l'ajouter au `.gitignore` si nécessaire

---

## Références

- [Documentation Playwright](https://playwright.dev/)
- [MCP Playwright (npm)](https://www.npmjs.com/package/@playwright/mcp)
- [Model Context Protocol](https://modelcontextprotocol.io/)
