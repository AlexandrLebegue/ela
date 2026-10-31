"""Planches des captures Flutter, sans retouche du contenu de l'interface."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SCREENS = ROOT / 'docs/screens/tendance'
FONT = str(ROOT / 'assets/fonts/NunitoSans.ttf')
PAPER = '#f4efe4'
INK = '#542a32'


def sheet(cells, columns, width, destination):
    font = ImageFont.truetype(FONT, 20)
    height = round(width * 915 / 412)
    margin, caption = 20, 48
    rows = (len(cells) + columns - 1) // columns
    board = Image.new('RGB', (columns * (width + margin) + margin,
                              rows * (height + caption + margin) + margin), PAPER)
    draw = ImageDraw.Draw(board)
    for i, (label, source) in enumerate(cells):
        x = margin + (i % columns) * (width + margin)
        y = margin + (i // columns) * (height + caption + margin)
        draw.text((x, y + 8), label, font=font, fill=INK)
        with Image.open(SCREENS / source) as original:
            thumbnail = original.convert('RGB').resize((width, height), Image.Resampling.LANCZOS)
            board.paste(thumbnail, (x, y + caption))
    board.save(SCREENS / destination, optimize=True)


sheet([
    ('Avant · jour', 'avant/jour/05-tendance.png'),
    ('Après · jour', 'apres/jour/05-tendance.png'),
    ('Avant · nuit', 'avant/nuit/05-tendance.png'),
    ('Après · nuit', 'apres/nuit/05-tendance.png'),
], 2, 380, 'avant-apres.png')
for theme in ('jour', 'nuit'):
    sheet([(f'{i} / 4 · {theme}', f'apres/{theme}/0{i}-hero.png') for i in range(1, 5)],
          4, 280, f'sequence-{theme}.png')
