# Claude Code OTel Observability

Dockerized OpenTelemetry Collector + Prometheus + Grafana stack for testing [Claude Code monitoring](https://code.claude.com/docs/en/monitoring-usage).

## Quick Start

```bash
docker compose up -d
```

Then configure Claude Code to export telemetry by setting these environment variables:

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
```

Or to also see prompts and tool details:

```bash
export OTEL_LOG_USER_PROMPTS=1
export OTEL_LOG_TOOL_DETAILS=1
```

## Services

| Service        | URL                      | Purpose                          |
| -------------- | ------------------------ | -------------------------------- |
| OTel Collector | `localhost:4317` (gRPC)  | Receives OTLP telemetry          |
| OTel Collector | `localhost:4318` (HTTP)  | Receives OTLP telemetry (HTTP)   |
| Prometheus     | http://localhost:9090     | Metrics storage & queries        |
| Grafana        | http://localhost:3000     | Dashboards (admin/admin)         |

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

Logs/events are written to a JSONL file inside the collector container and printed to debug output (`docker compose logs otel-collector`).

## Teardown

```bash
docker compose down -v
```
