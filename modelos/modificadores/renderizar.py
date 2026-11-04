"""Renderiza os RBXM relidos no manifesto com o renderizador geometrico ja usado nas mineradoras."""
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
models = json.loads((ROOT / "geometria.json").read_text(encoding="utf-8"))
uso = json.loads((ROOT / "geometria-uso.json").read_text(encoding="utf-8"))
out = ROOT / "previas" / hashlib.sha256((ROOT / "geometria.json").read_bytes() + (ROOT / "geometria-uso.json").read_bytes() + Path(__file__).read_bytes()).hexdigest()[:10]
out.mkdir(parents=True, exist_ok=True)


def particulas(efeitos):
    partes = []
    rng = renderizador.np.random.default_rng(1707)
    for efeito in efeitos:
        if efeito["tipo"] != "ParticleEmitter":
            continue
        origem = renderizador.np.array(efeito["a"])
        direcao = renderizador.np.array(efeito["direcao"])
        vida = sum(efeito["vida"]) / 2
        velocidade = sum(efeito["velocidade"]) / 2
        for idade in renderizador.np.linspace(.01, vida, max(1, int(vida * efeito["taxa"]))):
            pos = origem + direcao * idade * velocidade
            pos += rng.normal(0, .025 + idade * .3, 3) * (1 - abs(direcao))
            partes.append({"name": "ParticulaIlustrada", "size": [efeito["tamanho"]] * 3,
                           "cf": list(pos) + [1, 0, 0, 0, 1, 0, 0, 0, 1], "shape": "Ball",
                           "material": "Neon", "color": efeito["cor"], "transparency": .25, "collide": False})
    return partes


def minerios(caso):
    correia = next(p for p in caso["partesTransporte"] if p["name"] == "Correia")
    topo = correia["cf"][1] + correia["size"][1] / 2
    return [{"name": "MinerioIlustrado", "size": [1, 1, 1],
             "cf": [correia["cf"][0], topo + .5, p["cf"][2]] + [1, 0, 0, 0, 1, 0, 0, 0, 1],
             "shape": "Block", "material": "Slate", "color": [.58, .63, .68], "transparency": 0, "collide": False}
            for p in caso["partesModelo"] if p.get("operacao")]


