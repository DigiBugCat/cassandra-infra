# CLAUDE.md — Cassandra Infra

## What This Is

Terraform/OpenTofu for cloud-managed resources (Cloudflare, WorkOS, etc.). State stored in R2. No secrets in git — sensitive values come from `TF_VAR_*` environment variables.

## Repo Structure

```
cassandra-infra/
├── modules/
│   └── cloudflare-tunnel/       # Reusable: tunnel + DNS + WAF skip
├── environments/
│   └── production/
│       ├── runner/              # CF Tunnel for claude-agent-runner
│       ├── portal/              # Portal Worker + Access
│       └── yt-mcp/              # CF Tunnel + Worker edge + Access for yt-mcp
└── .gitignore                   # Ignores .terraform/, *.tfstate, *.tfvars
```

## Usage

```bash
source .env   # loads TF_VAR_* and AWS_* (for R2 state backend)

cd environments/production/runner
tofu init -backend-config=production.s3.tfbackend
tofu plan
tofu apply
```

## Secrets

All sensitive values via environment variables. The `.env` file (git-ignored) exports:

```bash
# Cloudflare (Global API Key — needed for DNS, WAF, tunnels)
export TF_VAR_cloudflare_api_key="..."
export TF_VAR_cloudflare_email="..."
export TF_VAR_cloudflare_account_id="..."
export TF_VAR_zone_id="9daf7ca045b2695b4297dfe130c02764"

# Tunnel secret (generate once: openssl rand -base64 32)
export TF_VAR_tunnel_secret="..."

# R2 state backend
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION="auto"
```

For CI/CD, these go in GitHub Secrets.

## Connecting to k8s

After `tofu apply`, the tunnel token needs to be created as a k8s secret manually:

```bash
# Get the tunnel token
tofu output -raw tunnel_token

# Create k8s secret (no sealed secrets — manual kubectl)
kubectl create secret generic cloudflare-tunnel \
  --namespace <namespace> \
  --from-literal=token=<tunnel-token>
```

## Adding More Services

As other services move here (memory, scheduler, MCP gateway), add them under `environments/production/<service>/`. Reuse modules where possible.
