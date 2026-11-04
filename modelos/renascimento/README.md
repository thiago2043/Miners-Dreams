# Recompensas de renascimento

Nove variantes dos modelos avançados aprovados, com reatores, coletores e estruturas adicionais. Os modelos preservam a grade de 3 studs, os bocais, corredores e sensores das bases. `gerar.luau` lê as definições em `src/shared/RecompensasRenascimento.luau` e exporta os nove assets mapeados pelo Rojo. A galeria serve apenas para inspeção e não é inserida no Workspace do jogo.

| Categoria | Modelos | Efeito |
| --- | --- | --- |
| Mineradoras | Aurora, Pulsar, Eterna | $2B, $5B, $10B por minério, a cada segundo |
| Fornalhas | Aurora, Supernova, Eterna | ×100, ×150, ×250 na venda |
| Modificadores | Selo da aurora, Prisma pulsar, Nexus eterno | ×20, ×25, ×30; uma faixa, três usos por tipo, sem limite monetário |

Cada vida ganha concede uma peça aleatória, com chance de 1/9 por modelo. Cópias acumulam; todas as recompensas voltam ao inventário nos próximos renascimentos. Não há concessão retroativa de vidas anteriores à implementação. As peças ficam fora da loja e não podem ser vendidas.

Verificações locais: `tests/recompensas_renascimento.luau` e `tests/reencarnacao.luau`. A primeira usa os assets reais e os componentes do jogo; a segunda usa perfil e mundo isolados, sem abrir dados de jogadores.
