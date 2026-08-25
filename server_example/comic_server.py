#!/usr/bin/env python3
"""
ComicStream - Serveur Local WebDAV / HTTP léger pour Bandes Dessinées et Mangas
Compatible avec les fichiers .cbz, .cbr, .pdf, .zip

Usage :
    python3 comic_server.py --port 8080 --dir ~/Comics
"""

import os
import sys
import socket
import argparse
import urllib.parse
from http.server import HTTPServer, SimpleHTTPRequestHandler
from datetime import datetime

SUPPORTED_EXTENSIONS = {'.cbz', '.cbr', '.pdf', '.zip', '.epub'}

def get_local_ip():
    """Récupère l'adresse IP locale de la machine sur le réseau WiFi/LAN."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def format_http_date(timestamp):
    dt = datetime.utcfromtimestamp(timestamp)
    return dt.strftime('%a, %d %b %Y %H:%M:%S GMT')

class ComicWebDavHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Enable CORS and WebDAV headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PROPFIND, HEAD')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Depth, Authorization')
        self.send_header('DAV', '1, 2')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Allow', 'GET, HEAD, POST, OPTIONS, PROPFIND')
        self.end_headers()

    def do_PROPFIND(self):
        """Gère les requêtes WebDAV PROPFIND pour lister les dossiers et fichiers."""
        path = self.translate_path(self.path)
        depth = self.headers.get('Depth', '1')

        if not os.path.exists(path):
            self.send_error(404, "Dossier introuvable")
            return

        is_dir = os.path.isdir(path)
        items_to_report = []

        # Target item itself
        items_to_report.append((self.path, path, is_dir))

        # Direct children if directory and Depth != 0
        if is_dir and depth != '0':
            try:
                for entry in sorted(os.listdir(path)):
                    if entry.startswith('.'):
                        continue
                    entry_path = os.path.join(path, entry)
                    entry_is_dir = os.path.isdir(entry_path)
                    entry_ext = os.path.splitext(entry)[1].lower()

                    # Only show directories or supported comic formats
                    if entry_is_dir or entry_ext in SUPPORTED_EXTENSIONS:
                        rel_url = urllib.parse.urljoin(self.path.rstrip('/') + '/', urllib.parse.quote(entry))
                        if entry_is_dir:
                            rel_url += '/'
                        items_to_report.append((rel_url, entry_path, entry_is_dir))
            except PermissionError:
                pass

        # Build WebDAV XML response
        xml = ['<?xml version="1.0" encoding="utf-8" ?>']
        xml.append('<D:multistatus xmlns:D="DAV:">')

        for item_url, item_sys_path, item_is_dir in items_to_report:
            try:
                stat_info = os.stat(item_sys_path)
                size = stat_info.st_size if not item_is_dir else 0
                mtime = format_http_date(stat_info.st_mtime)
                display_name = os.path.basename(item_sys_path.rstrip(os.sep))
                if not display_name:
                    display_name = "Racine"

                xml.append('  <D:response>')
                xml.append(f'    <D:href>{item_url}</D:href>')
                xml.append('    <D:propstat>')
                xml.append('      <D:prop>')
                xml.append(f'        <D:displayname>{display_name}</D:displayname>')
                if item_is_dir:
                    xml.append('        <D:resourcetype><D:collection/></D:resourcetype>')
                else:
                    xml.append('        <D:resourcetype/>')
                    xml.append(f'        <D:getcontentlength>{size}</D:getcontentlength>')
                xml.append(f'        <D:getlastmodified>{mtime}</D:getlastmodified>')
                xml.append('      </D:prop>')
                xml.append('      <D:status>HTTP/1.1 200 OK</D:status>')
                xml.append('    </D:propstat>')
                xml.append('  </D:response>')
            except Exception:
                continue

        xml.append('</D:multistatus>')
        xml_bytes = '\n'.join(xml).encode('utf-8')

        self.send_response(207, "Multi-Status")
        self.send_header('Content-Type', 'application/xml; charset=utf-8')
        self.send_header('Content-Length', str(len(xml_bytes)))
        self.end_headers()
        self.wfile.write(xml_bytes)

def main():
    parser = argparse.ArgumentParser(description="Serveur WebDAV/HTTP ComicStream pour bandes dessinées")
    parser.add_argument('--port', '-p', type=int, default=8080, help="Port d'écoute (défaut: 8080)")
    parser.add_argument('--dir', '-d', type=str, default='.', help="Dossier contenant vos BD/CBZ/PDF")
    args = parser.parse_args()

    comics_dir = os.path.abspath(os.path.expanduser(args.dir))
    if not os.path.exists(comics_dir):
        os.makedirs(comics_dir, exist_ok=True)

    os.chdir(comics_dir)

    ip = get_local_ip()
    port = args.port

    print("=" * 60)
    print(" 📚 Serveur ComicStream démarré avec succès !")
    print("=" * 60)
    print(f" 📂 Dossier partagé  : {comics_dir}")
    print(f" 🌐 Adresse locale   : http://{ip}:{port}/")
    print(f" 💻 Sur cette machine : http://localhost:{port}/")
    print("-" * 60)
    print(" 📱 Configuration dans l'application Flutter :")
    print(f"    - Protocole : WebDAV")
    print(f"    - Hôte/IP   : {ip}")
    print(f"    - Port      : {port}")
    print(f"    - Chemin    : /")
    print("=" * 60)
    print(" Appuyez sur Ctrl+C pour arrêter le serveur.")

    server = HTTPServer(('0.0.0.0', port), ComicWebDavHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nArrêt du serveur...")
        server.server_close()

if __name__ == '__main__':
    main()
