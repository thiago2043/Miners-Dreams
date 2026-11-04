"""Previas dos RBXM relidos; usa o renderizador de geometria ja existente no projeto."""
from pathlib import Path
import copy
import hashlib
import importlib.util
import json
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('render_mineradoras', ROOT.parent/'mineradoras'/'renderizar.py')
renderer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderer)
data = (ROOT/'geometria.json').read_bytes()
models = json.loads(data)
out = ROOT/'previas'/hashlib.sha256(data+Path(__file__).read_bytes()).hexdigest()[:10]
out.mkdir(parents=True, exist_ok=True)


def sheet(name, indices, camera=(1.1, .8, -1.7), cols=3, w=540, h=440):
    image = Image.new('RGB', (cols*w, 65+((len(indices)+cols-1)//cols)*(h+70)), (239, 242, 246))
    draw = ImageDraw.Draw(image)
    draw.text((20, 15), name, font=renderer.font(25, True), fill=(30, 41, 57))
    for j, i in enumerate(indices):
        m = models[i]
        x, y = j % cols*w, 65+j//cols*(h+70)
        image.paste(renderer.render(m['partes'], w, h, grid=True, camera=camera, reserva=m['blocos']), (x, y))
        draw.text((x+16, y+h+2), f"{m['codigo']} · {m['nome']}", font=renderer.font(21, True), fill=(30, 41, 57))
        draw.text((x+16, y+h+33), ' × '.join(map(str, m['blocos']))+' blocos · largura × comprimento × altura', font=renderer.font(15), fill=(74, 88, 109))
    path = out/(name.split(' · ')[0]+'.png')
    image.save(path)
    print(path)


sheet('01_Iniciais · F1–F3', list(range(3)))
sheet('02_Intermediarias · F4–F6', list(range(3, 6)))
sheet('03_Avancadas · F7–F9', list(range(6, 9)), w=620, h=520)
sheet('07_Paletas · F1–F9', list(range(9)), w=480, h=390)
sheet('04_Costas · CORPOS, RADIADORES E TUBULACOES', list(range(9)), camera=(-1.2, .8, 1.7), w=480, h=390)
sheet('05_Superior · ENTRADAS E OCUPACAO', list(range(9)), camera=(.12, 3, -.65), w=480, h=390)

parts = []
for i, m in enumerate(models):
    for p in m['partes']:
        q = copy.deepcopy(p)
        q['cf'][0] += i*25
        parts.append(q)
image = renderer.render(parts, 2350, 700, grid=True, camera=(.07, .8, -1.9))
draw = ImageDraw.Draw(image)
draw.text((20, 14), 'F1–F9 · MESMA ESCALA · cada quadrado equivale a um bloco', font=renderer.font(27, True), fill=(30, 41, 57))
image.save(out/'06_MesmaEscala.png')
print(out/'06_MesmaEscala.png')
(ROOT/'previa-atual.txt').write_text(str(out.relative_to(ROOT)).replace('\\', '/'), encoding='utf-8')
