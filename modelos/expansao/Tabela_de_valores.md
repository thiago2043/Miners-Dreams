# Tabela de valores das máquinas de loja e craft

**Miners Dreams · expansão de loja e craft.** São 50 máquinas para a loja e 50 de craft. Os códigos correspondem às folhas de [modelagem](README.md). Valores em potência de dez aparecem com a abreviação atual do jogo entre parênteses.

As medidas seguem largura × comprimento × altura em blocos de 3 studs. Taxas e efeitos são de base, antes de Extração, Fundição, Motores e Calibração.

**Limite** reúne usos por tipo e valor de entrada na mesma coluna. Por exemplo, `3 e < $...` permite três aplicações por minério e exige que o valor ao entrar em cada faixa seja inferior ao teto. O uso começa na primeira faixa válida e conta para a máquina inteira. Os fatores seguem a ordem das faixas. O efeito total é o produto quando todas as faixas aplicam. Arredondar em cada faixa pode mudar o resultado para minérios pequenos. Para os somadores, a passagem acrescenta o valor indicado.

**Compras da receita** soma os preços dos ingredientes de loja em todos os ramos, com arredondamento visual a três algarismos. É uma referência de compra, considerando uma unidade de cada ingrediente e estoque inicial vazio. O craft usa a [receita de peças](Receitas.md) como custo. **Renasc. mínimo** conta o primeiro ciclo em que todos os tipos de recompensa exigidos já podem ter sido entregues pelo cronograma garantido, supondo que o jogador guarde as peças. O saldo para comprar os demais ingredientes ainda precisa ser obtido.

**Bandeja e correia.** Piso é 0,9375 stud acima da base. Os níveis +1 e +2 sobem um e dois blocos. Desvio de −0,5 bloco é medido no eixo lateral local. A velocidade de referência para as correias é de 2 blocos/s.

## Loja

### Mineradoras

```text
código e máquina                  | minérios/s | valor do minério   | hitbox | avanço da saída | preço da máquina

LM01 Mineradora de magnetita      | 0,8        | $1,2·10^9 ($1,2B)  | 3x3x2  | 1,5             | $5·10^35 ($500De)
LM02 Mineradora de granito        | 1          | $8·10^9 ($8B)      | 4x3x3  | 1,5             | $2·10^37 ($20UDe)
LM03 Mineradora de xisto          | 0,8        | $4,5·10^10 ($45B)  | 3x4x3  | 2,5             | $5·10^39 ($5DDe)
LM04 Mineradora de carbeto        | 1          | $2,5·10^11 ($250B) | 4x4x3  | 2,5             | $2·10^43 ($20TDe)
LM05 Mineradora tectônica         | 0,8        | $4·10^12 ($4T)     | 5x4x4  | 2,5             | $10^48 ($1QiDe)
LM06 Mineradora criogênica        | 1          | $4·10^13 ($40T)    | 5x5x4  | 2,5             | $2·10^54 ($2SpDe)
LM07 Mineradora piroclástica      | 0,8        | $5·10^15 ($5Qd)    | 5x6x5  | 3,5             | $10^64 ($10Vi)
LM08 Mineradora antigravitacional | 0,8        | $2·10^19 ($20Qn)   | 6x5x5  | 3,5             | $10^80 ($100QiVi)
LM09 Mineradora periastro         | 1          | $5·10^24 ($5Sp)    | 7x6x5  | 3,5             | $10^100 ($10DTg)
LM10 Mineradora paralaxe          | 0,8        | $5·10^31 ($50N)    | 7x7x6  | 4,5             | $10^128 ($100UQag)
```

### Fornalhas

