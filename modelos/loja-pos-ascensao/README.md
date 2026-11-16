# Modelos da loja pós-Ascensão

A [galeria para Roblox Studio](Galeria100LojaPosAscensao.rbxm) reúne 20 mineradoras, 20 fornalhas e 60 modificadores, divididos em dez séries. Os 100 arquivos individuais estão em `assets/`. Veja os nomes, as dimensões e os preços em expoente e na abreviação do jogo na [tabela de preços](Tabela_de_precos.md).

O requisito e os preços gravados nos modelos são referências da modelagem. A proposta de economia usa os [preços por ciclo](../../analises/Precos_loja_por_ciclo.md) e as [fichas com produção, multiplicadores e limites](../../analises/Especificacao_250_maquinas_ascensao.md).

| Série | Preços propostos | Prévia |
| --- | --- | --- |
| Cerâmica orbital | $1e155–$1e164 | [10 modelos](previas/Serie-01.png) |
| Hélio superfluido | $1e168–$1e177 | [10 modelos](previas/Serie-02.png) |
| Metalurgia solar | $1e183–$1e192 | [10 modelos](previas/Serie-03.png) |
| Cristais de fase | $1e200–$1e209 | [10 modelos](previas/Serie-04.png) |
| Dinâmica gravítica | $1e219–$1e228 | [10 modelos](previas/Serie-05.png) |
| Vácuo de alta energia | $1e242–$1e251 | [10 modelos](previas/Serie-06.png) |
| Engenharia de neutrinos | $1e270–$1e279 | [10 modelos](previas/Serie-07.png) |
| Óptica de horizontes | $1e303–$1e312 | [10 modelos](previas/Serie-08.png) |
| Entropia dirigida | $1e341–$1e350 | [10 modelos](previas/Serie-09.png) |
| Eternidade | $1e390–$1e399 | [10 modelos](previas/Serie-10.png) |

Os modelos ocupam de 2×1×1 a 8×8×7 blocos. As mineradoras deixam cair minério à frente, sobre uma célula da grade. As fornalhas recebem minérios por uma bandeja 2×2. Os modificadores usam correias com dois blocos de largura, na altura padrão ou elevadas em um ou dois blocos. Cada faixa 3D tem um sensor correspondente.

Na raiz do projeto, `lune run modelos/loja-pos-ascensao/gerar.luau` exporta os modelos. Passe um caminho para um JSON de geometria como argumento opcional e use o mesmo caminho em `python modelos/loja-pos-ascensao/renderizar.py` para gerar as folhas com Pillow e NumPy. `lune run modelos/loja-pos-ascensao/verificar.luau` confere os arquivos exportados, a geometria, os encaixes e os preços.
