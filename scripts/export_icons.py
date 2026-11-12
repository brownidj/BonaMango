"""Export platform icon sizes from assets/images/icons/bona-mangxo.png using macOS tools."""
from pathlib import Path
import json, subprocess, shutil, struct
root=Path(__file__).resolve().parents[1]
master=root/'assets/images/icons/bona-mangxo.png';master.parent.mkdir(parents=True,exist_ok=True)
def resize(dest,size):
 dest.parent.mkdir(parents=True,exist_ok=True)
 subprocess.run(['sips','-z',str(size),str(size),str(master),'--out',str(dest)],check=True,stdout=subprocess.DEVNULL)
resize(master,1024)
flutter=root/'flutter_app'
resize(flutter/'assets/images/icons/bona-mangxo.png',1024)
# All native Apple sizes are defined by the asset catalog rather than inferred filenames.
for catalogue in [flutter/'ios/Runner/Assets.xcassets/AppIcon.appiconset',flutter/'macos/Runner/Assets.xcassets/AppIcon.appiconset']:
 for entry in json.loads((catalogue/'Contents.json').read_text())['images']:
  if 'filename' in entry:
   size=round(float(entry['size'].split('x')[0])*float(entry['scale'].removesuffix('x')))
   resize(catalogue/entry['filename'],size)
for name,size in [('LaunchImage.png',160),('LaunchImage@2x.png',320),('LaunchImage@3x.png',480)]:
 resize(flutter/'ios/Runner/Assets.xcassets/LaunchImage.imageset'/name,size)
for folder,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
 resize(flutter/f'android/app/src/main/res/mipmap-{folder}/ic_launcher.png',size)
for name,size in [('Icon-192.png',192),('Icon-512.png',512),('Icon-maskable-192.png',192),('Icon-maskable-512.png',512),('apple-touch-icon.png',180)]: resize(flutter/'web/icons'/name,size)
resize(flutter/'web/favicon.png',32)
iconset=root/'assets/images/icons/BonaMangxo.iconset';iconset.mkdir(exist_ok=True)
for size in [16,32,128,256,512]:
 resize(iconset/f'icon_{size}x{size}.png',size)
 resize(iconset/f'icon_{size}x{size}@2x.png',size*2)
subprocess.run(['iconutil','-c','icns',str(iconset),'-o',str(flutter/'assets/bona_mangxo.icns')],check=True)
shutil.rmtree(iconset)
# ICO supports an embedded 256px PNG directly.
small=root/'assets/images/icons/icon-256.png';resize(small,256);data=small.read_bytes()
(flutter/'windows/runner/resources/app_icon.ico').write_bytes(struct.pack('<HHH',0,1,1)+struct.pack('<BBBBHHII',0,0,0,0,1,32,len(data),22)+data)
small.unlink()
print('Exported Flutter, native launcher and launch-screen icons from the project master.')