```text
código e máquina              | multiplicador de venda | hitbox | bandeja L×C / nível / desvio | preço da fornalha

LF01 Fornalha de reverbero    | x1,25·10^2 (x125)      | 3x3x1  | 2x2 / piso / -0,5            | $7,5·10^35 ($750De)
LF02 Fornalha de basalto      | x3·10^2 (x300)         | 3x4x2  | 2x2 / piso / -0,5            | $5·10^37 ($50UDe)
LF03 Fornalha de ar quente    | x1,2·10^3 (x1,2K)      | 4x3x2  | 2x2 / piso                   | $10^41 ($100DDe)
LF04 Fornalha contrafluxo     | x6·10^3 (x6K)          | 4x4x3  | 2x2 / piso                   | $10^45 ($1QaDe)
LF05 Fornalha espiral térmica | x5·10^4 (x50K)         | 4x5x3  | 2x2 / piso                   | $10^51 ($1SxDe)
LF06 Fornalha safira          | x10^6 (x1M)            | 5x4x4  | 2x2 / piso / -0,5            | $10^59 ($100ODe)
LF07 Fornalha de arco solar   | x3·10^8 (x300M)        | 4x5x4  | 2x2 / piso                   | $10^71 ($100DVi)
LF08 Fornalha planalto        | x2·10^12 (x2T)         | 6x4x3  | 2x2 / piso                   | $10^86 ($100SpVi)
LF09 Fornalha de nácar        | x5·10^17 (x500Qd)      | 5x5x5  | 2x2 / piso / -0,5            | $10^106 ($10QaTg)
LF10 Fornalha limite polar    | x2·10^26 (x200Sp)      | 6x6x5  | 2x2 / piso                   | $10^136 ($10QaQag)
```

### Modificadores

