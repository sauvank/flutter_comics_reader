"""Create a separate Flutter project containing the production UI and demo data."""
from pathlib import Path
import shutil
import sys

repo = Path(__file__).resolve().parents[3]
preview = Path(sys.argv[1] if len(sys.argv) > 1 else '/tmp/comicstream-store')
if preview.resolve() == repo:
    raise ValueError('Use a separate output directory')
preview.mkdir(parents=True, exist_ok=True)
for folder in ['android', 'lib', 'assets']:
    shutil.copytree(repo / folder, preview / folder, dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns('build', '.gradle', '*.jks',
                                                 '*.keystore', 'key.properties'))
for name in ['pubspec.yaml', 'pubspec.lock']:
    shutil.copy2(repo / name, preview / name)
shutil.copy2(Path(__file__).with_name('capture_app.dart'), preview / 'lib/store_main.dart')
gradle = preview / 'android/app/build.gradle'
gradle.write_text(gradle.read_text().replace(
    'applicationId = "com.sauvank.comicstream"',
    'applicationId = "com.sauvank.comicstream.storepreview"'))
manifest = preview / 'android/app/src/main/AndroidManifest.xml'
manifest.write_text(manifest.read_text().replace(
    'android:label="ComicStream"', 'android:label="ComicStream Présentation"').replace(
    'android:name=".MainActivity"', 'android:name="com.sauvank.comicstream.MainActivity"'))
pubspec = preview / 'pubspec.yaml'
pubspec.write_text(pubspec.read_text().replace(
    '  uses-material-design: true',
    '  uses-material-design: true\n  assets:\n    - assets/store/'))
shutil.copytree(repo / 'marketing/play-store/art', preview / 'assets/store', dirs_exist_ok=True)
print(preview)
