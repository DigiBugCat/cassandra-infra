output "portal_url" {
  value = module.portal_edge.portal_url
}

output "mcp_keys_kv_namespace_id" {
  description = "KV namespace ID for MCP_KEYS — bind in portal + MCP worker wrangler.jsonc files"
  value       = module.portal_edge.mcp_keys_kv_namespace_id
}
