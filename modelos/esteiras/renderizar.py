"""Gera previas da geometria relida dos RBXM com o renderizador existente."""
from pathlib import Path
import copy
import hashlib
import importlib.util
import json
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("render_mineradoras", ROOT.parent / "mineradoras" / "renderizar.py")
renderizador = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderizador)
dados = (ROOT / "geometria.json").read_bytes()
modelos = json.loads(dados)
inclinadas = json.loads((ROOT / "geometria-inclinadas.json").read_bytes())
out = ROOT / "previas" / hashlib.sha256(dados + (ROOT / "geometria-inclinadas.json").read_bytes() + Path(__file__).read_bytes()).hexdigest()[:10]
out.mkdir(parents=True, exist_ok=True)


def folha(nome, indices, camera=(1.25, 1.15, 1.6), fonte=None):
    w, h, cols = 460, 350, min(3, len(indices))
    imagem = Image.new("RGB", (w * cols, 68 + ((len(indices) + cols - 1) // cols) * (h + 76)), (239, 242, 246))
    draw = ImageDraw.Draw(imagem)
    draw.text((20, 15), nome, font=renderizador.font(25, True), fill=(30, 41, 57))
    for j, i in enumerate(indices):
        m = (modelos if fonte is None else fonte)[i]
        x, y = j % cols * w, 68 + j // cols * (h + 76)
        camera_modelo = (camera[0], camera[1], -abs(camera[2])) if m.get("angulo", 0) < 0 else camera
        imagem.paste(renderizador.render(m["partes"], w, h, grid=True, camera=camera_modelo, reserva=m["blocos"]), (x, y))
        draw.text((x + 15, y + h + 4), m["nome"], font=renderizador.font(20, True), fill=(30, 41, 57))
        draw.text((x + 15, y + h + 34), " × ".join(map(str, m["blocos"])) + " blocos · largura × comprimento × altura",
                  font=renderizador.font(14), fill=(74, 88, 109))
    caminho = out / (nome.split(" · ")[0] + ".png")
    imagem.save(caminho)
    print(caminho)


folha("01_PlanasCentralizadorasParede · PLANAS, CENTRALIZADORAS E PAREDE", list(range(min(5, len(modelos)))))
folha("02_Inclinacao45 · AS MESMAS ESTEIRAS INCLINADAS", list(range(len(inclinadas))), fonte=inclinadas)
folha("03_PontasNaGrade · ESTEIRA 1×1 EM SUBIDA E DESCIDA", [2, 3], fonte=inclinadas)
comparacao = []
for i, m in enumerate(modelos[:5]):
    for p in m["partes"]:
        parte = copy.deepcopy(p)
        parte["cf"][0] += (i - 2) * 10
        comparacao.append(parte)
imagem = renderizador.render(comparacao, 1650, 600, grid=True, camera=(.12, 1.5, 2.2))
draw = ImageDraw.Draw(imagem)
draw.text((20, 14), "MESMA ESCALA · cada quadrado da grade representa um bloco", font=renderizador.font(25, True), fill=(30, 41, 57))
for i, m in enumerate(modelos[:5]):
    draw.text((15 + i * 330, 558), m["nome"], font=renderizador.font(21, True), fill=(30, 41, 57))
imagem.save(out / "04_MesmaEscala.png")
print(out / "04_MesmaEscala.png")
(ROOT / "previa-atual.txt").write_text(str(out.relative_to(ROOT)).replace("\\", "/"), encoding="utf-8")
