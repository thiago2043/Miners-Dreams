# Progressão de Renascimento e loja intermediária

Proposta de balanceamento para Miners Dreams. Reúne as 80 máquinas modeladas da loja intermediária, as seis propostas RS e os 50 marcos até a primeira Ascensão. Os valores da economia nova estão em potência de dez e com o sufixo do jogo. As hitboxes usam largura × comprimento × altura, em blocos de 3 studs.

## Regras do ciclo

- Os **127 modelos comerciais existentes** seguem os [preços revisados por ciclo](Precos_loja_por_ciclo.md). Os 80 modelos intermediários começam na faixa de $10^64 ($10Vi). Acima de $10^63 ($1Vi), o maior salto entre dois preços consecutivos da loja ampliada é **×1K**. A última oferta opcional custa $3·10^307 ($30UCe).
- As entregas preservam **1 ou 2 peças garantidas por reinício** do lote a cada cinco ciclos. Cada vida extra custa ×10^3 (×1K) e dá um sorteio entre os tipos de recompensa já obtidos. A rota abaixo usa uma vida por operação.
- Os modificadores só multiplicam. O limite conta aplicações por tipo em cada minério. A Calibração acrescenta 20% do limite base por nível, até +100%, com arredondamento ao inteiro mais próximo. As cópias de Renascimento continuam somando 50 pontos percentuais por unidade adicional ao bônus de cópias.
- Na 50ª reinicialização, depois de 49 Renascimentos concluídos e com $10^308 ($100UCe), o jogador pode escolher Ascensão diretamente. Pode escolher também o 50º Renascimento, receber seu lote e reunir novamente o saldo para Ascensão. Essa escolha mantém a possibilidade de completar as recompensas antes de reiniciar o progresso.
- Depois da primeira Ascensão, as 80 intermediárias e as seis RS saem da loja. Elas fecham a primeira rota de Renascimento. Os 127 modelos legados continuam disponíveis para recuperar os crafts. Os renascimentos têm metas locais de 10^21 (1Sx) a 10^119 (100OTg), com dois expoentes de diferença por reinício e três por vida extra. A [escala de Ascensão](Progressao_ascensao.md) aplica o deslocamento a esses valores. Os lotes mantêm o mesmo calendário.

## Metas e rota de compra

Os tempos desta seção foram simulados com os multiplicadores anteriores ao rebalanceamento da loja.

Cada ciclo começa com o kit básico e as recompensas garantidas acumuladas. A projeção faz as compras em ordem de preço, contabiliza o dinheiro gasto e usa uma linha com uma mineradora, uma fornalha e até 32 modificadores nos cinco primeiros ciclos ou 36 a partir do sexto. As primeiras rotas usam cópias comerciais dentro dos limites base. A partir do 19º ciclo, a linha usa uma unidade por tipo. O preço precisa caber em metade da meta e melhorar a produção projetada. A linha para de comprar quando a meta pode ser produzida em até 550 segundos. Entre R26 e R50, os novos efeitos foram ajustados para que o equipamento já acessível financie a próxima faixa de preço. O tempo conta a produção do dinheiro usado nas compras e na meta. A montagem e a substituição das peças ficam para o teste na plot.

Os resultados consideram que todo minério percorre a linha e chega à fornalha. Cada rota usa pelo menos 24 modificadores. Mesmo o melhor par mineradora + fornalha escolhido em cada rota, sem os modificadores, fica no mínimo nove ordens de grandeza por segundo abaixo da meta. No primeiro Renascimento, a projeção é de cerca de 8 min de operação e contempla 24 compras de tipos distintos. O tempo de montagem e o relato de até duas horas continuam sendo a referência para teste do jogador. Nos últimos cinco ciclos, o número projetado de compras antes da meta varia de 68 a 78 tipos. A maior espera em operação na tabela é de cerca de 37 min.

