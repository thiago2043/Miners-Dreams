# Comparação dos catálogos com até 64 modificadores

Análise matemática de 22/10/2026, baseada exclusivamente na tabela enviada pelo usuário. Não é medição dos jogos reais e não altera o projeto.

## Atualização: 1 segundo por colocação e 1 segundo por remoção

Esta seção aplica a regra nova a mineradoras, modificadores e fornalhas. Os registros de compras e catálogos nas seções posteriores preservam a comparação anterior, com ações instantâneas.

### Regras temporais

- As mesmas trajetórias de compras anteriores são reaplicadas. Esta rodada isola a mudança de duração das ações, sem procurar uma nova sequência ótima de compras.
- Cada colocação dura 1 segundo. Cada remoção dura 1 segundo. Uma ação é executada por vez.
- O kit inicial continua gratuito, mas colocar a mineradora e a fornalha exige 2 segundos; a renda começa após a montagem das duas.
- Uma peça continua operando até a remoção terminar. Uma peça colocada só passa a operar quando o segundo de colocação termina.
- Durante uma substituição, os demais equipamentos continuam produzindo. Se não houver mineradora ativa ou não houver fornalha instalada, a renda imediata do modelo é zero.
- A produção ocorre durante as ações. O dinheiro gerado é mantido no saldo e reduz a espera para financiar compras posteriores.
- O custo líquido de cada compra permanece igual ao cenário anterior e é reservado antes das ações dessa compra. A hipótese de revenda de 100% de mineradoras e fornalhas permanece; nenhum reembolso é acrescentado aos modificadores retirados.
- Mudanças na ordem dos modificadores também custam ações: cada peça deslocada precisa ser removida e recolocada. A maior subsequência comum entre a ordem antiga e a nova é preservada, minimizando o número de remoções e colocações para obter a ordem escolhida.
- Os modificadores que precisam sair são removidos primeiro; em seguida, as peças são colocadas na ordem final. A capacidade de 64 modificadores é respeitada durante todas as etapas.
- A meta é o primeiro instante em que o saldo disponível atinge o valor. Se isso acontecer durante uma ação, o cronômetro encerra nesse instante; a peça não é ativada antes de completar seu segundo de colocação.
- Permanecem fora da simulação o transporte e estoque de minérios em trânsito, esteiras, busca nos menus, geometria real e recompensas de reencarnação.

### Tempos novos até 1qd disponível

| Jogo | Até 1 mineradora | Até 2 mineradoras | Até 4 mineradoras |
|---|---:|---:|---:|
|Drillbit|4 min 3 s|3 min 22 s|3 min 3 s|
|Mechanical Ascension X|8 min 12 s|6 min 54 s|6 min 39 s|
|Mini Miners|4 min 46 s|3 min 25 s|3 min 3 s|
|Project Exodus|36 min 23 s|24 min 15 s|15 min 45 s|
|Reincarnated|18 h 4 min 23 s|9 h 26 min 24 s|4 h 55 min 28 s|

### Tempos novos até 10qn disponível

| Jogo | Até 1 mineradora | Até 2 mineradoras | Até 4 mineradoras |
|---|---:|---:|---:|
|Drillbit|5 min 36 s|4 min 20 s|3 min 43 s|
|Mechanical Ascension X|8 min 24 s|7 min 7 s|6 min 54 s|
|Mini Miners|5 min 22 s|4 min 0 s|3 min 36 s|
|Project Exodus|40 min 37 s|26 min 37 s|18 min 16 s|
|Reincarnated|28 h 31 min 59 s|14 h 55 min 7 s|7 h 48 min 32 s|

### Diferença para o cenário anterior: até quatro mineradoras, meta de 1qd

| Jogo | Antes | Agora | Acréscimo |
|---|---:|---:|---:|
|Drillbit|50 s|3 min 3 s|2 min 12 s|
|Mechanical Ascension X|5 min 39 s|6 min 39 s|1 min 0 s|
|Mini Miners|1 min 46 s|3 min 3 s|1 min 16 s|
|Project Exodus|15 min 15 s|15 min 45 s|30 s|
|Reincarnated|4 h 54 min 38 s|4 h 55 min 28 s|50 s|

### Ações até 1qd: rota com uma mineradora

| Jogo | Colocações completas | Remoções completas | Tempo em ações, incluindo a última ação parcial | Acréscimo líquido no tempo até a meta |
|---|---:|---:|---:|---:|
|Drillbit|103|37|140 s|124,862 s|
|Mechanical Ascension X|68|7|75,1 s|36,568 s|
|Mini Miners|70|10|80,56 s|46,807 s|
|Project Exodus|74|14|88 s|37,426 s|
|Reincarnated|159|93|252 s|62,037 s|

O tempo de ações não deve ser somado diretamente ao resultado anterior: o dinheiro produzido durante a montagem financia etapas seguintes. Em Drillbit com uma mineradora, 140 segundos de ações acrescentaram aproximadamente 124,862 segundos ao tempo até 1qd.

### Conferências realizadas

- Testes pequenos de colocação de modificador, substituição de mineradora, substituição de fornalha e meta alcançada durante uma colocação.
- Os 30 cenários com duração de ação igual a zero reproduziram os tempos anteriores.
- Conservação de dinheiro: renda gerada menos custos pagos corresponde ao saldo final da meta.
- Conferência de tempo: espera por compras mais ações mais espera final corresponde ao tempo total.
- Limite de até 64 modificadores durante todas as ações; todas as ações completas possuem 1 segundo.

Esses resultados continuam sendo uma simulação matemática, sem medição de partidas reais.

---

## Cenário anterior: ações instantâneas

## Modelo da comparação

- Metas comuns de saldo disponível: 1qd = 10^15 e 10qn = 10^19. Não representam requisitos de reencarnação confirmados desses jogos.
- Primeira mineradora e primeira fornalha gratuitas, saldo inicial zero; as demais peças são compradas.
- Até 1, 2 ou 4 mineradoras. Todas começam com uma; as adicionais são compradas quando escolhidas pela regra de retorno.
- Até 64 cópias físicas de modificadores na linha, além das mineradoras e da fornalha.
- Cada cópia recebe uma passagem por minério. Repetições exigem cópias compradas e ocupam espaço. O limite numérico é compartilhado por tipo e por minério.
- Os aditivos com condição inf usam apenas uma cópia e uma passagem; nenhuma fonte de melhoria infinita é explorada.
- Limites em dinheiro são verificados antes da aplicação. Intervalos usam mínimo incluído e máximo excluído. É permitido o resultado ultrapassar o máximo.
- Cópias com apenas limite de valor podem repetir o efeito enquanto a entrada for elegível; cada cópia é paga.
- Revenda da mineradora e da fornalha substituídas: 100% do preço, como hipótese comum de comparação. Modificadores retirados não geram reembolso no cálculo.
- Sem duração de minério, sem perdas, sem bônus de reencarnação, sem tempo de montagem ou de transporte, sem custo de esteiras.
- A linha usa uma ordem comum para todas as mineradoras. Uma heurística prioriza aditivos e limites máximos menores, com organização a partir do minério de maior valor inicial. Reorganizar não custa tempo no modelo.
- A compra é escolhida pela menor soma entre espera para financiá-la e tempo de recuperar o custo no ganho adicional de renda. A rota pode pular peças. Compras que individualmente atrasariam a meta são evitadas. Não há prova de ótimo global.
- Valores são contas aproximadas em ponto flutuante, sem presumir o arredondamento interno dos jogos.
- Modificadores aleatórios de Mini Miners são excluídos da comparação principal, pois a distribuição não foi informada. Um cenário com todos os resultados máximos é mostrado separadamente.

Produção = soma de (valor processado do minério / intervalo da mineradora) × multiplicador da fornalha.

## Tempos até 1qd disponível

| Jogo | Até 1 mineradora | Até 2 mineradoras | Até 4 mineradoras |
|---|---:|---:|---:|
|Drillbit|1 min 58 s|1 min 12 s|50 s|
|Mechanical Ascension X|7 min 36 s|6 min 10 s|5 min 39 s|
|Mini Miners|3 min 59 s|2 min 29 s|1 min 46 s|
|Project Exodus|35 min 46 s|23 min 38 s|15 min 15 s|
|Reincarnated|18 h 3 min|9 h 25 min|4 h 54 min|

## Tempos até 10qn disponível

| Jogo | Até 1 mineradora | Até 2 mineradoras | Até 4 mineradoras |
|---|---:|---:|---:|
|Drillbit|3 min 12 s|1 min 49 s|1 min 9 s|
|Mechanical Ascension X|7 min 36 s|6 min 10 s|5 min 39 s|
|Mini Miners|4 min 17 s|2 min 38 s|1 min 51 s|
|Project Exodus|39 min 43 s|25 min 35 s|17 min 27 s|
|Reincarnated|28 h 30 min|14 h 53 min|7 h 47 min|

## Drillbit

M1, M2... e U1, U2... são as posições da tabela do usuário, sem inventar nomes oficiais.

### Catálogo de mineradoras

| ID | Intervalo (s) | Valor do minério | Produção bruta/s | Preço |
|---|---:|---:|---:|---:|
|M1|1|$5|$5|$50|
|M2|0,8|$8|$10|$100|
|M3|1,5|$25|$16,667|$650|
|M4|1,4|$140|$100|$150K|
|M5|1|$3K|$3K|$1,5M|
|M6|1|$5K|$5K|$25M|
|M7|1|$9K|$9K|$250M|
|M8|1|$15K|$15K|$2B|
|M9|1|$45K|$45K|$62B|
|M10|1,5|$90K|$60K|$4T|
|M11|0,8|$140K|$175K|$2qd|

### Catálogo de modificadores

