"""Renderiza as seis séries a partir da geometria dos modelos Roblox."""
import importlib.util
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location(
    "folhas", ROOT.parent / "renascimento" / "novas" / "renderizar.py"
)
folhas = importlib.util.module_from_spec(spec)
spec.loader.exec_module(folhas)
folhas.ROOT = ROOT

modelos = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
(ROOT / "previas").mkdir(exist_ok=True)
titulos = ["Metalurgia fina", "Ligas sob pressão", "Reatores de cisalhamento",
           "Circuitos magnéticos", "Estabilidade de fase", "Horizonte do Renascimento"]
for n, titulo in enumerate(titulos, 1):
    itens = [m for m in modelos if m["serie"] == n]
    folhas.folha(f"Serie-{n:02d}", f"Loja intermediária · {titulo}", itens,
                 colunas=3 if n == 1 else 5)

brocas = [m for m in modelos if any(p["name"] == "MancalDaBroca" for p in m["partes"])]
folhas.folha("Brocas", "Mineradoras de broca · Frente e traseira", brocas, verso=True, colunas=5)
