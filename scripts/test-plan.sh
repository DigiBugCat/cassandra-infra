#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS=(
  "runner"
  "portal"
  "observability"
  "yt-mcp"
)

FAKE_CLOUDFLARE_API_KEY="0123456789abcdef0123456789abcdef01234"
FAKE_TUNNEL_SECRET="ZmFrZXR1bm5lbHNlY3JldGZha2V0dW5uZWxzZWNyZXQ="

usage() {
  cat <<'EOF'
Usage:
  scripts/test-plan.sh static
  scripts/test-plan.sh integration
  scripts/test-plan.sh full
EOF
}

cleanup_temp() {
  if [[ -n "${TEMP_ROOT:-}" && -d "${TEMP_ROOT}" ]]; then
    rm -rf "${TEMP_ROOT}"
  fi
}

create_temp_repo() {
  cleanup_temp
  TEMP_ROOT="$(mktemp -d)"
  trap cleanup_temp EXIT

  cp -R "${ROOT_DIR}" "${TEMP_ROOT}/repo"

  find "${TEMP_ROOT}/repo" -type d -name '.terraform' -prune -exec rm -rf {} +
  find "${TEMP_ROOT}/repo" -type f -name '.terraform.lock.hcl' -delete
  find "${TEMP_ROOT}/repo" -type f -name '*.tfplan' -delete
}

strip_backend_block() {
  local env_dir="$1"
  local main_tf="${env_dir}/main.tf"

  awk '
    /backend "s3" \{/ { skip = 1; next }
    skip && /^[[:space:]]*}/ { skip = 0; next }
    /# Configured via production\.s3\.tfbackend/ { next }
    { print }
  ' "${main_tf}" > "${main_tf}.tmp"

  mv "${main_tf}.tmp" "${main_tf}"
}

run_static() {
  local env

  create_temp_repo

  echo "[cassandra-infra] static: tofu fmt -check -recursive"
  (
    cd "${TEMP_ROOT}/repo"
    tofu fmt -check -recursive
  )

  for env in "${ENVIRONMENTS[@]}"; do
    echo "[cassandra-infra] static: ${env} tofu init -backend=false && tofu validate"
    (
      cd "${TEMP_ROOT}/repo/environments/production/${env}"
      tofu init -backend=false -input=false >/dev/null
      tofu validate
    )
  done
}

assert_plan() {
  local plan_json="$1"
  local jq_expr="$2"
  local description="$3"

  if jq -e "${jq_expr}" "${plan_json}" >/dev/null; then
    echo "  - ${description}"
  else
    echo "Assertion failed: ${description}" >&2
    jq "${jq_expr}" "${plan_json}" >&2 || true
    return 1
  fi
}

