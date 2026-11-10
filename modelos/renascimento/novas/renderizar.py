"""Monta folhas a partir da geometria exportada dos modelos."""
from pathlib import Path
import importlib.util
import json
import sys

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location(
    "renderizador", ROOT.parents[1] / "mineradoras" / "renderizar.py"
)
renderizador = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderizador)


def folha(nome, titulo, itens, verso=False):
    w, h, rodape = 390, 302, 58
    colunas = 4
    vistas = itens * 2 if verso else itens
    altura = 56 + (h + rodape) * ((len(vistas) + colunas - 1) // colunas)
    imagem = Image.new("RGB", (w * colunas, altura), "#17212e")
    texto = ImageDraw.Draw(imagem)
    texto.text((22, 14), titulo, font=renderizador.font(26, True), fill="#f0f4f6")
    for i, modelo in enumerate(vistas):
        x, y = i % colunas * w, 56 + (i // colunas) * (h + rodape)
        frente = 1 if modelo["categoria"] == "Mineradoras" else -1
        traseira = verso and i >= len(itens)
        camera = (-1.22, 0.77, -frente*1.8) if traseira else (1.24, 0.94, frente*1.8)
        imagem.paste(renderizador.render(modelo["partes"], w, h, camera=camera), (x, y))
        texto.text((x+14, y+h+5), f'{modelo["codigo"]}  {modelo["nome"]}',
                   font=renderizador.font(18, True), fill="#f0f4f6")
        detalhes = " × ".join(map(str, modelo["blocos"]))
        if "etapas" in modelo:
            etapas = modelo["etapas"]
            detalhes += f'   ·   {etapas} {"faixa" if etapas == 1 else "faixas"}'
            detalhes += f'   ·   Correia {modelo["largura"]}'
            if modelo["nivel"]:
                detalhes += f'   ·   Nível +{modelo["nivel"]}'
        else:
            detalhes += "   ·   Traseira" if traseira else "   ·   Frente"
        texto.text((x+14, y+h+32), detalhes, font=renderizador.font(15), fill="#b7c9d5")
    arquivo = ROOT / "previas" / f"{nome}.png"
    imagem.save(arquivo)
    print(arquivo, flush=True)


if __name__ == "__main__":
    modelos = json.loads((ROOT / "geometria.json").read_text(encoding="utf-8"))
    (ROOT / "previas").mkdir(exist_ok=True)
    for categoria in ("Mineradoras", "Fornalhas"):
        folha(categoria, categoria + " de renascimento",
              [m for m in modelos if m["categoria"] == categoria], verso=True)
    modificadores = [m for m in modelos if m["categoria"] == "Modificadores"]
    for i in range(0, len(modificadores), 11):
        lote = modificadores[i:i+11]
        faixa = f'{lote[0]["codigo"]}–{lote[-1]["codigo"]}'
        folha(f"Modificadores-{i//11+1}", f"Modificadores de renascimento   {faixa}", lote)