```text
R  | Meta                | Mineradora na linha               | Fornalha na linha                | Mods. | Tipos comprados | Operação (min)
01 | $10^21 ($1Sx)       | Mineradora cristalina             | Fornalha térmica                 | 32    | 24              | 7,9
02 | $10^24 ($1Sp)       | Mineradora aurora                 | Fornalha térmica                 | 32    | 17              | 5,6
03 | $10^27 ($1O)        | Mineradora aurora                 | Fornalha aurora                  | 32    | 16              | 2,0
04 | $10^30 ($1N)        | Mineradora aurora                 | Fornalha aurora                  | 32    | 21              | 1,3
05 | $10^33 ($1De)       | Mineradora aurora                 | Fornalha aurora                  | 32    | 26              | 5,9
06 | $10^34 ($10De)      | Mineradora aurora                 | Fornalha aurora                  | 36    | 27              | 1,5
07 | $3·10^34 ($30De)    | Mineradora pulsar                 | Fornalha aurora                  | 36    | 22              | 3,3
08 | $10^35 ($100De)     | Mineradora pulsar                 | Fornalha supernova               | 36    | 19              | 7,3
09 | $3·10^35 ($300De)   | Mineradora pulsar                 | Fornalha supernova               | 36    | 18              | 7,3
10 | $10^36 ($1UDe)      | Mineradora pulsar                 | Fornalha supernova               | 36    | 19              | 6,1
11 | $10^37 ($10UDe)     | Mineradora pulsar                 | Fornalha supernova               | 36    | 21              | 3,6
12 | $10^38 ($100UDe)    | Mineradora eterna                 | Fornalha supernova               | 36    | 16              | 7,7
13 | $10^40 ($10DDe)     | Mineradora eterna                 | Fornalha eterna                  | 36    | 16              | 0,8
14 | $10^41 ($100DDe)    | Mineradora eterna                 | Fornalha eterna                  | 36    | 16              | 0,5
15 | $10^43 ($10TDe)     | Mineradora eterna                 | Fornalha eterna                  | 36    | 19              | 4,5
16 | $10^44 ($100TDe)    | Mineradora eterna                 | Fornalha eterna                  | 36    | 21              | 2,6
17 | $10^46 ($10QaDe)    | Mineradora abissal                | Fornalha eterna                  | 36    | 16              | 5,1
18 | $10^48 ($1QiDe)     | Mineradora abissal                | Fornalha bastião                 | 36    | 14              | 8,6
19 | $10^50 ($100QiDe)   | Mineradora abissal                | Fornalha bastião                 | 34    | 30              | 5,8
20 | $10^52 ($10SxDe)    | Mineradora abissal                | Fornalha bastião                 | 34    | 28              | 4,1
21 | $10^56 ($100SpDe)   | Mineradora abissal                | Fornalha bastião                 | 36    | 30              | 4,7
22 | $10^61 ($10NDe)     | Mineradora abissal                | Fornalha bastião                 | 36    | 39              | 8,3
23 | $10^65 ($100Vi)     | Mineradora abissal                | Fornalha bastião                 | 36    | 46              | 2,6
24 | $10^70 ($10DVi)     | Mineradora abissal                | Fornalha bastião                 | 36    | 57              | 2,3
25 | $10^75 ($1QaVi)     | Mineradora abissal                | Fornalha bastião                 | 36    | 60              | 2,3
26 | $10^81 ($1SxVi)     | Mineradora abissal                | Fornalha bastião                 | 36    | 65              | 2,1
27 | $10^88 ($10OVi)     | Mineradora coroa solar            | Fornalha bastião                 | 36    | 67              | 4,3
28 | $10^94 ($10Tg)      | Mineradora coroa solar            | Fornalha mar de vidro            | 36    | 68              | 6,5
29 | $10^101 ($100DTg)   | Escavadora de cromo               | Fornalha de cromo tubular        | 36    | 75              | 1,3
30 | $10^108 ($1QiTg)    | Mineradora de níquel líquido      | Fornalha de cromo tubular        | 36    | 76              | 6,4
31 | $10^117 ($1OTg)     | Mineradora de níquel líquido      | Fornalha de cromo tubular        | 36    | 73              | 6,1
32 | $10^126 ($1UQag)    | Mineradora de níquel líquido      | Fornalha de grãos de níquel      | 36    | 76              | 1,1
33 | $10^136 ($10QaQag)  | Mineradora de níquel líquido      | Fornalha de têmpera rubra        | 36    | 77              | 6,5
34 | $10^145 ($10SpQag)  | Mineradora de minério sinterizado | Fornalha a vácuo de fenda        | 36    | 81              | 7,8
35 | $10^155 ($100Qig)   | Escavadora de hematita polida     | Fornalha a vácuo de fenda        | 36    | 82              | 3,5
36 | $10^164 ($100TQig)  | Mineradora de pressão abissal     | Fornalha de placas rubras        | 36    | 86              | 6,3
37 | $10^173 ($100SxQig) | Mineradora de ferrita orientada   | Fornalha de placas rubras        | 36    | 87              | 9,7
38 | $10^183 ($1Sxg)     | Escavadora de minério coercivo    | Fornalha de arco de ferrita      | 36    | 87              | 18,5
39 | $10^192 ($1TSxg)    | Escavadora de minério coercivo    | Fornalha de banho ferromagnético | 36    | 81              | 13,7
40 | $10^202 ($10SxSxg)  | Mineradora de agulhas magnéticas  | Fornalha de retorno magnético    | 36    | 74              | 19,7
41 | $10^213 ($1Spg)     | Escavadora de cristal bifásico    | Fornalha de retorno magnético    | 36    | 66              | 10,3
42 | $10^224 ($100TSpg)  | Mineradora de veios lamelares     | Fornalha de corpos gêmeos        | 36    | 66              | 15,9
43 | $10^235 ($10SpSpg)  | Mineradora de veios lamelares     | Fornalha de fibras prismáticas   | 36    | 62              | 10,4
44 | $10^246 ($1UOg)     | Escavadora de rocha metaestável   | Fornalha de face estável         | 36    | 64              | 16,6
45 | $10^257 ($100QaOg)  | Mineradora de basalto refratado   | Fornalha de face estável         | 36    | 66              | 23,0
46 | $10^267 ($1OOg)     | Mineradora de veios dourados      | Fornalha de sal dourado          | 36    | 68              | 23,4
47 | $10^277 ($10UNg)    | Mineradora de veios dourados      | Fornalha de fusão espelhada      | 36    | 71              | 30,1
48 | $10^287 ($100QaNg)  | Escavadora de estratos radiantes  | Fornalha de descarga radial      | 36    | 71              | 36,9
49 | $10^297 ($1ONg)     | Mineradora de escória branca      | Fornalha de descarga radial      | 36    | 75              | 35,1
50 | $10^308 ($100UCe)   | Escavadora do primeiro limiar     | Fornalha de reação contínua      | 36    | 78              | 35,6
```

