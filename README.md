# Cassandra Infra

> **Disclaimer:** This repo is a personal infrastructure configuration. It's public for reference — you'll need your own Cloudflare account, domain, and credentials.

Terraform/OpenTofu modules for cloud-managed resources (Cloudflare tunnels, DNS, Workers, Access policies).

## What's Here

- **`modules/cloudflare-tunnel/`** — Reusable module: CF Tunnel + DNS + WAF skip + Access policies
- **`modules/token-portal/`** — CF Worker for API key management dashboard
- **`environments/production/runner/`** — CF Tunnel for the Claude Agent Runner
- **`environments/production/portal/`** — Token management portal at `portal.REDACTED_DOMAIN`

## Usage

```bash
# Load credentials (git-ignored)
source .env

cd environments/production/runner
tofu init -backend-config=production.s3.tfbackend
tofu plan -var-file=production.tfvars
tofu apply -var-file=production.tfvars
```

## Secrets

All sensitive values via environment variables (`TF_VAR_*`) or `.tfvars` files (git-ignored). Nothing secret is committed to this repo.

See `.env` (git-ignored) for the required variables:
- `TF_VAR_cloudflare_api_key`
- `TF_VAR_cloudflare_email`
- `TF_VAR_tunnel_secret`
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (R2 state backend)

## State

Terraform state is stored in a Cloudflare R2 bucket (`cassandra-terraform-state`), configured via S3-compatible backend.

## License

[MIT](LICENSE)
