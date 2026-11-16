# Progressão das 50 Ascensões

Proposta para Miners Dreams. O primeiro marco é **`10^308` (100UCe)** e o quinquagésimo é **`10^(10^308)` (`e(1e308)`)**. Os dez primeiros marcos aumentam de `10^308` a `10^7000`. Do 11º ao 49º, o crescimento acelera no logaritmo do expoente. As [250 fichas](Especificacao_250_maquinas_ascensao.md) usam as mesmas séries, recompensas e receitas.

## Escala do dinheiro por ciclo

Se **E** for o expoente da meta exibida e **G** o expoente da meta local, o ciclo usa **B = E − G**. Exiba **valor local × 10^B**. Dentro do ciclo, some, subtraia e compare os inteiros locais. Preço, valor de saída, ganho por segundo, venda e custos do conteúdo legado seguem a mesma escala. A taxa de geração e os multiplicadores ficam inalterados pela conversão. Isso dispensa gravar o saldo como uma sequência de `10^308` zeros.

Na 1ª Ascensão, **B = 0**. Após a 1ª, a meta da 2ª é **`10^408`**, a meta local é **`10^179`** e **B = 229**. A primeira compra custa **$1,65·10^155 ($165Qig)** localmente e aparece como **$1,65·10^384 ($1,65e384)**. Na última, a meta local é **`10^284`** e **B = `10^308 − 284`**. No HUD, `e(1e308)` abrevia `10^(10^308)`. Preços cujo expoente fica visualmente igual com a abreviação podem mostrar também o valor local para distinguir as compras.

A escala vale entre duas reinicializações e é escolhida pelo número de Ascensões concluídas. O saldo reinicia no ciclo seguinte. O registro de valor histórico precisaria guardar o ciclo da medição ou a escala daquele valor. A regra em desenvolvimento ainda usa deslocamento fixo de +100 no expoente da meta, e esta proposta define a tabela que substituiria esse cálculo.

## Marcos e recompensas

O cabeçalho **A** é o número da Ascensão a concluir. **G** vale no ciclo que termina nesse marco. A última coluna mostra a recompensa quando o jogador ganha exatamente uma transição em cada Ascensão. A recompensa continua indexada por **transição cumulativa**. Uma extra dentro do mesmo ciclo mantém o custo de **×`10^10` sobre o marco anterior** e antecipa a entrega correspondente. As séries de loja dependem de **Ascensões concluídas**. A projeção a seguir usa apenas as transições mínimas.

Para reproduzir E do 11º ao 49º, calcule `10^(log10(7000) + (308 − log10(7000)) × ((A−10)/40)^2)` e trunque o resultado para três algarismos significativos. O inteiro resultante é **E** e a meta é `10^E`. Fixe os dois extremos exatamente como estão na tabela.


