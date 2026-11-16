# Modelos de Ascensão e de Craft de Ascensão

Cada lote tem 10 mineradoras, 10 fornalhas e 30 modificadores. Os arquivos individuais estão nas subpastas de `assets/`. Para revisar no Roblox Studio, importe a galeria do lote.

| Galeria | Mineradoras | Fornalhas | Modificadores |
| --- | --- | --- | --- |
| [Ascensão](Galeria50Ascensao.rbxm) | [AM01–10](previas/Ascensao-Mineradoras.png) | [AF01–10](previas/Ascensao-Fornalhas.png) | [AX01–10](previas/Ascensao-Modificadores-1.png), [AX11–20](previas/Ascensao-Modificadores-2.png), [AX21–30](previas/Ascensao-Modificadores-3.png) |
| [Craft de Ascensão](Galeria50CraftAscensao.rbxm) | [CAM01–10](previas/Craft-Mineradoras.png) | [CAF01–10](previas/Craft-Fornalhas.png) | [CAX01–10](previas/Craft-Modificadores-1.png), [CAX11–20](previas/Craft-Modificadores-2.png), [CAX21–30](previas/Craft-Modificadores-3.png) |
| [Craft intermediário de Ascensão](Galeria50CraftIntermediariosAscensao.rbxm) | [CIM01–10](previas/Intermediarios-Mineradoras.png) | [CIF01–10](previas/Intermediarios-Fornalhas.png) | [CIX01–10](previas/Intermediarios-Modificadores-1.png), [CIX11–20](previas/Intermediarios-Modificadores-2.png), [CIX21–30](previas/Intermediarios-Modificadores-3.png) |

As folhas e o manifesto `modelos.json` usam largura × comprimento × altura em blocos de 3 studs. As mineradoras têm a saída projetada sobre o centro de uma célula. As fornalhas têm bandeja de 2×2 e os modificadores têm correia de dois blocos de largura, alinhada à grade. Cada faixa física tem um sensor correspondente. As correias dos modificadores usam a altura de encaixe padrão ou ficam um ou dois blocos acima dela.

## Transições

A sequência de recompensas começa com a Mineradora do zênite na transição 1, o Filtro da aurora verde na 2 e a Fornalha do alvorecer na 3. A cada grupo de cinco transições há uma mineradora, uma fornalha e três modificadores. O manifesto registra a máquina de cada marco de 1 a 50.

## Receitas

As [100 receitas de Ascensão](Receitas.md) terminam na [Mineradora, Fornalha e Modificador Síntese da Ascensão](previas/Sinteses.png). Cada síntese reúne a Convergência anterior e os ramos do mesmo tipo. As três árvores cobrem as 60 máquinas de Renascimento, os 50 crafts anteriores à Ascensão, os 97 intermediários de Ascensão e as 100 peças da loja pós-Ascensão.

Em cada série da loja há uma receita de mineradora, uma de fornalha e três de modificador. Cada rota parte de duas compras por série. Na série 5, a receita reúne os resultados das séries 2 e 4, que incorporam as séries 1 e 3. Na série 10, a receita reúne os resultados das séries 5, 7 e 9, sendo que as séries 7 e 9 incorporam as séries 6 e 8. Assim, cada compra pós-Ascensão é consumida uma única vez para fabricar as três sínteses.

## Exportação

Os modelos e as receitas estão prontos para importar e revisar. Os efeitos de produção, os multiplicadores e a ligação com o catálogo do jogo ficam para a etapa de integração.

Na raiz do projeto, execute `lune run modelos/ascensao/gerar.luau` para gerar os assets. Passe um caminho JSON ao gerador e depois a `python modelos/ascensao/renderizar.py` para fazer as folhas com Pillow e NumPy. Os comandos `lune run modelos/ascensao/receitas.luau` e `lune run tests/modelos_ascensao.luau` verificam a cobertura das receitas e a geometria dos modelos.
