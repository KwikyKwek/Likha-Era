import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = 3000;

const mimeTypes = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

const server = http.createServer((req, res) => {
  try {
    const rawPath = req.url === '/' ? '/index.html' : req.url.split('?')[0];
    const decoded = decodeURIComponent(rawPath);
    const filePath = path.join(__dirname, decoded);
    const ext = path.extname(filePath).toLowerCase();

    // Mirror Vercel cleanUrls: if no extension, try appending .html
    const candidates = ext ? [filePath] : [filePath, filePath + '.html'];

    const tryNext = (list) => {
      if (!list.length) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      fs.readFile(list[0], (err, data) => {
        if (err) { tryNext(list.slice(1)); return; }
        const contentType = mimeTypes[path.extname(list[0]).toLowerCase()] || 'text/plain';
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(data);
      });
    };

    tryNext(candidates);
  } catch {
    res.writeHead(500);
    res.end('Server error');
  }
});

server.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