```text
código e máquina                | limite                  | multiplicadores/somador por faixa                                           | efeito total      | hitbox | correia L×C / nível / desvio | faixas | preço do modificador

LX01 Pente de magnetita         | 3 e < $5·10^11 ($500B)  | +5·10^9 (+5B)                                                               | +5·10^9 (+5B)     | 2x1x1  | 2x1 / piso                   | 1      | $6·10^35 ($600De)
LX02 Morsa de cromo             | 2 e < $10^24 ($1Sp)     | x7·10^0 (x7)                                                                | x7·10^0 (x7)      | 3x1x2  | 2x1 / piso / -0,5            | 1      | $10^36 ($1UDe)
LX03 Filtro de vermiculita      | 3 e < $10^14 ($100T)    | +4·10^11 (+400B)                                                            | +4·10^11 (+400B)  | 3x2x1  | 2x2 / piso / -0,5            | 1      | $3·10^36 ($3UDe)
LX04 Duto de hidrogênio         | 1 e < $10^28 ($10O)     | x10^1 (x10)                                                                 | x10^1 (x10)       | 3x2x2  | 2x2 / piso / -0,5            | 1      | $10^37 ($10UDe)
LX05 Peneira de turmalina       | 1 e < $10^30 ($1N)      | x3·10^0 (x3), depois x4·10^0 (x4)                                           | x1,2·10^1 (x12)   | 2x2x1  | 2x2 / piso                   | 2      | $3·10^37 ($30UDe)
LX06 Prensa de calcita          | 1                       | x1,4·10^1 (x14)                                                             | x1,4·10^1 (x14)   | 4x2x2  | 2x2 / piso                   | 1      | $10^38 ($100UDe)
LX07 Reator de zinco            | 1 e < $10^36 ($1UDe)    | x4·10^0 (x4), depois x4·10^0 (x4)                                           | x1,6·10^1 (x16)   | 4x3x2  | 2x3 / piso                   | 2      | $5·10^38 ($500UDe)
LX08 Leitor espectral           | 1                       | x1,8·10^1 (x18)                                                             | x1,8·10^1 (x18)   | 2x2x2  | 1x2 / piso / -0,5            | 1      | $10^40 ($10DDe)
LX09 Tambor de separação        | 1 e < $10^42 ($1TDe)    | x4·10^0 (x4), depois x5·10^0 (x5)                                           | x2·10^1 (x20)     | 3x3x2  | 2x3 / piso / -0,5            | 2      | $3·10^40 ($30DDe)
LX10 Banho refratário           | 1 e < $10^44 ($100TDe)  | x4·10^0 (x4), depois x5,5·10^0 (x5,5)                                       | x2,2·10^1 (x22)   | 4x2x1  | 2x2 / piso                   | 2      | $10^42 ($1TDe)
LX11 Prisma de fluorita         | 1 e < $10^50 ($100QiDe) | x4·10^0 (x4), depois x6·10^0 (x6)                                           | x2,4·10^1 (x24)   | 4x3x2  | 2x3 / piso                   | 2      | $5·10^43 ($50TDe)
LX12 Ponte de indução           | 1                       | x4·10^0 (x4), depois x7·10^0 (x7)                                           | x2,8·10^1 (x28)   | 4x3x3  | 2x3 / +1                     | 2      | $10^45 ($1QaDe)
LX13 Colimador boreal           | 1                       | x5·10^0 (x5), depois x6·10^0 (x6)                                           | x3·10^1 (x30)     | 3x4x2  | 2x4 / piso / -0,5            | 2      | $10^47 ($100QaDe)
LX14 Pórtico piezoelétrico      | 1                       | x5·10^0 (x5), depois x7·10^0 (x7)                                           | x3,5·10^1 (x35)   | 4x3x2  | 2x3 / piso                   | 2      | $10^49 ($10QiDe)
LX15 Cavidade de rubídio        | 1                       | x5·10^0 (x5), depois x8·10^0 (x8)                                           | x4·10^1 (x40)     | 3x3x2  | 2x3 / piso / -0,5            | 2      | $10^51 ($1SxDe)
LX16 Trilho de háfnio           | 1                       | x2·10^0 (x2), depois x4·10^0 (x4), depois x6·10^0 (x6)                      | x4,8·10^1 (x48)   | 4x4x3  | 2x4 / +1                     | 3      | $10^54 ($1SpDe)
LX17 Bobina de samário          | 1                       | x5·10^0 (x5), depois x10^1 (x10)                                            | x5·10^1 (x50)     | 4x3x2  | 2x3 / piso                   | 2      | $10^57 ($1ODe)
LX18 Pulso de ferrofluido       | 1                       | x2·10^0 (x2), depois x5·10^0 (x5), depois x6·10^0 (x6)                      | x6·10^1 (x60)     | 3x4x2  | 2x4 / piso / -0,5            | 3      | $10^60 ($1NDe)
LX19 Dobrador de luz            | 1                       | x6·10^0 (x6), depois x10^1 (x10)                                            | x6·10^1 (x60)     | 2x3x3  | 1x3 / +1 / -0,5              | 2      | $10^64 ($10Vi)
LX20 Ressonador de cobre branco | 1                       | x7·10^0 (x7), depois x10^1 (x10)                                            | x7·10^1 (x70)     | 5x3x3  | 2x3 / piso / -0,5            | 2      | $10^68 ($100UVi)
LX21 Malha de silício           | 1                       | x2·10^0 (x2), depois x5·10^0 (x5), depois x8·10^0 (x8)                      | x8·10^1 (x80)     | 4x4x2  | 2x4 / piso                   | 3      | $10^72 ($1TVi)
LX22 Inversor de fluxo          | 1                       | x3·10^0 (x3), depois x5·10^0 (x5), depois x6·10^0 (x6)                      | x9·10^1 (x90)     | 5x4x3  | 2x4 / +1 / -0,5              | 3      | $10^77 ($100QaVi)
LX23 Gaveta de antimônio        | 1                       | x4·10^0 (x4), depois x5·10^0 (x5), depois x5·10^0 (x5)                      | x10^2 (x100)      | 4x3x2  | 2x3 / piso                   | 3      | $10^83 ($100SxVi)
LX24 Difusor de hélio           | 1                       | x2·10^0 (x2), depois x5·10^0 (x5), depois x10^1 (x10)                       | x10^2 (x100)      | 4x5x4  | 2x5 / +1                     | 3      | $10^90 ($1NVi)
LX25 Limiar de irídio           | 1                       | x4·10^0 (x4), depois x5·10^0 (x5), depois x6·10^0 (x6)                      | x1,2·10^2 (x120)  | 5x4x3  | 2x4 / piso / -0,5            | 3      | $10^98 ($100UTg)
LX26 Forquilha de césio         | 1                       | x3·10^0 (x3), depois x5·10^0 (x5), depois x8·10^0 (x8)                      | x1,2·10^2 (x120)  | 4x4x4  | 2x4 / +2                     | 3      | $10^107 ($100QaTg)
LX27 Cicatriz de plasma         | 1                       | x3·10^0 (x3), depois x5·10^0 (x5), depois x9·10^0 (x9)                      | x1,35·10^2 (x135) | 5x5x2  | 2x5 / piso / -0,5            | 3      | $10^116 ($100SpTg)
LX28 Estação de penumbra        | 1                       | x3·10^0 (x3), depois x5·10^0 (x5), depois x10^1 (x10)                       | x1,5·10^2 (x150)  | 5x5x4  | 2x5 / +1 / -0,5              | 3      | $10^126 ($1UQag)
LX29 Divisor de marfim          | 1                       | x2·10^0 (x2), depois x3·10^0 (x3), depois x5·10^0 (x5), depois x6·10^0 (x6) | x1,8·10^2 (x180)  | 5x6x3  | 2x6 / piso / -0,5            | 4      | $10^137 ($100QaQag)
LX30 Portal de Van Allen        | 1                       | x2·10^0 (x2), depois x4·10^0 (x4), depois x5·10^0 (x5), depois x6·10^0 (x6) | x2,4·10^2 (x240)  | 6x5x5  | 2x5 / +2                     | 4      | $10^147 ($1OQag)
```