| ID | Condição original | Efeito original | Preço por cópia |
|---|---|---|---:|
|U1|inf|+10|$100|
|U2|$1k|+100|$1,25K|
|U3|$25k|+1k|$5K|
|U4|$35k|x1.4|$9K|
|U5|3|x1.1, x1.25, depois x1.75|$10K|
|U6|$10k~$100k|x1.5|$65K|
|U7|$90k~$500k|x1.2|$400K|
|U8|20|x1.05|$800K|
|U9|1|x2|$1,25M|
|U10|$1m~$100m|x1.75|$2,5M|
|U11|$10k~$1m|x1.6|$2,5M|
|U12|3 e $5m|x1.4|$5M|
|U13|2|x1.5|$10M|
|U14|1|x2|$25M|
|U15|$1.5m~$45m|x1.4|$80M|
|U16|$40m~$5b|x1.5|$175M|
|U17|1|x2|$5B|
|U18|4 e $1t|x2.5|$200B|
|U19|1|x4|$40T|
|U20|2|x2|$600T|
|U21|$1t~$5qd|x1.8|$50qd|
|U22|$1qd~$5qn|x1.4|$800qd|
|U23|$5qn~$25qn|x1.5|$10qn|
|U24|7 e $50qn~$150qn|x1.1|$40sx|

### Catálogo de fornalhas

| ID | Multiplicador | Preço |
|---|---:|---:|
|F1|×1|$0|
|F2|×1,5|$6K|
|F3|×3|$275K|
|F4|×4,5|$500M|
|F5|×6|$20B|
|F6|×8|$15qd|
|F7|×10|$100qn|

### Etapas da rota com uma mineradora até 1qd

| Marco de renda | Tempo acumulado | Renda ao cruzar o marco | Cópias de modificadores na linha |
|---|---:|---:|---:|
|$1K/s|1 min 42 s|$1,8975K/s|7|
|$1M/s|1 min 53 s|$1,104M/s|28|
|$1B/s|1 min 56 s|$1,3362B/s|46|
|$1T/s|1 min 56 s|$1,1706T/s|64|
|Saldo disponível de 1qd|1 min 58 s|$545,94T/s|64|

Mineradoras compradas nessa rota: M1 → M2.
Fornalhas usadas: ×1 → 1,5 → ×3 → ×4,5 → ×6.

### Composição final da linha para 1qd

| Modificador | Cópias físicas | Efeito | Condição |
|---|---:|---|---|
|U2|1|+100|$1k|
|U3|5|+1k|$25k|
|U4|2|x1.4|$35k|
|U5|3|x1.1, x1.25, depois x1.75|3|
|U6|5|x1.5|$10k~$100k|
|U7|7|x1.2|$90k~$500k|
|U8|10|x1.05|20|
|U9|1|x2|1|
|U10|9|x1.75|$1m~$100m|
|U11|3|x1.6|$10k~$1m|
|U13|2|x1.5|2|
|U14|1|x2|1|
|U16|9|x1.5|$40m~$5b|
|U17|1|x2|1|
|U18|4|x2.5|4 e $1t|
|U19|1|x4|1|

### Ordem física de modificadores no final

Uma passagem percorre a ordem abaixo; peças inelegíveis não aplicam efeito. Tipos repetidos representam cópias distintas e pagas.

U2 → U3 → U3 → U3 → U3 → U3 → U4 → U4 → U6 → U6 → U6 → U6 → U6 → U11 → U7 → U7 → U7 → U7 → U7 → U7 → U7 → U11 → U11 → U10 → U10 → U10 → U10 → U10 → U10 → U10 → U10 → U10 → U16 → U16 → U16 → U16 → U16 → U16 → U16 → U16 → U16 → U18 → U18 → U18 → U18 → U5 → U5 → U5 → U8 → U8 → U8 → U8 → U8 → U8 → U8 → U8 → U8 → U8 → U9 → U13 → U13 → U14 → U17 → U19

### Compras da rota com uma mineradora até 1qd

Valores de custo de mineradoras e fornalhas já descontam a revenda da anterior. Ao substituir um modificador por falta de espaço, o preço da peça nova é pago integralmente.

| # | Compra | Modificador retirado | Custo | Espera desta compra | Tempo acumulado | Renda após compra | Modificadores na linha |
|---:|---|---|---:|---:|---:|---:|---:|
|1|M2|—|$50|10 s|10 s|$10/s|0|
|2|U1|—|$100|10 s|20 s|$22,5/s|1|
|3|U2|—|$1,25K|56 s|1 min 16 s|$147,5/s|2|
|4|U2|—|$1,25K|8 s|1 min 24 s|$272,5/s|3|
|5|U2|—|$1,25K|5 s|1 min 29 s|$397,5/s|4|
|6|U2|—|$1,25K|3 s|1 min 32 s|$522,5/s|5|
|7|U2|—|$1,25K|2 s|1 min 34 s|$647,5/s|6|
|8|U3|—|$5K|8 s|1 min 42 s|$1,8975K/s|7|
|9|U3|—|$5K|3 s|1 min 45 s|$3,1475K/s|8|
|10|U3|—|$5K|2 s|1 min 46 s|$4,3975K/s|9|
|11|F2|—|$6K|1 s|1 min 47 s|$6,5963K/s|9|
|12|U3|—|$5K|1 s|1 min 48 s|$8,4712K/s|10|
|13|U3|—|$5K|1 s|1 min 49 s|$10,346K/s|11|
|14|U4|—|$9K|1 s|1 min 50 s|$14,485K/s|12|
|15|U4|—|$9K|1 s|1 min 50 s|$20,279K/s|13|
|16|U4|—|$9K|0 s|1 min 51 s|$28,39K/s|14|
|17|U4|—|$9K|0 s|1 min 51 s|$39,746K/s|15|
|18|U4|—|$9K|0 s|1 min 51 s|$55,645K/s|16|
|19|U4|—|$9K|0 s|1 min 51 s|$77,902K/s|17|
|20|U2|—|$1,25K|0 s|1 min 51 s|$79,314K/s|18|
|21|U2|—|$1,25K|0 s|1 min 51 s|$80,726K/s|19|
|22|U2|—|$1,25K|0 s|1 min 52 s|$82,138K/s|20|
|23|U2|—|$1,25K|0 s|1 min 52 s|$83,55K/s|21|
|24|U2|—|$1,25K|0 s|1 min 52 s|$84,961K/s|22|
|25|U5|—|$10K|0 s|1 min 52 s|$93,458K/s|23|
|26|U5|—|$10K|0 s|1 min 52 s|$116,82K/s|24|
|27|U5|—|$10K|0 s|1 min 52 s|$204,44K/s|25|
|28|U6|—|$65K|0 s|1 min 52 s|$306,66K/s|26|
|29|U6|—|$65K|0 s|1 min 52 s|$459,99K/s|27|
|30|F3|—|$269K|1 s|1 min 53 s|$919,97K/s|27|
|31|U7|—|$400K|0 s|1 min 53 s|$1,104M/s|28|
|32|U7|—|$400K|0 s|1 min 54 s|$1,3248M/s|29|
|33|U7|—|$400K|0 s|1 min 54 s|$1,5897M/s|30|
|34|U7|—|$400K|0 s|1 min 54 s|$1,9077M/s|31|
|35|U7|—|$400K|0 s|1 min 55 s|$2,2892M/s|32|
|36|U7|—|$400K|0 s|1 min 55 s|$2,747M/s|33|
|37|U7|—|$400K|0 s|1 min 55 s|$3,2964M/s|34|
|38|U7|—|$400K|0 s|1 min 55 s|$3,9557M/s|35|
|39|U7|—|$400K|0 s|1 min 55 s|$4,7469M/s|36|
|40|U9|—|$1,25M|0 s|1 min 55 s|$9,4937M/s|37|
|41|U10|—|$2,5M|0 s|1 min 56 s|$16,614M/s|38|
|42|U10|—|$2,5M|0 s|1 min 56 s|$29,074M/s|39|
|43|U10|—|$2,5M|0 s|1 min 56 s|$50,88M/s|40|
|44|U10|—|$2,5M|0 s|1 min 56 s|$89,041M/s|41|
|45|U10|—|$2,5M|0 s|1 min 56 s|$155,82M/s|42|
|46|U10|—|$2,5M|0 s|1 min 56 s|$272,69M/s|43|
|47|U10|—|$2,5M|0 s|1 min 56 s|$477,2M/s|44|
|48|U10|—|$2,5M|0 s|1 min 56 s|$835,1M/s|45|
|49|U11|—|$2,5M|0 s|1 min 56 s|$1,3362B/s|46|
|50|U11|—|$2,5M|0 s|1 min 56 s|$2,1379B/s|47|
|51|U8|—|$800K|0 s|1 min 56 s|$2,2448B/s|48|
|52|U8|—|$800K|0 s|1 min 56 s|$2,357B/s|49|
|53|U8|—|$800K|0 s|1 min 56 s|$2,4748B/s|50|
|54|U8|—|$800K|0 s|1 min 56 s|$2,5986B/s|51|
|55|U8|—|$800K|0 s|1 min 56 s|$2,7285B/s|52|
|56|U8|—|$800K|0 s|1 min 56 s|$2,8649B/s|53|
|57|U8|—|$800K|0 s|1 min 56 s|$3,0082B/s|54|
|58|U8|—|$800K|0 s|1 min 56 s|$3,1586B/s|55|
|59|U8|—|$800K|0 s|1 min 56 s|$3,3165B/s|56|
|60|U8|—|$800K|0 s|1 min 56 s|$3,4824B/s|57|
|61|U8|—|$800K|0 s|1 min 56 s|$3,6565B/s|58|
|62|U8|—|$800K|0 s|1 min 56 s|$3,8393B/s|59|
|63|U8|—|$800K|0 s|1 min 56 s|$4,0313B/s|60|
|64|U8|—|$800K|0 s|1 min 56 s|$4,2328B/s|61|
|65|U8|—|$800K|0 s|1 min 56 s|$4,4445B/s|62|
|66|U8|—|$800K|0 s|1 min 56 s|$4,6667B/s|63|
|67|U8|—|$800K|0 s|1 min 56 s|$4,9B/s|64|
|68|U6|U4|$65K|0 s|1 min 56 s|$5,25B/s|64|
|69|U6|U3|$65K|0 s|1 min 56 s|$5,4721B/s|64|
|70|U8|U7|$800K|0 s|1 min 56 s|$5,7457B/s|64|
|71|U10|U4|$2,5M|0 s|1 min 56 s|$7,1821B/s|64|
|72|U8|U1|$800K|0 s|1 min 56 s|$7,5261B/s|64|
|73|U8|U2|$800K|0 s|1 min 56 s|$7,7447B/s|64|
|74|U6|U4|$65K|0 s|1 min 56 s|$8,2978B/s|64|
|75|U3|U7|$5K|0 s|1 min 56 s|$8,3238B/s|64|
|76|U13|U2|$10M|0 s|1 min 56 s|$12,274B/s|64|
|77|U13|U2|$10M|0 s|1 min 56 s|$18,094B/s|64|
|78|U14|U2|$25M|0 s|1 min 56 s|$35,555B/s|64|
|79|U16|U2|$175M|0 s|1 min 56 s|$52,381B/s|64|
|80|U6|U4|$65K|0 s|1 min 56 s|$56,123B/s|64|
|81|U16|U2|$175M|0 s|1 min 56 s|$82,656B/s|64|
|82|U16|U2|$175M|0 s|1 min 56 s|$121,69B/s|64|
|83|U16|U2|$175M|0 s|1 min 56 s|$179,1B/s|64|
|84|U16|U2|$175M|0 s|1 min 56 s|$263,49B/s|64|
|85|U11|U6|$2,5M|0 s|1 min 56 s|$281,05B/s|64|
|86|U16|U8|$175M|0 s|1 min 56 s|$401,51B/s|64|
|87|U16|U8|$175M|0 s|1 min 56 s|$573,58B/s|64|
|88|U16|U8|$175M|0 s|1 min 56 s|$819,4B/s|64|
|89|U16|U8|$175M|0 s|1 min 56 s|$1,1706T/s|64|
|90|F4|—|$499,73M|0 s|1 min 56 s|$1,7559T/s|64|
|91|U17|U8|$5B|0 s|1 min 56 s|$3,3445T/s|64|
|92|F5|—|$19,5B|0 s|1 min 56 s|$4,4593T/s|64|
|93|U18|U8|$200B|0 s|1 min 56 s|$10,617T/s|64|
|94|U18|U8|$200B|0 s|1 min 56 s|$25,28T/s|64|
|95|U18|U8|$200B|0 s|1 min 56 s|$60,19T/s|64|
|96|U18|U8|$200B|0 s|1 min 56 s|$143,31T/s|64|
|97|U19|U8|$40T|0 s|1 min 56 s|$545,94T/s|64|
|—|Acumular o saldo final|—|—|2 s|1 min 58 s|$545,94T/s|64|

