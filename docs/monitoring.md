# Monitoring

## Monolog — Symfony logging

Monolog is Symfony's logging library, installed by default. It routes log messages to one or more **handlers** configured in `config/packages/monolog.yaml`.

### Handlers in this project

```yaml
monolog:
    handlers:
        file:
            type: rotating_file
            path: "%kernel.logs_dir%/%kernel.environment%.log"
            level: debug
            max_files: 7
        sentry_logs:
            type: service
            id: Sentry\SentryBundle\Monolog\LogsHandler
```

| Handler | Destination | Level | Purpose |
|---|---|---|---|
| `file` | `var/log/dev-YYYY-MM-DD.log` | debug | Rotating daily log file — keeps the last 7 days, older files deleted automatically |
| `sentry_logs` | Sentry → Explore → Logs | warning | Sends WARNING+ logs to Sentry (see Sentry section below) |

### Reading logs

**In the log file** (inside the dev container):

```bash
tail -f var/log/dev-$(date +%F).log
```

### Writing custom logs

Inject `LoggerInterface` in any service or controller:

```php
use Psr\Log\LoggerInterface;

public function __construct(private LoggerInterface $logger) {}

$this->logger->debug('Detailed debug info');
$this->logger->info('User logged in');
$this->logger->warning('Disk space low');
$this->logger->error('Payment failed');
$this->logger->critical('Database unreachable');
```

All messages pass through the Monolog pipeline and are dispatched to the configured handlers according to their level.

### Production configuration

The `when@prod:` block in `monolog.yaml` automatically applies in production — no manual change needed:

```yaml
when@prod:
    monolog:
        handlers:
            file:
                level: warning   # no more debug/info noise
                max_files: 30    # keep 30 days instead of 7
            stdout:
                type: stream
                path: php://stdout
                level: warning   # works with PHP-FPM in production
# sentry_logs is inherited from the base config — no need to repeat it
```

Key differences from dev:
- Level raised to `warning` — avoids writing thousands of debug/info lines per day
- `max_files: 30` — longer retention in prod
- `stdout` handler re-enabled — with PHP-FPM (standard production setup), PHP stdout is captured by Docker and your log aggregation system

---

## Built-in dev tools

These tools require no installation or configuration — they are available out of the box.

### Symfony

**Web Debug Toolbar** — visible at the bottom of every page in dev mode.

Shows at a glance: HTTP status, response time, memory usage, number of DB queries, number of log messages. Click any section to open the full profiler for that request.

**Symfony Profiler** — accessible at `http://localhost:8000/_profiler`

Lists recent requests with full details per request:
- Logs (all levels, filterable)
- Database queries with execution time
- Events dispatched
- Security context (authenticated user, roles)
- Cache hits/misses
- Performance timeline

**`symfony server:log`** — run in a dedicated terminal for real-time formatted log output:

```bash
symfony server:log
```

More readable than `tail -f` on the log file — shows colored, structured output.

### Next.js

**Browser DevTools** (F12) — the primary debugging tool for frontend code:
- **Console** tab: all `console.log`, `console.error`, warnings
- **Network** tab: HTTP requests, responses, timings — useful to debug API calls to Symfony
- **React DevTools** (browser extension): inspect component tree, props, state in real time

**Next.js error overlay** — in dev mode, unhandled errors display directly in the browser with a stack trace and source link. No configuration needed.

### When to use what

| Situation | Tool |
|---|---|
| Inspect a specific request (queries, logs, timing) | Symfony Profiler |
| Monitor logs in real time in terminal | `symfony server:log` |
| Debug a React component or API call | Browser DevTools |
| Track errors and logs in production | Sentry |

---

## Sentry — Error tracking (recommended)

Sentry is the recommended monitoring solution for most web applications. It tracks errors and exceptions in real time, groups similar errors, and provides detailed context (stack trace, breadcrumbs, user session) to help diagnose issues quickly.

It works as a **SaaS service** (sentry.io) — no container to run locally.

