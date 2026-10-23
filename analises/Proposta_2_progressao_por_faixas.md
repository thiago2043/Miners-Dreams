# Proposta 2 revisada — 55 modificadores com base em MAX e Mini Miners

Revisão teórica de 22/10/2026. O catálogo de modificadores e os resultados abaixo substituem a versão anterior. As 13 mineradoras e as nove fornalhas mantêm os valores da revisão anterior; nenhum script do jogo foi alterado.

## Objetivo de experiência

O jogador deve melhorar e reorganizar a plot enquanto permanece com uma mineradora. Novos modificadores devem ampliar as combinações, com ganhos perceptíveis e preços que deixem oportunidades de investimento entre os marcos.

Mechanical Ascension X (MAX) e Mini Miners (MM) passam a ser as referências principais dos modificadores: muitos tipos limitados por usos, multiplicadores fortes e combinações que preservam peças anteriores. Para mineradoras, continuam sendo considerados Drillbit, MAX e MM.

A fonte são os catálogos que você enviou em [Texto colado.txt](<C:/Users/thiagocraft/.codex/attachments/b59fdc17-2078-4610-9e39-88a1efde04ec/Texto colado.txt>), sem presumir que correspondam às versões atuais dos jogos.

## Composição do catálogo

```text
Catálogo               | Total | Só usos | Só valor | Híbridos | Aditivo sem limite
Mechanical Ascension X | 38    | 34      | 3        | 0        | 1
Mini Miners            | 26    | 22      | 0        | 4        | 0
Proposta revisada      | 55    | 40      | 10       | 4        | 1
```

Os dez solicitados são os tipos limitados apenas por valor. Somando os quatro híbridos, são 14 tipos com alguma restrição monetária: aproximadamente 25,5% dos 55, contra 62,5% na versão anterior, que tinha 15 entre 24.

Dos 40 modificadores limitados apenas por usos, 30 têm efeito por aplicação de pelo menos ×2 e 23 têm efeito acima de ×2. Considerando todos os 53 tipos multiplicativos, são 32 com pelo menos ×2 e 24 acima de ×2. A0 e H1 são os dois aditivos.

Na tabela enviada, MAX tem 28 tipos determinísticos com pelo menos ×2 e 19 acima de ×2; MM tem dez e seis, respectivamente. Dois tipos aleatórios de MM ficam fora dessa contagem: seus intervalos não definem um efeito garantido nem uma média sem conhecer as probabilidades.

## Como as peças devem continuar úteis

- Tipos numéricos diferentes acumulam seus efeitos. Um novo ×2,75 pode ser acrescentado à linha que já usa ×2 e ×2,4.
- A substituição de um tipo numérico passa a depender do espaço, do ganho total e do preço. Receber uma opção nova não desativa o tipo anterior.
- Efeitos menores com várias aplicações são complementos e alternativas espaciais. Eles não compõem a maior parte dos tipos numéricos.
- Os dez processadores por valor ajudam a alcançar patamares e a reduzir processamento. Seus preços ficam distribuídos entre compras numéricas, sem concentrar toda a evolução em uma sucessão de faixas.
- Os quatro híbridos têm uma utilidade temporária dentro de seus intervalos; sua retirada posterior é esperada quando o minério deixa de se enquadrar.
- Não é obrigatório comprar todo o catálogo. As rotas devem permitir escolhas; a existência de uma peça opcional não demonstra, por si só, que seu preço está ruim.

Os preços dos modificadores foram recalculados junto de seus efeitos. Aumentar os multiplicadores mantendo os preços do rascunho produziu uma aceleração excessiva nos testes e foi descartado.

## Regras de aplicação

Cada limite numérico é compartilhado entre todas as cópias do mesmo tipo para cada minério. Tipos diferentes têm contadores independentes. Uma linha com três cópias de um tipo limitado a duas aplicações só aplica esse tipo duas vezes ao minério.

Faixa a–b significa a ≤ valor de entrada < b. A condição é verificada antes do efeito; o resultado pode ultrapassar b. Um minério já acima do máximo não é reduzido.

Tipos sem limite numérico podem repetir enquanto sua condição monetária continuar satisfeita. O aditivo ilimitado também permite repetição; a simulação usa somente uma cópia dele como hipótese de comparação, sem modelar recirculação.

