"""Renderiza os modelos exportados em folhas de revisão."""
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
for origem in ("Loja", "Craft"):
    for categoria in ("Mineradoras", "Fornalhas", "Modificadores"):
        itens = [m for m in modelos if m["origem"] == origem and m["categoria"] == categoria]
        for inicio in range(0, len(itens), 10):
            pagina = itens[inicio:inicio + 10]
            sufixo = f"-{inicio // 10 + 1}" if len(itens) > 10 else ""
            titulo = f'{origem} · {categoria} · {pagina[0]["codigo"]}–{pagina[-1]["codigo"]}'
            folhas.folha(f"{origem}-{categoria}{sufixo}", titulo, pagina, colunas=5)

finais = [m for m in modelos if m["id"].endswith("Convergencia")]
folhas.folha("Convergencias", "Craft · As três convergências", finais, colunas=3)