### Setup

**1. Create a free account** on [sentry.io](https://sentry.io) and create a project (choose **Symfony** as platform).

**2. Install the bundle** inside the dev container:

```bash
composer require sentry/sentry-symfony
```

**3. Configure the DSN** in your `.env.local` (never commit this file):

```env
SENTRY_DSN="https://<your-dsn>@o<id>.ingest.sentry.io/<project-id>"
```

The DSN is available in your Sentry project settings.

**4. Enable the bundle for all environments** in `config/bundles.php`:

```php
Sentry\SentryBundle\SentryBundle::class => ['all' => true],
```

By default the Flex recipe registers it for `prod` only. Change to `all` if you want to test in `dev`.

**5. Configure** `config/packages/sentry.yaml`:

```yaml
sentry:
    dsn: '%env(SENTRY_DSN)%'
    options:
        enable_logs: true

services:
    Sentry\SentryBundle\Monolog\LogsHandler:
        arguments:
            - !php/const Monolog\Logger::WARNING
```

**6. Add the Monolog handler** in `config/packages/monolog.yaml`:

```yaml
monolog:
    handlers:
        # ... your existing handlers ...
        sentry_logs:
            type: service
            id: Sentry\SentryBundle\Monolog\LogsHandler
```

This sends all `WARNING`-level and above logs to Sentry → Explore → Logs.

### Test the integration

Add a temporary test controller:

```php
#[Route(path: '/_sentry-test')]
public function testSentry(LoggerInterface $logger): never
{
    $logger->warning('Something went wrong.');
    $logger->error('My custom logged error.');
    throw new \RuntimeException('Example exception.');
}
```

- The exception appears in Sentry → **Issues**
- The warning/error messages appear in Sentry → **Explore → Logs**

Visit `/_sentry-test`, verify both sections, then remove this controller.

### Where to find data in Sentry

| Section | How to access | What it shows | Useful in dev? |
|---|---|---|---|
| **Issues** | Left sidebar → Issues | Uncaught exceptions, grouped by type | Yes — primary debugging tool |
| **Logs** | Left sidebar → Explore → Logs | All Monolog messages (WARNING+) in chronological order | Yes — context around errors |
| **Traces** | Left sidebar → Explore → Traces | Full request lifecycle (frontend → API → DB) | Optional — more useful in prod |
| **Metrics** | Left sidebar → Explore → Metrics | Custom counters/gauges (e.g. orders per hour) | No — requires extra instrumentation |
| **Profiles** | Left sidebar → Explore → Profiles | Per-function performance profiling | No — requires profiling SDK |
| **Replays** | Left sidebar → Explore → Replays | User session recordings (clicks, scroll) | No — frontend only, useful for UX debugging in prod |

For most applications, **Issues** and **Logs** are sufficient.

### Notes

- Sentry groups identical errors — refreshing the test page increments the counter, it does not create a new issue
- The `when@prod` restriction in `sentry.yaml` and `bundles.php` is intentional for production-only setups — remove it only for testing
- Use `WARNING` as minimum log level to avoid noise from Symfony's internal `INFO` logs (e.g. matched routes)
- Free plan: 5,000 errors/month per project, sufficient for most applications

---

## Sentry — Next.js frontend (SSR)

Create a **separate Sentry project** (platform: **Next.js**) to get a distinct DSN for the frontend.

Next.js uses SSR (Server-Side Rendering), meaning code runs both in the browser **and** on the Node.js server. Sentry must capture errors in both contexts, which is why the setup is more complex: it generates 3 separate config files (`sentry.client.config.ts`, `sentry.server.config.ts`, `sentry.edge.config.ts`) plus an `instrumentation.ts` to initialize Sentry at server startup.

### Setup

Run the official wizard inside the dev container from the `frontend/` directory:

```bash
npx @sentry/wizard@latest -i nextjs
```

The wizard asks several questions. Here are the recommended answers for a standard project:

| Question | Recommended answer | Why |
|---|---|---|
| Route Sentry requests through a tunnel? | **No** | Adds a `/monitoring` proxy route to your app. Useful to bypass ad blockers in prod, but unnecessary overhead in dev |
| Enable Tracing? | **No** | Tracks full request lifecycles. Generates a lot of data and has a performance cost — enable in prod only if needed |
| Enable Session Replay? | **No** | Records user sessions (clicks, scroll). Useful for UX debugging in prod, not needed in dev |
| Enable Logs? | **Yes** | Sends `console.error` / `console.warn` to Sentry → Explore → Logs |
| Create an example page? | **Yes** | Generates `/sentry-example-page` to immediately test the integration |
| Using a CI/CD tool? | **No** *(dev)* / **Yes** *(prod)* | In prod with CI/CD, say Yes to upload source maps — this makes stack traces readable in minified code. Without it, Sentry shows minified variable names |
| Add MCP server configuration? | **No** | Configures the Sentry MCP server for AI assistants (Claude, Copilot). Can be added later if needed |

### Test the integration

Visit `/sentry-example-page` and click the button to send a test error.

Check results in Sentry → **Issues** and **Explore → Logs**.

Remove the example page once validated (`app/sentry-example-page/` and `app/api/sentry-example-api/`).

---

## Sentry — SPA frontend (Vite / Next.js without SSR)

For a pure SPA (no server-side rendering), the setup is much simpler: there is only one execution context — the browser — so a single config file is enough.

Create a **separate Sentry project** (platform: **React**, **Vue**, etc.) on sentry.io.

### Setup (Vite + React example)

```bash
npm install @sentry/react
```

Initialize Sentry once in `main.tsx`, before rendering the app:

```ts
import * as Sentry from '@sentry/react';

Sentry.init({
  dsn: import.meta.env.VITE_SENTRY_DSN,
  environment: import.meta.env.MODE, // 'development' or 'production'
});
```

Add the DSN to your `.env.local` (never commit this file):

```env
VITE_SENTRY_DSN="https://<your-dsn>@o<id>.ingest.sentry.io/<project-id>"
```

### Test the integration

Throw an error anywhere in the app:

```ts
throw new Error('Sentry test error');
```

Check it appears in Sentry → **Issues**.

### Notes

- No wizard needed, no multiple config files, no CI/CD questions
- Source maps in prod are optional — configure the `@sentry/vite-plugin` separately if needed
- For Next.js used as a SPA (static export with `output: 'export'`), use `@sentry/react` the same way

---

## Using the Sentry interface

### Issues — debugging errors

**Left sidebar → Issues**

Each issue represents a unique error type. Click on one to see:

- **Stack trace** — exact file, line and call chain where the error occurred
- **Breadcrumbs** — chronological sequence of events before the error (HTTP requests, logs, navigation)
- **Tags** — environment, URL, HTTP method, user agent
- **Event count / users affected** — how many times it happened and how many users were impacted

Useful actions on an issue:
- **Resolve** — mark as fixed (will reopen automatically if the error occurs again)
- **Ignore** — silence a known/irrelevant error
- **Assign** — assign to a team member

### Explore → Logs — reading logs

**Left sidebar → Explore → Logs**

Displays all logs sent by Monolog (WARNING+) and `console.error`/`console.warn` from the frontend.

Useful filters:
- **Level** — filter by `warning`, `error`, `critical`
- **Search bar** — search by message content, e.g. `payment failed`
- **Time range** — top right, adjust to narrow down to a specific period

Tip: when investigating an issue, copy the error timestamp from Issues and filter Logs to the same time window to see what happened just before the crash.

### Alerts — notifications

**Left sidebar → Alerts**

Configure automatic notifications when:
- A new issue appears (not just a repeat)
- An issue exceeds a threshold (e.g. more than 10 occurrences in 1 hour)
- A previously resolved issue reoccurs

Supports email, Slack, PagerDuty, and webhooks. Recommended for production.
