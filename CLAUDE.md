# CLAUDE.md — Cassandra Infra

## What This Is

Terraform/OpenTofu for all Cloudflare resources across the Cassandra stack. Single consolidated state manages everything. Modules live in their service repos (services own their infra definitions), this repo composes them.

## Repo Structure

```
cassandra-infra/
├── modules/
│   └── cloudflare-tunnel/           # Reusable: tunnel + DNS + WAF skip + Access
├── environments/
│   └── production/
│       ├── main.tf                  # All services composed here
│       ├── variables.tf             # Shared variables (CF creds, domain, access)
│       ├── outputs.tf               # All service outputs
│       └── production.s3.tfbackend  # R2 state backend config
└── .gitignore
```

## Module Sources (local paths via cassandra-stack submodules)

| Module | Source repo | Resources |
|--------|------------|-----------|
| `runner_tunnel` | `cassandra-infra/modules/cloudflare-tunnel` | CF Tunnel, DNS, WAF skip, Access apps (grafana, argocd) |
| `portal_edge` | `cassandra-portal/infra/modules/portal-edge` | KV (MCP_KEYS), D1 (PORTAL_DB), DNS, CF Access |
| `yt_mcp_tunnel` | `cassandra-infra/modules/cloudflare-tunnel` | CF Tunnel for yt-mcp backend |
| `yt_mcp_worker_edge` | `cassandra-yt-mcp/infra/modules/worker-edge` | DNS, KV (OAuth state) |
| `yt_mcp_backend_access` | `cassandra-yt-mcp/infra/modules/backend-access` | CF Access app + service token |
| `metrics_push` | `cassandra-observability/infra/modules/metrics-push` | CF Access app + service token for vm-push |

## Usage

```bash
source /path/to/cassandra-stack/env/infra.env  # loads TF_VAR_* and AWS_*

cd environments/production
tofu init -backend-config=production.s3.tfbackend
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

After `tofu apply`, use `tofu output <name>` to get IDs for wrangler.jsonc and GitHub Actions secrets:

- `portal_mcp_keys_kv_id` — MCP_KEYS KV namespace ID (shared)
- `portal_db_id` — D1 database ID for portal
- `runner_tunnel_token` — k8s secret for runner tunnel
- `yt_mcp_tunnel_token` — k8s secret for yt-mcp tunnel
- `yt_mcp_oauth_kv_id` — KV namespace ID for yt-mcp OAuth
- `vm_push_client_id` / `vm_push_client_secret` — metrics push service token

## Adding a New Service

1. Create `infra/modules/<name>/` in the service repo with Terraform resources
2. Add a `module` block in `environments/production/main.tf` sourcing it via local path
3. Add outputs in `environments/production/outputs.tf`
4. `tofu init -upgrade && tofu apply`