## Modificadores, em ordem de preço

IDs N são os 40 tipos limitados apenas por usos; V são os dez apenas por valor; H são os quatro híbridos; A0 é o aditivo ilimitado. Os IDs dos modificadores foram reorganizados por preço nesta proposta, que ainda não está implementada.

```text
ID  | Nome                      | Efeito por aplicação | Usos por minério    | Faixa de entrada  | Preço por cópia
A0  | Jato mineral              | +$10                 | Sem limite numérico | Qualquer valor    | $50
H1  | Banho de cobre            | +$10                 | 3                   | $0 ≤ v < $100     | $150
N01 | Prensa tripla             | ×1,75                | 3                   | Qualquer valor    | $750
V1  | Prensa de minério         | ×2                   | Sem limite numérico | $0 ≤ v < $100     | $10K
N02 | Laser básico              | ×2                   | 1                   | Qualquer valor    | $50K
H2  | Refinador de cobre        | ×1,3                 | 12                  | $0 ≤ v < $1K      | $75K
N03 | Bobina dupla              | ×1,5                 | 2                   | Qualquer valor    | $150K
N04 | Ionizador                 | ×2,4                 | 1                   | Qualquer valor    | $750K
V2  | Refinador industrial      | ×1,25                | Sem limite numérico | $0 ≤ v < $2,5K    | $1,5M
N05 | Laser industrial          | ×2                   | 1                   | Qualquer valor    | $20M
N06 | Raio de plasma            | ×2,75                | 1                   | Qualquer valor    | $75M
N07 | Bobina de indução         | ×1,8                 | 2                   | Qualquer valor    | $250M
V3  | Câmara magnética          | ×1,5                 | Sem limite numérico | $25K ≤ v < $100K  | $250M
V4  | Refinador molecular       | ×1,3                 | Sem limite numérico | $0 ≤ v < $1M      | $1B
N08 | Túnel de compressão       | ×1,25                | 4                   | Qualquer valor    | $4B
H3  | Processador térmico       | ×1,75                | 7                   | $0 ≤ v < $3,5M    | $5B
N09 | Catalisador térmico       | ×3                   | 1                   | Qualquer valor    | $5T
V5  | Câmara de plasma          | ×1,6                 | Sem limite numérico | $500K ≤ v < $5M   | $5T
N10 | Laser duplo               | ×2                   | 2                   | Qualquer valor    | $25T
N11 | Polarizador               | ×2,25                | 1                   | Qualquer valor    | $100T
N12 | Ressonador de plasma      | ×3                   | 2                   | Qualquer valor    | $300T
V6  | Refinador atômico         | ×1,25                | Sem limite numérico | $0 ≤ v < $50M     | $5qd
N13 | Acelerador modular        | ×1,15                | 10                  | Qualquer valor    | $40qd
N14 | Túnel molecular           | ×1,5                 | 3                   | Qualquer valor    | $150qd
H4  | Processador de partículas | ×1,3                 | 12                  | $0 ≤ v < $500M    | $250qd
N15 | Feixe molecular           | ×3,25                | 1                   | Qualquer valor    | $500qd
V7  | Câmara quântica           | ×1,5                 | Sem limite numérico | $100M ≤ v < $2,5B | $2,5qn
N16 | Compressor atômico        | ×2                   | 2                   | Qualquer valor    | $40qn
N17 | Câmara de fissão          | ×2,5                 | 1                   | Qualquer valor    | $100qn
N18 | Núcleo de antimatéria     | ×4                   | 1                   | Qualquer valor    | $300qn
N19 | Ressonador quântico       | ×3                   | 2                   | Qualquer valor    | $1,5sx
V8  | Câmara estelar            | ×1,75                | Sem limite numérico | $1B ≤ v < $25B    | $5sx
N20 | Anel de partículas        | ×1,4                 | 4                   | Qualquer valor    | $1sp
N21 | Laser quântico            | ×2                   | 1                   | Qualquer valor    | $3sp
N22 | Amplificador de fase      | ×2,75                | 2                   | Qualquer valor    | $6sp
N23 | Pulso estelar             | ×4,5                 | 1                   | Qualquer valor    | $40sp
V9  | Refinador galáctico       | ×1,35                | Sem limite numérico | $0 ≤ v < $1T      | $50sp
N24 | Anel gravitacional        | ×1,6                 | 4                   | Qualquer valor    | $250sp
N25 | Bobina estelar            | ×2                   | 2                   | Qualquer valor    | $4o
N26 | Túnel de fase             | ×1,5                 | 3                   | Qualquer valor    | $6o
N27 | Feixe de fótons           | ×3,5                 | 1                   | Qualquer valor    | $7,5o
N28 | Ressonador estelar        | ×2,5                 | 2                   | Qualquer valor    | $40o
N29 | Núcleo de quasar          | ×5                   | 1                   | Qualquer valor    | $100o
N30 | Compressor galáctico      | ×3                   | 2                   | Qualquer valor    | $600o
N31 | Túnel de horizonte        | ×1,75                | 3                   | Qualquer valor    | $1,5n
N32 | Feixe de singularidade    | ×4                   | 1                   | Qualquer valor    | $4n
N33 | Laser galáctico           | ×2                   | 1                   | Qualquer valor    | $6n
N34 | Polarizador cósmico       | ×2,25                | 1                   | Qualquer valor    | $10n
N35 | Ressonador de vácuo       | ×3                   | 2                   | Qualquer valor    | $20n
N36 | Núcleo de horizonte       | ×6                   | 1                   | Qualquer valor    | $90n
V10 | Câmara de singularidade   | ×2,5                 | Sem limite numérico | $250B ≤ v < $25T  | $250n
N37 | Amplificador de vácuo     | ×2,5                 | 2                   | Qualquer valor    | $5de
N38 | Pulso dimensional         | ×4                   | 1                   | Qualquer valor    | $15de
N39 | Ressonador dimensional    | ×3,5                 | 2                   | Qualquer valor    | $50de
N40 | Núcleo dimensional        | ×5                   | 1                   | Qualquer valor    | $250de
```

