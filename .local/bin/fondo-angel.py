#!/usr/bin/env python3
"""Dibuja desde cero la imagen base del fondo «Fallen Angels»: una silueta de
perfil con el pelo al viento, iluminada por detrás, sigilos tribales con
destellos. Sale en grises: después se le aplica fondo-y2k.py.

Uso: fondo-angel.py salida.png [--tam 1366x768] [--semilla N]"""
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

if len(sys.argv) < 2:
    sys.exit(__doc__)
W, H = 1366, 768
if "--tam" in sys.argv:
    W, H = map(int, sys.argv[sys.argv.index("--tam") + 1].split("x"))
semilla = int(sys.argv[sys.argv.index("--semilla") + 1]) if "--semilla" in sys.argv else 95
random.seed(semilla)
S = 2
w, h = W * S, H * S

def catmull(pts, pasos=14):
    """Curva suave que pasa por todos los puntos."""
    out = []
    for i in range(len(pts) - 1):
        p0 = pts[max(i - 1, 0)]; p1 = pts[i]; p2 = pts[i + 1]; p3 = pts[min(i + 2, len(pts) - 1)]
        for k in range(pasos):
            t = k / pasos; t2 = t * t; t3 = t2 * t
            out.append(tuple(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2
                                    + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3) for j in range(2)))
    out.append(pts[-1])
    return out

# coordenadas en una caja de 1000x1000 que se escala a la altura de la pantalla
esc = h / 1000
ox = w * 0.40 - 520 * esc   # la cabeza un poco a la izquierda del centro
def P(x, y):
    return (ox + x * esc, y * esc)

# ---------- perfil mirando a la izquierda ----------
frente = [(520, 120), (455, 150), (410, 215), (392, 290), (386, 340), (372, 368), (338, 425), (352, 440),
          (366, 446), (360, 468), (350, 482), (366, 494), (360, 512), (366, 540), (384, 568), (420, 588),
          (470, 592), (488, 640), (482, 720), (430, 830), (300, 1000)]
nuca = [(520, 120), (610, 125), (690, 180), (730, 270), (735, 380), (712, 480), (690, 560), (700, 680),
        (760, 820), (900, 1000)]
contorno = [P(*p) for p in catmull(frente)] + [P(*p) for p in reversed(catmull(nuca))]

mascara = Image.new("L", (w, h), 0)
ImageDraw.Draw(mascara).polygon(contorno, fill=255)

# ---------- fondo: casi negro, con una luz difusa detrás de la cabeza ----------
img = Image.new("L", (w, h), 6)
luz = Image.new("L", (w, h), 0)
cx, cy = P(640, 330)
ImageDraw.Draw(luz).ellipse([cx - 260 * esc, cy - 260 * esc, cx + 260 * esc, cy + 260 * esc], fill=120)
img = ImageChops.add(img, luz.filter(ImageFilter.GaussianBlur(150 * esc)))

# la silueta: oscura, con un leve relleno para que se lea la cara
cuerpo = Image.new("L", (w, h), 22)
img = Image.composite(cuerpo, img, mascara)

# ---------- luz de contorno (contraluz): fuerte en la nuca, suave en la cara ----------
borde = ImageChops.subtract(mascara, mascara.filter(ImageFilter.MinFilter(9)))
foco = Image.new("L", (w, h), 0)
fx, fy = P(700, 260)
ImageDraw.Draw(foco).ellipse([fx - 520 * esc, fy - 520 * esc, fx + 520 * esc, fy + 520 * esc], fill=255)
foco = ImageChops.add(foco.filter(ImageFilter.GaussianBlur(220 * esc)), Image.new("L", (w, h), 40))
borde = ImageChops.multiply(borde, foco)
img = ImageChops.screen(img, borde.filter(ImageFilter.GaussianBlur(2 * S)))
img = ImageChops.screen(img, borde.filter(ImageFilter.GaussianBlur(16 * S)).point(lambda v: v * 0.8))

# ---------- pelo ----------
def bezier(p0, p1, p2, p3, n=48):
    return [tuple((1 - t) ** 3 * p0[j] + 3 * (1 - t) ** 2 * t * p1[j] + 3 * (1 - t) * t * t * p2[j] + t ** 3 * p3[j]
                  for j in range(2)) for t in (k / (n - 1) for k in range(n))]

pelo = Image.new("L", (w, h), 0); d = ImageDraw.Draw(pelo)
def mechon(pts, brillo):
    d.line([P(*q) for q in pts], fill=brillo, width=random.choice([1, 1, 2, 2, 3]))

