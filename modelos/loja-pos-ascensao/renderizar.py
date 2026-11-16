"""Renderiza as dez séries a partir da geometria exportada dos modelos."""
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
for n in range(1, 11):
    itens = [m for m in modelos if m["serie"] == n]
    folhas.folha(f"Serie-{n:02d}",
                 f'Loja pós-Ascensão · Série {n:02d} · $1e{itens[0]["expoente"]} a $1e{itens[-1]["expoente"]}',
                 itens, colunas=5)
