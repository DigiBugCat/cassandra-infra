mock_provider "cloudflare" {}

variables {
  account_id    = "acc"
  zone_id       = "zone"
  domain        = "example.com"
  subdomain     = "claude-runner"
  tunnel_name   = "cassandra-runner"
  tunnel_secret = "ZmFrZXR1bm5lbHNlY3JldGZha2V0dW5uZWxzZWNyZXQ="
}

run "default_contract" {
  command = plan

  variables {
    origin_url = "http://localhost:8080"
    extra_ingress_rules = [
      {
        hostname      = "grafana.example.com"
        service       = "http://grafana.infra.svc.cluster.local:3000"
        no_tls_verify = true
      }
    ]
    extra_dns_hostnames = ["grafana"]
    access_protected_hostnames = [
      {
        hostname      = "grafana.example.com"
        idp_id        = "idp"
        emails        = ["test@example.com"]
        email_domains = ["example.com"]
      }
    ]
  }

  plan_options {
    refresh = false
  }

  assert {
    condition     = output.hostname == "claude-runner.example.com"
    error_message = "hostname output should combine subdomain and domain"
  }

  assert {
    condition     = cloudflare_record.tunnel.name == "claude-runner"
    error_message = "primary DNS record should use the primary subdomain"
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.this.config[0].ingress_rule[0].hostname == "claude-runner.example.com"
    error_message = "primary ingress should route the primary hostname"
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.this.config[0].ingress_rule[1].origin_request[0].no_tls_verify
    error_message = "extra ingress rules should preserve no_tls_verify"
  }

  assert {
    condition     = cloudflare_zero_trust_access_application.extra["grafana.example.com"].domain == "grafana.example.com"
    error_message = "extra access application should use the provided hostname"
  }
}

run "disabled_optional_resources" {
  command = plan

  variables {
    origin_url        = "http://localhost:8080"
    skip_waf          = false
    create_access_app = false
  }

  plan_options {
    refresh = false
  }

  assert {
    condition     = length(cloudflare_ruleset.waf_skip) == 0
    error_message = "WAF ruleset should not be created when skip_waf is false"
  }

  assert {
    condition     = output.access_app_id == ""
    error_message = "access app output should be empty when create_access_app is false"
  }

  assert {
    condition     = output.cf_access_client_id == ""
    error_message = "service token output should be empty when create_access_app is false"
  }
}
