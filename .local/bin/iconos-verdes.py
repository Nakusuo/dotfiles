#!/usr/bin/env python3
"""Crea el tema de iconos "BeautyLine Verde": BeautyLine (iconos de líneas) recoloreado con la paleta Verde Tech.
Uso: iconos-verdes.py   (necesita git; instala en ~/.local/share/icons/BeautyLine-Verde)
"""
import colorsys, os, re, shutil, subprocess, tempfile

URL = 'https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline.git'
dst = os.path.expanduser('~/.local/share/icons/BeautyLine-Verde')
tmp = tempfile.mkdtemp()
subprocess.run(['git', 'clone', '-q', '--depth', '1', URL, tmp + '/bl'], check=True)
if os.path.exists(dst):
    shutil.rmtree(dst)
shutil.copytree(tmp + '/bl', dst, symlinks=True,
                ignore=shutil.ignore_patterns('.git*', '*.md', 'AUTHORS', 'COPYING'))
shutil.rmtree(tmp)

hexre = re.compile(r'#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b')
cache = {}

def verde(m):
    h = m.group(1).lower()
    if len(h) == 3:
        h = ''.join(c * 2 for c in h)
    if h not in cache:
        r, g, b = (int(h[i:i + 2], 16) / 255 for i in range(0, 6, 2))
        hh, l, s = colorsys.rgb_to_hls(r, g, b)
        if s < 0.08:  # grises, blanco y negro: quedan neutros con un toque verde
            out = colorsys.hls_to_rgb(150 / 360, l, s)
        else:  # tono entre verde (150°) y verde azulado (172°) para que los degradados se sigan viendo
            out = colorsys.hls_to_rgb((150 + 22 * hh) / 360, 0.42 + 0.38 * l, 0.42)
        cache[h] = '#' + ''.join(f'{round(c * 255):02x}' for c in out)
    return cache[h]

for root, _, files in os.walk(dst):
    for f in files:
        p = os.path.join(root, f)
        if f.endswith('.svg') and not os.path.islink(p):
            s = open(p, encoding='utf-8', errors='ignore').read()
            t = hexre.sub(verde, s)
            if t != s:
                open(p, 'w', encoding='utf-8').write(t)

idx = os.path.join(dst, 'index.theme')
s = open(idx).read()
s = re.sub(r'^Name=.*$', 'Name=BeautyLine Verde', s, flags=re.M)
s = re.sub(r'^Inherits=.*$', 'Inherits=Colloid-Green-Everforest-Dark,breeze-dark,hicolor', s, flags=re.M)
open(idx, 'w').write(s)
print('Listo. Aplícalo con: /usr/lib/plasma-changeicons BeautyLine-Verde')