Os preços são por cópia física. Duas aplicações de um tipo exigem duas cópias na linha simulada. Reutilizar uma peça em voltas é possível pelas regras, mas o tempo e a geometria dessas voltas não estão neste modelo.

## Ganhos mais fortes e combinações

```text
Peça                       | Aplicações | Efeito acumulado
Prensa tripla — ×1,75      | 3          | ×5,359
Laser básico — ×2          | 1          | ×2
Ionizador — ×2,4           | 1          | ×2,4
Raio de plasma — ×2,75     | 1          | ×2,75
Ressonador de plasma — ×3  | 2          | ×9
Núcleo de antimatéria — ×4 | 1          | ×4
Núcleo de horizonte — ×6   | 1          | ×6
```

Exemplo de coexistência: Laser básico ×2, Ionizador ×2,4 e Raio de plasma ×2,75 dão ×13,2 em três aplicações de tipos distintos. O ×2 inicial continua contribuindo mesmo depois da compra dos outros dois.

Na rota com uma mineradora até 1qd, os 12 tipos limitados apenas por usos comprados continuam instalados ao chegar ao marco. Isso verifica retenção nessa rota; não garante que todo tipo deva permanecer para sempre quando a plot atingir 64 modificadores.

## Comprar antes ou esperar a próxima peça

Foram comparados três casos isolados. Cada caso parte de saldo zero e da renda observada antes da compra anterior na rota de uma mineradora. Só permite as duas compras indicadas, mantém as outras peças fixas e cobra um segundo para cada colocação.

O cenário de espera compra apenas a peça seguinte. O cenário de investimento compra a anterior e depois a seguinte, ficando com ambas. A renda durante a colocação ainda é a das peças que já estavam ativas. Os valores da tabela medem o tempo até concluir a colocação da peça seguinte.

```text
Compra anterior  | Compra seguinte | Esperar a seguinte | Comprar antes | Economia
Laser básico     | Bobina dupla    | 200,9 s            | 168,1 s       | 32,8 s
Laser industrial | Raio de plasma  | 140,1 s            | 108,1 s       | 32 s
Bobina dupla     | Ionizador       | 62,3 s             | 54,4 s        | 7,8 s
```

Esses exemplos verificam que comprar antes pode financiar melhor a próxima peça. Não provam a melhor rota considerando todas as outras compras, dinheiro já guardado, reorganizações ou espaço ocupado. Evitar uma peça pode continuar sendo uma decisão válida em uma configuração específica.

