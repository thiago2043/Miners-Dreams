# 100 modelos de loja e craft

Cada leva contém 10 mineradoras, 10 fornalhas e 30 modificadores. Os modelos individuais estão em `assets/Loja` e `assets/Craft`. Para revisar por categoria no Studio, importe `Galeria50Loja.rbxm` ou `Galeria50Craft.rbxm`.

| Leva | Mineradoras | Fornalhas | Modificadores |
| --- | --- | --- | --- |
| Loja | [LM01–10](previas/Loja-Mineradoras.png) | [LF01–10](previas/Loja-Fornalhas.png) | [LX01–10](previas/Loja-Modificadores-1.png), [LX11–20](previas/Loja-Modificadores-2.png), [LX21–30](previas/Loja-Modificadores-3.png) |
| Craft | [CM01–10](previas/Craft-Mineradoras.png) | [CF01–10](previas/Craft-Fornalhas.png) | [CX01–10](previas/Craft-Modificadores-1.png), [CX11–20](previas/Craft-Modificadores-2.png), [CX21–30](previas/Craft-Modificadores-3.png) |

As dimensões nas folhas seguem largura × comprimento × altura em blocos de 3 studs. As mineradoras têm saída no eixo da máquina, projetada até o centro da célula. As fornalhas usam bandejas de 2×2 blocos. Os modificadores têm correia própria, com dois blocos de largura na maioria das peças e quatro correias de um bloco. Cada faixa tem um sensor de igual volume. As correias elevadas sobem um ou dois blocos, mantendo a altura padrão relativa à esteira conectada.

As [50 receitas](Receitas.md) usam uma unidade de cada ingrediente indicado. Os três [crafts finais](previas/Convergencias.png) recebem três peças intermediárias cada. A árvore da Escavadora Convergência inclui 30 mineradoras de loja e renascimento e 9 crafts intermediários. A da Fornalha Convergência inclui 26 fornalhas e 9 crafts. A do Modificador Convergência inclui 131 modificadores e 29 crafts. O arquivo `receitas.json` registra os IDs de cada dependência.

Os 100 modelos individuais estão mapeados no Rojo e no catálogo. As 50 peças da loja usam os preços e efeitos da [tabela de valores](Tabela_de_valores.md). As outras 50 aparecem em Craft. Cada fabricação consome os ingredientes diretos do inventário e entrega uma unidade permanente. Um ingrediente fabricado abre sua própria receita. Unidades comuns são consumidas primeiro. O resultado pode ser colocado, recolhido e usado em outros crafts.

Na raiz do projeto, `lune run modelos/expansao/gerar.luau` exporta os modelos e as galerias. Para refazer as prévias, informe um caminho de saída JSON ao gerador e passe esse mesmo caminho a `python modelos/expansao/renderizar.py`. O renderizador usa Pillow e NumPy. `lune run tests/modelos_expansao.luau` confere os assets e a árvore completa de receitas.
