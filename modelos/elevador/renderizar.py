"""Renderiza os dois exemplos exportados pelo gerador de modelos."""
import importlib.util
import json
from pathlib import Path
import sys

from PIL import Image, ImageDraw


raiz = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("render_mineradoras", raiz.parent / "mineradoras" / "renderizar.py")
renderizador = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderizador)

cenas = json.loads(Path(sys.argv[1]).read_bytes())
largura, altura = 550, 570
folha = Image.new("RGB", (largura * 2, altura + 122), (232, 238, 244))
texto = ImageDraw.Draw(folha)
texto.text((24, 17), "Elevador vertical 1×1×H", font=renderizador.font(28, True), fill=(25, 37, 52))
texto.text((24, 52), "Entrada em âmbar · saída em turquesa", font=renderizador.font(17), fill=(65, 81, 101))
for i, (cena, titulo, percurso) in enumerate(zip(cenas, ("Subida", "Descida"), (
        "Entrada baixa +Z  →  saída alta +X",
        "Entrada alta +Z  →  saída baixa +Z",
), strict=True)):
    x = i * largura
    painel = renderizador.render(cena, largura, altura, grid=True, camera=(1.25, .62, 1.85), reserva=(1, 1, 4))
    folha.paste(painel, (x, 79))
    texto.text((x + 24, altura + 86), titulo, font=renderizador.font(19, True), fill=(25, 37, 52))
    texto.text((x + 117, altura + 88), percurso, font=renderizador.font(16), fill=(65, 81, 101))

folha.save(raiz / "ElevadorVertical.png")