## Função dos dez processadores por valor

V1 atua no começo; V2 amplia o processamento de minérios baixos; V3 exige uma entrada maior, enquanto V4 oferece um teto mais alto para processamento geral. V5 a V10 estendem os patamares ao longo das compras posteriores.

V3 custa $250M e V4 custa $1B. Comprar V3 antes pode ajudar a financiar V4 e diminuir a quantidade de aplicações necessária no estágio seguinte. Essa relação deve ser avaliada com o minério da mineradora e a linha completa, porque multiplicadores colocados antes de um patamar podem economizar espaço sem aumentar proporcionalmente a saída final.

Faixas que começam em zero continuam presentes em V1, V2, V4, V6 e V9. As janelas com mínimo e máximo aparecem distribuídas mais adiante. Os V não têm limite numérico fixo de uma ou duas aplicações.

## O que mudou na leitura das mineradoras

Renda bruta = valor do minério ÷ intervalo de geração. Não inclui modificadores nem fornalha.

Na versão anterior, M2 → M3 custava apenas 4 vezes mais e multiplicava a renda bruta por 12: de aproximadamente $33,33/s para $400/s. A M3 custava $2K e gerava $400/s brutos, equivalentes a seu próprio preço em 5 segundos, antes de qualquer melhoria.

Os exemplos abaixo mostram como os três catálogos abrem espaço para processamento entre trocas:

```text
Catálogo               | Preço: 3ª → 4ª | Crescimento do preço | Renda bruta/s: 3ª → 4ª | Crescimento da renda
Drillbit               | $650 → $150K   | ×230,77              | $16,667 → $100         | ×6
Mechanical Ascension X | $10K → $1M     | ×100                 | $12,5 → $30            | ×2,4
Mini Miners            | $100K → $5M    | ×50                  | $150 → $746,269        | ×4,98
Esta revisão           | $100K → $10M   | ×100                 | $37,5 → $150           | ×4
```

Os catálogos também possuem exceções com saltos grandes de rendimento, especialmente em Mechanical e em alguns marcos de Drillbit e Mini Miners. A proposta não impõe uma razão fixa para todas as trocas: preços crescem em escalas maiores que a renda bruta, com intervalos de geração variados e saltos de minério mais fortes em alguns marcos.

Nesta revisão, M2 → M3 passa de $1,5K para $100K, enquanto a renda bruta passa de $10/s para $37,50/s. A diferença de preço é financiada por processamento ao longo da permanência com a M2. A relação preço/renda bruta é um diagnóstico; não representa o tempo de compra na fábrica já melhorada.

## Mineradoras

Os valores de minério e os preços permanecem os da revisão anterior. A M1 mantém o intervalo inicial de 2 segundos, com minério de $5; uma unidade é gratuita no kit inicial. A tabela de renda bruta permite comparar valor e frequência sem confundir o preço com a produção de uma plot completa.

```text
ID  | Nome          | Intervalo (s) | Valor do minério | Preço  | Renda bruta/s
M1  | Básica        | 2             | $5               | $100   | $2,5
M2  | Cobre         | 1,5           | $15              | $1,5K  | $10
M3  | Ferro         | 1,2           | $45              | $100K  | $37,5
M4  | Industrial    | 1             | $150             | $10M   | $150
M5  | Pressurizada  | 1,5           | $1,2K            | $750M  | $800
M6  | Cristalina    | 1,2           | $6K              | $50B   | $5K
M7  | Ressonante    | 1,5           | $18K             | $2T    | $12K
M8  | Plasma        | 1             | $75K             | $100T  | $75K
M9  | Atômica       | 1,25          | $350K            | $5qd   | $280K
M10 | Quântica      | 1,5           | $2M              | $250qd | $1,333M
M11 | Singularidade | 1,2           | $15M             | $25qn  | $12,5M
M12 | Estelar       | 1             | $90M             | $2,5sx | $90M
M13 | Galáctica     | 1,25          | $500M            | $500sx | $400M
```

As mineradoras posteriores não são compras obrigatórias antes da primeira reencarnação em 1qd. O catálogo inclui peças para continuar além desse marco. Não há bloqueio por tempo nem exigência artificial de comprar todas em sequência.

## Fornalhas