### Crafts e alternativas

Os 50 crafts legados foram comparados com a linha de cada ciclo, expandindo as receitas até as peças de origem. O cálculo soma o custo das unidades de loja usadas na receita e retira da linha as recompensas garantidas consumidas quando falta uma cópia de reserva. 39 ciclos têm pelo menos uma alternativa de craft que melhora a etapa final da linha. A rota principal permanece possível com a loja e as recompensas garantidas.

```text
R  | Craft opcional           | Compras para a receita                    | Renda após o craft
7  | Escavadora de estratos   | $8,0824·10^6 ($8,08M)                     | $2,28·10^32 ($228N)/s
13 | Extratora cordilheira    | $8,16406080824·10^13 ($81,64T)            | $1,09·10^39 ($1,09DDe)/s
19 | Mineradora eixo polar    | $6,0060204·10^22 ($60,06Sx)               | $5,71·10^47 ($571QaDe)/s
25 | Fornalha cerâmica iônica | $6,0000000000000003008·10^35 ($600De)     | $1,47·10^73 ($14,7TVi)/s
32 | Comutador ferro-prisma   | $4,8862·10^4 ($48,86K)                    | $1,27·10^125 ($127Qag)/s
38 | Reator da coroa solar    | $3,54756348008478028862·10^20 ($354,75Qn) | $2,3·10^181 ($23NQig)/s
44 | Reator da coroa solar    | $3,54756348008478028862·10^20 ($354,75Qn) | $6,75·10^245 ($675Og)/s
46 | Arco dos horizontes      | $3,59363058062800052·10^37 ($35,93UDe)    | $1,9·10^266 ($190SpOg)/s
```

