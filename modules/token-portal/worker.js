// Cassandra Portal — CF Worker
// Serves the dashboard UI and manages service tokens via CF API.
// Env vars: CF_API_TOKEN, CF_ACCOUNT_ID, RUNNER_ACCESS_APP_ID, RUNNER_ACCESS_POLICY_ID

const CF_API = "https://api.cloudflare.com/client/v4";
const TOKEN_PREFIX = "cassandra/";

// ── API Handlers ──

async function listTokens(env) {
  const resp = await fetch(
    `${CF_API}/accounts/${env.CF_ACCOUNT_ID}/access/service_tokens`,
    { headers: { Authorization: `Bearer ${env.CF_API_TOKEN}` } },
  );
  const data = await resp.json();
  if (!data.success) throw new Error(data.errors?.[0]?.message || "Failed to list tokens");
  // Only show tokens created by this portal
  return data.result.filter((t) => t.name.startsWith(TOKEN_PREFIX));
}

async function createToken(env, name) {
  const prefixedName = TOKEN_PREFIX + name;
  // 1. Create the service token
  const resp = await fetch(
    `${CF_API}/accounts/${env.CF_ACCOUNT_ID}/access/service_tokens`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.CF_API_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ name: prefixedName, duration: "8760h" }),
    },
  );
  const data = await resp.json();
  if (!data.success) throw new Error(data.errors?.[0]?.message || "Failed to create token");
  const token = data.result;

  // 2. Add the new token to the runner's Access policy
  await addTokenToPolicy(env, token.id);

  return token;
}

async function revokeToken(env, tokenId) {
  // 1. Remove from runner Access policy
  await removeTokenFromPolicy(env, tokenId);

  // 2. Delete the service token
  const resp = await fetch(
    `${CF_API}/accounts/${env.CF_ACCOUNT_ID}/access/service_tokens/${tokenId}`,
    {
      method: "DELETE",
      headers: { Authorization: `Bearer ${env.CF_API_TOKEN}` },
    },
  );
  const data = await resp.json();
  if (!data.success) throw new Error(data.errors?.[0]?.message || "Failed to revoke token");
  return data.result;
}

// ── Policy Management ──

async function getPolicy(env) {
  const resp = await fetch(
    `${CF_API}/accounts/${env.CF_ACCOUNT_ID}/access/apps/${env.RUNNER_ACCESS_APP_ID}/policies/${env.RUNNER_ACCESS_POLICY_ID}`,
    { headers: { Authorization: `Bearer ${env.CF_API_TOKEN}` } },
  );
  const data = await resp.json();
  if (!data.success) throw new Error("Failed to get policy");
  return data.result;
}