Os multiplicadores e preços permanecem os da revisão anterior. Uma F1 é gratuita no kit inicial. A fornalha consome o minério e seu multiplicador não se acumula com outras fornalhas.

```text
ID | Nome       | Multiplicador | Preço
F1 | Básica     | ×1            | $100
F2 | Reforçada  | ×1,5          | $3K
F3 | Industrial | ×3            | $1M
F4 | Térmica    | ×5            | $500M
F5 | Plasma     | ×8            | $250B
F6 | Molecular  | ×12           | $25T
F7 | Quântica   | ×20           | $1qd
F8 | Estelar    | ×35           | $100qd
F9 | Galáctica  | ×60           | $10qn
```

## Primeiros passos recalculados

```text
Primeira compra do tipo | Tempo acumulado | Renda da plot/s
A0                      | 0 min 23 s      | $7,5
H1                      | 0 min 44 s      | $12,5
N01                     | 1 min 38 s      | $39,375
M2                      | 2 min 22 s      | $196,51
V1                      | 3 min 13 s      | $589,531
N02                     | 4 min 37 s      | $1,501K
N03                     | 8 min 02 s      | $18,362K
N04                     | 8 min 38 s      | $66,102K
M4                      | 10 min 05 s     | $436,261K
```

O exemplo mantém a M2 por aproximadamente 7 min 43 s antes da troca para M4. A busca salta M3 nessa rota; a utilidade de M3 precisa ser avaliada em outras configurações e em teste de jogo. A permanência de 3 min 13 s com M2 e a rota que comprava M3, mostradas na versão anterior, não descrevem este catálogo.

O registro mede uma sequência financeira de referência. Não força o jogador a seguir essa ordem nem comprova que saltar uma mineradora é a melhor decisão geral.

## Simulação de referência

Até 64 modificadores; até uma, duas ou quatro mineradoras; saldo zero; uma mineradora e uma fornalha gratuitas; uma cópia do aditivo ilimitado; repetições com cópias físicas; um segundo por colocação e por remoção de mineradora, modificador ou fornalha, incluindo reorganizações e a montagem inicial.

A produção continua durante as ações conforme as peças ativas. Mineradoras e fornalhas substituídas retornam 100% de seu preço nesta hipótese financeira; modificadores retirados não geram reembolso. Não há duração de minério, bônus de reencarnação, transporte nem custo de esteiras.

A busca automática usa uma ordem física comum aos minérios e escolhe compras por financiamento e retorno incremental. Ela não prova a melhor rota nem antecipa todas as vantagens futuras de liberar espaço. Os dois marcos são saldos disponíveis; chegar a 10qn não inclui reencarnar no meio do percurso.

```text
Configuração      | Até 1qd disponível | Até 10qn disponível
Até 1 mineradora  | 24 min 26 s        | 38 min 36 s
Até 2 mineradoras | 16 min 50 s        | 24 min 21 s
Até 4 mineradoras | 10 min 18 s        | 15 min 38 s
```

Na rota com uma mineradora, a maior espera para financiar uma compra até 1qd foi de aproximadamente 84 segundos. Até 10qn, houve uma espera de aproximadamente 2 min 44 s para a fornalha F8, cujos valores foram preservados. Esses tempos não medem aprendizagem, movimentação, menus ou construção de esteiras.

As configurações com mais mineradoras continuam mais rápidas. Os resultados não estabelecem uma duração mínima garantida para toda peça ou todo estágio.

## Evidência e limites

Conferidos nos seis cenários: conservação do saldo, soma de esperas e ações, limite de 64 modificadores, contagem numérica por tipo e um segundo para cada ação completa. Também foram verificadas as contagens do catálogo, a unicidade dos IDs e a preservação integral dos dados de mineradoras e fornalhas.

Uma rota estendida de diagnóstico, com uma mineradora e horizonte de saldo maior que os marcos acima, chegou a comprar todos os 55 tipos, incluindo os dez V, respeitando as 64 posições. Ela testa a utilização possível no modelo; não equivale a uma sequência de vidas, a uma rota ótima ou a teste com jogadores.

Ainda precisam de teste no jogo: sensação de progresso, montagem física, transporte, combinações fora da ordem automática, utilidade das mineradoras que a busca salta, recompensas de reencarnação e interação com a primeira leva. Nenhum script do jogo foi alterado.