## Especificações das 80 intermediárias

Os modelos ficam no [manifesto das 80 máquinas](../modelos/loja-intermediaria/modelos.json). O ciclo indicado é o primeiro em que o preço fica abaixo da meta, sem depender de chegar a um novo lote de recompensas. As peças da loja regular podem ser compradas antes sempre que houver saldo. Os modificadores têm uma aplicação base por tipo e duas com Calibração máxima. Cada fator separado por seta corresponde a uma faixa do modelo.

### Mineradoras

```text
Código e máquina                        | Preço                       | R  | Hitbox | Efeito
LIM01 Mineradora de cassiterita         | $1,724·10^66 ($1,72UVi)     | 24 | 3×3×2  | $1,39·10^18 ($1,39Qn)/minério · 0,9 minério/s
LIM02 Escavadora de cromo               | $8·10^88 ($80OVi)           | 28 | 4×3×3  | $1,25·10^23 ($125Sx)/minério · 1 minério/s
LIM03 Mineradora de níquel líquido      | $3,185·10^105 ($3,18QaTg)   | 30 | 3×4×3  | $1,96·10^25 ($19,6Sp)/minério · 1 minério/s
LIM04 Mineradora de minério sinterizado | $8·10^135 ($8QaQag)         | 33 | 4×4×4  | $5,23·10^26 ($523Sp)/minério · 1 minério/s
LIM05 Escavadora de hematita polida     | $8·10^145 ($80SpQag)        | 35 | 5×4×3  | $2,44·10^33 ($2,44De)/minério · 0,9 minério/s
LIM06 Mineradora de ferrita orientada   | $1,776·10^169 ($17,76QiQig) | 37 | 5×4×4  | $3,72·10^40 ($37,2DDe)/minério · 1 minério/s
LIM07 Escavadora de minério coercivo    | $8,747·10^179 ($874,7OQig)  | 38 | 4×5×4  | $1,71·10^43 ($17,1TDe)/minério · 1 minério/s
LIM08 Mineradora de agulhas magnéticas  | $2,03·10^193 ($20,3TSxg)    | 40 | 6×4×5  | $5,71·10^45 ($5,71QaDe)/minério · 0,9 minério/s
LIM09 Escavadora de cristal bifásico    | $5,012·10^206 ($501,2SpSxg) | 41 | 5×5×5  | $2,29·10^48 ($2,29QiDe)/minério · 1,1 minério/s
LIM10 Mineradora de veios lamelares     | $7,943·10^222 ($7,94TSpg)   | 42 | 6×5×5  | $1,26·10^51 ($1,26SxDe)/minério · 1 minério/s
LIM11 Escavadora de rocha metaestável   | $2,512·10^236 ($251,2SpSpg) | 44 | 6×6×6  | $6,87·10^53 ($687SxDe)/minério · 0,9 minério/s
LIM12 Mineradora de basalto refratado   | $7,943·10^249 ($7,94DOg)    | 45 | 6×6×6  | $2,7·10^56 ($270SpDe)/minério · 1,1 minério/s
LIM13 Mineradora de veios dourados      | $2,239·10^265 ($22,39SpOg)  | 46 | 7×5×6  | $8,35·10^58 ($83,5ODe)/minério · 1 minério/s
LIM14 Escavadora de estratos radiantes  | $3,981·10^277 ($39,81UNg)   | 48 | 7×6×6  | $2,56·10^61 ($25,6NDe)/minério · 0,9 minério/s
LIM15 Mineradora de escória branca      | $7,079·10^289 ($70,79QiNg)  | 49 | 8×6×7  | $5,8·10^63 ($5,8Vi)/minério · 1,1 minério/s
LIM16 Escavadora do primeiro limiar     | $4,467·10^299 ($446,7ONg)   | 50 | 8×7×7  | $1,64·10^66 ($1,64UVi)/minério · 1,1 minério/s
```

