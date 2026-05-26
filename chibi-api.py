#!/usr/bin/env python3
"""
Chibi Pipeline API Bridge  —  localhost:5555
Bridges the Chibi Studio HTML tool to:
  - ComfyUI REST API (localhost:8188)
  - rembg background removal

Usage:
  python chibi-api.py

Dependencies:
  - rembg (for background removal): pip install rembg[gpu]
  - Pillow:                          pip install Pillow
  - Everything else is Python stdlib
"""

import json
import urllib.request
import urllib.parse
import base64
import io
import sys
import os
import uuid
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

COMFYUI_URL = "http://localhost:8188"
PORT = 5555

# ── CORS headers ─────────────────────────────────────────────────────────────

CORS_HEADERS = {
    "Access-Control-Allow-Origin":  "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}


class Handler(BaseHTTPRequestHandler):

    # ── Routing ───────────────────────────────────────────────────────────────

    def do_OPTIONS(self):
        self._send(200, b"", "text/plain")

    def do_GET(self):
        parsed = urlparse(self.path)
        path   = parsed.path
        params = parse_qs(parsed.query)

        if path.startswith("/comfyui/status"):
            prompt_id = path.rstrip("/").split("/")[-1]
            self._proxy_get(f"{COMFYUI_URL}/history/{prompt_id}")

        elif path == "/comfyui/view":
            filename  = params.get("filename",  [""])[0]
            ftype     = params.get("type",      ["output"])[0]
            subfolder = params.get("subfolder", [""])[0]
            url = (f"{COMFYUI_URL}/view"
                   f"?filename={urllib.parse.quote(filename)}"
                   f"&type={ftype}"
                   f"&subfolder={urllib.parse.quote(subfolder)}")
            self._proxy_image(url)

        elif path == "/ping":
            self._json({"status": "ok", "comfyui": COMFYUI_URL})

        else:
            self._send(404, b"Not found", "text/plain")

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body   = self.rfile.read(length)
        path   = urlparse(self.path).path

        if   path == "/comfyui/upload": self._comfyui_upload(body)
        elif path == "/comfyui/queue":  self._comfyui_queue(body)
        elif path == "/rembg":          self._remove_bg(body)
        else: self._send(404, b"Not found", "text/plain")

    # ── ComfyUI: upload image ─────────────────────────────────────────────────

    def _comfyui_upload(self, body):
        try:
            data      = json.loads(body)
            raw_b64   = data["imageData"].split(",")[-1]
            img_bytes = base64.b64decode(raw_b64)
            filename  = data.get("filename", f"chibi_input_{uuid.uuid4().hex[:8]}.png")

            boundary  = b"----LikhaEraBoundary"
            form  = b"--" + boundary + b"\r\n"
            form += (f'Content-Disposition: form-data; name="image"; filename="{filename}"\r\n').encode()
            form += b"Content-Type: image/png\r\n\r\n"
            form += img_bytes
            form += b"\r\n--" + boundary + b"--\r\n"

            req = urllib.request.Request(
                f"{COMFYUI_URL}/upload/image",
                data=form,
                headers={"Content-Type": f"multipart/form-data; boundary={boundary.decode()}"},
            )
            with urllib.request.urlopen(req, timeout=30) as resp:
                result = resp.read()
            self._send(200, result, "application/json")

        except Exception as e:
            self._error(f"Upload failed: {e}")

    # ── ComfyUI: queue workflow ───────────────────────────────────────────────

    def _comfyui_queue(self, body):
        try:
            req = urllib.request.Request(
                f"{COMFYUI_URL}/prompt",
                data=body,
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=30) as resp:
                result = resp.read()
            self._send(200, result, "application/json")
        except Exception as e:
            self._error(f"Queue failed: {e}")

    # ── ComfyUI: proxy GET (history) ──────────────────────────────────────────

    def _proxy_get(self, url):
        try:
            with urllib.request.urlopen(url, timeout=15) as resp:
                data = resp.read()
            self._send(200, data, "application/json")
        except Exception as e:
            self._error(f"Proxy GET failed: {e}")

    # ── ComfyUI: proxy image ──────────────────────────────────────────────────

    def _proxy_image(self, url):
        try:
            with urllib.request.urlopen(url, timeout=15) as resp:
                data         = resp.read()
                content_type = resp.headers.get("Content-Type", "image/png")
            self._send(200, data, content_type)
        except Exception as e:
            self._error(f"Image proxy failed: {e}")

    # ── rembg: background removal ─────────────────────────────────────────────

    def _remove_bg(self, body):
        try:
            from rembg import remove
            from PIL import Image
        except ImportError:
            self._error(
                "rembg not installed.  Run:  pip install rembg[gpu]\n"
                "(CPU-only:  pip install rembg)"
            )
            return

        try:
            data      = json.loads(body)
            raw_b64   = data["imageData"].split(",")[-1]
            img_bytes = base64.b64decode(raw_b64)

            input_img  = Image.open(io.BytesIO(img_bytes)).convert("RGBA")
            output_img = remove(input_img)

            buf = io.BytesIO()
            output_img.save(buf, format="PNG")
            result_b64 = base64.b64encode(buf.getvalue()).decode()

            self._json({"imageData": f"data:image/png;base64,{result_b64}"})

        except Exception as e:
            self._error(f"Background removal failed: {e}")

    # ── helpers ───────────────────────────────────────────────────────────────

    def _send(self, code, body, content_type):
        self.send_response(code)
        for k, v in CORS_HEADERS.items():
            self.send_header(k, v)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _json(self, obj):
        self._send(200, json.dumps(obj).encode(), "application/json")

    def _error(self, msg):
        print(f"  [ERROR] {msg}", file=sys.stderr)
        self._send(500, json.dumps({"error": msg}).encode(), "application/json")

    def log_message(self, fmt, *args):
        print(f"  [chibi-api] {fmt % args}")


# ── entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    server = HTTPServer(("localhost", PORT), Handler)
    print(f"\n  ✦  Chibi Pipeline API Bridge")
    print(f"     Running on  http://localhost:{PORT}")
    print(f"     ComfyUI at  {COMFYUI_URL}")
    print(f"\n  Endpoints:")
    print(f"     POST /comfyui/upload   — upload image to ComfyUI input folder")
    print(f"     POST /comfyui/queue    — queue a workflow prompt")
    print(f"     GET  /comfyui/status/<id>  — check job status")
    print(f"     GET  /comfyui/view?filename=X&type=Y  — retrieve output image")
    print(f"     POST /rembg            — remove background (needs: pip install rembg)")
    print(f"\n  Press Ctrl+C to stop.\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Stopped.")