async function updatePolicyTokens(env, tokenIds) {
  const resp = await fetch(
    `${CF_API}/accounts/${env.CF_ACCOUNT_ID}/access/apps/${env.RUNNER_ACCESS_APP_ID}/policies/${env.RUNNER_ACCESS_POLICY_ID}`,
    {
      method: "PUT",
      headers: {
        Authorization: `Bearer ${env.CF_API_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        name: "Service token access",
        decision: "non_identity",
        precedence: 1,
        include: tokenIds.map((id) => ({ service_token: { token_id: id } })),
      }),
    },
  );
  const data = await resp.json();
  if (!data.success) throw new Error("Failed to update policy: " + JSON.stringify(data.errors));
}

async function addTokenToPolicy(env, newTokenId) {
  const policy = await getPolicy(env);
  const existing = extractTokenIds(policy);
  if (!existing.includes(newTokenId)) {
    existing.push(newTokenId);
  }
  await updatePolicyTokens(env, existing);
}

async function removeTokenFromPolicy(env, tokenId) {
  const policy = await getPolicy(env);
  const existing = extractTokenIds(policy).filter((id) => id !== tokenId);
  if (existing.length > 0) {
    await updatePolicyTokens(env, existing);
  }
}

function extractTokenIds(policy) {
  const ids = [];
  for (const rule of policy.include || []) {
    if (rule.service_token) {
      const st = rule.service_token;
      if (typeof st === "string") ids.push(st);
      else if (st.token_id) {
        if (Array.isArray(st.token_id)) ids.push(...st.token_id);
        else ids.push(st.token_id);
      }
    }
  }
  return ids;
}

// ── Router ──

async function handleRequest(request, env) {
  const url = new URL(request.url);

  // API routes
  if (url.pathname === "/api/tokens" && request.method === "GET") {
    try {
      const tokens = await listTokens(env);
      return jsonResponse(tokens);
    } catch (e) {
      return jsonResponse({ error: e.message }, 500);
    }
  }

  if (url.pathname === "/api/tokens" && request.method === "POST") {
    try {
      const { name } = await request.json();
      if (!name) return jsonResponse({ error: "name is required" }, 400);
      const token = await createToken(env, name);
      return jsonResponse(token);
    } catch (e) {
      return jsonResponse({ error: e.message }, 500);
    }
  }

  if (url.pathname.startsWith("/api/tokens/") && request.method === "DELETE") {
    try {
      const tokenId = url.pathname.split("/api/tokens/")[1];
      await revokeToken(env, tokenId);
      return jsonResponse({ ok: true });
    } catch (e) {
      return jsonResponse({ error: e.message }, 500);
    }
  }

  // Serve the portal HTML for everything else
  return new Response(PORTAL_HTML, {
    headers: { "Content-Type": "text/html;charset=UTF-8" },
  });
}

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export default {
  async fetch(request, env) {
    return handleRequest(request, env);
  },
};

// ── Portal HTML (Design 2: Dense) ──

const PORTAL_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Cassandra Portal</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Geist+Mono:wght@300;400;500&family=Sora:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
:root{--bg-0:#08070b;--bg-1:#0e0d13;--bg-2:#15141b;--bg-3:#1d1c24;--bg-4:#25242e;--border:#2e2d38;--border-active:#454359;--text-0:#f0eef8;--text-1:#c4c0d4;--text-2:#8a86a0;--text-3:#5c586e;--purple:#9b7cf8;--purple-soft:rgba(155,124,248,0.1);--purple-medium:rgba(155,124,248,0.2);--green:#4ade80;--green-soft:rgba(74,222,128,0.1);--red:#fb7185;--red-soft:rgba(251,113,133,0.1);--amber:#fbbf24;--amber-soft:rgba(251,191,36,0.08);--top-bar:44px}
body{font-family:'Sora',sans-serif;background:var(--bg-0);color:var(--text-0);min-height:100vh;font-size:13px}
.topbar{height:var(--top-bar);background:var(--bg-1);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 20px;gap:24px;position:sticky;top:0;z-index:20}
.topbar-brand{font-size:14px;font-weight:600;color:var(--purple);letter-spacing:-0.01em;margin-right:8px;display:flex;align-items:center;gap:8px}
.topbar-brand .dot{width:6px;height:6px;background:var(--purple);border-radius:50%;box-shadow:0 0 8px var(--purple)}
.topbar-nav{display:flex;gap:2px;flex:1}
.topbar-tab{padding:8px 16px;border-radius:6px;color:var(--text-2);font-size:12.5px;font-weight:400;cursor:pointer;transition:all .12s;text-decoration:none}
.topbar-tab:hover{background:var(--bg-3);color:var(--text-1)}
.topbar-tab.active{background:var(--purple-soft);color:var(--purple);font-weight:500}
.topbar-user{font-size:11.5px;color:var(--text-3);display:flex;align-items:center;gap:8px}
.topbar-user .avatar{width:24px;height:24px;border-radius:50%;background:var(--bg-4);border:1px solid var(--border);display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:600;color:var(--text-1)}
.layout{padding:20px;max-width:1400px;margin:0 auto}
.page{display:none}.page.active{display:block}
.dash-top{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:20px}
.metric{background:var(--bg-2);border:1px solid var(--border);border-radius:10px;padding:16px 18px;display:flex;flex-direction:column;gap:6px}
.metric-top{display:flex;justify-content:space-between;align-items:center}
.metric-label{font-size:11px;font-weight:400;color:var(--text-3);text-transform:uppercase;letter-spacing:.05em}
.metric-badge{font-size:10px;padding:2px 7px;border-radius:4px;font-weight:500}
.metric-badge.up{background:var(--green-soft);color:var(--green)}
.metric-badge.neutral{background:var(--bg-4);color:var(--text-2)}
.metric-value{font-size:28px;font-weight:600;letter-spacing:-0.02em;line-height:1}
.metric-sub{font-size:11px;color:var(--text-3)}
.dash-grid{display:grid;grid-template-columns:2fr 1fr;gap:12px}
.panel{background:var(--bg-2);border:1px solid var(--border);border-radius:10px;overflow:hidden}
.panel-header{padding:14px 18px;border-bottom:1px solid var(--border);display:flex;justify-content:space-between;align-items:center}
.panel-title{font-size:12px;font-weight:500;color:var(--text-1)}
.mini-table{width:100%;border-collapse:collapse}
.mini-table th{text-align:left;padding:8px 18px;font-size:10px;font-weight:500;color:var(--text-3);text-transform:uppercase;letter-spacing:.05em;background:var(--bg-3)}
.mini-table td{padding:10px 18px;font-size:12.5px;border-bottom:1px solid var(--border);color:var(--text-1)}
.mini-table tr:last-child td{border-bottom:none}
.session-id{font-family:'Geist Mono',monospace;font-size:11px;color:var(--text-2)}
.status-pill{display:inline-flex;align-items:center;gap:4px;font-size:11px;font-weight:500}
.status-pill::before{content:'';width:5px;height:5px;border-radius:50%}
.status-pill.active::before{background:var(--green);box-shadow:0 0 6px rgba(74,222,128,0.4)}.status-pill.active{color:var(--green)}
.status-pill.idle::before{background:var(--amber)}.status-pill.idle{color:var(--amber)}
.activity-item{padding:12px 18px;border-bottom:1px solid var(--border);display:flex;gap:12px}
.activity-item:last-child{border-bottom:none}
.activity-icon{width:28px;height:28px;border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:12px;flex-shrink:0}
.activity-icon.token{background:var(--purple-soft)}.activity-icon.session{background:var(--green-soft)}.activity-icon.error{background:var(--red-soft)}
.activity-text{font-size:12px;color:var(--text-1);line-height:1.4}
.activity-time{font-size:10.5px;color:var(--text-3);margin-top:2px}
.tokens-bar{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px}
.tokens-count{font-size:12px;color:var(--text-3)}.tokens-count strong{color:var(--text-1)}
.btn{display:inline-flex;align-items:center;gap:6px;padding:7px 14px;border-radius:6px;font-family:'Sora',sans-serif;font-size:12px;font-weight:500;border:none;cursor:pointer;transition:all .12s}
.btn-accent{background:var(--purple);color:var(--bg-0)}.btn-accent:hover{background:#ae90ff}
.btn-sm{padding:4px 10px;font-size:11px;border-radius:5px}
.btn-outline{background:transparent;border:1px solid var(--border);color:var(--text-2)}.btn-outline:hover{border-color:var(--border-active);color:var(--text-1)}
.btn-red-sm{background:transparent;border:1px solid transparent;color:var(--red);padding:4px 10px;font-size:11px;font-family:'Sora',sans-serif;cursor:pointer;border-radius:5px}.btn-red-sm:hover{background:var(--red-soft)}
.full-table{width:100%;border-collapse:collapse;background:var(--bg-2);border:1px solid var(--border);border-radius:10px;overflow:hidden}
.full-table th{text-align:left;padding:10px 18px;font-size:10.5px;font-weight:500;color:var(--text-3);text-transform:uppercase;letter-spacing:.05em;background:var(--bg-3);border-bottom:1px solid var(--border)}
.full-table td{padding:14px 18px;font-size:12.5px;border-bottom:1px solid var(--border);color:var(--text-1)}
.full-table tr:last-child td{border-bottom:none}
.full-table tr:hover td{background:rgba(155,124,248,0.02)}
.mono{font-family:'Geist Mono',monospace;font-size:11px;color:var(--text-2);background:var(--bg-3);padding:2px 6px;border-radius:3px}
.pill{display:inline-flex;align-items:center;gap:4px;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:500}
.pill.active{background:var(--green-soft);color:var(--green)}.pill.revoked{background:var(--bg-4);color:var(--text-3)}
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,0.65);backdrop-filter:blur(3px);z-index:100;align-items:center;justify-content:center}
.modal-overlay.active{display:flex}
.modal{background:var(--bg-1);border:1px solid var(--border);border-radius:10px;padding:24px;width:440px;animation:slideUp .18s ease}
@keyframes slideUp{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}
.modal h3{font-size:15px;font-weight:600;margin-bottom:6px}
.modal .desc{font-size:12px;color:var(--text-2);margin-bottom:20px}
.field{margin-bottom:16px}
.field label{display:block;font-size:10.5px;font-weight:500;color:var(--text-3);text-transform:uppercase;letter-spacing:.05em;margin-bottom:6px}
.field input{width:100%;padding:8px 12px;background:var(--bg-3);border:1px solid var(--border);border-radius:6px;font-family:'Sora',sans-serif;font-size:12.5px;color:var(--text-0);outline:none}
.field input:focus{border-color:var(--purple)}
.cred-box{background:var(--bg-3);border:1px solid var(--border);border-radius:6px;padding:12px;margin-bottom:12px;font-family:'Geist Mono',monospace;font-size:11.5px;color:var(--purple);word-break:break-all;line-height:1.5}
.cred-box .key{font-family:'Sora',sans-serif;font-size:9.5px;color:var(--text-3);text-transform:uppercase;letter-spacing:.06em;display:block;margin-bottom:3px}
.warn-banner{background:var(--amber-soft);border:1px solid rgba(251,191,36,0.12);border-radius:6px;padding:10px 12px;font-size:11.5px;color:var(--amber);margin-bottom:16px;display:flex;align-items:center;gap:8px}
.modal-footer{display:flex;justify-content:flex-end;gap:8px;margin-top:4px}
.monitor-empty{display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:360px;background:var(--bg-2);border:1px dashed var(--border);border-radius:10px}
.monitor-empty h3{font-size:14px;font-weight:500;color:var(--text-2);margin-bottom:4px}
.monitor-empty p{font-size:12px;color:var(--text-3)}
.loading{opacity:0.5;pointer-events:none}
.spinner{display:inline-block;width:14px;height:14px;border:2px solid var(--border);border-top-color:var(--purple);border-radius:50%;animation:spin .6s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}
.empty-state{text-align:center;padding:40px;color:var(--text-3);font-size:12.5px}
</style>
</head>
<body>
<header class="topbar">
  <div class="topbar-brand"><span class="dot"></span>Cassandra</div>
  <nav class="topbar-nav">
    <a class="topbar-tab active" data-page="dashboard">Dashboard</a>
    <a class="topbar-tab" data-page="tokens">Tokens</a>
    <a class="topbar-tab" data-page="monitoring">Monitoring</a>
  </nav>
  <div class="topbar-user">
    <div class="avatar">?</div>
    <span id="user-email">loading...</span>
  </div>
</header>
<div class="layout">
  <div class="page active" id="page-dashboard">
    <div class="dash-top">
      <div class="metric"><div class="metric-top"><span class="metric-label">Tokens</span><span class="metric-badge neutral" id="dash-token-badge">-</span></div><div class="metric-value" id="dash-token-count">-</div><div class="metric-sub" id="dash-token-sub">loading...</div></div>
      <div class="metric"><div class="metric-top"><span class="metric-label">Health</span><span class="metric-badge up">ok</span></div><div class="metric-value" style="font-size:16px;margin-top:6px">Operational</div><div class="metric-sub">CF Tunnel active</div></div>
      <div class="metric"><div class="metric-top"><span class="metric-label">Endpoint</span></div><div class="metric-value" style="font-size:12px;margin-top:8px;color:var(--text-1);word-break:break-all">claude-runner.REDACTED_DOMAIN</div><div class="metric-sub">via Cloudflare Access</div></div>
      <div class="metric"><div class="metric-top"><span class="metric-label">Auth</span></div><div class="metric-value" style="font-size:14px;margin-top:6px">Service Tokens</div><div class="metric-sub">CF-Access-Client-Id/Secret</div></div>
    </div>
    <div class="dash-grid">
      <div class="panel"><div class="panel-header"><span class="panel-title">Recent Tokens</span><a class="btn btn-sm btn-outline" style="cursor:pointer" data-nav="tokens">View All</a></div><div class="panel-body"><table class="mini-table"><thead><tr><th>Name</th><th>Client ID</th><th>Status</th><th>Created</th></tr></thead><tbody id="dash-tokens-body"><tr><td colspan="4" class="empty-state">Loading...</td></tr></tbody></table></div></div>
      <div class="panel"><div class="panel-header"><span class="panel-title">Quick Links</span></div><div style="padding:14px 18px;display:flex;flex-direction:column;gap:8px">
        <a href="https://claude-runner.REDACTED_DOMAIN/health" target="_blank" style="color:var(--text-1);font-size:12px;text-decoration:none;display:flex;align-items:center;gap:8px"><span style="font-size:14px">🔗</span> Runner Health Check</a>
        <a href="#" style="color:var(--text-2);font-size:12px;text-decoration:none;display:flex;align-items:center;gap:8px"><span style="font-size:14px">📊</span> Grafana (coming soon)</a>
        <a href="https://github.com/DigiBugCat" target="_blank" style="color:var(--text-1);font-size:12px;text-decoration:none;display:flex;align-items:center;gap:8px"><span style="font-size:14px">🐙</span> GitHub Org</a>
      </div></div>
    </div>
  </div>
  <div class="page" id="page-tokens">
    <div class="tokens-bar">
      <div class="tokens-count" id="tokens-count">Loading...</div>
      <button class="btn btn-accent" onclick="showCreateModal()">+ New Token</button>
    </div>
    <table class="full-table"><thead><tr><th>Name</th><th>Client ID</th><th>Created</th><th>Status</th><th></th></tr></thead><tbody id="tokens-body"><tr><td colspan="5" class="empty-state">Loading...</td></tr></tbody></table>
  </div>
  <div class="page" id="page-monitoring">
    <div class="monitor-empty"><h3>📊 Grafana Dashboards</h3><p>Monitoring dashboards will be embedded here</p></div>
  </div>
</div>

<div class="modal-overlay" id="modal">
  <div class="modal" id="modal-create">
    <h3>New Service Token</h3>
    <p class="desc">Create a CF Access service token for runner access.</p>
    <div class="field"><label>Token Name</label><input id="token-name" placeholder="e.g. my-laptop, ci-pipeline"></div>
    <div class="modal-footer"><button class="btn btn-outline" onclick="hideModal()">Cancel</button><button class="btn btn-accent" id="create-btn" onclick="createToken()">Create</button></div>
  </div>
  <div class="modal" id="modal-result" style="display:none">
    <h3>Token Created ✓</h3>
    <div class="warn-banner">⚠ Copy now — the secret won't be shown again.</div>
    <div class="cred-box"><span class="key">Client ID</span><span id="new-client-id"></span></div>
    <div class="cred-box"><span class="key">Client Secret</span><span id="new-client-secret"></span></div>
    <div class="modal-footer"><button class="btn btn-accent" onclick="hideModal(); loadTokens();">Done</button></div>
  </div>
</div>

<script>
// ── Nav ──
document.querySelectorAll('.topbar-tab').forEach(t=>{t.addEventListener('click',()=>{document.querySelectorAll('.topbar-tab').forEach(x=>x.classList.remove('active'));t.classList.add('active');document.querySelectorAll('.page').forEach(p=>p.classList.remove('active'));document.getElementById('page-'+t.dataset.page).classList.add('active')})});
document.querySelectorAll('[data-nav]').forEach(l=>{l.addEventListener('click',e=>{e.preventDefault();const p=l.dataset.nav;document.querySelectorAll('.topbar-tab').forEach(t=>t.classList.toggle('active',t.dataset.page===p));document.querySelectorAll('.page').forEach(pg=>pg.classList.remove('active'));document.getElementById('page-'+p).classList.add('active')})});

// ── User info from CF Access JWT ──
try{const jwt=document.cookie.split(';').map(c=>c.trim()).find(c=>c.startsWith('CF_Authorization='));if(jwt){const payload=JSON.parse(atob(jwt.split('=')[1].split('.')[1]));document.getElementById('user-email').textContent=payload.email||'unknown';document.querySelector('.avatar').textContent=(payload.email||'?')[0].toUpperCase()}}catch(e){document.getElementById('user-email').textContent='authenticated'}

// ── API ──
async function loadTokens(){
  try{
    const resp=await fetch('/api/tokens');
    const tokens=await resp.json();
    if(tokens.error){throw new Error(tokens.error)}
    renderTokens(tokens);
  }catch(e){
    document.getElementById('tokens-body').innerHTML='<tr><td colspan="5" class="empty-state">Failed to load: '+e.message+'</td></tr>';
  }
}

function renderTokens(tokens){
  const active=tokens.filter(t=>!t.deleted_at);
  const revoked=tokens.filter(t=>t.deleted_at);

  // Dashboard metrics
  document.getElementById('dash-token-count').textContent=active.length;
  document.getElementById('dash-token-badge').textContent=tokens.length+' total';
  document.getElementById('dash-token-sub').textContent=active.length+' active'+(revoked.length?' / '+revoked.length+' revoked':'');
  document.getElementById('tokens-count').innerHTML='<strong>'+tokens.length+'</strong> tokens · <strong>'+active.length+'</strong> active';

  // Dashboard recent table (top 4)
  const recent=active.slice(0,4);
  document.getElementById('dash-tokens-body').innerHTML=recent.length?recent.map(t=>'<tr><td style="font-weight:500">'+esc(t.name.replace('cassandra/',''))+'</td><td><code class="mono">'+t.client_id.slice(0,14)+'...</code></td><td><span class="pill active">● Active</span></td><td style="color:var(--text-3)">'+fmtDate(t.created_at)+'</td></tr>').join(''):'<tr><td colspan="4" class="empty-state">No tokens yet</td></tr>';

  // Full tokens table
  const rows=[...active,...revoked].map(t=>{
    const isRevoked=!!t.deleted_at;
    return '<tr'+(isRevoked?' style="opacity:0.4"':'')+'><td style="font-weight:500">'+esc(t.name.replace('cassandra/',''))+'</td><td><code class="mono">'+t.client_id.slice(0,14)+'...</code></td><td style="color:var(--text-3)">'+fmtDate(t.created_at)+'</td><td><span class="pill '+(isRevoked?'revoked':'active')+'">'+(isRevoked?'Revoked':'● Active')+'</span></td><td style="text-align:right">'+(isRevoked?'':'<button class="btn-red-sm" onclick="revokeToken(\\''+t.id+'\\',\\''+esc(t.name.replace('cassandra/',''))+'\\')">Revoke</button>')+'</td></tr>';
  });
  document.getElementById('tokens-body').innerHTML=rows.length?rows.join(''):'<tr><td colspan="5" class="empty-state">No tokens yet. Create one to get started.</td></tr>';
}

function fmtDate(d){if(!d)return'-';const dt=new Date(d);return dt.toLocaleDateString('en-US',{month:'short',day:'numeric',year:'numeric'})}
function esc(s){const d=document.createElement('div');d.textContent=s;return d.innerHTML}

// ── Create ──
function showCreateModal(){document.getElementById('modal').classList.add('active');document.getElementById('modal-create').style.display='block';document.getElementById('modal-result').style.display='none';document.getElementById('token-name').value='';document.getElementById('token-name').focus()}
function hideModal(){document.getElementById('modal').classList.remove('active')}
document.getElementById('modal').addEventListener('click',e=>{if(e.target===e.currentTarget)hideModal()});

async function createToken(){
  const name=document.getElementById('token-name').value.trim();
  if(!name)return;
  const btn=document.getElementById('create-btn');
  btn.innerHTML='<span class="spinner"></span> Creating...';btn.disabled=true;
  try{
    const resp=await fetch('/api/tokens',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name})});
    const token=await resp.json();
    if(token.error)throw new Error(token.error);
    document.getElementById('new-client-id').textContent=token.client_id;
    document.getElementById('new-client-secret').textContent=token.client_secret;
    document.getElementById('modal-create').style.display='none';
    document.getElementById('modal-result').style.display='block';
  }catch(e){alert('Failed: '+e.message)}finally{btn.innerHTML='Create';btn.disabled=false}
}

// ── Revoke ──
async function revokeToken(id,name){
  if(!confirm('Revoke token "'+name+'"? This cannot be undone.'))return;
  try{
    await fetch('/api/tokens/'+id,{method:'DELETE'});
    loadTokens();
  }catch(e){alert('Failed: '+e.message)}
}

// ── Init ──
loadTokens();
</script>
</body>
</html>`;