```text
A  | Saldo exigido     | Abreviação   | G   | Série ativa | Recompensa da transição
1  | $10^308           | $100UCe      | 308 | —           | AM01 Mineradora do zênite
2  | $10^408           | $1e408       | 179 | 01          | AX01 Filtro da aurora verde
3  | $10^540           | $1e540       | 181 | 01          | AF01 Fornalha do alvorecer
4  | $10^720           | $1e720       | 182 | 01          | AX02 Garra de luz fria
5  | $10^980           | $1e980       | 184 | 01          | AX03 Câmara da agulha solar
6  | $10^1350          | $1e1350      | 197 | 02          | AM02 Escavadora coroa de ferro
7  | $10^1900          | $1e1900      | 197 | 02          | AX04 Vetor da nebulosa
8  | $10^2800          | $1e2800      | 200 | 02          | AF02 Fornalha da vigília
9  | $10^4300          | $1e4300      | 201 | 02          | AX05 Polarizador do zéfiro
10 | $10^7000          | $1e7000      | 201 | 02          | AX06 Prisma de brasa azul
11 | $10^10800         | $1e10800     | 210 | 03          | AM03 Mineradora abóbada azul
12 | $10^40300         | $1e40300     | 210 | 03          | AX07 Condutor da orla
13 | $10^359000        | $1e359000    | 210 | 03          | AF03 Fornalha do vento polar
14 | $10^(7,7·10^6)    | $e(7,7e6)    | 210 | 03          | AX08 Malha do alto vácuo
15 | $10^(3,95·10^8)   | $e(3,95e8)   | 211 | 03          | AX09 Membrana luminosa
16 | $10^(4,88·10^10)  | $e(4,88e10)  | 220 | 04          | AM04 Escavadora da falha negra
17 | $10^(1,44·10^13)  | $e(1,44e13)  | 220 | 04          | AX10 Fole da borda solar
18 | $10^(1,02·10^16)  | $e(1,02e16)  | 220 | 04          | AF04 Fornalha de chama rosa
19 | $10^(1,74·10^19)  | $e(1,74e19)  | 221 | 04          | AX11 Trefila do eclipse
20 | $10^(7,15·10^22)  | $e(7,15e22)  | 221 | 04          | AX12 Ponte de luz polar
21 | $10^(7,02·10^26)  | $e(7,02e26)  | 230 | 05          | AM05 Mineradora arco de luz
22 | $10^(1,65·10^31)  | $e(1,65e31)  | 230 | 05          | AX13 Peneira da magnetosfera
23 | $10^(9,36·10^35)  | $e(9,36e35)  | 230 | 05          | AF05 Fornalha da dobra clara
24 | $10^(1,27·10^41)  | $e(1,27e41)  | 230 | 05          | AX14 Campo de vitrificação
25 | $10^(4,13·10^46)  | $e(4,13e46)  | 231 | 05          | AX15 Válvula de plasma claro
26 | $10^(3,23·10^52)  | $e(3,23e52)  | 243 | 06          | AM06 Escavadora do polo celeste
27 | $10^(6,06·10^58)  | $e(6,06e58)  | 243 | 06          | AX16 Fenda do solstício
28 | $10^(2,73·10^65)  | $e(2,73e65)  | 243 | 06          | AF06 Fornalha do craterio
29 | $10^(2,95·10^72)  | $e(2,95e72)  | 243 | 06          | AX17 Anel da maré ionizada
30 | $10^(7,65·10^79)  | $e(7,65e79)  | 243 | 06          | AX18 Freio de partículas
31 | $10^(4,76·10^87)  | $e(4,76e87)  | 252 | 07          | AM07 Mineradora da coroa rubra
32 | $10^(7,11·10^95)  | $e(7,11e95)  | 252 | 07          | AX19 Crivo de cristal azul
33 | $10^(2,54·10^104) | $e(2,54e104) | 252 | 07          | AF07 Fornalha da aurora escura
34 | $10^(2,19·10^113) | $e(2,19e113) | 253 | 07          | AX20 Cascata da penumbra
35 | $10^(4,52·10^122) | $e(4,52e122) | 253 | 07          | AX21 Estação da coroa violeta
36 | $10^(2,24·10^132) | $e(2,24e132) | 262 | 08          | AM08 Escavadora de horizonte duplo
37 | $10^(2,66·10^142) | $e(2,66e142) | 262 | 08          | AX22 Bolha de heliopausa
38 | $10^(7,6·10^152)  | $e(7,6e152)  | 262 | 08          | AF08 Fornalha da borda branca
39 | $10^(5,2·10^163)  | $e(5,2e163)  | 263 | 08          | AX23 Retificador da luz negra
40 | $10^(8,55·10^174) | $e(8,55e174) | 263 | 08          | AX24 Reator do norte magnético
41 | $10^(3,37·10^186) | $e(3,37e186) | 272 | 09          | AM09 Mineradora da órbita clara
42 | $10^(3,19·10^198) | $e(3,19e198) | 272 | 09          | AX25 Dobradiça da órbita
43 | $10^(7,25·10^210) | $e(7,25e210) | 272 | 09          | AF09 Fornalha da estrela oca
44 | $10^(3,95·10^223) | $e(3,95e223) | 272 | 09          | AX26 Obelisco de chama fria
45 | $10^(5,17·10^236) | $e(5,17e236) | 272 | 09          | AX27 Colisor da coroa branca
46 | $10^(1,62·10^250) | $e(1,62e250) | 283 | 10          | AM10 Escavadora do vazio dourado
47 | $10^(1,22·10^264) | $e(1,22e264) | 283 | 10          | AX28 Câmara de auroras gêmeas
48 | $10^(2,21·10^278) | $e(2,21e278) | 283 | 10          | AF10 Fornalha do sol imóvel
49 | $10^(9,6·10^292)  | $e(9,6e292)  | 283 | 10          | AX29 Torre da magnetocauda
50 | $10^(10^308)      | $e(1e308)    | 284 | 10          | AX30 Núcleo da órbita dourada
```