## Craft

### Mineradoras

```text
código e máquina                 | minérios/s | valor do minério    | hitbox  | avanço da saída | renasc. mínimo | compras da receita

CM01 Escavadora de estratos      | 1          | $1,5·10^11 ($150B)  | 5x5x4   | 2,5             | 6º             | ≈ $1,01·10^7 ($10,1M)
CM02 Escavadora de caldeira      | 1          | $2·10^14 ($200T)    | 6x5x5   | 2,5             | 11º            | ≈ $1,02·10^14 ($102T)
CM03 Mineradora eixo polar       | 1          | $2·10^18 ($2Qn)     | 6x6x5   | 3,5             | 16º            | ≈ $2,53·10^21 ($2,53Sx)
CM04 Mineradora contrapeso       | 1          | $3·10^23 ($300Sx)   | 7x6x5   | 3,5             | 26º            | ≈ $5,02·10^39 ($5,02DDe)
CM05 Escavadora do limiar        | 1          | $3·10^29 ($300O)    | 7x7x6   | 3,5             | 36º            | ≈ $10^64 ($10Vi)
CM06 Escavadora do afélio        | 1          | $4·10^36 ($4UDe)    | 8x7x6   | 4,5             | 46º            | ≈ $10^128 ($100UQag)
CM07 Extratora cordilheira       | 1          | $5·10^14 ($500T)    | 8x8x6   | 4,5             | 11º            | ≈ $1,02·10^14 ($102T)
CM08 Extratora da magnetosfera   | 1          | $8·10^23 ($800Sx)   | 9x8x7   | 4,5             | 26º            | ≈ $5,02·10^39 ($5,02DDe)
CM09 Extratora núcleo de estrela | 1          | $1,2·10^37 ($12UDe) | 9x9x7   | 4,5             | 46º            | ≈ $10^128 ($100UQag)
CM10 Escavadora convergência     | 1          | $10^38 ($100UDe)    | 11x10x8 | 5,5             | 46º            | ≈ $10^128 ($100UQag)
```

### Fornalhas