## Mechanical Ascension X

M1, M2... e U1, U2... são as posições da tabela do usuário, sem inventar nomes oficiais.

### Catálogo de mineradoras

| ID | Intervalo (s) | Valor do minério | Produção bruta/s | Preço |
|---|---:|---:|---:|---:|
|M1|3|$1|$0,33333|$120|
|M2|1|$5|$5|$2,5K|
|M3|2|$25|$12,5|$10K|
|M4|2|$60|$30|$1M|
|M5|3|$350|$116,67|$100M|
|M6|2|$10K|$5K|$250B|
|M7|1|$250K|$250K|$5T|
|M8|2|$35M|$17,5M|$1qn|
|M9|1|$1B|$1B|$250qn|

### Catálogo de modificadores

| ID | Condição original | Efeito original | Preço por cópia |
|---|---|---|---:|
|U1|inf|+4|$50|
|U2|1|x2|$100|
|U3|$250|x2|$200|
|U4|1|x2.5|$1K|
|U5|1|x1.5|$1K|
|U6|1|x2|$4K|
|U7|1|x3.456|$5K|
|U8|2|x1.5|$50K|
|U9|1|x1.5|$125K|
|U10|2|x2|$500K|
|U11|2|x2.5|$1M|
|U12|$10k|x1.25|$25M|
|U13|4|x1.2|$500M|
|U14|3|x1.5|$1B|
|U15|1|x3|$5B|
|U16|2|x2|$10B|
|U17|1|x3|$250B|
|U18|1|x1.5|$750B|
|U19|6|x1.26|$1T|
|U20|1|x2.5|$2,5T|
|U21|2|x1.8|$5T|
|U22|2|x3|$50T|
|U23|2|x2|$100T|
|U24|2|x2.5|$250T|
|U25|1|x4|$500T|
|U26|2|x3.5|$750T|
|U27|1|x4|$1qd|
|U28|$25m|x2.5|$10qd|
|U29|1|x2|$50qd|
|U30|2|x3|$250qd|
|U31|1|x3|$5qn|
|U32|1|x6|$25qn|
|U33|2|x2|$2,5sx|
|U34|2|x2|$100sx|
|U35|2|x4|$1sp|
|U36|1|x4|$5sp|
|U37|1|x3.5|$100sp|
|U38|1|x5|$250o|

### Catálogo de fornalhas

| ID | Multiplicador | Preço |
|---|---:|---:|
|F1|×1|$100|
|F2|×2|$25K|
|F3|×4|$5M|
|F4|×6|$5B|
|F5|×12|$250T|
|F6|×15|$30qd|
|F7|×16|$1qn|
|F8|×20|$250sx|

### Etapas da rota com uma mineradora até 1qd

| Marco de renda | Tempo acumulado | Renda ao cruzar o marco | Cópias de modificadores na linha |
|---|---:|---:|---:|
|$1K/s|5 min 37 s|$2,88K/s|11|
|$1M/s|5 min 51 s|$1,3437M/s|19|
|$1B/s|6 min 25 s|$1,3363B/s|42|
|$1T/s|7 min 30 s|$1,0828T/s|54|
|Saldo disponível de 1qd|7 min 36 s|$144,66qd/s|63|

Mineradoras compradas nessa rota: M1 → M2 → M7.
Fornalhas usadas: ×1 → 2 → ×4 → ×6 → ×12.

### Composição final da linha para 1qd

| Modificador | Cópias físicas | Efeito | Condição |
|---|---:|---|---|
|U1|1|+4|inf|
|U2|1|x2|1|
|U3|7|x2|$250|
|U4|1|x2.5|1|
|U5|1|x1.5|1|
|U6|1|x2|1|
|U7|1|x3.456|1|
|U8|2|x1.5|2|
|U9|1|x1.5|1|
|U10|2|x2|2|
|U11|2|x2.5|2|
|U12|15|x1.25|$10k|
|U13|4|x1.2|4|
|U14|3|x1.5|3|
|U15|1|x3|1|
|U16|2|x2|2|
|U17|1|x3|1|
|U18|1|x1.5|1|
|U19|6|x1.26|6|
|U20|1|x2.5|1|
|U21|2|x1.8|2|
|U22|2|x3|2|
|U23|2|x2|2|
|U24|2|x2.5|2|
|U25|1|x4|1|

### Ordem física de modificadores no final

Uma passagem percorre a ordem abaixo; peças inelegíveis não aplicam efeito. Tipos repetidos representam cópias distintas e pagas.

U3 → U3 → U3 → U3 → U3 → U3 → U3 → U12 → U12 → U12 → U12 → U12 → U12 → U12 → U12 → U12 → U12 → U12 → U12 → U12 → U12 → U12 → U1 → U2 → U4 → U5 → U6 → U7 → U8 → U8 → U9 → U10 → U10 → U11 → U11 → U13 → U13 → U13 → U13 → U14 → U14 → U14 → U15 → U16 → U16 → U17 → U18 → U19 → U19 → U19 → U19 → U19 → U19 → U20 → U21 → U21 → U22 → U22 → U23 → U23 → U24 → U24 → U25

### Compras da rota com uma mineradora até 1qd

Valores de custo de mineradoras e fornalhas já descontam a revenda da anterior. Ao substituir um modificador por falta de espaço, o preço da peça nova é pago integralmente.