## Loja e crafts

A [tabela completa da loja](Precos_loja_por_ciclo.md) usa preços por unidade e inclui o valor completo, além do preço local. Os primeiros itens pós-Ascensão ficam disponíveis após a 1ª Ascensão. As outras séries abrem a cada cinco Ascensões concluídas, do 5º ao 45º marco. As Sínteses podem ser montadas a partir da 45ª Ascensão concluída com suas dependências antigas. A partir da 49ª Ascensão concluída entram [três conceitos de ponta](Conceitos_fim_de_ciclo.md), com preço direto de até 20% da meta da 50ª.

## Conferência de produção

A fábrica de referência parte dos efeitos que já estão no catálogo. Considera as melhores mineradoras e fornalhas acessíveis entre loja, Renascimento, craft e o lote novo. Em uma rota de loja, testa 36 modificadores legados compatíveis, uma aplicação de até quatro recompensas já recebidas e até seis peças comerciais. Na rota de craft, o cálculo retira da linha os ingredientes consumidos pelos crafts usados. As sínteses têm sua própria rota. Peças paralelas somariam seus ganhos à renda. Os fatores abaixo correspondem a uma única linha.

O estudo começa com a fábrica já montada, as dependências de Renascimento e os estoques legados disponíveis. O tempo projetado de A02 a A50 foi de **5,3 a 50,7 min** de operação para juntar o saldo final do ciclo, antes de contar o tempo de reconstrução, obtenção de peças e ajustes de esteira. Os preços locais das 100 peças subiram gradualmente. As três ofertas de ponta de A50 são gastos adicionais e ficam fora destas projeções de produção. O par mineradora + fornalha de cada rota, trabalhando sozinho, ficou pelo menos **103 ordens de grandeza** abaixo da meta local por segundo. Este é um cálculo de rendimento em regime, com uma cópia de cada tipo na linha principal. Parte dos estoques pode exigir cópias extras para receitas antigas. A montagem completa e o espaço para esteiras precisam ser verificados na plot.


