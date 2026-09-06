#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script intelligent de conversion automatique de fichiers PDF / BD en archives CBZ.
Optimisé pour ComicStream avec retour d'état en temps réel et logs détaillés :
- Détection automatique du format réel (PDF véritable, ou archive CBR/RAR/ZIP/7Z renommée en .pdf)
- Extraction Ultra HD pour les vrais PDF via pdftoppm (300 DPI, 95% qualité JPEG par défaut)
- Suivi en temps réel de la progression page par page
- Extraction sans perte (100% qualité d'origine) pour les archives CBR/ZIP renommées via unar/7z
- Numérotation séquentielle standardisée des pages (page_0001.jpg, ...)
- Traitement parallèle multi-cœurs (ThreadPoolExecutor) avec verrou d'affichage thread-safe
- Staging local SSD avant transfert réseau CIFS sécurisé
"""

import os
import sys
import re
import time
import shutil
import zipfile
import tempfile
import argparse
import subprocess
import threading
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# Codes couleurs ANSI
GREEN = '[0;32m'
BLUE = '[0;34m'
YELLOW = '[1;33m'
RED = '[0;31m'
CYAN = '[0;36m'
MAGENTA = '[0;35m'
BOLD = '[1m'
NC = '[0m' # No Color

IMAGE_EXTENSIONS = ('.jpg', '.jpeg', '.png', '.webp', '.gif')
PRINT_LOCK = threading.Lock()

def print_log(message):
    """Affichage thread-safe avec vidage immédiat du tampon."""
    with PRINT_LOCK:
        print(message)
        sys.stdout.flush()

def format_size(size_bytes):
    """Formatage lisible de la taille en octets."""
    if size_bytes < 1024:
        return f"{size_bytes} B"
    elif size_bytes < 1024 * 1024:
        return f"{size_bytes / 1024:.1f} Ko"
    elif size_bytes < 1024 * 1024 * 1024:
        return f"{size_bytes / (1024 * 1024):.1f} Mo"
    else:
        return f"{size_bytes / (1024 * 1024 * 1024):.2f} Go"

def natural_sort_key(s):
    """Clé de tri naturel pour ordonner correctement les fichiers numérotés."""
    return [int(text) if text.isdigit() else text.lower() for text in re.split(r'(\d+)', str(s))]

def check_dependencies():
    """Vérifie que les outils d'extraction sont disponibles."""
    missing = []
    if shutil.which("pdftoppm") is None:
        missing.append("poppler-utils (pdftoppm)")
    if shutil.which("unar") is None and shutil.which("7z") is None:
        missing.append("unar ou p7zip-full")
        
    if missing:
        print_log(f"{RED}❌ Erreur : Des dépendances requises sont manquantes : {', '.join(missing)}{NC}")
        print_log(f"{YELLOW}💡 Pour les installer : sudo apt update && sudo apt install -y poppler-utils unar p7zip-full{NC}")
        return False
    return True

def detect_file_type(path):
    """Détecte le type réel du fichier via ses octets magiques (signature)."""
    try:
        with open(path, 'rb') as f:
            hdr = f.read(1024)
        if hdr.startswith(b'%PDF-') or b'%PDF-' in hdr[:1024]:
            return 'PDF'
        elif hdr.startswith(b'PK\x03\x04'):
            return 'ZIP'
        elif hdr.startswith(b'Rar!\x1a\x07'):
            return 'RAR'
        elif hdr.startswith(b'7z\xbc\xaf\x27\x1c'):
            return '7Z'
        else:
            return 'UNKNOWN'
    except Exception:
        return 'UNKNOWN'

def is_valid_cbz(cbz_path):
    """Vérifie rapidement si une archive CBZ existe et contient des images valides sans bloquer le réseau."""
    try:
        if not os.path.exists(cbz_path) or os.path.getsize(cbz_path) < 100:
            return False
        with zipfile.ZipFile(cbz_path, 'r') as zf:
            valid_images = [
                name for name in zf.namelist() 
                if name.lower().endswith(IMAGE_EXTENSIONS) and not name.startswith('__MACOSX/')
            ]
            return len(valid_images) > 0
    except Exception:
        return False

def collect_extracted_images(directory):
    """Collecte récursivement toutes les images extraites dans un dossier et les trie."""
    images = []
    for root, _, files in os.walk(directory):
        for f in files:
            if f.lower().endswith(IMAGE_EXTENSIONS) and not f.startswith('._'):
                images.append(os.path.join(root, f))
    images.sort(key=natural_sort_key)
    return images

def convert_single_pdf(pdf_path, index, total, base_root="", dpi=300, quality=95, format_type="jpeg", keep_pdf=False, force=False, dry_run=False):
    """
    Convertit un unique fichier PDF (ou archive renommée) en archive CBZ avec suivi en temps réel.
    """
    start_time = time.time()
    pdf_path = os.path.abspath(pdf_path)
    file_dir = os.path.dirname(pdf_path)
    base_name = os.path.splitext(os.path.basename(pdf_path))[0]
    dest_cbz = os.path.join(file_dir, f"{base_name}.cbz")
    pdf_rel = os.path.relpath(pdf_path, base_root) if base_root and os.path.isdir(base_root) else os.path.basename(pdf_path)
    tag = f"[{index}/{total}]"
    
    print_log(f"{BLUE}{tag} ⏳ Analyse :{NC} {CYAN}{pdf_rel}{NC}...")
    
    # 1. Vérification si le CBZ existe déjà
    if os.path.exists(dest_cbz) and not force:
        if is_valid_cbz(dest_cbz):
            if not keep_pdf and not dry_run:
                try:
                    os.remove(pdf_path)
                    print_log(f"{YELLOW}{tag} ⏭️  Déjà converti :{NC} {pdf_rel} ➔ {os.path.basename(dest_cbz)} {GREEN}(PDF doublon nettoyé){NC}")
                    return {
                        "status": "SKIPPED_CLEANED",
                        "pdf": pdf_path,
                        "cbz": dest_cbz,
                        "pages": 0,
                        "type": "EXISTS",
                        "msg": "CBZ existant et valide (PDF résiduel nettoyé)"
                    }
                except Exception as e:
                    print_log(f"{YELLOW}{tag} ⏭️  Déjà converti :{NC} {pdf_rel} (Erreur suppression PDF: {e})")
                    return {
                        "status": "SKIPPED",
                        "pdf": pdf_path,
                        "cbz": dest_cbz,
                        "pages": 0,
                        "type": "EXISTS",
                        "msg": f"CBZ existant valide (Erreur suppression PDF: {e})"
                    }
            print_log(f"{YELLOW}{tag} ⏭️  Ignoré :{NC} {pdf_rel} (Archive CBZ déjà prête)")
            return {
                "status": "SKIPPED",
                "pdf": pdf_path,
                "cbz": dest_cbz,
                "pages": 0,
                "type": "EXISTS",
                "msg": "Archive CBZ déjà existante et valide"
            }

    # Détection du type de fichier réel
    detected_type = detect_file_type(pdf_path)

    if dry_run:
        type_str = f"PDF Ultra HD {dpi} DPI" if detected_type == "PDF" else f"Archive {detected_type} ➔ CBZ direct"
        print_log(f"{CYAN}{tag} [SIMULATION] {pdf_rel} ➔ {os.path.basename(dest_cbz)} ({type_str}){NC}")
        return {
            "status": "DRY_RUN",
            "pdf": pdf_path,
            "cbz": dest_cbz,
            "pages": 0,
            "type": detected_type,
            "msg": f"Conversion simulée ({type_str})"
        }

    print_log(f"{BLUE}{tag} 🚀 Démarrage conversion [{detected_type}] :{NC} {CYAN}{pdf_rel}{NC} ({dpi} DPI)...")

    # 2. Dossier temporaire pour extraction
    temp_dir = tempfile.mkdtemp(prefix="comic_conv_")
    
    try:
        # A) CAS VRAI PDF : Extraction via pdftoppm (Rendu Ultra HD avec progression page par page)
        if detected_type == "PDF":
            cmd = [
                "pdftoppm",
                "-progress",
                "-r", str(dpi),
                "-aa", "yes",
                "-aaVector", "yes"
            ]
            if format_type.lower() == "png":
                cmd.append("-png")
            else:
                cmd.extend(["-jpeg", "-jpegopt", f"quality={quality}"])

            cmd.extend([pdf_path, os.path.join(temp_dir, "page")])
            
            proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
            
            last_logged_page = 0
            for raw_line in iter(proc.stderr.readline, ''):
                line = raw_line.strip()
                if not line:
                    continue
                parts = line.split()
                if len(parts) >= 2 and parts[0].isdigit() and parts[1].isdigit():
                    curr_p = int(parts[0])
                    tot_p = int(parts[1])
                    
                    # Intervalle dynamique pour un suivi réactif en temps réel
                    step = 5 if tot_p <= 50 else (10 if tot_p <= 150 else 15)
                    
                    if curr_p == 1 or curr_p == tot_p or (curr_p - last_logged_page) >= step:
                        last_logged_page = curr_p
                        pct = int((curr_p / tot_p) * 100)
                        print_log(f"   {YELLOW}↳ {tag} Rendu Ultra HD ({base_name[:30]}...):{NC} page {curr_p}/{tot_p} ({pct}%)")
            
            proc.wait()
            if proc.returncode != 0:
                if shutil.which("unar"):
                    print_log(f"   {YELLOW}↳ {tag} Fallback extraction unar...{NC}")
                    unar_proc = subprocess.run(["unar", "-quiet", "-output-directory", temp_dir, pdf_path], capture_output=True)
                    if unar_proc.returncode != 0:
                        raise RuntimeError(f"Erreur d'extraction pdftoppm/unar (code {proc.returncode})")
                else:
                    raise RuntimeError(f"Erreur d'extraction pdftoppm (code {proc.returncode})")

        # B) CAS ARCHIVE RAR/CBR : Extraction sans perte via unar ou 7z
        elif detected_type == "RAR":
            print_log(f"   {YELLOW}↳ {tag} Décompression archive CBR/RAR en cours...{NC}")
            extracted = False
            if shutil.which("unar"):
                proc = subprocess.run(["unar", "-quiet", "-output-directory", temp_dir, pdf_path], capture_output=True)
                if proc.returncode == 0:
                    extracted = True
            if not extracted and shutil.which("7z"):
                proc = subprocess.run(["7z", "x", f"-o{temp_dir}", "-y", pdf_path], capture_output=True)
                if proc.returncode in (0, 1):
                    extracted = True
            if not extracted:
                raise RuntimeError("Échec de décompression de l'archive RAR/CBR")

        # C) CAS ARCHIVE ZIP/CBZ : Extraction directe
        elif detected_type == "ZIP":
            print_log(f"   {YELLOW}↳ {tag} Décompression archive CBZ/ZIP en cours...{NC}")
            try:
                with zipfile.ZipFile(pdf_path, 'r') as zf:
                    zf.extractall(temp_dir)
            except Exception:
                if shutil.which("unar"):
                    subprocess.run(["unar", "-quiet", "-output-directory", temp_dir, pdf_path], check=True)
                else:
                    raise

        # D) CAS ARCHIVE 7Z / CB7
        elif detected_type == "7Z":
            print_log(f"   {YELLOW}↳ {tag} Décompression archive CB7/7Z en cours...{NC}")
            if shutil.which("7z"):
                subprocess.run(["7z", "x", f"-o{temp_dir}", "-y", pdf_path], check=True, capture_output=True)
            elif shutil.which("unar"):
                subprocess.run(["unar", "-quiet", "-output-directory", temp_dir, pdf_path], check=True, capture_output=True)

        # E) CAS INCONNU : Fallback
        else:
            print_log(f"   {YELLOW}↳ {tag} Tentative de lecture du format inconnu...{NC}")
            proc = subprocess.run(["pdftoppm", "-jpeg", "-r", str(dpi), pdf_path, os.path.join(temp_dir, "page")], capture_output=True)
            if proc.returncode != 0:
                if shutil.which("unar"):
                    unar_proc = subprocess.run(["unar", "-quiet", "-output-directory", temp_dir, pdf_path], capture_output=True)
                    if unar_proc.returncode != 0:
                        raise RuntimeError("Format de fichier non reconnu et illisible")
                else:
                    raise RuntimeError("Format de fichier non reconnu et illisible")

        # 3. Récupération et tri de toutes les images extraites
        image_files = collect_extracted_images(temp_dir)
        if not image_files:
            raise RuntimeError("Aucune image valide trouvée dans le fichier")
        
        num_pages = len(image_files)
        
        # 4. Création de l'archive CBZ standardisée EN LOCAL (SSD rapide)
        print_log(f"   {BLUE}↳ {tag} Empaquetage CBZ local ({num_pages} pages)...{NC}")
        local_cbz = os.path.join(temp_dir, "comic_archive.cbz")
        with zipfile.ZipFile(local_cbz, 'w', zipfile.ZIP_STORED, allowZip64=True) as zf:
            for idx, img_path in enumerate(image_files, start=1):
                ext = os.path.splitext(img_path)[1].lower()
                entry_name = f"page_{idx:04d}{ext}"
                zf.write(img_path, arcname=entry_name)
        
        # 5. Contrôle d'intégrité strict du CBZ EN LOCAL
        if not is_valid_cbz(local_cbz):
            raise RuntimeError("Échec de validation de l'archive CBZ générée en local")
        
        final_size = os.path.getsize(local_cbz)
        final_size_str = format_size(final_size)
        
        # 6. Transfert sécurisé vers le dossier de destination (NAS CIFS ou Disque Local)
        print_log(f"   {MAGENTA}↳ {tag} Transfert vers le stockage ({final_size_str})...{NC}")
        dest_tmp = dest_cbz + f".tmp_{os.getpid()}"
        if os.path.exists(dest_tmp):
            try:
                os.remove(dest_tmp)
            except Exception:
                pass
        
        shutil.copyfile(local_cbz, dest_tmp)
        if os.path.exists(dest_cbz):
            try:
                os.remove(dest_cbz)
            except Exception:
                pass
        os.replace(dest_tmp, dest_cbz)
        
        # Vérification finale de la présence sur la destination
        if not os.path.exists(dest_cbz) or os.path.getsize(dest_cbz) == 0:
            raise RuntimeError("Le fichier CBZ final n'a pas pu être écrit sur le stockage distant")
        
        # 7. Suppression sécurisée du fichier source d'origine
        clean_note = ""
        if not keep_pdf:
            try:
                os.remove(pdf_path)
                clean_note = " (PDF supprimé 🗑️)"
            except Exception as e:
                clean_note = f" (Avertissement: Impossible de supprimer le PDF: {e})"
        
        elapsed = time.time() - start_time
        detail_type = "PDF ➔ CBZ Ultra HD (300 DPI)" if detected_type == "PDF" else f"Archive {detected_type} ➔ CBZ"
        
        print_log(f"{GREEN}{tag} ✅ Terminé :{NC} {pdf_rel} ➔ {CYAN}{os.path.basename(dest_cbz)}{NC} ({num_pages} pages, {final_size_str}) en {elapsed:.1f}s{clean_note}")
        
        return {
            "status": "SUCCESS",
            "pdf": pdf_path,
            "cbz": dest_cbz,
            "pages": num_pages,
            "size": final_size,
            "elapsed": elapsed,
            "type": detected_type,
            "msg": f"{num_pages} pages [{detail_type}] ({final_size_str}) en {elapsed:.1f}s"
        }

    except Exception as e:
        elapsed = time.time() - start_time
        print_log(f"{RED}{tag} ❌ Erreur :{NC} {pdf_rel} ➔ {e}")
        return {
            "status": "ERROR",
            "pdf": pdf_path,
            "cbz": dest_cbz,
            "pages": 0,
            "size": 0,
            "elapsed": elapsed,
            "type": detected_type,
            "msg": f"Exception lors de la conversion : {e}"
        }
    finally:
        if os.path.exists(temp_dir):
            shutil.rmtree(temp_dir, ignore_errors=True)

def find_pdf_files(target_path):
    """Recherche récursive de tous les fichiers PDF."""
    target = Path(target_path)
    if not target.exists():
        return []
    if target.is_file():
        if target.suffix.lower() == '.pdf':
            return [str(target)]
        return []
    
    pdf_list = []
    for root, _, files in os.walk(target):
        for f in files:
            if f.lower().endswith('.pdf'):
                pdf_list.append(os.path.join(root, f))
    
    pdf_list.sort(key=natural_sort_key)
    return pdf_list

def main():
    parser = argparse.ArgumentParser(
        description="Conversion intelligente par lot de fichiers PDF et BD en archives CBZ Ultra HD."
    )
    parser.add_argument("path", help="Dossier racine ou fichier PDF à convertir")
    parser.add_argument("--dpi", type=int, default=300, help="Résolution de rendu DPI pour les PDF (Défaut: 300 DPI Ultra HD)")
    parser.add_argument("--quality", type=int, default=95, help="Qualité JPEG de 1 à 100 pour les PDF (Défaut: 95% Haute Fidélité)")
    parser.add_argument("--format", choices=["jpeg", "png"], default="jpeg", help="Format image de rendu (Défaut: jpeg, ou png sans perte)")
    parser.add_argument("--workers", "-j", type=int, default=min(4, os.cpu_count() or 2), help="Nombre de conversions parallèles")
    parser.add_argument("--keep-pdf", action="store_true", help="Conserver les fichiers originaux après conversion")
    parser.add_argument("--force", action="store_true", help="Reconvertir même si un fichier CBZ existe déjà")
    parser.add_argument("--dry-run", action="store_true", help="Simuler les opérations sans modifier les fichiers")
    
    args = parser.parse_args()
    
    if not check_dependencies():
        sys.exit(1)
        
    target_path = os.path.abspath(args.path)
    if not os.path.exists(target_path):
        print_log(f"{RED}❌ Erreur : Le chemin '{target_path}' n'existe pas.{NC}")
        sys.exit(1)
        
    pdfs = find_pdf_files(target_path)
    total_pdfs = len(pdfs)
    
    if total_pdfs == 0:
        print_log(f"{GREEN}✅ Aucun fichier PDF trouvé dans '{target_path}'. Bibliothèque 100% CBZ/CBR.")
        sys.exit(0)
        
    print_log(f"{BLUE}======================================================{NC}")
    print_log(f"{BOLD}📚 CONVERSION INTELLIGENTE PDF ➔ CBZ (ComicStream Ultra HD){NC}")
    print_log(f"{BLUE}======================================================{NC}")
    print_log(f"📂 Cible        : {CYAN}{target_path}{NC}")
    print_log(f"📄 Total PDF(s) : {YELLOW}{total_pdfs}{NC}")
    print_log(f"⚙️  Paramètres   : {args.dpi} DPI (Ultra HD) | {args.format.upper()} Qualité {args.quality}% | {args.workers} workers")
    print_log(f"🗑️  Nettoyage   : {'Conservation des originaux' if args.keep_pdf else 'Suppression automatique des originaux après validation'}")
    if args.dry_run:
        print_log(f"{YELLOW}⚠️  MODE SIMULATION (DRY-RUN) : Aucun fichier ne sera altéré.{NC}")
    print_log(f"{BLUE}======================================================{NC}\n")

    stats = {
        "success": 0,
        "skipped": 0,
        "error": 0,
        "total_pages": 0,
        "total_bytes": 0
    }
    
    total_start = time.time()
    
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {
            executor.submit(
                convert_single_pdf,
                pdf,
                idx,
                total_pdfs,
                base_root=target_path,
                dpi=args.dpi,
                quality=args.quality,
                format_type=args.format,
                keep_pdf=args.keep_pdf,
                force=args.force,
                dry_run=args.dry_run
            ): pdf for idx, pdf in enumerate(pdfs, start=1)
        }
        
        for future in as_completed(futures):
            res = future.result()
            
            if res["status"] == "SUCCESS":
                stats["success"] += 1
                stats["total_pages"] += res.get("pages", 0)
                stats["total_bytes"] += res.get("size", 0)
            elif res["status"] in ("SKIPPED", "SKIPPED_CLEANED"):
                stats["skipped"] += 1
            elif res["status"] == "DRY_RUN":
                stats["success"] += 1
            else:
                stats["error"] += 1

    total_time = time.time() - total_start
    
    print_log(f"\n{BLUE}======================================================{NC}")
    print_log(f"{BOLD}📊 Résumé de la conversion :{NC}")
    print_log(f"   • Total traités         : {total_pdfs}")
    print_log(f"   • Convertis avec succès : {GREEN}{stats['success']}{NC} ({stats['total_pages']} pages, {format_size(stats['total_bytes'])})")
    print_log(f"   • Déjà prêts/ignorés    : {YELLOW}{stats['skipped']}{NC}")
    if stats["error"] > 0:
        print_log(f"   • Échecs / Erreurs      : {RED}{stats['error']}{NC}")
    print_log(f"   ⏱️  Temps total          : {total_time:.1f}s")
    print_log(f"{BLUE}======================================================{NC}\n")

    if stats["error"] > 0:
        sys.exit(2)
    sys.exit(0)

if __name__ == "__main__":
    main()
