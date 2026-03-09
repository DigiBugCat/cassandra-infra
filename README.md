# Cassandra Infra

> **Disclaimer:** This repo is a personal infrastructure configuration. It's public for reference — you'll need your own Cloudflare account, domain, and credentials.

Terraform/OpenTofu for all Cloudflare resources across the Cassandra stack. Single root module, one `tofu apply` manages everything.

This repo is stack-scoped rather than standalone: the root module intentionally references sibling repos in the `cassandra-stack` workspace via `../cassandra-*` paths to avoid a bootstrap chicken-and-egg problem.

## What's Here

- **`main.tf`** — Terraform block + provider
- **`runner.tf`** — CF Tunnel for the runner plus grafana, argocd, and vm-push ingress
- **`portal.tf`** — Portal Worker edge (KV, D1, DNS, CF Access)
- **`yt-mcp.tf`** — yt-mcp backend tunnel, Worker edge, and backend Access
- **`observability.tf`** — CF Access service token for Worker metrics push
- **`modules/cloudflare-tunnel/`** — Reusable module: CF Tunnel + DNS + WAF skip + Access policies
- **`environments/`** — Backend config examples and local tfvars (gitignored)

## Deploying

```bash
# 1. Load credentials (git-ignored, exports TF_VAR_* and AWS_*)
source /path/to/cassandra-stack/env/infra.env

# 2. Run from the cassandra-infra repo inside the cassandra-stack workspace
cd /path/to/cassandra-stack/cassandra-infra

# 3. Init (first time only)
tofu init -backend-config=environments/production/production.s3.tfbackend

# 4. Plan and apply
tofu plan
tofu apply
```

### After applying the runner tunnel

The runner tunnel token needs to go into the k8s cluster:

```bash
# Get the token
tofu output -raw runner_tunnel_token

# Create the secret (or seal it)
kubectl create secret generic cloudflare-tunnel --namespace claude-runner \
  --from-literal=token='<tunnel-token>'
```

## Secrets

All sensitive values via environment variables (`TF_VAR_*`). Nothing secret is committed to this repo.

See `cassandra-stack/env/infra.env` (git-ignored) for the required variables.

## State

Terraform state is stored in a Cloudflare R2 bucket, configured via the S3-compatible backend file at `environments/production/production.s3.tfbackend`.

## License

[MIT](LICENSE)