```text
A  | Rota     | Mineradora                          | Fornalha                        | Mod. na linha | Renda local por segundo     | Minutos em regime
02 | Craft    | Escavadora de zircônia laminada     | Fornalha de sinterização dupla  | 42            | ≈ $4,83·10^175 ($48,3SpQig) | 34,5
03 | Craft    | Escavadora de zircônia laminada     | Fornalha de sinterização dupla  | 43            | ≈ $2,32·10^178 ($23,2OQig)  | 7,2
04 | Craft    | Escavadora de zircônia laminada     | Fornalha do alvorecer           | 43            | ≈ $3,48·10^178 ($34,8OQig)  | 47,9
05 | Craft    | Escavadora de zircônia laminada     | Fornalha do alvorecer           | 44            | ≈ $2,09·10^181 ($20,9NQig)  | 8
06 | Loja     | Escavadora de banho criogênico      | Fornalha de hélio comprimido    | 45            | ≈ $1,3·10^194 ($130TSxg)    | 12,8
07 | Loja     | Escavadora de banho criogênico      | Fornalha de hélio comprimido    | 45            | ≈ $1,3·10^194 ($130TSxg)    | 12,8
08 | Loja     | Escavadora de banho criogênico      | Fornalha de hélio comprimido    | 46            | ≈ $9,44·10^196 ($94,4QaSxg) | 17,6
09 | Loja     | Escavadora de banho criogênico      | Fornalha da vigília             | 46            | ≈ $3,78·10^197 ($378QaSxg)  | 44,1
10 | Loja     | Escavadora de banho criogênico      | Fornalha da vigília             | 46            | ≈ $7,08·10^197 ($708QaSxg)  | 23,5
11 | Loja     | Escavadora de tungstênio solar      | Fornalha de arco de tungstênio  | 46            | ≈ $6,91·10^206 ($691SpSxg)  | 24,1
12 | Loja     | Escavadora de tungstênio solar      | Fornalha de arco de tungstênio  | 46            | ≈ $6,91·10^206 ($691SpSxg)  | 24,1
13 | Loja     | Escavadora de tungstênio solar      | Fornalha de arco de tungstênio  | 46            | ≈ $1,03·10^207 ($1,03OSxg)  | 16,1
14 | Loja     | Escavadora de tungstênio solar      | Fornalha do vento polar         | 46            | ≈ $3,1·10^207 ($3,1OSxg)    | 5,4
15 | Loja     | Escavadora de tungstênio solar      | Fornalha do vento polar         | 46            | ≈ $5,3·10^207 ($5,3OSxg)    | 31,5
16 | Loja     | Escavadora de quartzo de fase       | Fornalha de espelhos de fase    | 46            | ≈ $5,5·10^216 ($5,5USpg)    | 30,3
17 | Loja     | Escavadora de quartzo de fase       | Fornalha de espelhos de fase    | 46            | ≈ $5,5·10^216 ($5,5USpg)    | 30,3
18 | Loja     | Escavadora de quartzo de fase       | Fornalha de espelhos de fase    | 46            | ≈ $8,29·10^216 ($8,29USpg)  | 20,1
19 | Loja     | Escavadora de quartzo de fase       | Fornalha de chama rosa          | 46            | ≈ $3,32·10^217 ($33,2USpg)  | 50,3
20 | Loja     | Escavadora de quartzo de fase       | Fornalha de chama rosa          | 46            | ≈ $5,6·10^217 ($56USpg)     | 29,8
21 | Loja     | Escavadora de lentes gravíticas     | Fornalha de poço gravítico      | 46            | ≈ $4,26·10^226 ($42,6QaSpg) | 39,2
22 | Loja     | Escavadora de lentes gravíticas     | Fornalha de poço gravítico      | 46            | ≈ $4,26·10^226 ($42,6QaSpg) | 39,2
23 | Loja     | Escavadora de lentes gravíticas     | Fornalha de poço gravítico      | 46            | ≈ $6,31·10^226 ($63,1QaSpg) | 26,4
24 | Loja     | Escavadora de lentes gravíticas     | Fornalha da dobra clara         | 46            | ≈ $1,89·10^227 ($189QaSpg)  | 8,8
25 | Loja     | Escavadora de lentes gravíticas     | Fornalha da dobra clara         | 46            | ≈ $3,29·10^227 ($329QaSpg)  | 50,7
26 | Craft    | Escavadora de cavidades gêmeas      | Fornalha de expansão pulsada    | 46            | ≈ $3,79·10^239 ($379OSpg)   | 44
27 | Craft    | Escavadora de cavidades gêmeas      | Fornalha de expansão pulsada    | 46            | ≈ $3,79·10^239 ($379OSpg)   | 44
28 | Craft    | Escavadora de cavidades gêmeas      | Fornalha de expansão pulsada    | 46            | ≈ $5,96·10^239 ($596OSpg)   | 28
29 | Craft    | Escavadora de cavidades gêmeas      | Fornalha do craterio            | 46            | ≈ $1,19·10^240 ($1,19NSpg)  | 14
30 | Craft    | Escavadora de cavidades gêmeas      | Fornalha do craterio            | 46            | ≈ $2,01·10^240 ($2,01NSpg)  | 8,3
31 | Craft    | Escavadora de partículas rarefeitas | Fornalha de aniquilação pulsada | 46            | ≈ $2,17·10^249 ($2,17DOg)   | 7,7
32 | Craft    | Escavadora de partículas rarefeitas | Fornalha de aniquilação pulsada | 46            | ≈ $2,17·10^249 ($2,17DOg)   | 7,7
33 | Craft    | Escavadora de partículas rarefeitas | Fornalha de aniquilação pulsada | 46            | ≈ $3,12·10^249 ($3,12DOg)   | 5,3
34 | Craft    | Escavadora de partículas rarefeitas | Fornalha da aurora escura       | 46            | ≈ $4,68·10^249 ($4,68DOg)   | 35,6
35 | Craft    | Escavadora de partículas rarefeitas | Fornalha da aurora escura       | 46            | ≈ $8,14·10^249 ($8,14DOg)   | 20,5
36 | Craft    | Escavadora de espelhos convergentes | Fornalha de foco duplo          | 46            | ≈ $1,2·10^259 ($12QiOg)     | 13,9
37 | Craft    | Escavadora de espelhos convergentes | Fornalha de foco duplo          | 46            | ≈ $1,2·10^259 ($12QiOg)     | 13,9
38 | Craft    | Escavadora de espelhos convergentes | Fornalha de foco duplo          | 46            | ≈ $1,84·10^259 ($18,4QiOg)  | 9,1
39 | Craft    | Escavadora de espelhos convergentes | Fornalha da borda branca        | 46            | ≈ $3,67·10^259 ($36,7QiOg)  | 45,4
40 | Craft    | Escavadora de espelhos convergentes | Fornalha da borda branca        | 46            | ≈ $6,39·10^259 ($63,9QiOg)  | 26,1
41 | Craft    | Escavadora do horizonte reverso     | Fornalha de gradiente focal     | 46            | ≈ $6,16·10^268 ($61,6OOg)   | 27,1
42 | Craft    | Escavadora do horizonte reverso     | Fornalha de gradiente focal     | 46            | ≈ $6,16·10^268 ($61,6OOg)   | 27,1
43 | Craft    | Escavadora do horizonte reverso     | Fornalha de gradiente focal     | 46            | ≈ $9,31·10^268 ($93,1OOg)   | 17,9
44 | Craft    | Escavadora do horizonte reverso     | Fornalha da estrela oca         | 46            | ≈ $1,4·10^269 ($140OOg)     | 11,9
45 | Craft    | Escavadora do horizonte reverso     | Fornalha da estrela oca         | 46            | ≈ $2,36·10^269 ($236OOg)    | 7,1
46 | Sínteses | Mineradora síntese da ascensão      | Fornalha síntese da ascensão    | 5             | ≈ $2,07·10^280 ($20,7DNg)   | 8,1
47 | Sínteses | Mineradora síntese da ascensão      | Fornalha síntese da ascensão    | 5             | ≈ $2,07·10^280 ($20,7DNg)   | 8,1
48 | Sínteses | Mineradora síntese da ascensão      | Fornalha síntese da ascensão    | 5             | ≈ $3,03·10^280 ($30,3DNg)   | 5,5
49 | Sínteses | Mineradora síntese da ascensão      | Fornalha síntese da ascensão    | 5             | ≈ $3,03·10^280 ($30,3DNg)   | 5,5
50 | Sínteses | Mineradora síntese da ascensão      | Fornalha síntese da ascensão    | 5             | ≈ $5,34·10^280 ($53,4DNg)   | 31,2
```

