"""Renderiza os modelos de Ascensão em folhas por origem e tipo."""
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
for origem, nome in (
    ("Ascensao", "Ascensão"),
    ("Craft", "Craft de Ascensão"),
    ("Intermediarios", "Craft intermediário de Ascensão"),
):
    for categoria in ("Mineradoras", "Fornalhas", "Modificadores"):
        itens = [m for m in modelos if m["origem"] == origem and m["categoria"] == categoria]
        for inicio in range(0, len(itens), 10):
            pagina = itens[inicio:inicio+10]
            sufixo = f"-{inicio // 10 + 1}" if len(itens) > 10 else ""
            folhas.folha(f"{origem}-{categoria}{sufixo}",
                         f"{nome} · {categoria} · {pagina[0]['codigo']}–{pagina[-1]['codigo']}",
                         pagina, colunas=5)

finais = [m for m in modelos if m["id"].endswith("SinteseDaAscensao")]
folhas.folha("Sinteses", "Craft de Ascensão · As três sínteses", finais, colunas=3)