```text
código e máquina               | multiplicador de venda | hitbox | bandeja L×C / nível / desvio | renasc. mínimo | compras da receita

CF01 Fornalha crisol duplo     | x1,5·10^4 (x15K)       | 4x4x3  | 2x2 / piso                   | 7º             | ≈ $5,01·10^8 ($501M)
CF02 Fornalha espelho fundido  | x2·10^7 (x20M)         | 5x4x4  | 2x2 / piso / -0,5            | 12º            | ≈ $1,03·10^15 ($1,03Qd)
CF03 Fornalha cerâmica iônica  | x2·10^11 (x200B)       | 5x5x4  | 2x2 / piso / -0,5            | 17º            | ≈ $7,5·10^35 ($750De)
CF04 Fornalha câmara de hélio  | x3·10^16 (x30Qd)       | 6x5x4  | 2x2 / piso                   | 27º            | ≈ $10^45 ($1QaDe)
CF05 Fornalha arco abissal     | x3·10^23 (x300Sx)      | 5x6x5  | 2x2 / piso / -0,5            | 37º            | ≈ $10^71 ($100DVi)
CF06 Fornalha chama fria       | x4·10^31 (x40N)        | 6x5x5  | 2x2 / piso                   | 47º            | ≈ $10^136 ($10QaQag)
CF07 Fornalha coroa refratária | x5·10^7 (x50M)         | 6x6x6  | 2x2 / piso                   | 12º            | ≈ $1,03·10^15 ($1,03Qd)
CF08 Fornalha bifurcação       | x8·10^16 (x80Qd)       | 7x6x5  | 2x2 / piso / -0,5            | 27º            | ≈ $10^45 ($1QaDe)
CF09 Fornalha aurora tripla    | x1,2·10^32 (x120N)     | 7x7x6  | 2x2 / piso / -0,5            | 47º            | ≈ $10^136 ($10QaQag)
CF10 Fornalha convergência     | x10^33 (x1De)          | 9x8x7  | 2x2 / piso / -0,5            | 47º            | ≈ $10^136 ($10QaQag)
```

### Modificadores

