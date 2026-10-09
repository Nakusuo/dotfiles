#!/usr/bin/env python3
"""Convierte cualquier imagen en un fondo cyberpunk 2000 / Fallen Angels:
cámara de visión nocturna verde, VHS (colores corridos, grano, scanlines)
y la pantalla de videocámara («Standard NVG», REC en rojo).

Uso: fondo-y2k.py imagen salida.png [--ascii] [--errores] [--sin-osd] [--tam 1366x768]
  --ascii    la imagen hecha de caracteres verdes sobre código (retrato hacker)
  --errores  ventanas de error tipo Windows 98, una roja con 警告
  --sin-osd  sin los textos de videocámara
Necesita Pillow (python-pillow). Para el 警告, una fuente japonesa (noto-fonts-cjk)."""
import math, os, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps, ImageChops

args = [a for a in sys.argv[1:] if not a.startswith("--")]
opciones = [a for a in sys.argv[1:] if a.startswith("--")]
if len(args) < 2:
    sys.exit(__doc__)
W, H = 1366, 768
if "--tam" in sys.argv:
    W, H = map(int, sys.argv[sys.argv.index("--tam") + 1].split("x"))
    args = [a for a in args if a != f"{W}x{H}"]
S = 2
w, h = W * S, H * S
random.seed(2000)

NEGRO  = (3, 9, 4)
VERDE  = (110, 200, 70)
LIMA   = (182, 240, 106)   # el verde del OSD (#b6f06a)
BLANCO = (228, 255, 196)
ROJO   = (208, 50, 40)
TITULO_A, TITULO_B = (47, 107, 78), (95, 168, 160)
ROJO_A = (107, 26, 31)
BISEL_C, BISEL_O = (143, 211, 174), (5, 8, 6)

def fuente(nombres, tam):
    """La primera fuente que exista (Linux y Windows)."""
    for n in nombres:
        for d in ("/usr/share/fonts", os.path.expanduser("~/.local/share/fonts"), "C:/Windows/Fonts"):
            if not os.path.isdir(d):
                continue
            for raiz, _, archivos in os.walk(d):
                if n in archivos:
                    return ImageFont.truetype(os.path.join(raiz, n), tam)
    return ImageFont.load_default(tam)

MONO  = ["JetBrainsMonoNerdFont-Regular.ttf", "JetBrainsMono-Regular.ttf", "DejaVuSansMono.ttf", "consola.ttf"]
MONOB = ["JetBrainsMonoNerdFont-Bold.ttf", "JetBrainsMono-Bold.ttf", "DejaVuSansMono-Bold.ttf", "consolab.ttf"]
SANSB = ["LiberationSans-Bold.ttf", "DejaVuSans-Bold.ttf", "arialbd.ttf"]
JAPO  = ["NotoSansCJK-Bold.ttc", "NotoSansCJKjp-Bold.otf", "YuGothB.ttc", "msgothic.ttc"]

def capa():
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

# ---------- la imagen en visión nocturna ----------
foto = ImageOps.fit(Image.open(args[0]).convert("RGB"), (w, h), Image.LANCZOS, centering=(0.5, 0.4))
gris = ImageOps.autocontrast(foto.convert("L"), cutoff=1)