| # | Compra | Modificador retirado | Custo | Espera desta compra | Tempo acumulado | Renda após compra | Modificadores na linha |
|---:|---|---|---:|---:|---:|---:|---:|
|1|U1|—|$50|2 min 30 s|2 min 30 s|$1,6667/s|1|
|2|U2|—|$100|1 min 0 s|3 min 30 s|$3,3333/s|2|
|3|U3|—|$200|1 min 0 s|4 min 30 s|$6,6667/s|3|
|4|U3|—|$200|30 s|5 min 0 s|$13,333/s|4|
|5|U3|—|$200|15 s|5 min 15 s|$26,667/s|5|
|6|U3|—|$200|8 s|5 min 23 s|$53,333/s|6|
|7|U3|—|$200|4 s|5 min 26 s|$106,67/s|7|
|8|U3|—|$200|2 s|5 min 28 s|$213,33/s|8|
|9|U3|—|$200|1 s|5 min 29 s|$256/s|9|
|10|U4|—|$1K|4 s|5 min 33 s|$640/s|10|
|11|U5|—|$1K|2 s|5 min 35 s|$960/s|11|
|12|M2|—|$2,38K|2 s|5 min 37 s|$2,88K/s|11|
|13|U7|—|$5K|2 s|5 min 39 s|$9,9533K/s|12|
|14|U6|—|$4K|0 s|5 min 39 s|$19,907K/s|13|
|15|F2|—|$24,9K|1 s|5 min 40 s|$39,813K/s|13|
|16|U8|—|$50K|1 s|5 min 42 s|$59,72K/s|14|
|17|U8|—|$50K|1 s|5 min 42 s|$89,58K/s|15|
|18|U9|—|$125K|1 s|5 min 44 s|$134,37K/s|16|
|19|U10|—|$500K|4 s|5 min 48 s|$268,74K/s|17|
|20|U10|—|$500K|2 s|5 min 49 s|$537,48K/s|18|
|21|U11|—|$1M|2 s|5 min 51 s|$1,3437M/s|19|
|22|U11|—|$1M|1 s|5 min 52 s|$3,3592M/s|20|
|23|F3|—|$4,975M|1 s|5 min 54 s|$6,7185M/s|20|
|24|U12|—|$25M|4 s|5 min 57 s|$8,3981M/s|21|
|25|U12|—|$25M|3 s|6 min 0 s|$10,498M/s|22|
|26|U12|—|$25M|2 s|6 min 3 s|$13,122M/s|23|
|27|U12|—|$25M|2 s|6 min 5 s|$16,402M/s|24|
|28|U12|—|$25M|2 s|6 min 6 s|$20,503M/s|25|
|29|U12|—|$25M|1 s|6 min 7 s|$25,629M/s|26|
|30|U12|—|$25M|1 s|6 min 8 s|$32,036M/s|27|
|31|U12|—|$25M|1 s|6 min 9 s|$40,045M/s|28|
|32|U12|—|$25M|1 s|6 min 10 s|$50,056M/s|29|
|33|U12|—|$25M|0 s|6 min 10 s|$62,571M/s|30|
|34|U12|—|$25M|0 s|6 min 11 s|$78,213M/s|31|
|35|U12|—|$25M|0 s|6 min 11 s|$97,767M/s|32|
|36|U12|—|$25M|0 s|6 min 11 s|$122,21M/s|33|
|37|U12|—|$25M|0 s|6 min 11 s|$152,76M/s|34|
|38|U12|—|$25M|0 s|6 min 12 s|$190,95M/s|35|
|39|U13|—|$500M|3 s|6 min 14 s|$229,14M/s|36|
|40|U13|—|$500M|2 s|6 min 16 s|$274,97M/s|37|
|41|U14|—|$1B|4 s|6 min 20 s|$412,45M/s|38|
|42|U13|—|$500M|1 s|6 min 21 s|$494,94M/s|39|
|43|U13|—|$500M|1 s|6 min 22 s|$593,93M/s|40|
|44|U14|—|$1B|2 s|6 min 24 s|$890,9M/s|41|
|45|U14|—|$1B|1 s|6 min 25 s|$1,3363B/s|42|
|46|U15|—|$5B|4 s|6 min 29 s|$4,009B/s|43|
|47|F4|—|$4,995B|1 s|6 min 30 s|$6,0136B/s|43|
|48|U16|—|$10B|2 s|6 min 32 s|$12,027B/s|44|
|49|U16|—|$10B|1 s|6 min 32 s|$24,054B/s|45|
|50|U17|—|$250B|10 s|6 min 43 s|$72,163B/s|46|
|51|U18|—|$750B|10 s|6 min 53 s|$108,24B/s|47|
|52|U20|—|$2,5T|23 s|7 min 16 s|$270,61B/s|48|
|53|U19|—|$1T|4 s|7 min 20 s|$340,97B/s|49|
|54|U19|—|$1T|3 s|7 min 23 s|$429,62B/s|50|
|55|U19|—|$1T|2 s|7 min 25 s|$541,32B/s|51|
|56|U19|—|$1T|2 s|7 min 27 s|$682,07B/s|52|
|57|U19|—|$1T|1 s|7 min 29 s|$859,4B/s|53|
|58|U19|—|$1T|1 s|7 min 30 s|$1,0828T/s|54|
|59|M7|—|$5T|5 s|7 min 34 s|$24,805T/s|54|
|60|U21|—|$5T|0 s|7 min 35 s|$44,648T/s|55|
|61|U21|—|$5T|0 s|7 min 35 s|$80,367T/s|56|
|62|U22|—|$50T|1 s|7 min 35 s|$241,1T/s|57|
|63|U22|—|$50T|0 s|7 min 36 s|$723,3T/s|58|
|64|U23|—|$100T|0 s|7 min 36 s|$1,4466qd/s|59|
|65|U23|—|$100T|0 s|7 min 36 s|$2,8932qd/s|60|
|66|U24|—|$250T|0 s|7 min 36 s|$7,233qd/s|61|
|67|U24|—|$250T|0 s|7 min 36 s|$18,083qd/s|62|
|68|F5|—|$250T|0 s|7 min 36 s|$36,165qd/s|62|
|69|U25|—|$500T|0 s|7 min 36 s|$144,66qd/s|63|
|—|Acumular o saldo final|—|—|0 s|7 min 36 s|$144,66qd/s|63|

## Mini Miners

M1, M2... e U1, U2... são as posições da tabela do usuário, sem inventar nomes oficiais.

### Catálogo de mineradoras

| ID | Intervalo (s) | Valor do minério | Produção bruta/s | Preço |
|---|---:|---:|---:|---:|
|M1|1|$2|$2|$50|
|M2|0,83|$35|$42,169|$1,5K|
|M3|1|$150|$150|$100K|
|M4|0,67|$500|$746,27|$5M|
|M5|2|$5K|$2,5K|$5B|
|M6|2,5|$25K|$10K|$150B|
|M7|1,25|$100K|$80K|$5T|
|M8|1,33|$500K|$375,94K|$500T|
|M9|0,5|$2,5M|$5M|$25qd|
|M10|1,33|$15M|$11,278M|$1qn|
|M11|1|$50M|$50M|$250qn|
|M12|0,8|$200M|$250M|$50sx|

### Catálogo de modificadores

| ID | Condição original | Efeito original | Preço por cópia |
|---|---|---|---:|
|U1|3 e $100|+10|$100|
|U2|3|x1.75|$750|
|U3|1|x2.5|$5K|
|U4|15 e $1k|x1.3|$10K|
|U5|1|x2.2|$250K|
|U6|1|x2|$1,5M|
|U7|10|x1.1|$2M|
|U8|2|x3.32|$5M|
|U9|7 e $3.5m|x1.75|$20M|
|U10|2|x1.5|$2,5B|
|U11|2|x1.5|$10B|
|U12|1|x1.75|$75B|
|U13|1|x2.46|$500B|
|U14|2|x1.5|$2,5T|
|U15|15 e $500m|x1.3|$10T|
|U16|1|x2|$100T|
|U17|1|random x1~x3|$2,5qd|
|U18|1|x3|$10qd|
|U19|2|x1.75|$50qd|
|U20|1|x1.5|$75qd|
|U21|4|x1.25|$100qd|
|U22|1|x1.95|$2,5qn|
|U23|5|random x0.5~x3.5|$10qn|
|U24|1|x2|$50qn|
|U25|1|x3.6|$1,25sx|
|U26|2|x2|$25sx|

### Catálogo de fornalhas

| ID | Multiplicador | Preço |
|---|---:|---:|
|F1|×1|$100|
|F2|×2|$2,5K|
|F3|×3,5|$500K|
|F4|×7,5|$250M|
|F5|×25|$50B|
|F6|×50|$1T|
|F7|×75|$200T|
|F8|×250|$5qd|
|F9|×400|$2,5qn|
|F10|×600|$5sx|

### Etapas da rota com uma mineradora até 1qd

| Marco de renda | Tempo acumulado | Renda ao cruzar o marco | Cópias de modificadores na linha |
|---|---:|---:|---:|
|$1K/s|2 min 7 s|$2,0986K/s|7|
|$1M/s|3 min 12 s|$3,192M/s|22|
|$1B/s|3 min 23 s|$1,0417B/s|39|
|$1T/s|3 min 55 s|$7,3854T/s|45|
|Saldo disponível de 1qd|3 min 59 s|$2,5517qd/s|63|

Mineradoras compradas nessa rota: M1 → M2 → M4 → M5 → M6 → M7.
Fornalhas usadas: ×1 → 2 → ×3,5 → ×7,5 → ×25 → ×50 → ×75.

### Composição final da linha para 1qd

| Modificador | Cópias físicas | Efeito | Condição |
|---|---:|---|---|
|U1|3|+10|3 e $100|
|U2|3|x1.75|3|
|U3|1|x2.5|1|
|U4|11|x1.3|15 e $1k|
|U5|1|x2.2|1|
|U6|1|x2|1|
|U7|10|x1.1|10|
|U8|2|x3.32|2|
|U9|7|x1.75|7 e $3.5m|
|U10|2|x1.5|2|
|U11|2|x1.5|2|
|U12|1|x1.75|1|
|U13|1|x2.46|1|
|U14|2|x1.5|2|
|U15|15|x1.3|15 e $500m|
|U16|1|x2|1|

### Ordem física de modificadores no final

Uma passagem percorre a ordem abaixo; peças inelegíveis não aplicam efeito. Tipos repetidos representam cópias distintas e pagas.

U1 → U1 → U1 → U4 → U4 → U4 → U4 → U4 → U4 → U4 → U4 → U4 → U4 → U4 → U9 → U9 → U9 → U9 → U9 → U9 → U9 → U15 → U15 → U15 → U15 → U15 → U15 → U15 → U15 → U15 → U15 → U15 → U15 → U15 → U15 → U15 → U2 → U2 → U2 → U3 → U5 → U6 → U7 → U7 → U7 → U7 → U7 → U7 → U7 → U7 → U7 → U7 → U8 → U8 → U10 → U10 → U11 → U11 → U12 → U13 → U14 → U14 → U16

