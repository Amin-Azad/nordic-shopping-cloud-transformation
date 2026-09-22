'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;
const KEY_VAULT_URI = process.env.KEY_VAULT_URI || '';
const PROBE_SECRET_NAME = process.env.PROBE_SECRET_NAME || 'readiness-probe';

const META = {
  service: 'nordicshop-api',
  role: process.env.APP_ROLE || 'api',
  region: process.env.DEPLOYMENT_REGION || 'unknown',
  environment: process.env.ENVIRONMENT_NAME || 'unknown',
  commit: process.env.BUILD_COMMIT || 'unknown',
  builtAt: process.env.BUILD_TIMESTAMP || 'unknown'
};

// The Azure SDK is loaded lazily so the process still starts and serves
// /health/live even if the dependency is missing. A readiness failure should
// be reported, not turned into a crash loop.
let secretClient = null;
let secretClientError = null;

function getSecretClient() {
  if (secretClient || secretClientError) {
    return secretClient;
  }
  if (!KEY_VAULT_URI) {
    secretClientError = 'KEY_VAULT_URI is not configured';
    return null;
  }
  try {
    const { DefaultAzureCredential } = require('@azure/identity');
    const { SecretClient } = require('@azure/keyvault-secrets');
    secretClient = new SecretClient(KEY_VAULT_URI, new DefaultAzureCredential());
    return secretClient;
  } catch (err) {
    secretClientError = `SDK unavailable: ${err.message}`;
    return null;
  }
}

/**
 * Reaching Key Vault from inside the App Service exercises, in one call:
 *   1. the system-assigned managed identity token exchange
 *   2. private DNS resolution of privatelink.vaultcore.azure.net
 *   3. the private endpoint network path
 *   4. the Key Vault Secrets User RBAC assignment
 *
 * A 404 means the secret does not exist but all four of the above worked, so
 * it counts as ready. A 403 or a timeout means something in the chain is wrong.
 */
async function checkKeyVault() {
  const client = getSecretClient();
  if (!client) {
    return { ok: false, detail: secretClientError };
  }
  const startedAt = Date.now();
  try {
    await client.getSecret(PROBE_SECRET_NAME);
    return { ok: true, detail: 'secret read', latencyMs: Date.now() - startedAt };
  } catch (err) {
    const status = err.statusCode || err.code || 'error';
    if (status === 404) {
      return {
        ok: true,
        detail: 'authenticated over private endpoint, probe secret absent',
        latencyMs: Date.now() - startedAt
      };
    }
    return { ok: false, detail: `${status}: ${err.message}`, latencyMs: Date.now() - startedAt };
  }
}

function sendJson(res, status, body) {
  const payload = JSON.stringify(body, null, 2);
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff'
  });
  res.end(payload);
}

const server = http.createServer(async (req, res) => {
  const url = (req.url || '/').split('?')[0];

  try {
    if (url === '/health/live') {
      return sendJson(res, 200, { status: 'live', ...META });
    }

    if (url === '/health/ready') {
      const keyVault = await checkKeyVault();
      return sendJson(res, keyVault.ok ? 200 : 503, {
        status: keyVault.ok ? 'ready' : 'not-ready',
        checks: { keyVault },
        ...META
      });
    }

    if (url === '/version') {
      return sendJson(res, 200, META);
    }

    if (url === '/') {
      const page = path.join(__dirname, 'public', 'index.html');
      return fs.readFile(page, (err, data) => {
        if (err) {
          return sendJson(res, 500, { error: 'status page unavailable' });
        }
        res.writeHead(200, {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'no-store',
          'x-content-type-options': 'nosniff'
        });
        res.end(data);
      });
    }

    return sendJson(res, 404, { error: 'not found', path: url });
  } catch (err) {
    return sendJson(res, 500, { error: 'unhandled', detail: err.message });
  }
});

server.listen(PORT, () => {
  console.log(`nordicshop-api listening on ${PORT} (commit ${META.commit})`);
});

// App Service sends SIGTERM during restarts and swaps.
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server');
  server.close(() => process.exit(0));
});

module.exports = server;
