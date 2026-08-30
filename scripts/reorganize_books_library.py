#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de réorganisation et standardisation de la bibliothèque numérique BOOKS.
Supporte le mode simulation (--dry-run) ou application directe.
"""

import os
import sys
import shutil
import zipfile
import re
import argparse

BOOKS_DIR = "/mnt/misc/BOOKS"

def parse_args():
    parser = argparse.ArgumentParser(description="Réorganisation de la bibliothèque BOOKS")
    parser.add_argument("--dry-run", action="store_true", help="Simuler les opérations sans modifier les fichiers")
    return parser.parse_args()

class LibraryOrganizer:
    def __init__(self, base_dir, dry_run=False):
        self.base_dir = base_dir
        self.dry_run = dry_run
        self.stats = {
            "moved_files": 0,
            "renamed_files": 0,
            "renamed_dirs": 0,
            "created_cbz": 0,
            "deleted_junk": 0,
            "errors": 0
        }

    def log(self, prefix, message):
        tag = "[SIMULATION] " if self.dry_run else ""
        print(f"{tag}{prefix} {message}")

    def safe_move(self, src, dst):
        if not os.path.exists(src):
            self.log("⚠️", f"Source introuvable : {src}")
            return False
        if src == dst:
            return True
        
        self.log("➡️", f"{src}  ===>  {dst}")
        if not self.dry_run:
            try:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.move(src, dst)
                self.stats["moved_files"] += 1
                return True
            except Exception as e:
                self.log("❌", f"Erreur déplacement {src} -> {dst}: {e}")
                self.stats["errors"] += 1
                return False
        else:
            self.stats["moved_files"] += 1
            return True

    def safe_rename(self, src, dst):
        if not os.path.exists(src):
            self.log("⚠️", f"Source introuvable : {src}")
            return False
        if src == dst:
            return True
        
        self.log("✏️", f"{src}  --->  {dst}")
        if not self.dry_run:
            try:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                os.rename(src, dst)
                self.stats["renamed_files"] += 1
                return True
            except Exception as e:
                self.log("❌", f"Erreur renommage {src} -> {dst}: {e}")
                self.stats["errors"] += 1
                return False
        else:
            self.stats["renamed_files"] += 1
            return True

    def safe_delete_file(self, path):
        if not os.path.exists(path):
            return
        self.log("🗑️", f"Suppression fichier inutile : {path}")
        if not self.dry_run:
            try:
                os.remove(path)
                self.stats["deleted_junk"] += 1
            except Exception as e:
                self.log("❌", f"Erreur suppression {path}: {e}")
                self.stats["errors"] += 1
        else:
            self.stats["deleted_junk"] += 1

    def safe_delete_tree(self, path):
        if not os.path.exists(path):
            return
        self.log("🗑️", f"Suppression dossier inutile : {path}")
        if not self.dry_run:
            try:
                shutil.rmtree(path)
                self.stats["deleted_junk"] += 1
            except Exception as e:
                self.log("❌", f"Erreur suppression dossier {path}: {e}")
                self.stats["errors"] += 1
        else:
            self.stats["deleted_junk"] += 1

    def create_cbz_from_dir(self, source_dir, dest_cbz):
        if not os.path.exists(source_dir):
            self.log("⚠️", f"Dossier source introuvable pour CBZ : {source_dir}")
            return False
        
        self.log("📦", f"Création archive CBZ : {dest_cbz} à partir de {source_dir}")
        if not self.dry_run:
            try:
                os.makedirs(os.path.dirname(dest_cbz), exist_ok=True)
                tmp_cbz = dest_cbz + ".tmp"
                with zipfile.ZipFile(tmp_cbz, 'w', zipfile.ZIP_DEFLATED) as zf:
                    for root, _, files in os.walk(source_dir):
                        for f in sorted(files):
                            if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.gif', '.xml')):
                                abs_f = os.path.join(root, f)
                                arcname = os.path.relpath(abs_f, source_dir)
                                zf.write(abs_f, arcname)
                os.rename(tmp_cbz, dest_cbz)
                shutil.rmtree(source_dir)
                self.stats["created_cbz"] += 1
                return True
            except Exception as e:
                self.log("❌", f"Erreur création CBZ {dest_cbz}: {e}")
                if os.path.exists(dest_cbz + ".tmp"):
                    os.remove(dest_cbz + ".tmp")
                self.stats["errors"] += 1
                return False
        else:
            self.stats["created_cbz"] += 1
            return True

    def clean_junk_files(self):
        self.log("🧹", "Recherche et suppression des fichiers résiduels (.nfo isolés, txt de téléchargement, Thumbs.db)...")
        for root, dirs, files in os.walk(self.base_dir, topdown=False):
            for f in files:
                lower = f.lower()
                fp = os.path.join(root, f)
                if lower in ['uploaded_from_alldebrid.txt', 'thumbs.db', '.ds_store', 'desktop.ini']:
                    self.safe_delete_file(fp)

    def remove_empty_dirs(self):
        for root, dirs, files in os.walk(self.base_dir, topdown=False):
            for d in dirs:
                dp = os.path.join(root, d)
                try:
                    if os.path.exists(dp) and not os.listdir(dp):
                        self.log("📂", f"Suppression sous-dossier vide : {dp}")
                        if not self.dry_run:
                            os.rmdir(dp)
                except Exception:
                    pass

    def run(self):
        bd_dir = os.path.join(self.base_dir, "BD")
        manga_dir = os.path.join(self.base_dir, "Manga")
        livres_dir = os.path.join(self.base_dir, "Livres")
        comics_dir = os.path.join(self.base_dir, "Comics")

        # 0. Normaliser 'comics' en 'Comics'
        old_comics_dir = os.path.join(self.base_dir, "comics")
        if os.path.exists(old_comics_dir) and not os.path.exists(comics_dir):
            self.safe_rename(old_comics_dir, comics_dir)
        elif not os.path.exists(comics_dir):
            if not self.dry_run:
                os.makedirs(comics_dir, exist_ok=True)

        # 1. NETTOYAGE & REORGANISATION BD
        self.log("\n📁", "=== Étape 1 : Réorganisation BD ===")
        # Supprimer Weapons (film égaré)
        weapons = os.path.join(bd_dir, "Weapons.2025.MULTI.VF2.1080p.WEBRip.EAC3.5.1.x265-aq")
        if os.path.exists(weapons):
            self.safe_delete_tree(weapons)

        # Déplacer les Comics égarés dans BD vers Comics
        self.safe_move(os.path.join(bd_dir, "Cyberpunk 2077"), os.path.join(comics_dir, "Cyberpunk 2077"))
        self.safe_move(os.path.join(bd_dir, "Injustice Gods Among Us Year I a V - FR - cbz - Mykeysnotyours"), os.path.join(comics_dir, "Injustice"))
        self.safe_move(os.path.join(bd_dir, "invicible 1-18"), os.path.join(comics_dir, "Invincible"))
        self.safe_move(os.path.join(bd_dir, "Red Son.cbz"), os.path.join(comics_dir, "Superman", "Superman - Red Son.cbz"))
        self.safe_move(os.path.join(bd_dir, "V pour Vendetta (Alan Moore) [Intégrale].cbr"), os.path.join(comics_dir, "V pour Vendetta", "V pour Vendetta (Intégrale).cbr"))
        self.safe_move(os.path.join(bd_dir, "Warhammer"), os.path.join(comics_dir, "Warhammer 40k", "Forge of War"))

        # Déplacer Manga égaré dans BD vers Manga
        planetes_src = os.path.join(bd_dir, "Planetes")
        planetes_dst = os.path.join(manga_dir, "Planetes")
        if os.path.exists(planetes_src):
            self.safe_move(planetes_src, planetes_dst)

        # Renommer les dossiers de séries BD
        self.safe_rename(
            os.path.join(bd_dir, "Conquetes.Soleil.Productions.[INTEGRALE].2018.FR.[PDF]-Folkscanomy"),
            os.path.join(bd_dir, "Conquêtes")
        )
        self.safe_rename(
            os.path.join(bd_dir, "Les.Mondes.D.Aldebaran.Leo.[COLLECTION].FR.[Cbz]-Atro"),
            os.path.join(bd_dir, "Les Mondes d'Aldébaran")
        )
        self.safe_rename(
            os.path.join(bd_dir, "Orbital.[T1-9+HS].FR.[CBZ]-NOTAG"),
            os.path.join(bd_dir, "Orbital")
        )
        self.safe_rename(
            os.path.join(bd_dir, "Renaissance.T01.Les.Deracines.Duval.Emem.2018.FR.[CBZ]-PRiNTER"),
            os.path.join(bd_dir, "Renaissance")
        )
        self.safe_rename(
            os.path.join(bd_dir, "[BD] - XIII"),
            os.path.join(bd_dir, "XIII")
        )
        self.safe_rename(
            os.path.join(bd_dir, "La guerre eternelle"),
            os.path.join(bd_dir, "La Guerre Éternelle")
        )
        self.safe_rename(
            os.path.join(bd_dir, "Les Naufrages d'Ythaq"),
            os.path.join(bd_dir, "Les Naufragés d'Ythaq")
        )

        # Harmoniser Sillage
        sillage_cbz_src = os.path.join(bd_dir, "Sillage (33 Tomes) FR CBZ")
        sillage_main = os.path.join(bd_dir, "Sillage")
        monde_sillage = os.path.join(bd_dir, "Monde de Sillage")
        if os.path.exists(sillage_cbz_src):
            self.safe_rename(sillage_cbz_src, sillage_main)

        # Renommer fichiers dans Conquêtes
        cq_dir = os.path.join(bd_dir, "Conquêtes")
        if os.path.exists(cq_dir):
            for f in os.listdir(cq_dir):
                m = re.match(r'Conquetes---T(\d+)\.pdf', f, re.IGNORECASE)
                if m:
                    num = int(m.group(1))
                    new_f = f"Conquêtes - T{num:02d}.pdf"
                    self.safe_rename(os.path.join(cq_dir, f), os.path.join(cq_dir, new_f))

        # 2. NETTOYAGE & REORGANISATION COMICS
        self.log("\n📁", "=== Étape 2 : Réorganisation Comics ===")
        # Batman
        batman_dir = os.path.join(comics_dir, "Batman")
        self.safe_move(os.path.join(comics_dir, "Batman - Cataclysme - Urban Comics .cbr"), os.path.join(batman_dir, "Batman - Cataclysme.cbr"))
        self.safe_move(os.path.join(comics_dir, "Batman No Man's Land - CBR"), os.path.join(batman_dir, "No Man's Land"))
        
        nml_dir = os.path.join(batman_dir, "No Man's Land")
        if os.path.exists(nml_dir):
            for f in os.listdir(nml_dir):
                m = re.search(r'Tome\s*(\d+)', f, re.IGNORECASE)
                if m:
                    num = int(m.group(1))
                    ext = os.path.splitext(f)[1]
                    new_f = f"Batman - No Man's Land - T{num:02d}{ext}"
                    self.safe_rename(os.path.join(nml_dir, f), os.path.join(nml_dir, new_f))

        # Superman
        superman_dir = os.path.join(comics_dir, "Superman")
        self.safe_move(os.path.join(comics_dir, "La Mort de Superman.cbr"), os.path.join(superman_dir, "Superman - La Mort de Superman.cbr"))

        # Invincible
        invincible_dir = os.path.join(comics_dir, "Invincible")
        if os.path.exists(invincible_dir):
            for item in list(os.listdir(invincible_dir)):
                ip = os.path.join(invincible_dir, item)
                if os.path.isdir(ip):
                    # Sous-dossiers T17 / T18
                    for sf in os.listdir(ip):
                        if sf.lower().endswith(('.cbz', '.cbr', '.pdf')):
                            self.safe_move(os.path.join(ip, sf), os.path.join(invincible_dir, sf))
                    self.safe_delete_tree(ip)

            # Normaliser noms de fichiers Invincible
            for f in os.listdir(invincible_dir):
                fp = os.path.join(invincible_dir, f)
                if not os.path.isfile(fp):
                    continue
                ext = os.path.splitext(f)[1]
                # Match patterns
                m = re.search(r'(?:Invincible|Tome|T|v)[\s._\-]*(\d+)', f, re.IGNORECASE)
                if m:
                    num = int(m.group(1))
                    # Chercher titre optionnel
                    title_match = re.search(r'-\s*\d+\s*-\s*([^-\(\[\.]+)', f)
                    if title_match and len(title_match.group(1).strip()) > 2:
                        title = title_match.group(1).strip()
                        new_f = f"Invincible - T{num:02d} - {title}{ext}"
                    else:
                        new_f = f"Invincible - T{num:02d}{ext}"
                    self.safe_rename(fp, os.path.join(invincible_dir, new_f))

        # Warhammer 40k
        wh_dir = os.path.join(comics_dir, "Warhammer 40k")
        if not os.path.exists(wh_dir) and os.path.exists(os.path.join(comics_dir, "warhammer 40k")):
            self.safe_rename(os.path.join(comics_dir, "warhammer 40k"), wh_dir)

        if os.path.exists(wh_dir):
            for item in list(os.listdir(wh_dir)):
                ip = os.path.join(wh_dir, item)
                if os.path.isdir(ip) and item not in ["Forge of War"]:
                    cbz_path = os.path.join(wh_dir, f"{item}.cbz")
                    self.create_cbz_from_dir(ip, cbz_path)

        # 3. NETTOYAGE & REORGANISATION MANGA
        self.log("\n📁", "=== Étape 3 : Réorganisation Manga ===")
        # Alice on Border Road
        aobr_dir = os.path.join(manga_dir, "Alice on Border Road")
        for f in os.listdir(manga_dir):
            fp = os.path.join(manga_dir, f)
            if os.path.isfile(fp) and "alice on border road" in f.lower():
                ext = os.path.splitext(f)[1]
                m = re.search(r'(?:Volume|T|Road)[\s._\-]*(\d+)', f, re.IGNORECASE)
                if m:
                    num = int(m.group(1))
                    new_f = f"Alice on Border Road - T{num:02d}{ext}"
                    self.safe_move(fp, os.path.join(aobr_dir, new_f))

        # Alice in Borderland
        aib_old = os.path.join(manga_dir, "alice in borderland")
        aib_new = os.path.join(manga_dir, "Alice in Borderland")
        if os.path.exists(aib_old):
            self.safe_rename(aib_old, aib_new)

        # Planetes : Convertir les 4 dossiers d'images en CBZ
        planetes_dir = os.path.join(manga_dir, "Planetes")
        if os.path.exists(planetes_dir):
            for i in range(1, 5):
                tome_d = os.path.join(planetes_dir, f"Planetes tome {i}")
                if os.path.exists(tome_d):
                    cbz_dest = os.path.join(planetes_dir, f"Planetes - T{i:02d}.cbz")
                    self.create_cbz_from_dir(tome_d, cbz_dest)

        # Battle Royale : Archiver en CBZ
        br_dir = os.path.join(manga_dir, "Battle Royale")
        if os.path.exists(br_dir):
            for item in list(os.listdir(br_dir)):
                ip = os.path.join(br_dir, item)
                m = re.search(r'Tome\s*(\d+)', item, re.IGNORECASE)
                if os.path.isdir(ip) and m and item != "Format iPad":
                    num = int(m.group(1))
                    cbz_dest = os.path.join(br_dir, f"Battle Royale - T{num:02d}.cbz")
                    self.create_cbz_from_dir(ip, cbz_dest)
            # Renommer Format iPad en Format EPUB
            ipad_dir = os.path.join(br_dir, "Format iPad")
            if os.path.exists(ipad_dir):
                self.safe_rename(ipad_dir, os.path.join(br_dir, "Format EPUB"))

        # Renommer dossiers Manga
        self.safe_rename(
            os.path.join(manga_dir, "Btooom! 1 à 22 FR CBR [Scantrad + ScanManga]"),
            os.path.join(manga_dir, "Btooom!")
        )
        self.safe_rename(
            os.path.join(manga_dir, "Deadman Wonderland Volumes 1 à 13 PACK.INTEGRAL"),
            os.path.join(manga_dir, "Deadman Wonderland")
        )
        self.safe_rename(
            os.path.join(manga_dir, "Dédale [Intégrale 2 tomes] [CBR FR] [Scan SP]"),
            os.path.join(manga_dir, "Dédale")
        )
        self.safe_rename(
            os.path.join(manga_dir, "Hunter X Hunter Scans"),
            os.path.join(manga_dir, "Hunter x Hunter")
        )
        self.safe_rename(
            os.path.join(manga_dir, "Sousou no Frieren T01 à 6 +Ch.65 à 79 [Kanehito - Tsukasa] [Scantrad KSS et Blue Solo SP FR CBZ]"),
            os.path.join(manga_dir, "Frieren")
        )

        # Nettoyer Neun (supprimer les dossiers vides NeuN_02 et NeuN_03)
        neun_dir = os.path.join(manga_dir, "Neun")
        if os.path.exists(neun_dir):
            for d in ["NeuN_02", "NeuN_03"]:
                dp = os.path.join(neun_dir, d)
                if os.path.isdir(dp):
                    self.safe_delete_tree(dp)

        # 4. NETTOYAGE & REORGANISATION LIVRES
        self.log("\n📁", "=== Étape 4 : Réorganisation Livres ===")
        # Supprimer dossier vide Magic
        magic_dir = os.path.join(livres_dir, "Magic")
        if os.path.exists(magic_dir):
            self.safe_delete_tree(magic_dir)

        # Auteurs & Séries
        self.safe_rename(os.path.join(livres_dir, "Asimov,Isaac"), os.path.join(livres_dir, "Isaac Asimov", "Cycle de Fondation"))
        self.safe_rename(os.path.join(livres_dir, "dune"), os.path.join(livres_dir, "Frank Herbert", "Dune"))
        self.safe_rename(os.path.join(livres_dir, "Dmitry Glukhovsky"), os.path.join(livres_dir, "Dmitry Glukhovsky", "Metro"))
        self.safe_rename(os.path.join(livres_dir, "Red Queen (4 tomes) - Victoria Aveyard"), os.path.join(livres_dir, "Victoria Aveyard", "Red Queen"))
        self.safe_rename(os.path.join(livres_dir, "Suzanne Collins"), os.path.join(livres_dir, "Suzanne Collins", "Hunger Games"))
        self.safe_rename(os.path.join(livres_dir, "The Witcher"), os.path.join(livres_dir, "Andrzej Sapkowski", "Le Sorceleur (The Witcher)"))
        self.safe_rename(os.path.join(livres_dir, "Coraline"), os.path.join(livres_dir, "Neil Gaiman", "Coraline"))

        # Peter Watts (fichiers vrac)
        pw_dir = os.path.join(livres_dir, "Peter Watts")
        for f in os.listdir(livres_dir):
            fp = os.path.join(livres_dir, f)
            if os.path.isfile(fp) and ("peter watts" in f.lower() or "peter-watts" in f.lower()):
                self.safe_move(fp, os.path.join(pw_dir, f))

        # Cuisine
        cuisine_f = os.path.join(livres_dir, "Super nickel - Les meilleures recettes de la table 55.epub")
        if os.path.exists(cuisine_f):
            self.safe_move(cuisine_f, os.path.join(livres_dir, "Cuisine", "Super nickel - Les meilleures recettes de la table 55.epub"))

        # LDVELH : Aplatir l'arborescence triple
        ldvelh_root = os.path.join(livres_dir, "LDVELH - Livres dont vous êtes le héros - DéfisFantastiques Histoire LoupSolitaire QuêteDuGraal")
        ldvelh_dest = os.path.join(livres_dir, "LDVELH")
        if os.path.exists(ldvelh_root):
            sub1 = os.path.join(ldvelh_root, "LDVELH - Livres dont vous êtes le héros - DéfisFantastiques_Histoire_LoupSolitaire_QuêteDuGraal")
            if os.path.exists(sub1):
                for cat in ["Défis Fantastiques", "Histoire", "Loup solitaire", "Quête du Graal"]:
                    cp = os.path.join(sub1, cat)
                    if os.path.exists(cp):
                        self.safe_move(cp, os.path.join(ldvelh_dest, cat))
            self.safe_delete_tree(ldvelh_root)

        # 5. NETTOYAGE FINAL
        self.clean_junk_files()
        self.remove_empty_dirs()

        self.log("\n🏁", "=== BILAN DES OPÉRATIONS ===")
        for k, v in self.stats.items():
            print(f"  • {k}: {v}")

if __name__ == "__main__":
    args = parse_args()
    organizer = LibraryOrganizer(BOOKS_DIR, dry_run=args.dry_run)
    organizer.run()
