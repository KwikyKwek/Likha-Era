/**
 * Chibi Pipeline API Bridge  —  localhost:5555
 * Node.js replacement for chibi-api.py (no Python required)
 *
 * Usage:   node chibi-api.mjs
 *
 * Endpoints
 *   POST /comfyui/upload      — upload image to ComfyUI input folder
 *   POST /comfyui/queue       — queue a workflow prompt
 *   GET  /comfyui/status/:id  — check job status / history
 *   GET  /comfyui/view        — proxy output image (?filename=X&type=Y&subfolder=Z)
 *   POST /rembg               — remove background (uses @imgly/background-removal-node)
 *   GET  /ping                — health check
 */

import http  from 'http';
import { URL } from 'url';
import { Buffer } from 'buffer';

const COMFYUI = 'http://localhost:8188';
const PORT    = 5555;

const CORS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

// ── helpers ────────────────────────────────────────────────────────────────

function reply(res, status, body, type = 'application/json') {
  const data = typeof body === 'string' ? Buffer.from(body) : Buffer.from(JSON.stringify(body));
  res.writeHead(status, { ...CORS, 'Content-Type': type, 'Content-Length': data.length });
  res.end(data);
}

function err(res, msg) {
  console.error('  [ERR]', msg);
  reply(res, 500, { error: String(msg) });
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', c => chunks.push(c));
    req.on('end',  () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

function httpGet(url, timeoutMs = 15000) {
  return new Promise((resolve, reject) => {
    const req = http.get(url, res => {
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end',  () => resolve({ data: Buffer.concat(chunks), ct: res.headers['content-type'] || 'application/octet-stream' }));
    });
    req.setTimeout(timeoutMs, () => { req.destroy(); reject(new Error('Timeout')); });
    req.on('error', reject);
  });
}

function httpPost(urlStr, body, contentType, timeoutMs = 30000) {
  return new Promise((resolve, reject) => {
    const u = new URL(urlStr);
    const options = {
      hostname: u.hostname, port: u.port || 80,
      path: u.pathname + u.search, method: 'POST',
      headers: { 'Content-Type': contentType, 'Content-Length': body.length },
    };
    const req = http.request(options, res => {
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end',  () => resolve({ data: Buffer.concat(chunks), ct: res.headers['content-type'] || 'application/json' }));
    });
    req.setTimeout(timeoutMs, () => { req.destroy(); reject(new Error('Timeout')); });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ── route handlers ─────────────────────────────────────────────────────────

async function handleUpload(req, res) {
  try {
    const body     = await readBody(req);
    const payload  = JSON.parse(body.toString());
    const raw      = payload.imageData.includes(',') ? payload.imageData.split(',')[1] : payload.imageData;
    const imgBuf   = Buffer.from(raw, 'base64');
    const filename = payload.filename || `chibi_${Date.now()}.png`;

    const boundary = `----NodeBridge${Date.now()}`;
    const head     = Buffer.from(
      `--${boundary}\r\nContent-Disposition: form-data; name="image"; filename="${filename}"\r\nContent-Type: image/png\r\n\r\n`
    );
    const tail = Buffer.from(`\r\n--${boundary}--\r\n`);
    const form = Buffer.concat([head, imgBuf, tail]);

    const result = await httpPost(
      `${COMFYUI}/upload/image`, form,
      `multipart/form-data; boundary=${boundary}`
    );
    reply(res, 200, result.data.toString(), 'application/json');
  } catch (e) { err(res, e); }
}

async function handleQueue(req, res) {
  try {
    const body   = await readBody(req);
    const result = await httpPost(`${COMFYUI}/prompt`, body, 'application/json');
    reply(res, 200, result.data.toString(), 'application/json');
  } catch (e) { err(res, e); }
}

async function handleStatus(req, res, promptId) {
  try {
    const { data } = await httpGet(`${COMFYUI}/history/${promptId}`);
    reply(res, 200, data.toString(), 'application/json');
  } catch (e) { err(res, e); }
}

async function handleView(req, res, query) {
  try {
    const filename  = query.get('filename')  || '';
    const type      = query.get('type')      || 'output';
    const subfolder = query.get('subfolder') || '';
    const url = `${COMFYUI}/view?filename=${encodeURIComponent(filename)}&type=${type}&subfolder=${encodeURIComponent(subfolder)}`;
    const { data, ct } = await httpGet(url);
    reply(res, 200, data, ct);
  } catch (e) { err(res, e); }
}

async function handleRembg(req, res) {
  let removeBackground;
  try {
    ({ removeBackground } = await import('@imgly/background-removal-node'));
  } catch {
    err(res, 'Background removal package not found. Run: npm install @imgly/background-removal-node');
    return;
  }

  try {
    const body    = await readBody(req);
    const payload = JSON.parse(body.toString());
    const raw     = payload.imageData.includes(',') ? payload.imageData.split(',')[1] : payload.imageData;
    const imgBuf  = Buffer.from(raw, 'base64');

    console.log('  [rembg] Removing background… (first run downloads models ~50MB)');
    const resultBlob = await removeBackground(imgBuf);
    const resultBuf  = Buffer.from(await resultBlob.arrayBuffer());
    const b64        = resultBuf.toString('base64');
    reply(res, 200, { imageData: `data:image/png;base64,${b64}` });
    console.log('  [rembg] Done.');
  } catch (e) { err(res, e); }
}

// ── server ─────────────────────────────────────────────────────────────────

const server = http.createServer(async (req, res) => {
  const u     = new URL(req.url, `http://localhost:${PORT}`);
  const path  = u.pathname;
  const query = u.searchParams;

  if (req.method === 'OPTIONS') { reply(res, 200, ''); return; }

  try {
    if (req.method === 'GET') {
      if (path === '/ping') {
        reply(res, 200, { status: 'ok', comfyui: COMFYUI, node: process.version });
      } else if (path.startsWith('/comfyui/status/')) {
        const id = path.split('/').pop();
        await handleStatus(req, res, id);
      } else if (path === '/comfyui/view') {
        await handleView(req, res, query);
      } else {
        reply(res, 404, { error: 'Not found' });
      }
    } else if (req.method === 'POST') {
      if      (path === '/comfyui/upload') await handleUpload(req, res);
      else if (path === '/comfyui/queue')  await handleQueue(req, res);
      else if (path === '/rembg')          await handleRembg(req, res);
      else reply(res, 404, { error: 'Not found' });
    } else {
      reply(res, 405, { error: 'Method not allowed' });
    }
  } catch (e) {
    err(res, e);
  }
});

server.listen(PORT, 'localhost', () => {
  console.log('\n  ✦  Chibi Pipeline API Bridge (Node.js)');
  console.log(`     Running on  http://localhost:${PORT}`);
  console.log(`     ComfyUI at  ${COMFYUI}`);
  console.log(`     Node.js     ${process.version}\n`);
  console.log('  Endpoints:');
  console.log('     POST /comfyui/upload      — upload image to ComfyUI');
  console.log('     POST /comfyui/queue       — queue a workflow');
  console.log('     GET  /comfyui/status/:id  — check job status');
  console.log('     GET  /comfyui/view        — retrieve output image');
  console.log('     POST /rembg               — remove background');
  console.log('\n  Press Ctrl+C to stop.\n');
});

server.on('error', e => {
  if (e.code === 'EADDRINUSE') {
    console.error(`  Port ${PORT} is already in use. Stop the other process first.`);
  } else {
    console.error('  Server error:', e);
  }
  process.exit(1);
});
