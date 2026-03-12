# Claude Code OTel Observability

Dockerized OpenTelemetry Collector + Prometheus + Grafana stack for testing [Claude Code monitoring](https://code.claude.com/docs/en/monitoring-usage).

## What You Get

A pre-built Grafana dashboard ("Claude Code Monitoring") with panels for:

- Sessions started
- Total cost (USD)
- Token usage (by type: input, output, cache read, cache creation)
- Lines of code modified
- Commits & PRs created
- Active time
- Code edit tool decisions
- Cost and token rates over time

| Service        | URL                      | Purpose                          |
| -------------- | ------------------------ | -------------------------------- |
| OTel Collector | `localhost:4317` (gRPC)  | Receives OTLP telemetry          |
| OTel Collector | `localhost:4318` (HTTP)  | Receives OTLP telemetry (HTTP)   |
| Prometheus     | http://localhost:9090     | Metrics storage & queries        |
| Grafana        | http://localhost:3000     | Dashboards (admin/admin)         |

## Setup

There are two steps: **1)** start the collector stack, and **2)** tell Claude Code where to send telemetry.

### Step 1: Start the Collector Stack

```bash
docker compose up -d
```

### Step 2: Configure Environment Variables

Claude Code needs these environment variables to export telemetry to the collector:

| Variable                         | Value                     | Purpose                        |
| -------------------------------- | ------------------------- | ------------------------------ |
| `CLAUDE_CODE_ENABLE_TELEMETRY`   | `1`                       | Enable telemetry export        |
| `OTEL_METRICS_EXPORTER`          | `otlp`                    | Use OTLP for metrics           |
| `OTEL_LOGS_EXPORTER`             | `otlp`                    | Use OTLP for logs              |
| `OTEL_EXPORTER_OTLP_ENDPOINT`   | `http://localhost:4317`   | Collector gRPC endpoint        |
| `OTEL_EXPORTER_OTLP_PROTOCOL`   | `grpc`                    | Transport protocol             |

Optional variables for additional detail:

| Variable                  | Value | Purpose                              |
| ------------------------- | ----- | ------------------------------------ |
| `OTEL_LOG_USER_PROMPTS`   | `1`   | Include user prompt text in logs     |
| `OTEL_LOG_TOOL_DETAILS`   | `1`   | Include tool input/output in logs    |

Pick one of the methods below to set them. After setting variables, **restart VS Code / your terminal** so Claude Code picks them up.

---

#### Automated Setup Script (does both steps)

The included setup scripts start the Docker stack *and* configure your environment in one command:

```bash
# macOS / Linux / Git Bash
./setup.sh          # Set variables + start Docker stack
./setup.sh --env    # Only set variables (don't start Docker)
./setup.sh --check  # Only verify current configuration
./setup.sh --clean  # Remove variables and tear down stack
```

```powershell
# Windows (PowerShell)
.\setup.ps1          # Set variables + start Docker stack
.\setup.ps1 -Env     # Only set variables (don't start Docker)
.\setup.ps1 -Check   # Only verify current configuration
.\setup.ps1 -Clean   # Remove variables and tear down stack
```

---

#### Windows: System Environment Variables (persistent, recommended)

Variables persist across all terminals, VS Code sessions, and reboots.

**Option A — GUI:**

1. Press `Win + S` and search **"Edit environment variables for your account"**
2. Click **"New..."** for each variable listed above
3. Click **OK** to save
4. **Restart VS Code** (or any open terminals)

**Option B — PowerShell (sets persistent user-level variables):**

```powershell
[Environment]::SetEnvironmentVariable("CLAUDE_CODE_ENABLE_TELEMETRY", "1", "User")
[Environment]::SetEnvironmentVariable("OTEL_METRICS_EXPORTER", "otlp", "User")
[Environment]::SetEnvironmentVariable("OTEL_LOGS_EXPORTER", "otlp", "User")
[Environment]::SetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4317", "User")
[Environment]::SetEnvironmentVariable("OTEL_EXPORTER_OTLP_PROTOCOL", "grpc", "User")
```

---

#### VS Code: Extension Settings (persistent, VS Code only)

Only applies when using Claude Code inside VS Code, not from a standalone terminal.

1. Open Settings JSON: `Ctrl+Shift+P` → **"Preferences: Open User Settings (JSON)"**
2. Add:

```json
"claude-code.envVars": {
  "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
  "OTEL_METRICS_EXPORTER": "otlp",
  "OTEL_LOGS_EXPORTER": "otlp",
  "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317",
  "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc"
}
```

3. Reload the window: `Ctrl+Shift+P` → **"Developer: Reload Window"**

---

#### macOS / Linux: Shell Profile (persistent)

Add to your `~/.bashrc`, `~/.zshrc`, or `~/.profile`:

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
```

Then restart your terminal or run `source ~/.bashrc` (or equivalent).

---

#### Current Session Only (temporary)

For a quick test without persisting anything. If you launch VS Code from this terminal (`code .`), the extension inherits the variables.

**Bash / Zsh / Git Bash:**

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
```

**PowerShell (current session):**

```powershell
$env:CLAUDE_CODE_ENABLE_TELEMETRY = "1"
$env:OTEL_METRICS_EXPORTER = "otlp"
$env:OTEL_LOGS_EXPORTER = "otlp"
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4317"
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"
```

**CMD:**

```cmd
set CLAUDE_CODE_ENABLE_TELEMETRY=1
set OTEL_METRICS_EXPORTER=otlp
set OTEL_LOGS_EXPORTER=otlp
set OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
set OTEL_EXPORTER_OTLP_PROTOCOL=grpc
```

## Verifying It Works

### Ask Claude to check

Start a Claude Code session and ask:

> "Check if my OTel environment variables are set correctly"

Claude can inspect its own environment and confirm the variables are present:

```
CLAUDE_CODE_ENABLE_TELEMETRY=1        ✓
OTEL_METRICS_EXPORTER=otlp            ✓
OTEL_LOGS_EXPORTER=otlp               ✓
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317  ✓
OTEL_EXPORTER_OTLP_PROTOCOL=grpc      ✓
```

### Check the collector is receiving data

After running a Claude Code session with telemetry enabled:

```bash
# Check collector logs for incoming telemetry
docker compose logs otel-collector | tail -20

# Check Prometheus for metrics
curl -s http://localhost:9090/api/v1/label/__name__/values | python -m json.tool
```

### Check Grafana

Open [http://localhost:3000](http://localhost:3000) (login: `admin` / `admin`) and navigate to the **Claude Code Monitoring** dashboard. After a Claude session with telemetry enabled, you should see data populating the panels.

## Teardown

```bash
docker compose down -v
```

To also remove the persisted environment variables, run the setup script with `--clean` / `-Clean`, or manually remove them from your system/shell profile.