```text
código e máquina              | limite | multiplicadores/somador por faixa                                                                                     | efeito total      | hitbox | correia L×C / nível / desvio | faixas | renasc. mínimo | compras da receita

CX01 Comutador ferro-prisma   | 1      | x4·10^0 (x4), depois x10^1 (x10)                                                                                      | x4·10^1 (x40)     | 3x3x2  | 2x3 / piso / -0,5            | 2      | 13º            | ≈ $6,1·10^4 ($61K)
CX02 Peneira pressurizada     | 1      | x5·10^0 (x5), depois x10^1 (x10)                                                                                      | x5·10^1 (x50)     | 4x3x2  | 2x3 / piso                   | 2      | 19º            | ≈ $2,48·10^6 ($2,48M)
CX03 Ponte dos cristais       | 1      | x6·10^0 (x6), depois x9·10^0 (x9)                                                                                     | x5,4·10^1 (x54)   | 4x3x3  | 2x3 / piso                   | 2      | 20º            | $5,95·10^8 ($595M)
CX04 Coletor de marfim        | 1      | x6·10^0 (x6), depois x10^1 (x10)                                                                                      | x6·10^1 (x60)     | 3x4x2  | 2x4 / piso / -0,5            | 2      | 23º            | $5,01·10^12 ($5,01T)
CX05 Dobra térmica            | 1      | x8·10^0 (x8), depois x10^1 (x10)                                                                                      | x8·10^1 (x80)     | 4x3x3  | 2x3 / +1                     | 2      | 25º            | $5,43·10^15 ($5,43Qd)
CX06 Bobina criomagnética     | 1      | x7·10^0 (x7), depois x1,1·10^1 (x11)                                                                                  | x7,7·10^1 (x77)   | 4x4x2  | 2x4 / piso                   | 2      | 24º            | $9,4·10^17 ($940Qd)
CX07 Refletor de cobalto      | 1      | x9·10^0 (x9), depois x1,1·10^1 (x11)                                                                                  | x9,9·10^1 (x99)   | 3x3x2  | 2x3 / piso / -0,5            | 2      | 30º            | ≈ $4,43·10^20 ($443Qn)
CX08 Cadinho de sol           | 1      | x4·10^0 (x4), depois x5·10^0 (x5), depois x5·10^0 (x5)                                                                | x10^2 (x100)      | 4x4x2  | 2x4 / piso                   | 3      | 29º            | ≈ $4,01·10^24 ($4,01Sp)
CX09 Estrangulador de campo   | 1      | x4·10^0 (x4), depois x4·10^0 (x4), depois x6·10^0 (x6)                                                                | x9,6·10^1 (x96)   | 4x4x3  | 2x4 / +1                     | 3      | 30º            | ≈ $4,35·10^27 ($4,35O)
CX10 Fenda de quartzo         | 1      | x4·10^0 (x4), depois x5·10^0 (x5), depois x5·10^0 (x5)                                                                | x10^2 (x100)      | 2x4x3  | 1x4 / +1 / -0,5              | 3      | 34º            | ≈ $1,54·10^29 ($154O)
CX11 Cascata de indução       | 1      | x4·10^0 (x4), depois x5·10^0 (x5), depois x6·10^0 (x6)                                                                | x1,2·10^2 (x120)  | 4x4x3  | 2x4 / +1                     | 3      | 35º            | $1,21·10^31 ($12,1N)
CX12 Relé de vapor            | 1      | x3·10^0 (x3), depois x3·10^0 (x3), depois x1,1·10^1 (x11)                                                             | x9,9·10^1 (x99)   | 4x3x2  | 2x3 / piso                   | 3      | 33º            | $3,7·10^32 ($370N)
CX13 Linha radiante           | 1      | x5·10^0 (x5), depois x5·10^0 (x5), depois x6·10^0 (x6)                                                                | x1,5·10^2 (x150)  | 5x4x3  | 2x4 / piso / -0,5            | 3      | 39º            | $9,2·10^35 ($920De)
CX14 Ampola de espectro       | 1      | x3·10^0 (x3), depois x5·10^0 (x5), depois x1,5·10^1 (x15)                                                             | x2,25·10^2 (x225) | 3x4x4  | 2x4 / +2 / -0,5              | 3      | 40º            | $4,4·10^37 ($44UDe)
CX15 Garra da magnetopausa    | 1      | x4·10^0 (x4), depois x5·10^0 (x5), depois x5·10^0 (x5)                                                                | x10^2 (x100)      | 5x4x3  | 2x4 / piso / -0,5            | 3      | 44º            | $4,06·10^40 ($40,6DDe)
CX16 Ressonador de basalto    | 1      | x3·10^0 (x3), depois x6·10^0 (x6), depois x10^1 (x10)                                                                 | x1,8·10^2 (x180)  | 5x5x3  | 2x5 / +1 / -0,5              | 3      | 45º            | ≈ $1,01·10^47 ($101QaDe)
CX17 Sonda do antipolo        | 1      | x3·10^0 (x3), depois x4·10^0 (x4), depois x9·10^0 (x9)                                                                | x1,08·10^2 (x108) | 2x4x4  | 1x4 / +2 / -0,5              | 3      | 45º            | ≈ $10^60 ($1NDe)
CX18 Retificador de maré      | 1      | x5·10^0 (x5), depois x6·10^0 (x6), depois x1,2·10^1 (x12)                                                             | x3,6·10^2 (x360)  | 5x5x4  | 2x5 / +1 / -0,5              | 3      | 48º            | ≈ $10^77 ($100QaVi)
CX19 Pórtico da forja         | 1      | x5·10^0 (x5), depois x8·10^0 (x8), depois x1,2·10^1 (x12)                                                             | x4,8·10^2 (x480)  | 5x5x3  | 2x5 / piso / -0,5            | 3      | 50º            | ≈ $10^107 ($100QaTg)
CX20 Circuito de antimatéria  | 1      | x6·10^0 (x6), depois x8·10^0 (x8), depois x10^1 (x10)                                                                 | x4,8·10^2 (x480)  | 6x4x4  | 2x4 / +1                     | 3      | 50º            | ≈ $10^147 ($1OQag)
CX21 Matriz de amplificação   | 1      | x3·10^0 (x3), depois x4·10^0 (x4), depois x4·10^0 (x4), depois x5·10^0 (x5)                                           | x2,4·10^2 (x240)  | 5x5x4  | 2x5 / +1 / -0,5              | 4      | 23º            | ≈ $5,01·10^12 ($5,01T)
CX22 Nave de irradiação       | 1      | x3·10^0 (x3), depois x4·10^0 (x4), depois x5·10^0 (x5), depois x5·10^0 (x5)                                           | x3·10^2 (x300)    | 6x5x4  | 2x5 / +1                     | 4      | 30º            | ≈ $4,43·10^20 ($443Qn)
CX23 Coroa de cisalha         | 1      | x3·10^0 (x3), depois x4·10^0 (x4), depois x5·10^0 (x5), depois x6·10^0 (x6)                                           | x3,6·10^2 (x360)  | 5x6x4  | 2x6 / +1 / -0,5              | 4      | 34º            | ≈ $1,58·10^29 ($158O)
CX24 Coletor de duas fases    | 1      | x4·10^0 (x4), depois x4·10^0 (x4), depois x5·10^0 (x5), depois x6·10^0 (x6)                                           | x4,8·10^2 (x480)  | 6x5x5  | 2x5 / +2                     | 4      | 40º            | ≈ $4,49·10^37 ($44,9UDe)
CX25 Condutor de eclipse      | 1      | x3·10^0 (x3), depois x4·10^0 (x4), depois x5·10^0 (x5), depois x7·10^0 (x7)                                           | x4,2·10^2 (x420)  | 6x6x4  | 2x6 / +1                     | 4      | 45º            | ≈ $10^60 ($1NDe)
CX26 Malha do zênite          | 1      | x4·10^0 (x4), depois x5·10^0 (x5), depois x5·10^0 (x5), depois x6·10^0 (x6)                                           | x6·10^2 (x600)    | 6x6x5  | 2x6 / +2                     | 4      | 50º            | ≈ $10^147 ($1OQag)
CX27 Reator da coroa solar    | 1      | x4·10^0 (x4), depois x5·10^0 (x5), depois x5·10^0 (x5), depois x5·10^0 (x5)                                           | x5·10^2 (x500)    | 7x6x5  | 2x6 / +1 / -0,5              | 4      | 30º            | ≈ $4,43·10^20 ($443Qn)
CX28 Arco dos horizontes      | 1      | x4·10^0 (x4), depois x5·10^0 (x5), depois x5·10^0 (x5), depois x6·10^0 (x6)                                           | x6·10^2 (x600)    | 7x7x6  | 2x7 / +2 / -0,5              | 4      | 40º            | ≈ $4,49·10^37 ($44,9UDe)
CX29 Câmara do ponto zero     | 1      | x4·10^0 (x4), depois x5·10^0 (x5), depois x5·10^0 (x5), depois x8·10^0 (x8)                                           | x8·10^2 (x800)    | 7x8x5  | 2x8 / +1 / -0,5              | 4      | 50º            | ≈ $10^147 ($1OQag)
CX30 Modificador convergência | 1      | x2·10^0 (x2), depois x2·10^0 (x2), depois x2·10^0 (x2), depois x5·10^0 (x5), depois x5·10^0 (x5), depois x5·10^0 (x5) | x10^3 (x1K)       | 9x9x6  | 2x9 / piso / -0,5            | 6      | 50º            | ≈ $10^147 ($1OQag)
```

