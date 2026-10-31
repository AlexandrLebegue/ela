#!/usr/bin/env python3
"""Compose les captures Flutter sans modifier leur contenu.
python3 -m pip install -r tools/screens/requirements.txt
python3 tools/screens/contact_sheet.py
"""
from pathlib import Path
import textwrap
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SCREENS = ROOT / 'docs/screens'
FONT = ROOT / 'assets/fonts'
LABELS = {
    '05-tendance': 'Tendance', '08-recherche': 'Recherche',
    '11-scanner': 'Scanner et ISBN', '13-fiche-presse': 'Fiche de lecture',
    '23-bibliotheque': 'Bibliothèque', '29-premium': 'Édition Premium',
}
TITLE = ImageFont.truetype(str(FONT / 'CormorantGaramond.ttf'), 48)
LABEL = ImageFont.truetype(str(FONT / 'NunitoSans.ttf'), 28)
SMALL = ImageFont.truetype(str(FONT / 'NunitoSans.ttf'), 21)
PAD, GAP, CELL, IMAGE_H, CAPTION, HEADER = 24, 24, 388, 862, 106, 142
WIDTH = PAD * 2 + GAP + CELL * 2

def compose(items, title, subtitle, destination, night=False):
    bg = '#19262c' if night else '#f8f4eb'
    fg = '#f2e9d8' if night else '#302c27'
    muted = '#c1b7a5' if night else '#6c6257'
    rows = (len(items) + 1) // 2
    canvas = Image.new('RGB', (WIDTH, HEADER + rows * (IMAGE_H + CAPTION) + PAD), bg)
    draw = ImageDraw.Draw(canvas)
    draw.text((PAD, 18), title, font=TITLE, fill=fg)
    draw.text((PAD, 83), subtitle, font=SMALL, fill=muted)
    draw.line((PAD, 122, WIDTH-PAD, 122), fill=muted)
    for i, (path, caption) in enumerate(items):
        x = PAD + (i % 2) * (CELL + GAP)
        y = HEADER + (i // 2) * (IMAGE_H + CAPTION)
        with Image.open(path) as source:
            image = source.convert('RGB')
            image.thumbnail((CELL, IMAGE_H), Image.Resampling.LANCZOS)
            canvas.paste(image, (x + (CELL-image.width)//2, y))
        draw.rectangle((x, y, x+CELL-1, y+IMAGE_H-1), outline=muted)
        for line, text in enumerate(textwrap.wrap(caption, width=25)):
            draw.text((x, y+IMAGE_H+12+line*34), text, font=LABEL, fill=fg)
    canvas.save(destination, optimize=True)

for mode in ('jour', 'nuit'):
    paths = sorted((SCREENS / 'apres' / mode).glob('*.png'))
    if len(paths) != 60:
        raise SystemExit(f'{mode}: 60 captures attendues, {len(paths)} trouvées')
    compose([(p, p.stem.replace('-', ' · ', 1).replace('-', ' ')) for p in paths],
            f'Ela · carnet visuel / {mode}', '60 scènes · 412 × 915 dp · polices embarquées · zoom possible',
            SCREENS / f'planche-{mode}.png', mode == 'nuit')
items = []
for key, label in LABELS.items():
    for state, heading in [('avant', 'Avant'), ('apres', 'Après')]:
        items.append((SCREENS / state / 'jour' / f'{key}.png', f'{heading} · {label}'))
compose(items, 'Ela · avant / après', 'Six parcours · même format téléphone · même catalogue', SCREENS / 'avant-apres.png')
print('Planches jour, nuit et comparaison générées.')
