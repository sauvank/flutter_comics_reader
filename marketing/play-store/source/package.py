"""Validate exported images and package the files for manual Play Console upload."""
from pathlib import Path
import hashlib
import json
import zipfile
from PIL import Image

root = Path(__file__).resolve().parent.parent
files = sorted((root / 'exports').rglob('*.jpg'))
assert len(files) == 11, f'Expected 11 exports, found {len(files)}'
manifest = []
for file in files:
    with Image.open(file) as img:
        expected = ((1024, 500) if file.name == 'feature-graphic.jpg'
                    else (1200, 1920) if file.parent.name == 'tablet'
                    else (1080, 1920))
        assert img.size == expected, (file, img.size)
        assert img.mode == 'RGB' and img.format == 'JPEG', (file, img.mode)
        img.verify()
    manifest.append({
        'file': str(file.relative_to(root)),
        'width': expected[0], 'height': expected[1],
        'bytes': file.stat().st_size,
        'sha256': hashlib.sha256(file.read_bytes()).hexdigest(),
    })
manifest_file = root / 'exports/manifest.json'
manifest_file.write_text(json.dumps(manifest, indent=2) + '\n')
archive = root / 'ComicStream-Google-Play-FR.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as bundle:
    for file in files + [manifest_file, root / 'README.md', root / 'preview.jpg']:
        bundle.write(file, file.relative_to(root))
print(f'Validated {len(files)} RGB images. Archive: {archive} ({archive.stat().st_size:,} bytes)')