## Referência para a progressão

As 50 novas máquinas entram acima do maior preço da loja atual. Hoje, o Núcleo dimensional custa $2,5·10^35 ($250De). A nova faixa começa em $5·10^35 ($500De) e chega a $10^147 ($1OQag).

Os crafts dependem do ramo de ingredientes e por isso a potência e o ciclo mínimo podem subir ou descer entre códigos vizinhos. Cada craft melhora o efeito de uma unidade do ingrediente mais forte da mesma categoria.

36 dos 60 modificadores têm fator por passagem de até ×100. Para o mesmo tipo, o limite proposto também mantém a multiplicação acumulada até ×1K. Cada craft modificador tem uma aplicação por minério e a redução de espaço faz parte do ganho, já que o fator da peça não equivale ao produto de todos os ingredientes da árvore.

A Escavadora Convergência gera um minério de $10^38 ($100UDe) por segundo. A Fornalha Convergência vende a x10^33 (x1De) e o Modificador Convergência aplica x10^3 (x1K) ao completar suas seis faixas. Uma linha que vende toda essa produção com os três efeitos rende $10^74 ($100TVi)/s antes dos upgrades e de outros modificadores.

O saldo por ciclo depende das máquinas atuais, das cópias disponíveis, da rota e do espaço da fábrica. As três convergências exigem o fim da árvore de receitas e não entram nas estimativas de renda dos primeiros ciclos.