### Compras da rota com uma mineradora até 1qd

Valores de custo de mineradoras e fornalhas já descontam a revenda da anterior. Ao substituir um modificador por falta de espaço, o preço da peça nova é pago integralmente.

| # | Compra | Modificador retirado | Custo | Espera desta compra | Tempo acumulado | Renda após compra | Modificadores na linha |
|---:|---|---|---:|---:|---:|---:|---:|
|1|U1|—|$100|50 s|50 s|$12/s|1|
|2|U1|—|$100|8 s|58 s|$22/s|2|
|3|U1|—|$100|5 s|1 min 3 s|$32/s|3|
|4|U2|—|$750|23 s|1 min 26 s|$56/s|4|
|5|U2|—|$750|13 s|1 min 40 s|$98/s|5|
|6|U2|—|$750|8 s|1 min 47 s|$171,5/s|6|
|7|M2|—|$1,45K|8 s|1 min 56 s|$419,71/s|6|
|8|F2|—|$2,4K|6 s|2 min 2 s|$839,42/s|6|
|9|U3|—|$5K|6 s|2 min 7 s|$2,0986K/s|7|
|10|U4|—|$10K|5 s|2 min 12 s|$2,7281K/s|8|
|11|U4|—|$10K|4 s|2 min 16 s|$3,5466K/s|9|
|12|U4|—|$10K|3 s|2 min 19 s|$4,6105K/s|10|
|13|U4|—|$10K|2 s|2 min 21 s|$5,9937K/s|11|
|14|U4|—|$10K|2 s|2 min 23 s|$7,7918K/s|12|
|15|U4|—|$10K|1 s|2 min 24 s|$10,129K/s|13|
|16|U4|—|$10K|1 s|2 min 25 s|$13,168K/s|14|
|17|U4|—|$10K|1 s|2 min 26 s|$17,119K/s|15|
|18|U4|—|$10K|1 s|2 min 26 s|$22,254K/s|16|
|19|U4|—|$10K|0 s|2 min 27 s|$28,93K/s|17|
|20|U4|—|$10K|0 s|2 min 27 s|$37,609K/s|18|
|21|U5|—|$250K|7 s|2 min 34 s|$82,741K/s|19|
|22|F3|—|$497,5K|6 s|2 min 40 s|$144,8K/s|19|
|23|U6|—|$1,5M|10 s|2 min 50 s|$289,59K/s|20|
|24|U8|—|$5M|17 s|3 min 7 s|$961,45K/s|21|
|25|U8|—|$5M|5 s|3 min 12 s|$3,192M/s|22|
|26|U7|—|$2M|1 s|3 min 13 s|$3,5112M/s|23|
|27|U7|—|$2M|1 s|3 min 14 s|$3,8623M/s|24|
|28|U7|—|$2M|1 s|3 min 14 s|$4,2486M/s|25|
|29|U7|—|$2M|0 s|3 min 15 s|$4,6734M/s|26|
|30|U7|—|$2M|0 s|3 min 15 s|$5,1408M/s|27|
|31|U7|—|$2M|0 s|3 min 15 s|$5,6548M/s|28|
|32|U7|—|$2M|0 s|3 min 16 s|$6,2203M/s|29|
|33|U7|—|$2M|0 s|3 min 16 s|$6,8423M/s|30|
|34|U7|—|$2M|0 s|3 min 16 s|$7,5266M/s|31|
|35|U7|—|$2M|0 s|3 min 17 s|$8,2792M/s|32|
|36|M4|—|$4,9985M|1 s|3 min 17 s|$9,6717M/s|32|
|37|U9|—|$20M|2 s|3 min 19 s|$16,925M/s|33|
|38|U9|—|$20M|1 s|3 min 21 s|$29,62M/s|34|
|39|U9|—|$20M|1 s|3 min 21 s|$51,834M/s|35|
|40|U9|—|$20M|0 s|3 min 22 s|$90,71M/s|36|
|41|U9|—|$20M|0 s|3 min 22 s|$158,74M/s|37|
|42|U9|—|$20M|0 s|3 min 22 s|$277,8M/s|38|
|43|U9|—|$20M|0 s|3 min 22 s|$486,15M/s|39|
|44|F4|—|$249,5M|1 s|3 min 23 s|$1,0417B/s|39|
|45|U10|—|$2,5B|2 s|3 min 25 s|$1,5626B/s|40|
|46|U10|—|$2,5B|2 s|3 min 27 s|$2,3439B/s|41|
|47|M5|—|$4,995B|2 s|3 min 29 s|$3,574B/s|41|
|48|U11|—|$10B|3 s|3 min 31 s|$5,3611B/s|42|
|49|U11|—|$10B|2 s|3 min 33 s|$8,0416B/s|43|
|50|F5|—|$49,75B|6 s|3 min 40 s|$26,805B/s|43|
|51|U12|—|$75B|3 s|3 min 42 s|$46,909B/s|44|
|52|M6|—|$145B|3 s|3 min 45 s|$187,64B/s|44|
|53|U13|—|$500B|3 s|3 min 48 s|$461,59B/s|45|
|54|F6|—|$950B|2 s|3 min 50 s|$923,18B/s|45|
|55|M7|—|$4,85T|5 s|3 min 55 s|$7,3854T/s|45|
|56|U14|—|$2,5T|0 s|3 min 56 s|$11,078T/s|46|
|57|U14|—|$2,5T|0 s|3 min 56 s|$16,617T/s|47|
|58|U15|—|$10T|1 s|3 min 57 s|$21,602T/s|48|
|59|U15|—|$10T|0 s|3 min 57 s|$28,083T/s|49|
|60|U15|—|$10T|0 s|3 min 57 s|$36,508T/s|50|
|61|U15|—|$10T|0 s|3 min 58 s|$47,46T/s|51|
|62|U15|—|$10T|0 s|3 min 58 s|$61,698T/s|52|
|63|U15|—|$10T|0 s|3 min 58 s|$80,208T/s|53|
|64|U15|—|$10T|0 s|3 min 58 s|$104,27T/s|54|
|65|U15|—|$10T|0 s|3 min 58 s|$135,55T/s|55|
|66|U15|—|$10T|0 s|3 min 58 s|$176,22T/s|56|
|67|U15|—|$10T|0 s|3 min 58 s|$229,08T/s|57|
|68|U15|—|$10T|0 s|3 min 58 s|$297,81T/s|58|
|69|U15|—|$10T|0 s|3 min 58 s|$387,15T/s|59|
|70|U15|—|$10T|0 s|3 min 58 s|$503,29T/s|60|
|71|U15|—|$10T|0 s|3 min 59 s|$654,28T/s|61|
|72|U15|—|$10T|0 s|3 min 59 s|$850,56T/s|62|
|73|U16|—|$100T|0 s|3 min 59 s|$1,7011qd/s|63|
|74|F7|—|$199T|0 s|3 min 59 s|$2,5517qd/s|63|
|—|Acumular o saldo final|—|—|0 s|3 min 59 s|$2,5517qd/s|63|

## Project Exodus

M1, M2... e U1, U2... são as posições da tabela do usuário, sem inventar nomes oficiais.

### Catálogo de mineradoras

| ID | Intervalo (s) | Valor do minério | Produção bruta/s | Preço |
|---|---:|---:|---:|---:|
|M1|0,7|$15|$21,429|$2K|
|M2|1,5|$100|$66,667|$100K|
|M3|2|$400|$200|$1M|
|M4|1,6|$1K|$625|$75M|
|M5|1,3|$3,7K|$2,8462K|$250M|
|M6|0,4|$5K|$12,5K|$175B|
|M7|1|$10K|$10K|$1T|
|M8|1|$40K|$40K|$175T|
|M9|0,6|$250K|$416,67K|$200qd|

### Catálogo de modificadores

| ID | Condição original | Efeito original | Preço por cópia |
|---|---|---|---:|
|U1|inf|+5|$25|
|U2|$200|x1.5|$100|
|U3|3 e $20m|x1,95|$2K|
|U4|$1k~$5k|x1.4|$25K|
|U5|$10k|x1.3|$200K|
|U6|$10k~$25k|x1.65|$200K|
|U7|12|x1.05|$2,5M|
|U8|$10k~$85k|x1.44|$10M|
|U9|1|x1.25|$50M|
|U10|$85k~$165k|x1.1|$300M|
|U11|2|x1.5|$650M|
|U12|1|x3|$800M|
|U13|$10k~$350k|x1.77|$1B|
|U14|1|5x|$5B|
|U15|$350k~$2.5m|x1.5|$10B|
|U16|$350k~$2.5m|x1.5|$10B|
|U17|1|x2|$50B|
|U18|2|x1.28|$100B|
|U19|3|x1.3|$450B|
|U20|$2m~$250m|x1.8|$1T|
|U21|1|x6|$10T|
|U22|1|x1.5|$500T|
|U23|$75m~$5b|x1.9|$2qd|
|U24|2|x1.5|$7,5qd|
|U25|1|x3.5|$50qd|
|U26|$125m~$800b|x2.6|$1qn|
|U27|2|x2|$75qn|
|U28|3 e $1qd~$50qn|x2.4|$200qn|
|U29|$500b|x3|$750qn|
|U30|$500b~$1qd|x4.5|$750qn|
|U31|1|x5|$5sx|

### Catálogo de fornalhas

| ID | Multiplicador | Preço |
|---|---:|---:|
|F1|×1|$0|
|F2|×1,5|$50K|
|F3|×3|$250M|
|F4|×6|$150B|
|F5|×12|$100T|

### Etapas da rota com uma mineradora até 1qd

