# Recompensas de renascimento

O catálogo contém 60 recompensas: 7 mineradoras, 7 fornalhas e 46 modificadores. As nove variantes originais ficam em `assets`; os 51 modelos adicionais ficam em `novas/assets`. Todos estão mapeados no Rojo, na grade de 3 studs. As galerias são apenas para inspeção e não são inseridas no Workspace do jogo. Os dois geradores leem os efeitos de `src/shared/RecompensasRenascimento.luau`.

| Categoria | Modelos | Efeito |
| --- | --- | --- |
| Mineradoras | Aurora até Meridiano | $750M até $1UDe por minério, um minério/s |
| Fornalhas | Aurora até Catedral | ×100 até ×10N na venda |
| Modificadores | Selo da aurora até Porta do Meridiano | Primeira unidade: ×20–×400; cópias: +50 pontos percentuais por unidade; 4–8 usos por tipo |

Cada renascimento concede 1 ou 2 peças garantidas. Os ciclos 1–5 distribuem o conjunto do 5º; 6–10, o do 10º; e assim até o 50º. Depois disso, repete-se a distribuição do último conjunto. Os conjuntos pequenos repetem peças para manter ao menos uma entrega em cada ciclo. Cada vida extra concede uma peça aleatória entre os tipos já obtidos, incluindo a entrega atual. Não há limite de estoque baseado nos usos por minério. As recompensas e personalizações voltam ao inventário nos próximos ciclos e não podem ser compradas ou vendidas.

A primeira aplicação de modificador de renascimento exige processamento de ×10K sobre o minério de saída da mineradora. As faixas aplicam seus fatores em sequência. Cópias somam bônus sobre o valor processado, inclusive entre tipos diferentes; a mesma unidade física não reaplica. A venda e o valor mostrado no minério incluem esses bônus. A migração entrega uma unidade dos tipos garantidos faltantes pelos ciclos já concluídos, sem substituir quantidades ou personalizações existentes, e registra sua execução para não duplicar entregas.

As especificações completas ficam em `analises/Especificacao_maquinas_renascimento.md`. Os custos projetados para futuras mecânicas nesse documento não substituem a curva atual de renascimento.

Verificações locais: `tests/recompensas_renascimento.luau`, `tests/sorteio_renascimento.luau`, `tests/modelos_novos_renascimento.luau` e `tests/reencarnacao.luau`. Usam os assets reais, componentes e perfis isolados, sem acessar dados de jogadores. `tests/studio_recompensas_renascimento.luau` é a conferência manual disponível para o Studio.