### Fornalhas

```text
Código e máquina                       | Preço                      | R  | Hitbox | Efeito
LIF01 Fornalha de banho de sal         | $8·10^73 ($80TVi)          | 25 | 2×3×1  | ×1,25·10^11 (×125B) na venda
LIF02 Fornalha de cromo tubular        | $2,53·10^96 ($2,53UTg)     | 29 | 4×3×2  | ×1,28·10^18 (×1,28Qn) na venda
LIF03 Fornalha de grãos de níquel      | $3,713·10^114 ($3,71SpTg)  | 31 | 3×4×3  | ×7,75·10^18 (×7,75Qn) na venda
LIF04 Fornalha de têmpera rubra        | $2·10^129 ($2DQag)         | 33 | 3×3×3  | ×1,32·10^23 (×132Sx) na venda
LIF05 Fornalha a vácuo de fenda        | $8·10^141 ($8SxQag)        | 34 | 4×4×3  | ×1,26·10^25 (×12,6Sp) na venda
LIF06 Fornalha de placas rubras        | $2,01·10^155 ($201Qig)     | 36 | 4×5×4  | ×7,25·10^26 (×725Sp) na venda
LIF07 Fornalha de arco de ferrita      | $3,941·10^174 ($3,94SpQig) | 38 | 4×4×4  | ×3,34·10^29 (×334O) na venda
LIF08 Fornalha de banho ferromagnético | $1,941·10^185 ($194,1Sxg)  | 39 | 5×4×4  | ×1,04·10^32 (×104N) na venda
LIF09 Fornalha de retorno magnético    | $9,564·10^195 ($9,56QaSxg) | 40 | 5×5×4  | ×4,9·10^34 (×49De) na venda
LIF10 Fornalha de corpos gêmeos        | $6,31·10^214 ($63,1Spg)    | 42 | 5×4×4  | ×2,27·10^37 (×22,7UDe) na venda
LIF11 Fornalha de fibras prismáticas   | $1,995·10^228 ($1,99QiSpg) | 43 | 5×5×5  | ×1,14·10^40 (×11,4DDe) na venda
LIF12 Fornalha de face estável         | $6,31·10^241 ($63,1NSpg)   | 44 | 6×5×5  | ×5,65·10^42 (×5,65TDe) na venda
LIF13 Fornalha de sal dourado          | $2,818·10^260 ($281,8QiOg) | 46 | 6×5×5  | ×1,52·10^45 (×1,52QaDe) na venda
LIF14 Fornalha de fusão espelhada      | $5,012·10^272 ($501,2NOg)  | 47 | 6×6×6  | ×4,27·10^47 (×427QaDe) na venda
LIF15 Fornalha de descarga radial      | $8,913·10^284 ($891,3TNg)  | 48 | 7×6×6  | ×1,21·10^50 (×121QiDe) na venda
LIF16 Fornalha de reação contínua      | $1,585·10^297 ($1,58ONg)   | 50 | 7×7×6  | ×3,39·10^52 (×33,9SxDe) na venda
```

### Modificadores