## Reconstrução após Ascensão

A [rota de Renascimento e loja intermediária](Progressao_renascimento_loja_intermediaria.md) fecha a primeira Ascensão em $10^308 ($100UCe) no 50º marco. A projeção usa as entregas garantidas e contabiliza as compras antes de cada meta. Na Ascensão, as recompensas dessa família reiniciam. Os 127 modelos legados voltam a alimentar os crafts, com os valores locais da tabela de preços.

Depois da primeira Ascensão, o Renascimento tem uma curva local de $10^21 ($1Sx) a $10^119 ($100OTg) para recuperar as dependências das receitas. Cada ciclo sobe dois expoentes e cada vida extra sobe três. O marco local de cada Renascimento recebe o mesmo deslocamento do ciclo de Ascensão. Para um craft, o jogador só precisa chegar às entregas indicadas na ficha. Receitas que reutilizam a mesma recompensa ainda exigem as cópias correspondentes. Essa aquisição pode estender o ciclo além dos tempos da tabela.

## Conferências locais

A lista tem 50 metas crescentes, 50 recompensas distintas, 100 preços de loja e 100 fichas de craft. Os preços completos de estreia das 100 máquinas pós-Ascensão ficam acima de 10^308. Os dez modelos pós-Ascensão antes aditivos passam a multiplicar com dois usos base. As tabelas de tempo pós-Ascensão são a referência de fábrica pronta. A duração da recuperação das cópias de receita, a montagem e o formato de saldo no jogo ainda exigem validação.