| Marco de renda | Tempo acumulado | Renda ao cruzar o marco | Cópias de modificadores na linha |
|---|---:|---:|---:|
|$1K/s|20 s|$1,2375K/s|9|
|$1M/s|17 min 45 s|$1,7828M/s|34|
|$1B/s|32 min 44 s|$1,3295B/s|44|
|$1T/s|35 min 9 s|$1,7021T/s|56|
|Saldo disponível de 1qd|35 min 46 s|$36,765T/s|58|

Mineradoras compradas nessa rota: M1 → M4 → M5 → M6.
Fornalhas usadas: ×1 → 1,5 → ×3 → ×6 → ×12.

### Composição final da linha para 1qd

| Modificador | Cópias físicas | Efeito | Condição |
|---|---:|---|---|
|U1|1|+5|inf|
|U2|6|x1.5|$200|
|U3|3|x1,95|3 e $20m|
|U4|5|x1.4|$1k~$5k|
|U5|1|x1.3|$10k|
|U6|2|x1.65|$10k~$25k|
|U7|12|x1.05|12|
|U8|3|x1.44|$10k~$85k|
|U9|1|x1.25|1|
|U11|2|x1.5|2|
|U12|1|x3|1|
|U13|3|x1.77|$10k~$350k|
|U14|1|5x|1|
|U15|4|x1.5|$350k~$2.5m|
|U17|1|x2|1|
|U18|2|x1.28|2|
|U19|3|x1.3|3|
|U20|6|x1.8|$2m~$250m|
|U21|1|x6|1|

### Ordem física de modificadores no final

Uma passagem percorre a ordem abaixo; peças inelegíveis não aplicam efeito. Tipos repetidos representam cópias distintas e pagas.

U2 → U2 → U2 → U2 → U2 → U2 → U4 → U4 → U4 → U4 → U4 → U1 → U5 → U3 → U6 → U6 → U8 → U8 → U8 → U13 → U13 → U13 → U15 → U15 → U15 → U15 → U3 → U3 → U20 → U20 → U20 → U20 → U20 → U20 → U7 → U7 → U7 → U7 → U7 → U7 → U7 → U7 → U7 → U7 → U7 → U7 → U9 → U11 → U11 → U12 → U14 → U17 → U18 → U18 → U19 → U19 → U19 → U21

### Compras da rota com uma mineradora até 1qd

Valores de custo de mineradoras e fornalhas já descontam a revenda da anterior. Ao substituir um modificador por falta de espaço, o preço da peça nova é pago integralmente.

| # | Compra | Modificador retirado | Custo | Espera desta compra | Tempo acumulado | Renda após compra | Modificadores na linha |
|---:|---|---|---:|---:|---:|---:|---:|
|1|U1|—|$25|1 s|1 s|$28,571/s|1|
|2|U2|—|$100|4 s|5 s|$42,857/s|2|
|3|U2|—|$100|2 s|7 s|$64,286/s|3|
|4|U2|—|$100|2 s|9 s|$96,429/s|4|
|5|U2|—|$100|1 s|10 s|$144,64/s|5|
|6|U2|—|$100|1 s|10 s|$216,96/s|6|
|7|U2|—|$100|0 s|11 s|$325,45/s|7|
|8|U3|—|$2K|6 s|17 s|$634,62/s|8|
|9|U3|—|$2K|3 s|20 s|$1,2375K/s|9|
|10|U3|—|$2K|2 s|22 s|$2,4131K/s|10|
|11|U4|—|$25K|10 s|32 s|$3,3784K/s|11|
|12|U4|—|$25K|7 s|39 s|$4,7298K/s|12|
|13|U4|—|$25K|5 s|45 s|$6,6217K/s|13|
|14|U4|—|$25K|4 s|48 s|$9,2703K/s|14|
|15|F2|—|$50K|5 s|54 s|$13,906K/s|14|
|16|U5|—|$200K|14 s|1 min 8 s|$18,077K/s|15|
|17|U4|—|$25K|1 s|1 min 10 s|$25,308K/s|16|
|18|U6|—|$200K|8 s|1 min 18 s|$41,758K/s|17|
|19|U6|—|$200K|5 s|1 min 22 s|$68,901K/s|18|
|20|U8|—|$10M|2 min 25 s|3 min 47 s|$99,218K/s|19|
|21|U8|—|$10M|1 min 41 s|5 min 28 s|$142,87K/s|20|
|22|U8|—|$10M|1 min 10 s|6 min 38 s|$205,74K/s|21|
|23|U7|—|$2,5M|12 s|6 min 50 s|$216,02K/s|22|
|24|U7|—|$2,5M|12 s|7 min 2 s|$226,83K/s|23|
|25|U7|—|$2,5M|11 s|7 min 13 s|$238,17K/s|24|
|26|U7|—|$2,5M|10 s|7 min 23 s|$250,08K/s|25|
|27|U7|—|$2,5M|10 s|7 min 33 s|$262,58K/s|26|
|28|U7|—|$2,5M|10 s|7 min 43 s|$275,71K/s|27|
|29|U7|—|$2,5M|9 s|7 min 52 s|$289,49K/s|28|
|30|U7|—|$2,5M|9 s|8 min 1 s|$303,97K/s|29|
|31|U7|—|$2,5M|8 s|8 min 9 s|$319,17K/s|30|
|32|U7|—|$2,5M|8 s|8 min 17 s|$335,12K/s|31|
|33|U7|—|$2,5M|7 s|8 min 24 s|$351,88K/s|32|
|34|U7|—|$2,5M|7 s|8 min 31 s|$369,48K/s|33|
|35|M4|—|$74,998M|3 min 23 s|11 min 54 s|$713,1K/s|33|
|36|U9|—|$50M|1 min 10 s|13 min 4 s|$891,38K/s|34|
|37|F3|—|$249,95M|4 min 40 s|17 min 45 s|$1,7828M/s|34|
|38|M5|—|$175M|1 min 38 s|19 min 23 s|$2,1048M/s|34|
|39|U12|—|$800M|6 min 20 s|25 min 43 s|$6,3144M/s|35|
|40|U11|—|$650M|1 min 43 s|27 min 26 s|$9,4716M/s|36|
|41|U11|—|$650M|1 min 9 s|28 min 35 s|$14,207M/s|37|
|42|U13|—|$1B|1 min 10 s|29 min 45 s|$25,147M/s|38|
|43|U13|—|$1B|40 s|30 min 25 s|$44,51M/s|39|
|44|U13|—|$1B|22 s|30 min 47 s|$78,783M/s|40|
|45|U14|—|$5B|1 min 3 s|31 min 51 s|$393,92M/s|41|
|46|U15|—|$10B|25 s|32 min 16 s|$590,88M/s|42|
|47|U15|—|$10B|17 s|32 min 33 s|$886,31M/s|43|
|48|U15|—|$10B|11 s|32 min 44 s|$1,3295B/s|44|
|49|U15|—|$10B|8 s|32 min 52 s|$1,9942B/s|45|
|50|U17|—|$50B|25 s|33 min 17 s|$3,9884B/s|46|
|51|M6|—|$174,75B|44 s|34 min 1 s|$12,512B/s|46|
|52|F4|—|$149,75B|12 s|34 min 13 s|$25,025B/s|46|
|53|U18|—|$100B|4 s|34 min 17 s|$32,032B/s|47|
|54|U18|—|$100B|3 s|34 min 20 s|$41B/s|48|
|55|U19|—|$450B|11 s|34 min 31 s|$53,301B/s|49|
|56|U19|—|$450B|8 s|34 min 39 s|$69,291B/s|50|
|57|U19|—|$450B|6 s|34 min 46 s|$90,078B/s|51|
|58|U20|—|$1T|11 s|34 min 57 s|$162,14B/s|52|
|59|U20|—|$1T|6 s|35 min 3 s|$291,85B/s|53|
|60|U20|—|$1T|3 s|35 min 6 s|$525,33B/s|54|
|61|U20|—|$1T|2 s|35 min 8 s|$945,6B/s|55|
|62|U20|—|$1T|1 s|35 min 9 s|$1,7021T/s|56|
|63|U20|—|$1T|1 s|35 min 10 s|$3,0637T/s|57|
|64|U21|—|$10T|3 s|35 min 13 s|$18,382T/s|58|
|65|F5|—|$99,85T|5 s|35 min 19 s|$36,765T/s|58|
|—|Acumular o saldo final|—|—|27 s|35 min 46 s|$36,765T/s|58|

## Reincarnated

M1, M2... e U1, U2... são as posições da tabela do usuário, sem inventar nomes oficiais.

### Catálogo de mineradoras

| ID | Intervalo (s) | Valor do minério | Produção bruta/s | Preço |
|---|---:|---:|---:|---:|
|M1|1|$2|$2|$50|
|M2|1,5|$15|$10|$75K|
|M3|2|$40|$20|$10M|
|M4|1,25|$85|$68|$2,5B|
|M5|2|$180|$90|$50B|
|M6|1,25|$500|$400|$400T|
|M7|1,5|$1K|$666,67|$1qn|
|M8|2|$5K|$2,5K|$4sx|
|M9|1|$25K|$25K|$5sp|
|M10|1|$200K|$200K|$1,25n|
|M11|1|$500K|$500K|$7,5de|

### Catálogo de modificadores

