# Cassandra Infra

> **Disclaimer:** This repo is a personal infrastructure configuration. It's public for reference — you'll need your own Cloudflare account, domain, and credentials.

Terraform/OpenTofu modules for cloud-managed resources (Cloudflare tunnels, DNS, Workers, Access policies).

## What's Here

- **`modules/cloudflare-tunnel/`** — Reusable module: CF Tunnel + DNS + WAF skip + Access policies
- **`environments/production/runner/`** — CF Tunnel for the Claude Agent Runner plus grafana, argocd, and vm-push ingress
- **`environments/production/portal/`** — Portal Worker edge and Access
- **`environments/production/observability/`** — CF Access service token for Worker metrics push
- **`environments/production/yt-mcp/`** — yt-mcp backend tunnel, Worker edge, and backend Access

## Deploying

Each environment is a separate Terraform root under `environments/`. Not GitOps — you run `tofu apply` manually.

```bash
# 1. Load credentials (git-ignored .env exports TF_VAR_* and AWS_*)
source .env

# 2. Pick an environment
cd environments/production/runner   # or environments/production/portal

# 3. Init (first time only)
tofu init -backend-config=production.s3.tfbackend

# 4. Plan and apply
tofu plan -var-file=production.tfvars
tofu apply -var-file=production.tfvars
```

## Verification

Use the repo test harness from this subrepo:

```bash
./scripts/test-plan.sh static
./scripts/test-plan.sh integration
./scripts/test-plan.sh full
```

Or from the stack root:

```bash
./scripts/subrepo-test-plan.sh run cassandra-infra static
./scripts/subrepo-test-plan.sh run cassandra-infra integration
./scripts/subrepo-test-plan.sh run cassandra-infra full
```

### After applying the runner tunnel

The tunnel token output needs to go into the k8s cluster:

```bash
# Get the token
tofu output -raw tunnel_token

# Create the secret (or seal it)
kubectl create secret generic cloudflare-tunnel --namespace claude-runner \
  --from-literal=token='<tunnel-token>'
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
