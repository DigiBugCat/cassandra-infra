# CLAUDE.md — Cassandra Infra

## What This Is

Terraform/OpenTofu for all Cloudflare resources across the Cassandra stack. Single root module manages everything. Services own their infra definitions (modules in their repos), this repo composes them.

## Repo Structure

```
cassandra-infra/
├── main.tf                # terraform block + provider
├── variables.tf           # shared variables (CF creds, domain, access)
├── tunnel.tf              # single CF Tunnel for all k8s services + DNS + outputs
├── portal.tf              # portal KV + D1 + DNS + Access + outputs
├── yt-mcp.tf              # yt-mcp worker edge + backend access + outputs
├── acl.tf                 # ACL worker edge (KV, DNS) + outputs
├── observability.tf       # metrics push access + outputs
├── unifi.tf               # UniFi DHCP reservations for k3s nodes
├── modules/
│   └── cloudflare-tunnel/ # reusable: tunnel + DNS + WAF skip + Access
└── environments/
    └── production/
        ├── production.s3.tfbackend          # R2 state backend (gitignored)
        └── production.s3.tfbackend.example  # template with placeholders
```

## Module Sources (local paths via cassandra-stack submodules)

| Module | Source repo | Resources |
|--------|------------|-----------|
| `runner_tunnel` | `cassandra-infra/modules/cloudflare-tunnel` | Single CF Tunnel for all k8s services (runner, grafana, argocd, vm-push, ci, yt-mcp-api, yt-mcp-mcp) |
| `portal_edge` | `cassandra-portal/infra/modules/portal-edge` | KV (MCP_KEYS), D1 (PORTAL_DB), DNS, CF Access |
| `yt_mcp_worker_edge` | `cassandra-yt-mcp/infra/modules/worker-edge` | DNS, KV (OAuth state) |
| `yt_mcp_backend_access` | `cassandra-yt-mcp/infra/modules/backend-access` | CF Access app + service token |
| `acl_edge` | `cassandra-auth/infra/modules/acl-edge` | KV (ACL_CREDENTIALS), DNS |
| `metrics_push` | `cassandra-observability/infra/modules/metrics-push` | CF Access app + service token for vm-push |

## Usage

```bash
source /path/to/cassandra-stack/env/infra.env  # loads TF_VAR_* and AWS_*

tofu init -backend-config=environments/production/production.s3.tfbackend
tofu plan
tofu apply
```

One `tofu apply` manages all services. Module changes in service repos are picked up automatically (local paths).

## Secrets

All sensitive values via environment variables from `cassandra-stack/env/infra.env` (git-ignored):

- `TF_VAR_cloudflare_api_key` — Global API Key
- `TF_VAR_cloudflare_email` — Account email
- `TF_VAR_cloudflare_account_id` — Account ID
- `TF_VAR_zone_id` — Zone ID
- `TF_VAR_tunnel_secret` — Shared tunnel secret
- `TF_VAR_domain` — Root domain
- `TF_VAR_allowed_emails` — CF Access allowed emails
- `TF_VAR_allowed_email_domains` — CF Access allowed domains
- `TF_VAR_google_idp_id` — CF Access Google IdP ID
- R2 state backend credentials (AWS-compatible key pair)

## Outputs

After `tofu apply`, use `tofu output <name>` to get IDs for wrangler.jsonc and Woodpecker secrets:

- `portal_mcp_keys_kv_id` — MCP_KEYS KV namespace ID (shared)
- `portal_db_id` — D1 database ID for portal
- `tunnel_token` — k8s secret for the single CF tunnel (used by runner cloudflared sidecar)
- `yt_mcp_oauth_kv_id` — KV namespace ID for yt-mcp OAuth
- `vm_push_client_id` / `vm_push_client_secret` — metrics push service token

## Adding a New Service

1. Create `infra/modules/<name>/` in the service repo with Terraform resources
2. Create `<service>.tf` in this repo with module block (local path source) + outputs
3. `tofu init -upgrade && tofu apply`