| ID | Condição original | Efeito original | Preço por cópia |
|---|---|---|---:|
|U1|4|+2|$150|
|U2|3|x1.3|$1,25K|
|U3|2|x1.5|$7,75K|
|U4|2|x1.15|$15K|
|U5|2|x1.15|$15K|
|U6|16|x1.07|$27,5K|
|U7|1|x1.25|$50K|
|U8|3|+5|$125K|
|U9|2|x2|$625K|
|U10|$1k|x1.09|$5M|
|U11|4|x1.5|$20M|
|U12|1|x1.8|$200M|
|U13|1|x3|$650M|
|U14|3|x1.65|$1,85B|
|U15|2|x2|$30B|
|U16|$5k|x1.07|$60B|
|U17|4|x1.4|$200B|
|U18|1|x2|$900B|
|U19|2|x2|$2T|
|U20|16|x1.1|$8T|
|U21|3|x1.5|$20T|
|U22|6|x1.3|$100T|
|U23|$3k~$20k|x1.43|$500T|
|U24|8|x1.35|$2,5qd|
|U25|1|x3|$12,5qd|
|U26|$18k~$160k|x2|$200qd|
|U27|3|x2|$2qn|
|U28|1|x3|$10qn|
|U29|3|x2.25|$250qn|
|U30|$158k~$3.25m|x1.04|$10sx|
|U31|2|x1.75|$1sp|
|U32|3|x2.5|$95sp|
|U33|1|x3|$1,75o|
|U34|$3.25m~$26m|x2|$6o|
|U35|5|x1.25|$180o|
|U36|10|x1.2|$5n|
|U37|1|x3|$225n|
|U38|3|x1.75|$1,45de|
|U39|$26m~$2.5b|x1.1|$6de|
|U40|$2.5b~$1.56t|x5|$1,2ude|

### Catálogo de fornalhas

| ID | Multiplicador | Preço |
|---|---:|---:|
|F1|×1|$50|
|F2|×2|$25K|
|F3|×3|$150M|
|F4|×5|$7,5B|
|F5|×6,5|$350B|
|F6|×8|$4T|
|F7|×12|$25qd|
|F8|×25|$750qn|
|F9|×37,5|$80sp|
|F10|×60|$20n|
|F11|×75|$100de|

### Etapas da rota com uma mineradora até 1qd

| Marco de renda | Tempo acumulado | Renda ao cruzar o marco | Cópias de modificadores na linha |
|---|---:|---:|---:|
|$1K/s|1 h 0 min|$1,1911K/s|31|
|$1M/s|3 h 52 min|$1,1973M/s|64|
|$1B/s|5 h 57 min|$1,4095B/s|64|
|$1T/s|Não alcançado antes da meta|—|—|
|Saldo disponível de 1qd|18 h 3 min|$339,51B/s|64|

Mineradoras compradas nessa rota: M1 → M2 → M3 → M4 → M5 → M6.
Fornalhas usadas: ×1 → 2 → ×3 → ×5 → ×6,5 → ×8.

### Composição final da linha para 1qd

| Modificador | Cópias físicas | Efeito | Condição |
|---|---:|---|---|
|U2|3|x1.3|3|
|U3|2|x1.5|2|
|U4|2|x1.15|2|
|U5|2|x1.15|2|
|U7|1|x1.25|1|
|U9|2|x2|2|
|U10|9|x1.09|$1k|
|U11|4|x1.5|4|
|U12|1|x1.8|1|
|U13|1|x3|1|
|U14|3|x1.65|3|
|U15|2|x2|2|
|U17|4|x1.4|4|
|U18|1|x2|1|
|U19|2|x2|2|
|U20|16|x1.1|16|
|U21|3|x1.5|3|
|U22|6|x1.3|6|

### Ordem física de modificadores no final

Uma passagem percorre a ordem abaixo; peças inelegíveis não aplicam efeito. Tipos repetidos representam cópias distintas e pagas.

U10 → U10 → U10 → U10 → U10 → U10 → U10 → U10 → U10 → U2 → U2 → U2 → U3 → U3 → U4 → U4 → U5 → U5 → U7 → U9 → U9 → U11 → U11 → U11 → U11 → U12 → U13 → U14 → U14 → U14 → U15 → U15 → U17 → U17 → U17 → U17 → U18 → U19 → U19 → U20 → U20 → U20 → U20 → U20 → U20 → U20 → U20 → U20 → U20 → U20 → U20 → U20 → U20 → U20 → U20 → U21 → U21 → U21 → U22 → U22 → U22 → U22 → U22 → U22

### Compras da rota com uma mineradora até 1qd

Valores de custo de mineradoras e fornalhas já descontam a revenda da anterior. Ao substituir um modificador por falta de espaço, o preço da peça nova é pago integralmente.

