# 80 máquinas intermediárias da loja

A [galeria para Roblox Studio](Galeria80LojaIntermediaria.rbxm) reúne 16 mineradoras, 16 fornalhas e 48 modificadores. Use os arquivos individuais em `assets/` para importar uma peça de cada vez. A [tabela de preços](Tabela_de_precos.md) mostra as dimensões e os preços em expoente e na abreviação do jogo.

| Série | Peças | Prévia |
| --- | ---: | --- |
| Metalurgia fina | 6 | [Modelos](previas/Serie-01.png) |
| Ligas sob pressão | 10 | [Modelos](previas/Serie-02.png) |
| Reatores de cisalhamento | 12 | [Modelos](previas/Serie-03.png) |
| Circuitos magnéticos | 14 | [Modelos](previas/Serie-04.png) |
| Estabilidade de fase | 19 | [Modelos](previas/Serie-05.png) |
| Horizonte do Renascimento | 19 | [Modelos](previas/Serie-06.png) |

Os preços completam a [loja anterior à primeira Ascensão](../../analises/Precos_loja_por_ciclo.md), considerando as 127 máquinas da loja e os [seis conceitos pré-Ascensão](../../analises/Conceitos_fim_de_ciclo.md). O teto de ×1.000 entre preços consecutivos exige 68 inserções. As outras 12 peças reduzem alguns dos maiores intervalos em cada série.

As hitboxes variam de 2×1×1 a 8×8×7 blocos. As mineradoras deixam o minério cair sobre uma célula da grade. As fornalhas têm bandeja 2×2. Os modificadores usam correias de dois blocos de largura, com a superfície no nível padrão ou um ou dois blocos acima. Cada uma das faixas 3D tem seu próprio sensor.

As cinco [mineradoras de broca](previas/Brocas.png) têm mancal no chassi e uma flange que cobre a traseira da hélice.

Os arquivos são modelos de referência para integração. Os efeitos, a renda e o tempo de compra ainda dependem de balanceamento.

Na raiz do projeto, `lune run modelos/loja-intermediaria/gerar.luau` exporta os modelos. Passe um caminho de JSON como argumento para exportar a geometria e use o mesmo caminho em `python modelos/loja-intermediaria/renderizar.py` com Pillow e NumPy. Execute `lune run modelos/loja-intermediaria/verificar.luau` para conferir os arquivos, as conexões e a sequência de preços.