coronilla = catmull([(440, 175), (500, 128), (580, 120), (660, 150), (715, 220), (735, 320)], 20)
for _ in range(260):   # sobre la cabeza: de la frente hacia atrás, pegado al cráneo
    i = random.randrange(len(coronilla) // 2)
    x0, y0 = coronilla[i]
    x1, y1 = coronilla[min(len(coronilla) - 1, i + random.randint(8, 40))]
    mechon(bezier((x0, y0 + 4), (x0 + 60, y0 - 18), (x1 - 10, y1 - 10), (x1 + random.uniform(0, 40), y1 + random.uniform(0, 60))),
           int(random.uniform(60, 200)))
nuca_pelo = catmull([(600, 125), (690, 180), (730, 280), (735, 380), (712, 480)], 20)
for _ in range(320):   # cubre el cráneo: de la línea de la frente hasta la nuca
    x0, y0 = random.choice(coronilla[:len(coronilla) // 3])
    x1, y1 = random.choice(nuca_pelo[len(nuca_pelo) // 3:])
    mechon(bezier((x0, y0 + 6), (x0 + 90, y0 - 30), (x1 + 10, y1 - 140), (x1 + random.uniform(0, 30), y1)),
           int(random.uniform(50, 190)))
for _ in range(300):   # cae por la espalda
    x0, y0 = random.choice(nuca_pelo)
    largo = random.uniform(350, 650)
    mechon(bezier((x0, y0), (x0 + 60, y0 + largo * 0.3), (x0 + random.uniform(20, 140), y0 + largo * 0.7),
                  (x0 + random.uniform(40, 260), y0 + largo)), int(random.uniform(70, 230)))
for _ in range(330):   # vuela con el viento hacia la derecha
    x0, y0 = random.choice(nuca_pelo)
    largo = random.uniform(300, 760)
    caida = random.uniform(40, 330)
    mechon(bezier((x0, y0), (x0 + largo * 0.3, y0 + random.uniform(-60, 40)),
                  (x0 + largo * 0.65, y0 + caida * 0.5 + random.uniform(-80, 80)), (x0 + largo, y0 + caida)),
           int(random.uniform(80, 255)))
# las puntas se apagan hacia la derecha
desv = Image.linear_gradient("L").rotate(90, expand=True).resize((w, h)).transpose(Image.FLIP_LEFT_RIGHT)
pelo = ImageChops.multiply(pelo, desv.point(lambda v: min(255, int(v * 1.6))))
img = ImageChops.screen(img, pelo.filter(ImageFilter.GaussianBlur(9 * S)).point(lambda v: min(255, int(v * 1.3))))
img = ImageChops.screen(img, pelo)

# ---------- sigilos tribales: cuerpo afilado lleno de púas curvas, simétrico ----------
def sigilo(cx, cy, tam, giro):
    capa = Image.new("L", (w, h), 0); d = ImageDraw.Draw(capa)
    ca, sa = math.cos(giro), math.sin(giro)
    def T(u, v):   # u a lo largo del sigilo, v de lado
        return (cx + u * ca - v * sa, cy + u * sa + v * ca)
    n = 30
    espina = [(-tam + 2 * tam * k / n, math.sin(k / n * math.pi * 1.5) * tam * 0.12) for k in range(n + 1)]
    grosor = lambda k: tam * 0.07 * math.sin(k / n * math.pi) + 1
    d.polygon([T(u, v + grosor(k)) for k, (u, v) in enumerate(espina)] +
              [T(u, v - grosor(k)) for k, (u, v) in reversed(list(enumerate(espina)))], fill=235)
    for k in range(2, n - 1):
        u, v = espina[k]
        for lado in (-1, 1):
            if random.random() < 0.75:
                largo = tam * random.uniform(0.12, 0.42) * math.sin(k / n * math.pi)
                atras = random.uniform(0.4, 1.0)          # púas inclinadas hacia atrás
                g = grosor(k) * random.uniform(0.6, 1.1)
                base1, base2 = (u - g, v + lado * grosor(k) * 0.5), (u + g, v + lado * grosor(k) * 0.5)
                medio = (u - largo * atras * 0.4, v + lado * largo * 0.6)
                punta = (u - largo * atras, v + lado * largo)
                d.polygon([T(*base1), T(*medio), T(*punta), T(medio[0] + g * 0.7, medio[1]), T(*base2)], fill=235)
    return capa

for (sx, sy, tam, giro) in [(w * 0.84, h * 0.22, 120 * S, -1.05), (w * 0.10, h * 0.72, 105 * S, -2.2)]:
    s = sigilo(sx, sy, tam, giro)
    img = ImageChops.screen(img, s.filter(ImageFilter.GaussianBlur(9 * S)))
    img = ImageChops.screen(img, s.point(lambda v: int(v * 0.85)))

# ---------- destellos ----------
dest = Image.new("L", (w, h), 0); d = ImageDraw.Draw(dest)
for _ in range(6):
    x, y = random.uniform(0.05, 0.95) * w, random.uniform(0.05, 0.9) * h
    r = random.uniform(10, 26) * S
    d.line([(x - r, y), (x + r, y)], fill=255, width=S)
    d.line([(x, y - r), (x, y + r)], fill=255, width=S)
    d.ellipse([x - 2 * S, y - 2 * S, x + 2 * S, y + 2 * S], fill=255)
img = ImageChops.screen(img, dest.filter(ImageFilter.GaussianBlur(3 * S)))
img = ImageChops.screen(img, dest)

img.resize((W, H), Image.LANCZOS).save(sys.argv[1])
print("Listo:", sys.argv[1])