if "--ascii" in opciones:
    # fondo de código tenue y la imagen hecha de caracteres
    img = Image.new("RGB", (w, h), NEGRO)
    d = ImageDraw.Draw(img)
    fc = fuente(MONO, 11 * S)
    codigo = ["struct vm86_kernel *vm86;", "unsigned long addr;", "if (curpcb->pcb_ext == 0)",
              "    return (SIGBUS);", "vm86->vm86_eflags &= ~PSL_VIP;", "/* segment descriptor */",
              "int retcode = SIGTRAP;", "addr = MAKE_ADDR(vmf->vmf_cs);", "i_byte = fubyte(addr);",
              "#define PCB_EXT_SIZE 0x1000", "} else if (inc_ip > 0) {", "return (retcode);"]
    for y in range(0, h, 15 * S):
        d.text((random.randint(-40, 10) * S, y), "   ".join(random.sample(codigo, 4)), font=fc, fill=(14, 40, 18))
    celda = 7 * S
    peq = gris.resize((w // celda, h // celda))
    fa = fuente(MONOB, 9 * S)
    chars = " .:-=+*#%@"
    for cy in range(peq.height):
        for cx in range(peq.width):
            v = peq.getpixel((cx, cy)) / 255
            if v < 0.12:
                continue
            col = tuple(int(VERDE[k] + (BLANCO[k] - VERDE[k]) * v ** 2) for k in range(3))
            d.text((cx * celda, cy * celda), chars[min(len(chars) - 1, int(v * len(chars)))], font=fa, fill=col)
else:
    img = ImageOps.colorize(gris, black=NEGRO, mid=VERDE, white=BLANCO)
    img = Image.blend(img, foto, 0.12)

# bloom: lo claro brilla
halo = img.filter(ImageFilter.GaussianBlur(14 * S))
img = ImageChops.screen(img, Image.blend(Image.new("RGB", img.size), halo, 0.45))

# VHS: rojo y azul corridos
r, g, b = img.split()
r = ImageChops.offset(r, 3 * S, 0); b = ImageChops.offset(b, -3 * S, 0)
img = Image.merge("RGB", (r, g, b)).convert("RGBA")

# ---------- ventanas de error Windows 98 ----------
def ventana(x, y, ancho, alto, titulo, mensaje, roja=False, icono="!"):
    v = capa(); d = ImageDraw.Draw(v)
    d.rectangle([x, y, x + ancho, y + alto], fill=(10, 18, 13, 235))
    d.rectangle([x, y, x + ancho, y + 2 * S], fill=(*BISEL_C, 220))
    d.rectangle([x, y, x + 2 * S, y + alto], fill=(*BISEL_C, 220))
    d.rectangle([x, y + alto - 2 * S, x + ancho, y + alto], fill=(*BISEL_O, 255))
    d.rectangle([x + ancho - 2 * S, y, x + ancho, y + alto], fill=(*BISEL_O, 255))
    a, bb = (ROJO_A, ROJO) if roja else (TITULO_A, TITULO_B)
    tx0, ty0, tx1, ty1 = x + 4 * S, y + 4 * S, x + ancho - 4 * S, y + 22 * S
    for i in range(tx1 - tx0):
        f = i / (tx1 - tx0)
        d.line([(tx0 + i, ty0), (tx0 + i, ty1)], fill=tuple(int(a[k] + (bb[k] - a[k]) * f) for k in range(3)) + (255,))
    ft = fuente(JAPO, 12 * S) if any(ord(c) > 0x3000 for c in titulo) else fuente(SANSB, 11 * S)
    d.text((tx0 + 5 * S, ty0 + 2 * S), titulo, font=ft, fill=(255, 255, 255, 255))
    for j, s in enumerate(["×", "□", "_"]):
        bx = tx1 - (j + 1) * 18 * S
        d.rectangle([bx, ty0 + 2 * S, bx + 15 * S, ty1 - 2 * S], fill=(58, 74, 65, 255), outline=(*BISEL_C, 255), width=S)
        d.text((bx + 4 * S, ty0 + 1 * S), s, font=fuente(SANSB, 11 * S), fill=(230, 240, 232, 255))
    cx, cy = x + 26 * S, y + 22 * S + (alto - 22 * S) / 2
    col = ROJO if roja else (212, 181, 106)
    d.ellipse([cx - 13 * S, cy - 13 * S, cx + 13 * S, cy + 13 * S], fill=(*col, 255), outline=(255, 255, 255, 255), width=2 * S)
    fi = fuente(SANSB, 16 * S)
    d.text((cx - d.textlength(icono, font=fi) / 2, cy - 11 * S), icono, font=fi, fill=(255, 255, 255, 255))
    d.multiline_text((x + 50 * S, cy - 13 * S), mensaje, font=fuente(MONO, 10 * S), fill=(207, 220, 212, 255), spacing=3 * S)
    sombra = capa(); ImageDraw.Draw(sombra).rectangle([x + 6 * S, y + 6 * S, x + ancho + 6 * S, y + alto + 6 * S], fill=(0, 0, 0, 120))
    return Image.alpha_composite(sombra.filter(ImageFilter.GaussianBlur(4 * S)), v)

if "--errores" in opciones:
    img = Image.alpha_composite(img, ventana(w - 320 * S, 90 * S, 250 * S, 80 * S, "System Error", "Unknown device on\nport COM2."))
    img = Image.alpha_composite(img, ventana(w - 290 * S, 150 * S, 250 * S, 80 * S, "System Error", "Connection lost.\nRetrying..."))
    img = Image.alpha_composite(img, ventana(w - 350 * S, h - 290 * S, 280 * S, 92 * S, "警告  WARNING", "Signal integrity\ncompromised.", roja=True, icono="×"))

# ---------- CRT y grano ----------
c = capa(); d = ImageDraw.Draw(c)
for y in range(0, h, 3 * S):
    d.line([(0, y), (w, y)], fill=(0, 0, 0, 55), width=S)
img = Image.alpha_composite(img, c)
ruido = Image.effect_noise((w, h), 60).convert("RGBA"); ruido.putalpha(26)
img = Image.alpha_composite(img, ruido)
vin = Image.radial_gradient("L").resize((w, h)).point(lambda v: int(min(220, max(0, (v - 110) * 1.4))))
negro = Image.new("RGBA", (w, h), (0, 0, 0, 255)); negro.putalpha(vin)
img = Image.alpha_composite(img, negro)

# ---------- pantalla de videocámara ----------
if "--sin-osd" not in opciones:
    o = capa(); d = ImageDraw.Draw(o)
    f16, f28, f13 = fuente(MONO, 16 * S), fuente(MONO, 28 * S), fuente(MONO, 13 * S)
    fb22, fb30, fb16 = fuente(MONOB, 22 * S), fuente(MONOB, 30 * S), fuente(MONOB, 16 * S)
    m = 28 * S
    d.text((m, 18 * S), "Standard NVG", font=f16, fill=(*LIMA, 255))
    d.text((m, 38 * S), "40° FOV", font=f28, fill=(*LIMA, 255))
    # ALT en rojo y la i en círculo
    ax = w - m - 30 * S
    d.ellipse([ax, 22 * S, ax + 30 * S, 52 * S], outline=(*LIMA, 255), width=2 * S)
    d.text((ax + 11 * S, 25 * S), "i", font=fb22, fill=(*LIMA, 255))
    aw = d.textlength("ALT", font=fb22)
    d.rectangle([ax - 10 * S - aw - 12 * S, 22 * S, ax - 10 * S, 52 * S], fill=(*ROJO, 255))
    d.text((ax - 10 * S - aw - 6 * S, 23 * S), "ALT", font=fb22, fill=(16, 16, 16, 255))
    # ZOOM
    zw = d.textlength("ZOOM", font=f13)
    d.rectangle([m, h - 26 * S - 22 * S, m + zw + 10 * S, h - 26 * S], outline=(*LIMA, 255), width=2 * S)
    d.text((m + 5 * S, h - 26 * S - 20 * S), "ZOOM", font=f13, fill=(*LIMA, 255))
    # REC y contador
    tc = "00:05:37"; tw = d.textlength(tc, font=fb30); rw = d.textlength("● REC", font=fb16)
    x0 = (w - tw - rw - 12 * S) / 2
    d.text((x0, h - 20 * S - 30 * S), "● REC", font=fb16, fill=(*ROJO, 255))
    d.text((x0 + rw + 12 * S, h - 20 * S - 40 * S), tc, font=fb30, fill=(*ROJO, 255))
    d.text((w - m - d.textlength("((•))", font=f16), h - 24 * S - 22 * S), "((•))", font=f16, fill=(*LIMA, 255))
    img = Image.alpha_composite(img, o)

img.convert("RGB").resize((W, H), Image.LANCZOS).save(args[1], optimize=True)
print("Listo:", args[1])
