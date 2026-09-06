#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script intelligent de conversion automatique de fichiers PDF / BD en archives CBZ.
Optimisé pour ComicStream et la lecture ultra-haute qualité :
- Détection automatique du format réel (PDF véritable, ou archive CBR/RAR/ZIP/7Z renommée en .pdf)
- Extraction Ultra HD pour les vrais PDF via pdftoppm (300 DPI, 95% qualité JPEG par défaut)
- Extraction sans perte (100% qualité d'origine) pour les archives CBR/ZIP renommées via unar/7z
- Numérotation séquentielle standardisée des pages (page_0001.jpg, ...)
- Traitement parallèle multi-cœurs (ThreadPoolExecutor)
- Vérification rigoureuse de l'intégrité de l'archive CBZ avant suppression du fichier source
"""

import os
import sys
import re
import shutil
import zipfile
import tempfile
import argparse
import subprocess
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# Codes couleurs ANSI
GREEN = '\033[0;32m'
BLUE = '\033[0;34m'
YELLOW = '\033[1;33m'
RED = '\033[0;31m'
CYAN = '\033[0;36m'
BOLD = '\033[1m'
NC = '\033[0m' # No Color

IMAGE_EXTENSIONS = ('.jpg', '.jpeg', '.png', '.webp', '.gif')

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
        print(f"{RED}❌ Erreur : Des dépendances requises sont manquantes : {', '.join(missing)}{NC}")
        print(f"{YELLOW}💡 Pour les installer : sudo apt update && sudo apt install -y poppler-utils unar p7zip-full{NC}")
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
    """Vérifie si une archive CBZ existe et contient au moins une image valide."""
    if not os.path.exists(cbz_path) or os.path.getsize(cbz_path) == 0:
        return False
    try:
        with zipfile.ZipFile(cbz_path, 'r') as zf:
            if zf.testzip() is not None:
                return False
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

def convert_single_pdf(pdf_path, dpi=300, quality=95, format_type="jpeg", keep_pdf=False, force=False, dry_run=False):
    """
    Convertit un unique fichier PDF (ou archive renommée) en archive CBZ avec la meilleure résolution.
    Retourne un dictionnaire avec le statut et les détails.
    """
    pdf_path = os.path.abspath(pdf_path)
    file_dir = os.path.dirname(pdf_path)
    base_name = os.path.splitext(os.path.basename(pdf_path))[0]
    dest_cbz = os.path.join(file_dir, f"{base_name}.cbz")
    
    # 1. Vérification si le CBZ existe déjà
    if os.path.exists(dest_cbz) and not force:
        if is_valid_cbz(dest_cbz):
            if not keep_pdf and not dry_run:
                try:
                    os.remove(pdf_path)
                    return {
                        "status": "SKIPPED_CLEANED",
                        "pdf": pdf_path,
                        "cbz": dest_cbz,
                        "pages": 0,
                        "type": "EXISTS",
                        "msg": "CBZ existant et valide (PDF résiduel nettoyé)"
                    }
                except Exception as e:
                    return {
                        "status": "SKIPPED",
                        "pdf": pdf_path,
                        "cbz": dest_cbz,
                        "pages": 0,
                        "type": "EXISTS",
                        "msg": f"CBZ existant valide (Erreur suppression PDF: {e})"
                    }
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
        return {
            "status": "DRY_RUN",
            "pdf": pdf_path,
            "cbz": dest_cbz,
            "pages": 0,
            "type": detected_type,
            "msg": f"Conversion simulée ({type_str})"
        }

    # 2. Dossier temporaire pour extraction
    temp_dir = tempfile.mkdtemp(prefix="comic_conv_")
    tmp_cbz = dest_cbz + f".tmp_{os.getpid()}"
    
    try:
        # A) CAS VRAI PDF : Extraction via pdftoppm (Rendu Ultra HD)
        if detected_type == "PDF":
            cmd = [
                "pdftoppm",
                "-r", str(dpi),
                "-aa", "yes",
                "-aaVector", "yes"
            ]
            if format_type.lower() == "png":
                cmd.append("-png")
            else:
                cmd.extend(["-jpeg", "-jpegopt", f"quality={quality}"])

            cmd.extend([pdf_path, os.path.join(temp_dir, "page")])
            
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            if proc.returncode != 0:
                # Si pdftoppm échoue, tenter en fallback unar (au cas où la signature PDF était ambiguë)
                if shutil.which("unar"):
                    unar_proc = subprocess.run(["unar", "-quiet", "-output-directory", temp_dir, pdf_path], capture_output=True)
                    if unar_proc.returncode != 0:
                        return {
                            "status": "ERROR",
                            "pdf": pdf_path,
                            "cbz": dest_cbz,
                            "pages": 0,
                            "type": detected_type,
                            "msg": f"Erreur pdftoppm : {proc.stderr.strip() or proc.returncode}"
                        }
                else:
                    return {
                        "status": "ERROR",
                        "pdf": pdf_path,
                        "cbz": dest_cbz,
                        "pages": 0,
                        "type": detected_type,
                        "msg": f"Erreur pdftoppm : {proc.stderr.strip() or proc.returncode}"
                    }

        # B) CAS ARCHIVE RAR/CBR : Extraction sans perte via unar ou 7z
        elif detected_type == "RAR":
            extracted = False
            if shutil.which("unar"):
                proc = subprocess.run(["unar", "-quiet", "-output-directory", temp_dir, pdf_path], capture_output=True)
                if proc.returncode == 0:
                    extracted = True
            if not extracted and shutil.which("7z"):
                proc = subprocess.run(["7z", "x", f"-o{temp_dir}", "-y", pdf_path], capture_output=True)
                if proc.returncode in (0, 1): # 0 = ok, 1 = warning mineur
                    extracted = True
            if not extracted:
                return {
                    "status": "ERROR",
                    "pdf": pdf_path,
                    "cbz": dest_cbz,
                    "pages": 0,
                    "type": detected_type,
                    "msg": "Échec de l'extraction de l'archive RAR/CBR"
                }

        # C) CAS ARCHIVE ZIP/CBZ : Extraction directe via zipfile ou unar
        elif detected_type == "ZIP":
            try:
                with zipfile.ZipFile(pdf_path, 'r') as zf:
                    zf.extractall(temp_dir)
            except Exception:
                if shutil.which("unar"):
                    subprocess.run(["unar", "-quiet", "-output-directory", temp_dir, pdf_path], check=True)
                else:
                    raise

        # D) CAS ARCHIVE 7Z / CB7 : Extraction via 7z ou unar
        elif detected_type == "7Z":
            if shutil.which("7z"):
                subprocess.run(["7z", "x", f"-o{temp_dir}", "-y", pdf_path], check=True, capture_output=True)
            elif shutil.which("unar"):
                subprocess.run(["unar", "-quiet", "-output-directory", temp_dir, pdf_path], check=True, capture_output=True)

        # E) CAS INCONNU : Essayer pdftoppm puis unar
        else:
            proc = subprocess.run(["pdftoppm", "-jpeg", "-r", str(dpi), pdf_path, os.path.join(temp_dir, "page")], capture_output=True)
            if proc.returncode != 0:
                if shutil.which("unar"):
                    unar_proc = subprocess.run(["unar", "-quiet", "-output-directory", temp_dir, pdf_path], capture_output=True)
                    if unar_proc.returncode != 0:
                        return {
                            "status": "ERROR",
                            "pdf": pdf_path,
                            "cbz": dest_cbz,
                            "pages": 0,
                            "type": detected_type,
                            "msg": "Format de fichier non reconnu et illisible"
                        }
                else:
                    return {
                        "status": "ERROR",
                        "pdf": pdf_path,
                        "cbz": dest_cbz,
                        "pages": 0,
                        "type": detected_type,
                        "msg": "Format de fichier non reconnu et illisible"
                    }

        # 3. Récupération et tri de toutes les images extraites
        image_files = collect_extracted_images(temp_dir)
        if not image_files:
            return {
                "status": "ERROR",
                "pdf": pdf_path,
                "cbz": dest_cbz,
                "pages": 0,
                "type": detected_type,
                "msg": "Aucune image trouvée dans le fichier"
            }
        
        # 4. Création de l'archive CBZ standardisée EN LOCAL (SSD rapide, évite les verrous CIFS)
        local_cbz = os.path.join(temp_dir, "comic_archive.cbz")
        with zipfile.ZipFile(local_cbz, 'w', zipfile.ZIP_STORED, allowZip64=True) as zf:
            for idx, img_path in enumerate(image_files, start=1):
                ext = os.path.splitext(img_path)[1].lower()
                entry_name = f"page_{idx:04d}{ext}"
                zf.write(img_path, arcname=entry_name)
        
        # 5. Contrôle d'intégrité strict du CBZ EN LOCAL (Instantané et 100% fiable)
        if not is_valid_cbz(local_cbz):
            return {
                "status": "ERROR",
                "pdf": pdf_path,
                "cbz": dest_cbz,
                "pages": 0,
                "type": detected_type,
                "msg": "Échec de validation locale de l'archive CBZ générée"
            }
        
        # 6. Transfert sécurisé vers le dossier de destination (NAS CIFS ou Disque Local)
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
            return {
                "status": "ERROR",
                "pdf": pdf_path,
                "cbz": dest_cbz,
                "pages": 0,
                "type": detected_type,
                "msg": "Le fichier CBZ final n'a pas pu être écrit sur le stockage de destination"
            }
        
        # 7. Suppression sécurisée du fichier source d'origine
        if not keep_pdf:
            try:
                os.remove(pdf_path)
            except Exception as e:
                return {
                    "status": "SUCCESS_KEEP_ON_ERROR",
                    "pdf": pdf_path,
                    "cbz": dest_cbz,
                    "pages": num_pages,
                    "type": detected_type,
                    "msg": f"CBZ créé ({num_pages} pages), mais impossible de supprimer l'original: {e}"
                }
        
        detail_type = "PDF ➔ CBZ Ultra HD (300 DPI)" if detected_type == "PDF" else f"Archive {detected_type} renommée ➔ CBZ standardisé (100% Qualité brute)"
        return {
            "status": "SUCCESS",
            "pdf": pdf_path,
            "cbz": dest_cbz,
            "pages": num_pages,
            "type": detected_type,
            "msg": f"{num_pages} pages [{detail_type}]"
        }

    except Exception as e:
        if os.path.exists(tmp_cbz):
            try:
                os.remove(tmp_cbz)
            except Exception:
                pass
        return {
            "status": "ERROR",
            "pdf": pdf_path,
            "cbz": dest_cbz,
            "pages": 0,
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
        print(f"{RED}❌ Erreur : Le chemin '{target_path}' n'existe pas.{NC}")
        sys.exit(1)
        
    pdfs = find_pdf_files(target_path)
    total_pdfs = len(pdfs)
    
    if total_pdfs == 0:
        print(f"{GREEN}✅ Aucun fichier PDF trouvé dans '{target_path}'. Bibliothèque 100% CBZ/CBR.${NC}")
        sys.exit(0)
        
    print(f"{BLUE}======================================================{NC}")
    print(f"{BOLD}📚 CONVERSION INTELLIGENTE PDF ➔ CBZ (ComicStream Ultra HD){NC}")
    print(f"{BLUE}======================================================{NC}")
    print(f"📂 Cible        : {CYAN}{target_path}{NC}")
    print(f"📄 Total PDF(s) : {YELLOW}{total_pdfs}{NC}")
    print(f"⚙️  Paramètres   : {args.dpi} DPI (Ultra HD) | {args.format.upper()} Qualité {args.quality}% | {args.workers} workers")
    print(f"🗑️  Nettoyage   : {'Conservation des originaux' if args.keep_pdf else 'Suppression automatique des originaux après validation'}")
    if args.dry_run:
        print(f"{YELLOW}⚠️  MODE SIMULATION (DRY-RUN) : Aucun fichier ne sera altéré.{NC}")
    print(f"{BLUE}======================================================{NC}\n")

    stats = {
        "success": 0,
        "skipped": 0,
        "error": 0,
        "total_pages": 0
    }
    
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {
            executor.submit(
                convert_single_pdf,
                pdf,
                dpi=args.dpi,
                quality=args.quality,
                format_type=args.format,
                keep_pdf=args.keep_pdf,
                force=args.force,
                dry_run=args.dry_run
            ): pdf for pdf in pdfs
        }
        
        completed_count = 0
        for future in as_completed(futures):
            completed_count += 1
            res = future.result()
            pdf_rel = os.path.relpath(res["pdf"], target_path) if os.path.isdir(target_path) else os.path.basename(res["pdf"])
            cbz_name = os.path.basename(res["cbz"])
            
            tag = f"[{completed_count}/{total_pdfs}]"
            
            if res["status"] == "SUCCESS":
                stats["success"] += 1
                stats["total_pages"] += res["pages"]
                clean_info = " (Original supprimé 🗑️)" if not args.keep_pdf else ""
                type_tag = f"[{res['type']}] " if res.get('type') and res['type'] != 'PDF' else ""
                print(f"{GREEN}{tag} ✅ Converti :{NC} {pdf_rel} ➔ {CYAN}{cbz_name}{NC} ({res['pages']} pages) {YELLOW}{type_tag}{NC}{clean_info}")
                
            elif res["status"] == "SKIPPED_CLEANED":
                stats["skipped"] += 1
                print(f"{YELLOW}{tag} ⏭️  Déjà converti :{NC} {pdf_rel} ➔ {cbz_name} {GREEN}(Fichier doublon supprimé){NC}")
                
            elif res["status"] == "SKIPPED":
                stats["skipped"] += 1
                print(f"{YELLOW}{tag} ⏭️  Ignoré :{NC} {pdf_rel} (CBZ déjà présent)")
                
            elif res["status"] == "DRY_RUN":
                stats["success"] += 1
                print(f"{CYAN}{tag} [SIMULATION] {pdf_rel} ➔ {cbz_name} ({res['msg']}){NC}")
                
            elif res["status"] == "SUCCESS_KEEP_ON_ERROR":
                stats["success"] += 1
                stats["total_pages"] += res["pages"]
                print(f"{YELLOW}{tag} ⚠️ Converti avec avertissement :{NC} {pdf_rel} ➔ {cbz_name} ({res['msg']})")
                
            else: # ERROR
                stats["error"] += 1
                print(f"{RED}{tag} ❌ Erreur :{NC} {pdf_rel} ➔ {res['msg']}")

    print(f"\n{BLUE}======================================================{NC}")
    print(f"{BOLD}📊 Résumé de la conversion :{NC}")
    print(f"   • Total traités      : {total_pdfs}")
    print(f"   • Convertis avec succès : {GREEN}{stats['success']}{NC} ({stats['total_pages']} pages)")
    print(f"   • Déjà prêts/ignorés : {YELLOW}{stats['skipped']}{NC}")
    if stats["error"] > 0:
        print(f"   • Échecs / Erreurs   : {RED}{stats['error']}{NC}")
    print(f"{BLUE}======================================================{NC}\n")

    if stats["error"] > 0:
        sys.exit(2)
    sys.exit(0)

if __name__ == "__main__":
    main()
