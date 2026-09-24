"""Static server for a built Flutter web app.

`python -m http.server` looks for a real file at every path, so deep links such
as /loginPage or /energyDetails come back 404. A single-page app needs every
unknown path to fall through to index.html and let the app route itself.

    python serve_web.py            # serves build/web on 8000
    python serve_web.py 8001       # different port
"""

import http.server
import os
import socketserver
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000


class SpaHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def do_GET(self):
        path = self.translate_path(self.path)
        if not os.path.isfile(path):
            self.path = "/index.html"
        return super().do_GET()

    def end_headers(self):
        # Always hand back the freshest build; a cached main.dart.js is the
        # classic reason a change "did not take effect".
        self.send_header("Cache-Control", "no-store, must-revalidate")
        super().end_headers()

    def log_message(self, *args):
        pass  # quiet


if not os.path.isdir(ROOT):
    sys.exit(f"build/web not found — run: flutter build web --release")

with socketserver.TCPServer(("", PORT), SpaHandler) as httpd:
    print(f"serving {ROOT} at http://localhost:{PORT}  (Ctrl+C to stop)")
    httpd.serve_forever()
