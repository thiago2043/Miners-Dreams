"""Gera vistas dos assets existentes, reutilizando o renderizador do projeto."""
from pathlib import Path
import importlib.util
import json
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('renderer', ROOT.parent/'mineradoras'/'renderizar.py')
renderer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderer)
models = json.loads((ROOT/'geometria.json').read_text(encoding='utf-8'))
out = ROOT/'previas'
out.mkdir(exist_ok=True)

for group, title, sign in [(0, 'Mineradoras', 1), (1, 'Fornalhas', -1), (2, 'Modificadores', -1)]:
    w, h = 600, 430
    image = Image.new('RGB', (w*3, 60+(h+65)*2), (239, 242, 246))
    draw = ImageDraw.Draw(image)
    draw.text((22, 14), title+' de renascimento', font=renderer.font(27, True), fill=(30, 41, 57))
    for row in range(2):
        camera = (1.2, .65, sign*1.8) if row == 0 else (-1.2, .7, -sign*1.8)
        for col, model in enumerate(models[group*3:group*3+3]):
            x, y = col*w, 60+row*(h+65)
            image.paste(renderer.render(model['partes'], w, h, camera=camera), (x, y))
            draw.text((x+18, y+h+5), model['nome'], font=renderer.font(23, True), fill=(30, 41, 57))
            draw.text((x+18, y+h+35), 'Frente e lateral' if row == 0 else 'Costas e lateral', font=renderer.font(17), fill=(74, 88, 109))
    path = out/(title+'.png')
    image.save(path)
    print(path)