```text
Código e máquina                       | Preço                       | R  | Hitbox | Efeito
LIX01 Escova de latão                  | $3,713·10^64 ($37,13Vi)     | 23 | 2×1×1  | ×7,8125·10^0 (×7,81) · total ×7,8125·10^0 (×7,81)
LIX02 Pulsador de solda                | $8·10^69 ($8DVi)            | 24 | 3×2×2  | ×9,4531·10^0 (×9,45) · total ×9,4531·10^0 (×9,45)
LIX03 Sapatas de flúor                 | $4·10^78 ($4QiVi)           | 26 | 2×2×1  | ×3,4375·10^0 (×3,43) → ×3,4375·10^0 (×3,43) · total ×1,181640625·10^1 (×11,81)
LIX04 Grampo de cobre anódico          | $2·10^80 ($200QiVi)         | 26 | 3×2×2  | ×3,5355·10^0 (×3,53) → ×3,5356·10^0 (×3,53) · total ×1,25001138·10^1 (×12,5)
LIX05 Injetor de cromo frio            | $8·10^84 ($8SpVi)           | 27 | 3×2×2  | ×1,6·10^1 (×16) · total ×1,6·10^1 (×16)
LIX06 Prensa de cromo azul             | $1,268·10^101 ($126,8DTg)   | 30 | 4×2×2  | ×4,7434·10^0 (×4,74) → ×4,7434·10^0 (×4,74) · total ×2,249984356·10^1 (×22,49)
LIX07 Válvula de néon líquido          | $2,01·10^103 ($20,1TTg)     | 30 | 3×3×2  | ×5,3·10^1 (×53) → ×5,3·10^1 (×53) · total ×2,809·10^3 (×2,8K)
LIX08 Colar de níquel capilar          | $5,048·10^107 ($504,8QaTg)  | 30 | 4×3×2  | ×1,22·10^4 (×12,2K) → ×1,21·10^4 (×12,1K) · total ×1,4762·10^8 (×147,62M)
LIX09 Peneira de metal poroso          | $1,724·10^117 ($1,72OTg)    | 32 | 3×4×2  | ×1,15·10^4 (×11,5K) → ×1,15·10^4 (×11,5K) · total ×1,3225·10^8 (×132,25M)
LIX10 Canal de pressão capilar         | $2,828·10^124 ($28,28Qag)   | 32 | 4×4×3  | ×5,2·10^1 (×52) → ×5,1·10^1 (×51) · total ×2,652·10^3 (×2,65K)
LIX11 Pino de cisalhamento             | $4·10^131 ($400DQag)        | 33 | 3×3×2  | ×8,35·10^2 (×835) → ×8,34·10^2 (×834) · total ×6,9639·10^5 (×696,39K)
LIX12 Desbastador de silicato          | $8·10^137 ($800QaQag)       | 34 | 4×3×2  | ×4,3·10^1 (×43) → ×4,3·10^1 (×43) · total ×1,849·10^3 (×1,84K)
LIX13 Grade de escória rubra           | $8·10^139 ($80QiQag)        | 34 | 4×4×3  | ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,5·10^1 (×15) · total ×4,335·10^3 (×4,33K)
LIX14 Fenda de silicato espelhado      | $8·10^143 ($800SxQag)       | 34 | 4×3×3  | ×7·10^1 (×70) → ×6,9·10^1 (×69) · total ×4,83·10^3 (×4,83K)
LIX15 Coroa de gotas metálicas         | $1,268·10^153 ($1,26Qig)    | 35 | 5×3×3  | ×1,5·10^1 (×15) → ×1,5·10^1 (×15) → ×1,3·10^1 (×13) · total ×2,925·10^3 (×2,92K)
LIX16 Palheta de fosfato vítreo        | $3,185·10^157 ($31,85UQig)  | 36 | 4×5×3  | ×2,2·10^1 (×22) → ×2,2·10^1 (×22) → ×2·10^1 (×20) · total ×9,68·10^3 (×9,68K)
LIX17 Prensa de escama vítrea          | $5,048·10^159 ($5,04DQig)   | 36 | 5×4×4  | ×2,3·10^1 (×23) → ×2,3·10^1 (×23) → ×2,3·10^1 (×23) · total ×1,2167·10^4 (×12,16K)
LIX18 Relé de ferrita roxa             | $3,769·10^166 ($37,69QaQig) | 37 | 3×4×3  | ×1,06·10^2 (×106) → ×1,05·10^2 (×105) · total ×1,113·10^4 (×11,13K)
LIX19 Indutor de ferrita orientada     | $8,365·10^171 ($8,36SxQig)  | 37 | 5×4×3  | ×3,3·10^1 (×33) → ×3,3·10^1 (×33) → ×3,1·10^1 (×31) · total ×3,3759·10^4 (×33,75K)
LIX20 Trilho de histerese              | $1,857·10^177 ($1,85OQig)   | 38 | 4×4×2  | ×3,3·10^1 (×33) → ×3,3·10^1 (×33) → ×3,2·10^1 (×32) · total ×3,4848·10^4 (×34,84K)
LIX21 Porta de inversão magnética      | $4,121·10^182 ($412,1NQig)  | 38 | 5×4×4  | ×3,3·10^1 (×33) → ×3,3·10^1 (×33) → ×3,2·10^1 (×32) · total ×3,4848·10^4 (×34,84K)
LIX22 Colimador de pó ferrimagnético   | $9,146·10^187 ($91,46USxg)  | 39 | 4×5×3  | ×3,4·10^1 (×34) → ×3,4·10^1 (×34) → ×3,2·10^1 (×32) · total ×3,6992·10^4 (×36,99K)
LIX23 Arranjo de dipolos               | $4,309·10^190 ($43,09DSxg)  | 39 | 5×5×4  | ×3,4·10^1 (×34) → ×3,4·10^1 (×34) → ×3,2·10^1 (×32) · total ×3,6992·10^4 (×36,99K)
LIX24 Bobina de polaridade reversa     | $4,506·10^198 ($4,5QiSxg)   | 40 | 6×4×4  | ×3,5·10^1 (×35) → ×3,5·10^1 (×35) → ×3,3·10^1 (×33) · total ×4,0425·10^4 (×40,42K)
LIX25 Pórtico de domínios magnéticos   | $2,123·10^201 ($2,12SxSxg)  | 40 | 5×5×5  | ×1,5·10^1 (×15) → ×1,5·10^1 (×15) → ×1,5·10^1 (×15) → ×1,2·10^1 (×12) · total ×4,05·10^4 (×40,5K)
LIX26 Lente de cristal bifásico        | $2,512·10^209 ($251,2OSxg)  | 41 | 4×4×3  | ×3,6·10^1 (×36) → ×3,6·10^1 (×36) → ×3,5·10^1 (×35) · total ×4,536·10^4 (×45,36K)
LIX27 Separador de facetas gêmeas      | $1,259·10^212 ($125,9NSxg)  | 41 | 5×4×4  | ×3,6·10^1 (×36) → ×3,6·10^1 (×36) → ×3,5·10^1 (×35) · total ×4,536·10^4 (×45,36K)
LIX28 Malha de venas prismáticas       | $3,162·10^217 ($31,62USpg)  | 42 | 4×5×4  | ×3,6·10^1 (×36) → ×3,6·10^1 (×36) → ×3,6·10^1 (×36) · total ×4,6656·10^4 (×46,65K)
LIX29 Bomba de vidro polar             | $1,585·10^220 ($15,85DSpg)  | 42 | 5×4×4  | ×3,7·10^1 (×37) → ×3,7·10^1 (×37) → ×3,5·10^1 (×35) · total ×4,7915·10^4 (×47,91K)
LIX30 Viga de tração de vidro          | $3,981·10^225 ($3,98QaSpg)  | 43 | 6×4×4  | ×1,2·10^1 (×12) → ×1,2·10^1 (×12) → ×1,2·10^1 (×12) → ×8,8583·10^0 (×8,85) · total ×1,53071424·10^4 (×15,3K)
LIX31 Reator de clivagem térmica       | $10^231 ($1SxSpg)           | 43 | 5×5×4  | ×3,7·10^1 (×37) → ×3,7·10^1 (×37) → ×3,7·10^1 (×37) · total ×5,0653·10^4 (×50,65K)
LIX32 Ressonador de camada dupla       | $5,012·10^233 ($501,2SxSpg) | 43 | 6×5×4  | ×1,5·10^1 (×15) → ×1,5·10^1 (×15) → ×1,5·10^1 (×15) → ×1,5·10^1 (×15) · total ×5,0625·10^4 (×50,62K)
LIX33 Trefila de fase vítrea           | $1,259·10^239 ($125,9OSpg)  | 44 | 6×5×5  | ×1,5·10^1 (×15) → ×1,5·10^1 (×15) → ×1,5·10^1 (×15) → ×1,5·10^1 (×15) · total ×5,0625·10^4 (×50,62K)
LIX34 Anel de fase trincada            | $3,162·10^244 ($31,62Og)    | 44 | 6×6×5  | ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,5·10^1 (×15) · total ×6,144·10^4 (×61,44K)
LIX35 Coletor de poeira bifásica       | $1,585·10^247 ($15,85UOg)   | 45 | 7×5×5  | ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,5·10^1 (×15) · total ×6,144·10^4 (×61,44K)
LIX36 Compensador de tensão prismática | $3,981·10^252 ($3,98TOg)    | 45 | 6×6×5  | ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,6·10^1 (×16) · total ×6,5536·10^4 (×65,53K)
LIX37 Pórtico de fase estável          | $1,995·10^255 ($1,99QaOg)   | 45 | 7×6×5  | ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,6·10^1 (×16) · total ×6,5536·10^4 (×65,53K)
LIX38 Prensa de fronteira térmica      | $7,943·10^262 ($79,43SxOg)  | 46 | 5×5×4  | ×3,7·10^1 (×37) → ×3,7·10^1 (×37) → ×3,7·10^1 (×37) · total ×5,0653·10^4 (×50,65K)
LIX39 Escudo de sopro quente           | $6,31·10^267 ($6,31OOg)     | 47 | 6×5×5  | ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,4·10^1 (×14) · total ×5,7344·10^4 (×57,34K)
LIX40 Lente de fusão espelhada         | $1,778·10^270 ($1,77NOg)    | 47 | 6×6×5  | ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,7·10^1 (×17) · total ×8,3521·10^4 (×83,52K)
LIX41 Válvula de metal incandescente   | $1,413·10^275 ($141,3Ng)    | 47 | 6×5×5  | ×2,7·10^1 (×27) → ×2,7·10^1 (×27) → ×2,7·10^1 (×27) → ×2,7·10^1 (×27) · total ×5,31441·10^5 (×531,44K)
LIX42 Colar de refluxo luminoso        | $1,122·10^280 ($11,22DNg)   | 48 | 6×6×6  | ×3·10^1 (×30) → ×3·10^1 (×30) → ×3·10^1 (×30) → ×2,8·10^1 (×28) · total ×7,56·10^5 (×756K)
LIX43 Colisor de fluxo térmico         | $3,162·10^282 ($3,16TNg)    | 48 | 7×6×5  | ×3·10^1 (×30) → ×3·10^1 (×30) → ×3·10^1 (×30) → ×2,9·10^1 (×29) · total ×7,83·10^5 (×783K)
LIX44 Grade de retorno incandescente   | $2,512·10^287 ($251,2QaNg)  | 49 | 7×5×5  | ×3,1·10^1 (×31) → ×3,1·10^1 (×31) → ×3,1·10^1 (×31) → ×2,8·10^1 (×28) · total ×8,34148·10^5 (×834,14K)
LIX45 Concentrador de chama branca     | $1,995·10^292 ($19,95SxNg)  | 49 | 7×6×6  | ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,5·10^1 (×15) · total ×1,252815·10^6 (×1,25M)
LIX46 Canal de arco contínuo           | $5,623·10^294 ($5,62SpNg)   | 49 | 7×7×5  | ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,6·10^1 (×16) · total ×1,336336·10^6 (×1,33M)
LIX47 Ressonador de fusão controlada   | $1,259·10^302 ($125,9NNg)   | 50 | 8×7×6  | ×2·10^1 (×20) → ×2·10^1 (×20) → ×2·10^1 (×20) → ×2·10^1 (×20) → ×1,7·10^1 (×17) · total ×2,72·10^6 (×2,72M)
LIX48 Pórtico do primeiro limiar       | $3,548·10^304 ($35,48Ce)    | 50 | 8×8×7  | ×3,2·10^1 (×32) → ×3,2·10^1 (×32) → ×3,2·10^1 (×32) → ×3,2·10^1 (×32) → ×3·10^1 (×30) · total ×3,145728·10^7 (×31,45M)
```

As [seis fichas RS](Conceitos_fim_de_ciclo.md) completam esta tabela. A [progressão pós-Ascensão](Progressao_ascensao.md) reúne as demais compras, crafts, transições e o marco 10^(10^308).