def folha(nome, indices, colunas=3, camera=(1.3, .85, 1.8), fonte=None):
    w, h = 510, 405
    image = Image.new("RGB", (w * colunas, 72 + ((len(indices) + colunas - 1) // colunas) * (h + 94)), (239, 242, 246))
    draw = ImageDraw.Draw(image)
    draw.text((22, 17), nome, font=renderizador.font(27, True), fill=(30, 41, 57))
    for j, i in enumerate(indices):
        m = (models if fonte is None else fonte)[i]
        x, y = j % colunas * w, 72 + j // colunas * (h + 94)
        pecas = m["partes"] + particulas(m.get("efeitos", [])) + (minerios(m) if fonte else [])
        image.paste(renderizador.render(pecas, w, h, camera=m.get("cameraUso", camera), reserva=None if fonte else m["blocos"]), (x, y))
        draw.text((x + 15, y + h + 3), f'{m["codigo"]} · {m["nome"]} · {m["etapas"]} etapa' + ('s' if m["etapas"] != 1 else ''), font=renderizador.font(18, True), fill=(30, 41, 57))
        transporte = 'transporte externo' if fonte else (f'correia {m["passagem"] // 4} × {m["blocos"][1]}' if m["esteira"] else 'sem esteira')
        draw.text((x + 15, y + h + 32), f'{m["blocos"][0]} × {m["blocos"][1]} × {m["altura"]} blocos · {transporte}',
                  font=renderizador.font(16), fill=(74, 88, 109))
        draw.text((x + 15, y + h + 57), f'Altura da passagem: {m["alturaPassagem"]:g} studs', font=renderizador.font(16), fill=(74, 88, 109))
    image.save(out / (nome.split(" · ")[0] + ".png"))


folha("01_Iniciais · JATOS, BANHO E PRENSAS", list(range(6)))
folha("02_SegundoGrupo · BOBINAS, REFINO E FEIXES", list(range(6, 12)))
folha("03_Passagem · VISTA DE FRENTE", list(range(12)), 4, camera=(.12, .32, 2.0))
folha("04_Superior · FORMAS E DISTRIBUIÇÃO DOS MÓDULOS", list(range(12)), 4, camera=(.2, 2.1, .7))
folha("07_TerceiroGrupo · MAGNETISMO, COMPRESSÃO E CALOR", list(range(12, 18)))
folha("08_QuartoGrupo · LASERS, RESSONÂNCIA E ACELERAÇÃO", list(range(18, 24)))
folha("09_NovosFrente · PASSAGEM DOS PRÓXIMOS 12", list(range(12, 24)), 4, camera=(.12, .32, 2.0))
folha("10_NovosSuperior · DISTRIBUIÇÃO DAS ETAPAS", list(range(12, 24)), 4, camera=(.2, 2.1, .7))
folha("15_QuintoGrupo · PARTÍCULAS, FISSÃO E ANTIMATÉRIA", list(range(24, 30)))
folha("16_SextoGrupo · RESSONÂNCIA, ANÉIS E PULSOS", list(range(30, 36)))
folha("17_TerceiraLevaFrente · PASSAGENS E APOIOS", list(range(24, 36)), 4, camera=(.12, .32, 2.0))
folha("18_TerceiraLevaSuperior · DISTRIBUIÇÃO DAS ETAPAS", list(range(24, 36)), 4, camera=(.2, 2.1, .7))
folha("20_SetimoGrupo · REFINO, GRAVIDADE E ÓPTICA", list(range(36, 42)))
folha("21_OitavoGrupo · QUASAR, HORIZONTE E POLARIDADE", list(range(42, 48)))
folha("22_QuartaLevaFrente · PASSAGENS E APOIOS", list(range(36, 48)), 4, camera=(.12, .32, 2.0))
folha("23_QuartaLevaSuperior · DISTRIBUIÇÃO DAS ETAPAS", list(range(36, 48)), 4, camera=(.2, 2.1, .7))
remodelados = [12, 25, 28, 33, 35, 37, 41]
folha("25_Remodelados · SETE MODELOS COM ESTEIRA PRÓPRIA", remodelados, 4)
folha("26_UltimaLeva · VÁCUO, HORIZONTE E DIMENSÕES", list(range(48, 55)), 4)
folha("27_RemodeladosFrente · PASSAGENS E APOIOS", remodelados, 4, camera=(.12, .32, 2.0))
folha("28_UltimaLevaSuperior · DISTRIBUIÇÃO DAS ETAPAS", list(range(48, 55)), 4, camera=(.2, 2.1, .7))

conjunto = []
for i, m in enumerate(models):
    for p in m["partes"]:
        parte = copy.deepcopy(p)
        parte["cf"][0] += (i % 6) * 24
        parte["cf"][2] += (i // 6) * 28
        conjunto.append(parte)
imagem = renderizador.render(conjunto, 2400, 1900, grid=True, camera=(.5, 1.0, 1.8))
imagem.save(out / "05_MesmaEscala.png")

grade = Image.new("RGB", (1440, 630), (239, 242, 246))
draw = ImageDraw.Draw(grade)
draw.text((22, 16), "BORDAS UTILIZÁVEIS SOBRE A GRADE · esquema das medidas nativas", font=renderizador.font(25, True), fill=(30, 41, 57))
for j, i in enumerate([1, 3, 21]):
    m = models[i]
    largura, fundo = m["blocos"][0] * 3, m["blocos"][1] * 3
    correia = next(p for p in m["partes"] if p["name"] == "Correia")
    escala = 16
    x, y = j * 480 + 240 - largura * escala / 2, 108
    draw.rectangle((x, y, x + largura * escala, y + fundo * escala), fill=(217, 224, 231), outline=(91, 105, 121), width=2)
    esquerda = x + (largura / 2 + correia["cf"][0] - correia["size"][0] / 2) * escala
    direita = esquerda + correia["size"][0] * escala
    draw.rectangle((esquerda, y, direita, y + fundo * escala), fill=(94, 191, 215))
    for celula in range(m["blocos"][0] + 1):
        px = x + celula * 3 * escala
        draw.line((px, y, px, y + fundo * escala), fill=(110, 130, 145), width=1)
    for celula in range(m["blocos"][1] + 1):
        py = y + celula * 3 * escala
        draw.line((x, py, x + largura * escala, py), fill=(110, 130, 145), width=1)
    draw.rectangle((esquerda, y, direita, y + fundo * escala), outline=(12, 104, 136), width=4)
    draw.text((j * 480 + 24, 450), f'{m["codigo"]} · {m["nome"]}', font=renderizador.font(23, True), fill=(30, 41, 57))
    draw.text((j * 480 + 24, 487), f'Área útil: {correia["size"][0] / 3:g} × {correia["size"][2] / 3:g} blocos', font=renderizador.font(21), fill=(38, 107, 130))
    draw.text((j * 480 + 24, 522), 'Cada célula = 3 × 3 studs', font=renderizador.font(19), fill=(74, 88, 109))
draw.text((22, 586), 'Azul: superfície da correia. Cinza: reserva lateral da máquina. As bordas azuis coincidem com as linhas da grade.', font=renderizador.font(19), fill=(74, 88, 109))
grade.save(out / "06_AlinhamentoGrade.png")

comparacao = []
escolhidos = [33, 35, 48, 50, 51, 54]
for j, i in enumerate(escolhidos):
    for p in models[i]["partes"]:
        parte = copy.deepcopy(p)
        parte["cf"][0] += j * 26
        comparacao.append(parte)
camera = renderizador.np.array([.08, .48, 2.0])
camera /= renderizador.np.linalg.norm(camera)
direita = renderizador.np.cross([0., 1., 0.], camera)
direita /= renderizador.np.linalg.norm(direita)
cima = renderizador.np.cross(camera, direita)
vertices = renderizador.np.concatenate([g[0] for g in renderizador.geometria(comparacao)])
px, py = vertices @ direita, vertices @ cima
escala = min((2400 - 90) / (px.max() - px.min()), (720 - 75) / (py.max() - py.min()))
centro_x = (px.min() + px.max()) / 2
amostra = renderizador.render(comparacao, 2400, 720, camera=camera)
draw = ImageDraw.Draw(amostra)
draw.text((22, 17), "TAMANHOS REAIS NA MESMA ESCALA · sem ampliar individualmente as peças pequenas", font=renderizador.font(28, True), fill=(30, 41, 57))
for j, i in enumerate(escolhidos):
    m = models[i]
    x = (j * 26 * direita[0] - centro_x) * escala + 1200
    for texto, y, forte in [(f'{m["codigo"]} · {m["nome"]}', 636, True),
                             (f'{m["blocos"][0]} × {m["blocos"][1]} × {m["altura"]} blocos', 670, False)]:
        fonte = renderizador.font(21, forte)
        meia_largura = draw.textlength(texto, font=fonte) / 2
        centro_rotulo = max(18 + meia_largura, min(2382 - meia_largura, x))
        draw.text((centro_rotulo, y), texto, font=fonte, anchor="mt", fill=(30, 41, 57) if forte else (74, 88, 109))
amostra.save(out / "11_VariedadeEscala.png")

casos = []
for c in uso["casos"]:
    m = copy.deepcopy(next(d for d in models if d["codigo"] == c["codigo"]))
    m.update(c)
    corpo = next(p for p in c["partes"] if p["name"] == "HitboxConstrucao")
    m["cameraUso"] = (-1.3, .85, 1.8) if corpo["cf"][0] > 0 else (1.3, .85, 1.8)
    casos.append(m)
folha("12_SemEsteiraEmUso · FAIXAS SOBRE TRANSPORTE EXISTENTE", list(range(len(casos))), fonte=casos)
minerios_linha = [p for c in casos for p in minerios(c)]
linha = renderizador.render(uso["partes"] + particulas(uso["efeitos"]) + minerios_linha, 1800, 1400, camera=(1.1, 1.5, 1.8))
draw = ImageDraw.Draw(linha)
draw.text((24, 18), "USO COMPARTILHADO DO TRANSPORTE · corpos fora da linha de minério", font=renderizador.font(28, True), fill=(30, 41, 57))
draw.text((24, 58), "Correias úteis de 2 × 3 blocos. Ao lado: N02 sobre o H2 novo. Guias ocultas após colocar.", font=renderizador.font(23), fill=(74, 88, 109))
linha.save(out / "13_LinhaCompartilhada.png")

comparativo = Image.new("RGB", (1400, 1120), (239, 242, 246))
draw = ImageDraw.Draw(comparativo)
draw.text((22, 15), "GUIA NA COLOCAÇÃO E EFEITO APÓS COLOCAR", font=renderizador.font(28, True), fill=(30, 41, 57))
for linha_caso, indice in enumerate([1, 2]):
    c = casos[indice]
    for modo in range(2):
        corpo = copy.deepcopy(c["partesModelo"])
        if modo == 0:
            for p in corpo:
                p["transparency"] = p.get("transparenciaPrevia", .65) if p.get("guia") else (1 if p.get("operacao") else max(p["transparency"], .55))
        extras = [] if modo == 0 else particulas(c["efeitos"])
        imagem = renderizador.render(corpo + c["partesTransporte"] + extras + minerios(c), 700, 440, camera=c["cameraUso"])
        x, y = modo * 700, 80 + linha_caso * 510
        comparativo.paste(imagem, (x, y))
        draw.text((x + 20, y + 449), f'{c["codigo"]} · ' + ('Durante a colocação' if modo == 0 else 'Depois de colocar'), font=renderizador.font(23, True), fill=(30, 41, 57))
comparativo.save(out / "14_GuiaEOperacao.png")
(ROOT / "previa-atual.txt").write_text(str(out.relative_to(ROOT)), encoding="utf-8")
print(out, flush=True)