run_plan_smoke() {
  local env="$1"
  local plan_args=()
  local env_dir
  local plan_json

  case "${env}" in
    runner)
      plan_args=(
        "-var=cloudflare_api_key=${FAKE_CLOUDFLARE_API_KEY}"
        "-var=cloudflare_email=test@example.com"
        "-var=cloudflare_account_id=acc"
        "-var=zone_id=zone"
        "-var=tunnel_secret=${FAKE_TUNNEL_SECRET}"
        "-var=allowed_emails=[\"test@example.com\"]"
        "-var=allowed_email_domains=[\"example.com\"]"
        "-var=domain=example.com"
        "-var=google_idp_id=idp"
      )
      ;;
    portal)
      plan_args=(
        "-var=cloudflare_api_key=${FAKE_CLOUDFLARE_API_KEY}"
        "-var=cloudflare_email=test@example.com"
        "-var=cloudflare_account_id=acc"
        "-var=zone_id=zone"
        "-var=domain=example.com"
        "-var=allowed_emails=[\"test@example.com\"]"
        "-var=allowed_email_domains=[\"example.com\"]"
        "-var=google_idp_id=idp"
      )
      ;;
    observability)
      plan_args=(
        "-var=cloudflare_api_key=${FAKE_CLOUDFLARE_API_KEY}"
        "-var=cloudflare_email=test@example.com"
        "-var=cloudflare_account_id=acc"
        "-var=zone_id=zone"
        "-var=domain=example.com"
      )
      ;;
    yt-mcp)
      plan_args=(
        "-var=cloudflare_api_key=${FAKE_CLOUDFLARE_API_KEY}"
        "-var=cloudflare_email=test@example.com"
        "-var=cloudflare_account_id=acc"
        "-var=zone_id=zone"
        "-var=tunnel_secret=${FAKE_TUNNEL_SECRET}"
        "-var=domain=example.com"
      )
      ;;
    *)
      echo "Unknown environment: ${env}" >&2
      return 1
      ;;
  esac

  echo "[cassandra-infra] integration: ${env} smoke plan"
  env_dir="${TEMP_ROOT}/repo/environments/production/${env}"
  plan_json="${env_dir}/plan.json"

  (
    strip_backend_block "${env_dir}"

    cd "${env_dir}"
    tofu init -input=false >/dev/null
    tofu plan -refresh=false -input=false -lock=false -out=plan.tfplan "${plan_args[@]}" >/dev/null
    tofu show -json plan.tfplan > "${plan_json}"

    case "${env}" in
      runner)
        assert_plan "${plan_json}" \
          '.planned_values.outputs.hostname.value == "claude-runner.example.com"' \
          "runner hostname output stays on the expected public host"
        assert_plan "${plan_json}" \
          'any(.. | objects | .address?; . == "module.tunnel.cloudflare_zero_trust_tunnel_cloudflared_config.this")' \
          "runner plan includes the tunnel ingress config"
        assert_plan "${plan_json}" \
          'any(.. | objects | .address?; . == "module.tunnel.cloudflare_zero_trust_access_application.extra[\"grafana.example.com\"]")' \
          "runner plan includes CF Access for grafana"
        ;;
      portal)
        assert_plan "${plan_json}" \
          '.planned_values.outputs.portal_url.value == "https://portal.example.com"' \
          "portal plan exposes the expected portal URL"
        assert_plan "${plan_json}" \
          '(.planned_values.outputs | has("mcp_keys_kv_namespace_id"))' \
          "portal plan exposes the MCP keys KV output"
        assert_plan "${plan_json}" \
          'any(.. | objects | .address?; . == "module.portal_edge.cloudflare_workers_kv_namespace.mcp_keys")' \
          "portal plan includes the shared MCP keys namespace"
        ;;
      observability)
        assert_plan "${plan_json}" \
          '.planned_values.outputs.vm_push_url.value == "https://vm-push.example.com/api/v1/import/prometheus"' \
          "observability plan exposes the VictoriaMetrics push URL"
        assert_plan "${plan_json}" \
          '(.planned_values.outputs | has("vm_push_client_id") and has("vm_push_client_secret"))' \
          "observability plan exposes the service token outputs"
        assert_plan "${plan_json}" \
          'any(.. | objects | .address?; . == "module.metrics_push.cloudflare_zero_trust_access_service_token.vm_push")' \
          "observability plan includes the vm-push service token"
        ;;
      yt-mcp)
        assert_plan "${plan_json}" \
          '.planned_values.outputs.backend_hostname.value == "yt-mcp-api.example.com"' \
          "yt-mcp plan exposes the backend hostname"
        assert_plan "${plan_json}" \
          '.planned_values.outputs.worker_hostname.value == "yt-mcp.example.com" and .planned_values.outputs.callback_url.value == "https://yt-mcp.example.com/callback" and .planned_values.outputs.mcp_url.value == "https://yt-mcp.example.com/mcp"' \
          "yt-mcp plan exposes the worker, callback, and MCP URLs"
        assert_plan "${plan_json}" \
          'any(.. | objects | .address?; . == "module.worker_edge.cloudflare_workers_kv_namespace.oauth") and any(.. | objects | .address?; . == "module.backend_access.cloudflare_zero_trust_access_service_token.backend")' \
          "yt-mcp plan includes both Worker OAuth KV and backend service token resources"
        ;;
    esac
  )
}

run_integration() {
  local env

  create_temp_repo

  echo "[cassandra-infra] integration: tofu test (modules/cloudflare-tunnel)"
  (
    cd "${TEMP_ROOT}/repo/modules/cloudflare-tunnel"
    tofu init -backend=false -input=false >/dev/null
    tofu test
  )

  for env in "${ENVIRONMENTS[@]}"; do
    run_plan_smoke "${env}"
  done
}

run_full() {
  run_static
  echo
  run_integration
}

main() {
  local phase="${1:-}"

  case "${phase}" in
    static)
      run_static
      ;;
    integration)
      run_integration
      ;;
    full)
      run_full
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
