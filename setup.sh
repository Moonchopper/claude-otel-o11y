#!/usr/bin/env bash
set -euo pipefail

VARS=(
  "CLAUDE_CODE_ENABLE_TELEMETRY=1"
  "OTEL_METRICS_EXPORTER=otlp"
  "OTEL_LOGS_EXPORTER=otlp"
  "OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317"
  "OTEL_EXPORTER_OTLP_PROTOCOL=grpc"
)

SHELL_RC=""
detect_shell_rc() {
  if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
    SHELL_RC="$HOME/.zshrc"
  elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == */bash ]]; then
    SHELL_RC="$HOME/.bashrc"
  else
    SHELL_RC="$HOME/.profile"
  fi
}

check_env() {
  echo "Checking Claude Code OTel environment variables..."
  echo ""
  all_good=true
  for entry in "${VARS[@]}"; do
    name="${entry%%=*}"
    expected="${entry#*=}"
    actual="${!name:-}"
    if [[ "$actual" == "$expected" ]]; then
      printf "  %-40s %s\n" "$name=$expected" "✓"
    elif [[ -n "$actual" ]]; then
      printf "  %-40s %s\n" "$name=$actual" "✗ (expected: $expected)"
      all_good=false
    else
      printf "  %-40s %s\n" "$name" "✗ (not set)"
      all_good=false
    fi
  done
  echo ""

  if docker compose ps --status running 2>/dev/null | grep -q otel-collector; then
    echo "  OTel Collector container:                running ✓"
  else
    echo "  OTel Collector container:                not running ✗"
    all_good=false
  fi

  echo ""
  if $all_good; then
    echo "Everything looks good! Start a Claude Code session to generate telemetry."
  else
    echo "Some checks failed. Run './setup.sh' to configure everything."
  fi
}

set_env() {
  detect_shell_rc
  echo "Adding environment variables to $SHELL_RC ..."

  # Remove any existing block
  if [[ -f "$SHELL_RC" ]]; then
    sed -i.bak '/# BEGIN claude-otel-o11y/,/# END claude-otel-o11y/d' "$SHELL_RC"
  fi

  {
    echo ""
    echo "# BEGIN claude-otel-o11y"
    for entry in "${VARS[@]}"; do
      echo "export $entry"
    done
    echo "# END claude-otel-o11y"
  } >> "$SHELL_RC"

  echo "Variables added to $SHELL_RC"
  echo ""
  echo "To apply now, run:"
  echo "  source $SHELL_RC"
}

clean_env() {
  detect_shell_rc
  echo "Removing environment variables from $SHELL_RC ..."

  if [[ -f "$SHELL_RC" ]]; then
    sed -i.bak '/# BEGIN claude-otel-o11y/,/# END claude-otel-o11y/d' "$SHELL_RC"
    echo "Variables removed from $SHELL_RC"
  else
    echo "No $SHELL_RC found, nothing to clean."
  fi

  echo "Tearing down Docker stack..."
  docker compose down -v 2>/dev/null || true
  echo "Done."
}

start_stack() {
  echo "Starting Docker stack..."
  docker compose up -d
  echo ""
  echo "Services:"
  echo "  OTel Collector:  localhost:4317 (gRPC), localhost:4318 (HTTP)"
  echo "  Prometheus:      http://localhost:9090"
  echo "  Grafana:         http://localhost:3000 (admin/admin)"
}

usage() {
  echo "Usage: ./setup.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  (none)     Set environment variables and start Docker stack"
  echo "  --env      Only set environment variables"
  echo "  --check    Only verify current configuration"
  echo "  --clean    Remove variables and tear down stack"
  echo "  --help     Show this help"
}

case "${1:-}" in
  --check)
    check_env
    ;;
  --env)
    set_env
    ;;
  --clean)
    clean_env
    ;;
  --help|-h)
    usage
    ;;
  "")
    set_env
    echo ""
    start_stack
    echo ""
    echo "Restart your terminal (or run 'source $SHELL_RC'), then start a Claude Code session."
    echo "Run './setup.sh --check' to verify everything is configured."
    ;;
  *)
    echo "Unknown option: $1"
    usage
    exit 1
    ;;
esac