| # | Compra | Modificador retirado | Custo | Espera desta compra | Tempo acumulado | Renda após compra | Modificadores na linha |
|---:|---|---|---:|---:|---:|---:|---:|
|1|U1|—|$150|1 min 15 s|1 min 15 s|$4/s|1|
|2|U1|—|$150|38 s|1 min 53 s|$6/s|2|
|3|U1|—|$150|25 s|2 min 18 s|$8/s|3|
|4|U1|—|$150|19 s|2 min 36 s|$10/s|4|
|5|U2|—|$1,25K|2 min 5 s|4 min 41 s|$13/s|5|
|6|U2|—|$1,25K|1 min 36 s|6 min 17 s|$16,9/s|6|
|7|U2|—|$1,25K|1 min 14 s|7 min 31 s|$21,97/s|7|
|8|U3|—|$7,75K|5 min 53 s|13 min 24 s|$32,955/s|8|
|9|U3|—|$7,75K|3 min 55 s|17 min 19 s|$49,433/s|9|
|10|F2|—|$24,95K|8 min 25 s|25 min 44 s|$98,865/s|9|
|11|U4|—|$15K|2 min 32 s|28 min 16 s|$113,69/s|10|
|12|U4|—|$15K|2 min 12 s|30 min 28 s|$130,75/s|11|
|13|U5|—|$15K|1 min 55 s|32 min 22 s|$150,36/s|12|
|14|U5|—|$15K|1 min 40 s|34 min 2 s|$172,92/s|13|
|15|M2|—|$74,95K|7 min 13 s|41 min 16 s|$265,14/s|13|
|16|U7|—|$50K|3 min 9 s|44 min 24 s|$331,42/s|14|
|17|U6|—|$27,5K|1 min 23 s|45 min 47 s|$354,62/s|15|
|18|U6|—|$27,5K|1 min 18 s|47 min 5 s|$379,44/s|16|
|19|U6|—|$27,5K|1 min 12 s|48 min 17 s|$406,01/s|17|
|20|U6|—|$27,5K|1 min 8 s|49 min 25 s|$434,43/s|18|
|21|U6|—|$27,5K|1 min 3 s|50 min 28 s|$464,84/s|19|
|22|U6|—|$27,5K|59 s|51 min 27 s|$497,37/s|20|
|23|U6|—|$27,5K|55 s|52 min 23 s|$532,19/s|21|
|24|U6|—|$27,5K|52 s|53 min 14 s|$569,44/s|22|
|25|U6|—|$27,5K|48 s|54 min 3 s|$609,3/s|23|
|26|U6|—|$27,5K|45 s|54 min 48 s|$651,96/s|24|
|27|U6|—|$27,5K|42 s|55 min 30 s|$697,59/s|25|
|28|U6|—|$27,5K|39 s|56 min 9 s|$746,42/s|26|
|29|U6|—|$27,5K|37 s|56 min 46 s|$798,67/s|27|
|30|U6|—|$27,5K|34 s|57 min 21 s|$854,58/s|28|
|31|U6|—|$27,5K|32 s|57 min 53 s|$914,4/s|29|
|32|U6|—|$27,5K|30 s|58 min 23 s|$978,41/s|30|
|33|U8|—|$125K|2 min 8 s|1 h 0 min|$1,1911K/s|31|
|34|U8|—|$125K|1 min 45 s|1 h 2 min|$1,4038K/s|32|
|35|U8|—|$125K|1 min 29 s|1 h 3 min|$1,6165K/s|33|
|36|U9|—|$625K|6 min 27 s|1 h 10 min|$3,233K/s|34|
|37|U9|—|$625K|3 min 13 s|1 h 13 min|$6,466K/s|35|
|38|M3|—|$9,925M|25 min 35 s|1 h 39 min|$8,04K/s|35|
|39|U11|—|$20M|41 min 28 s|2 h 20 min|$12,06K/s|36|
|40|U11|—|$20M|27 min 38 s|2 h 48 min|$18,09K/s|37|
|41|U11|—|$20M|18 min 26 s|3 h 6 min|$27,135K/s|38|
|42|U11|—|$20M|12 min 17 s|3 h 18 min|$40,702K/s|39|
|43|U10|—|$5M|2 min 3 s|3 h 20 min|$44,366K/s|40|
|44|U10|—|$5M|1 min 53 s|3 h 22 min|$48,359K/s|41|
|45|U10|—|$5M|1 min 43 s|3 h 24 min|$52,711K/s|42|
|46|U10|—|$5M|1 min 35 s|3 h 26 min|$57,455K/s|43|
|47|U10|—|$5M|1 min 27 s|3 h 27 min|$62,626K/s|44|
|48|U10|—|$5M|1 min 20 s|3 h 28 min|$68,262K/s|45|
|49|U10|—|$5M|1 min 13 s|3 h 30 min|$74,406K/s|46|
|50|U10|—|$5M|1 min 7 s|3 h 31 min|$81,102K/s|47|
|51|U10|—|$5M|1 min 2 s|3 h 32 min|$88,401K/s|48|
|52|U10|—|$5M|57 s|3 h 33 min|$96,357K/s|49|
|53|U10|—|$5M|52 s|3 h 33 min|$105,03K/s|50|
|54|U10|—|$5M|48 s|3 h 34 min|$114,48K/s|51|
|55|U10|—|$5M|44 s|3 h 35 min|$124,79K/s|52|
|56|U10|—|$5M|40 s|3 h 36 min|$136,02K/s|53|
|57|U10|—|$5M|37 s|3 h 36 min|$148,26K/s|54|
|58|U10|—|$5M|34 s|3 h 37 min|$161,6K/s|55|
|59|U10|—|$5M|31 s|3 h 37 min|$176,15K/s|56|
|60|U10|—|$5M|28 s|3 h 38 min|$192K/s|57|
|61|U10|—|$5M|26 s|3 h 38 min|$209,28K/s|58|
|62|U10|—|$5M|24 s|3 h 39 min|$228,11K/s|59|
|63|U10|—|$5M|22 s|3 h 39 min|$248,64K/s|60|
|64|U10|—|$5M|20 s|3 h 39 min|$271,02K/s|61|
|65|U10|—|$5M|18 s|3 h 40 min|$295,41K/s|62|
|66|U10|—|$5M|17 s|3 h 40 min|$322K/s|63|
|67|U10|—|$5M|16 s|3 h 40 min|$350,98K/s|64|
|68|U10|U1|$5M|14 s|3 h 40 min|$370,42K/s|64|
|69|U10|U1|$5M|13 s|3 h 41 min|$390,52K/s|64|
|70|U10|U1|$5M|13 s|3 h 41 min|$411,24K/s|64|
|71|U10|U1|$5M|12 s|3 h 41 min|$432,52K/s|64|
|72|U10|U6|$5M|12 s|3 h 41 min|$440,61K/s|64|
|73|U10|U6|$5M|11 s|3 h 41 min|$448,84K/s|64|
|74|U10|U6|$5M|11 s|3 h 42 min|$457,23K/s|64|
|75|U10|U6|$5M|11 s|3 h 42 min|$465,78K/s|64|
|76|U10|U6|$5M|11 s|3 h 42 min|$474,49K/s|64|
|77|F3|—|$149,97M|5 min 16 s|3 h 47 min|$711,73K/s|64|
|78|U12|U6|$200M|4 min 41 s|3 h 52 min|$1,1973M/s|64|
|79|U13|U6|$650M|9 min 3 s|4 h 1 min|$3,3569M/s|64|
|80|U14|U6|$1,85B|9 min 11 s|4 h 10 min|$5,1766M/s|64|
|81|U14|U6|$1,85B|5 min 57 s|4 h 16 min|$7,9826M/s|64|
|82|U14|U6|$1,85B|3 min 52 s|4 h 20 min|$12,31M/s|64|
|83|M4|—|$2,49B|3 min 22 s|4 h 23 min|$19,901M/s|64|
|84|U1|U10|$150|0 s|4 h 23 min|$20,314M/s|64|
|85|U1|U10|$150|0 s|4 h 23 min|$20,786M/s|64|
|86|U6|U1|$27,5K|0 s|4 h 23 min|$21,944M/s|64|
|87|U6|U10|$27,5K|0 s|4 h 23 min|$23,723M/s|64|
|88|U6|U1|$27,5K|0 s|4 h 23 min|$25,013M/s|64|
|89|U6|U10|$27,5K|0 s|4 h 23 min|$27,032M/s|64|
|90|U6|U8|$27,5K|0 s|4 h 23 min|$27,976M/s|64|
|91|U1|U10|$150|0 s|4 h 23 min|$28,752M/s|64|
|92|U6|U10|$27,5K|0 s|4 h 23 min|$31,082M/s|64|
|93|U6|U1|$27,5K|0 s|4 h 23 min|$32,572M/s|64|
|94|U6|U8|$27,5K|0 s|4 h 23 min|$33,018M/s|64|
|95|U6|U8|$27,5K|0 s|4 h 23 min|$33,367M/s|64|
|96|U10|U6|$5M|0 s|4 h 23 min|$33,99M/s|64|
|97|F4|—|$7,35B|3 min 36 s|4 h 27 min|$56,651M/s|64|
|98|U15|U6|$30B|8 min 50 s|4 h 36 min|$105,89M/s|64|
|99|U15|U6|$30B|4 min 43 s|4 h 41 min|$197,92M/s|64|
|100|U17|U6|$200B|16 min 50 s|4 h 57 min|$258,97M/s|64|
|101|U17|U6|$200B|12 min 52 s|5 h 10 min|$338,83M/s|64|
|102|U17|U6|$200B|9 min 50 s|5 h 20 min|$443,33M/s|64|
|103|U17|U6|$200B|7 min 31 s|5 h 28 min|$580,06M/s|64|
|104|F5|—|$342,5B|9 min 50 s|5 h 37 min|$754,08M/s|64|
|105|U18|U6|$900B|19 min 54 s|5 h 57 min|$1,4095B/s|64|
|106|U19|U6|$2T|23 min 39 s|6 h 21 min|$2,6346B/s|64|
|107|U19|U6|$2T|12 min 39 s|6 h 34 min|$4,9244B/s|64|
|108|F6|—|$3,65T|12 min 21 s|6 h 46 min|$6,0608B/s|64|
|109|U21|U6|$20T|55 min 0 s|7 h 41 min|$8,4965B/s|64|
|110|U21|U6|$20T|39 min 14 s|8 h 20 min|$11,911B/s|64|
|111|U21|U6|$20T|27 min 59 s|8 h 48 min|$16,698B/s|64|
|112|U20|U6|$8T|7 min 59 s|8 h 56 min|$17,166B/s|64|
|113|U20|U6|$8T|7 min 46 s|9 h 4 min|$17,647B/s|64|
|114|U22|U10|$100T|1 h 34 min|10 h 38 min|$21,047B/s|64|
|115|U22|U10|$100T|1 h 19 min|11 h 58 min|$25,102B/s|64|
|116|U22|U10|$100T|1 h 6 min|13 h 4 min|$29,938B/s|64|
|117|U22|U10|$100T|55 min 40 s|14 h 0 min|$35,706B/s|64|
|118|U22|U10|$100T|46 min 41 s|14 h 46 min|$42,585B/s|64|
|119|U22|U10|$100T|39 min 8 s|15 h 26 min|$50,79B/s|64|
|120|M5|—|$47,5B|1 s|15 h 26 min|$51,907B/s|64|
|121|U1|U10|$150|0 s|15 h 26 min|$52,393B/s|64|
|122|U1|U10|$150|0 s|15 h 26 min|$52,966B/s|64|
|123|U1|U10|$150|0 s|15 h 26 min|$53,638B/s|64|
|124|U6|U1|$27,5K|0 s|15 h 26 min|$56,775B/s|64|
|125|U6|U1|$27,5K|0 s|15 h 26 min|$60,089B/s|64|
|126|U6|U1|$27,5K|0 s|15 h 26 min|$63,589B/s|64|
|127|U20|U6|$8T|2 min 6 s|15 h 28 min|$65,372B/s|64|
|128|U20|U6|$8T|2 min 2 s|15 h 30 min|$67,204B/s|64|
|129|U20|U6|$8T|1 min 59 s|15 h 32 min|$69,089B/s|64|
|130|U20|U10|$8T|1 min 56 s|15 h 34 min|$69,722B/s|64|
|131|M6|—|$399,95T|1 h 35 min|17 h 9 min|$130,9B/s|64|
|132|U1|U10|$150|0 s|17 h 9 min|$131,14B/s|64|
|133|U1|U10|$150|0 s|17 h 9 min|$131,38B/s|64|
|134|U6|U1|$27,5K|0 s|17 h 9 min|$140,32B/s|64|
|135|U6|U10|$27,5K|0 s|17 h 9 min|$150,16B/s|64|
|136|U6|U10|$27,5K|0 s|17 h 9 min|$160,7B/s|64|
|137|U6|U10|$27,5K|0 s|17 h 9 min|$171,99B/s|64|
|138|U6|U10|$27,5K|0 s|17 h 9 min|$184,07B/s|64|
|139|U6|U10|$27,5K|0 s|17 h 9 min|$197B/s|64|
|140|U6|U10|$27,5K|0 s|17 h 9 min|$210,84B/s|64|
|141|U6|U10|$27,5K|0 s|17 h 9 min|$225,66B/s|64|
|142|U6|U10|$27,5K|0 s|17 h 9 min|$241,53B/s|64|
|143|U6|U1|$27,5K|0 s|17 h 9 min|$257,49B/s|64|
|144|U20|U6|$8T|31 s|17 h 10 min|$264,71B/s|64|
|145|U20|U6|$8T|30 s|17 h 10 min|$272,13B/s|64|
|146|U20|U6|$8T|29 s|17 h 11 min|$279,76B/s|64|
|147|U20|U6|$8T|29 s|17 h 11 min|$287,61B/s|64|
|148|U20|U6|$8T|28 s|17 h 12 min|$295,67B/s|64|
|149|U20|U6|$8T|27 s|17 h 12 min|$303,96B/s|64|
|150|U20|U6|$8T|26 s|17 h 13 min|$312,48B/s|64|
|151|U20|U6|$8T|26 s|17 h 13 min|$321,24B/s|64|
|152|U20|U6|$8T|25 s|17 h 13 min|$330,25B/s|64|
|153|U20|U6|$8T|24 s|17 h 14 min|$339,51B/s|64|
|—|Acumular o saldo final|—|—|49 min 5 s|18 h 3 min|$339,51B/s|64|

## Mini Miners e aleatoriedade

Para uma mineradora e meta de 10qn: sem modificadores aleatórios, 4 min 17 s. Com todos os resultados aleatórios no máximo, 4 min 6 s. Esse segundo caso é otimista e não representa média, probabilidade nem garantia.

## Limites da evidência

Os catálogos fornecidos podem estar incompletos para descrever cada jogo. Não foram incluídos itens de renascimento, bônus permanentes, restrições de desbloqueio não informadas, geometria real, capacidade de transporte ou tempo de montagem. Os tempos de menos de alguns minutos demonstram a aceleração matemática de muitas compras instantâneas, e não uma previsão de tempo de partida.

Os cenários são rotas calculadas, não provas da sequência mais rápida. Os requisitos de dinheiro de cada jogo também não foram inferidos; 1qd e 10qn são apenas marcos comuns de comparação.

