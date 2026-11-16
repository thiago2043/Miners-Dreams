# Especificação das máquinas de renascimento

**Miners Dreams · especificação das recompensas.** São **60 modelos** integrados ao catálogo, com 7 mineradoras, 7 fornalhas e 46 modificadores. Os efeitos e as entregas abaixo estão implementados. Os requisitos monetários e a mecânica de `10^308` permanecem como proposta para a progressão futura.

A hitbox usa **largura × comprimento × altura**, em blocos de **3 studs**. Os valores aparecem em potência de dez e, entre parênteses, na abreviação do jogo. O formatador exibe `10^308` (100UCe) e usa notação científica após a faixa de sufixos.

## Entrega e requisitos

Cada reinicialização entrega **1 ou 2 peças garantidas** do conjunto correspondente. Os ciclos **1º–5º** distribuem o lote do 5º, **6º–10º** distribuem o do 10º, e assim por diante. Até o marco, todos os tipos daquele lote são entregues. Lotes com três tipos repetem peças nos dois últimos ciclos. O contador avança uma posição por reinicialização, mesmo quando ela dá várias vidas. Após o 50º, repete-se a distribuição do último lote.

- Cada vida acima da primeira dá um sorteio com chances iguais entre os tipos já obtidos, incluindo os tipos garantidos na operação atual. Cópias podem acumular no inventário acima do limite de usos por minério.
- As máquinas têm raridade **Renascimento** e entram no inventário como recompensa. Cópias e personalizações voltam ao inventário ao renascer. O catálogo atual bloqueia a compra e a venda dessas peças.
- Na migração, os renascimentos concluídos definem quais lotes o jogador já alcançou. A entrega inclui os tipos faltantes, preserva quantidades e personalizações e precisa ficar registrada para evitar duplicação.

Os cinco primeiros ciclos pedem $`10^21` ($1Sx), $`10^24` ($1Sp), $`10^27` ($1O), $`10^30` ($1N), $`10^33` ($1De). Do 6º ao 10º, os requisitos são $`10^34` ($10De), $`3·10^34` ($30De), $`10^35` ($100De), $`3·10^35` ($300De), $`10^36` ($1UDe). Nos ciclos intermediários a partir do 11º, distribua a diferença de expoentes entre os dois marcos em cinco passos. Para o passo `k`, use `expoente anterior + piso(k × diferença / 5)`. A cada vida extra, multiplique por ×`10^3` (×1K) o marco anterior de vida no mesmo ciclo. O jogador pode confirmar com +1 vida mesmo quando há extras disponíveis.

```text
Reencarnação | Saldo exigido      | Entrega garantida                          | Peças

5º           | $10^33 ($1De)      | Aurora, Fornalha aurora e Selo da aurora   | 3
10º          | $10^36 ($1UDe)     | Pulsar, Fornalha supernova e Prisma pulsar | 3
15º          | $10^43 ($10TDe)    | Eterna, Fornalha eterna e Nexus eterno     | 3
20º          | $10^52 ($10SxDe)   | Abissal, Bastião e XR01 a XR05             | 7
25º          | $10^75 ($1QaVi)    | XR06 a XR12                                | 7
30º          | $10^108 ($1QiTg)   | Coroa solar, Mar de vidro e XR13 a XR18    | 8
35º          | $10^155 ($100Qig)  | XR19 a XR25                                | 7
40º          | $10^202 ($10SxSxg) | Umbra, Cíclotron e XR26 a XR31             | 8
45º          | $10^257 ($100QaOg) | XR32 a XR38                                | 7
50º          | $10^308 ($100UCe)  | Meridiano, Catedral e XR39 a XR43          | 7
```

No 50º marco, $10^308 ($100UCe) com 49 Renascimentos concluídos dá acesso à escolha entre Renascimento e Ascensão. A [progressão completa](Progressao_renascimento_loja_intermediaria.md) detalha as consequências dessa escolha e a rota de compra.

## Mineradoras

Todas geram **um minério por segundo** antes do upgrade de extração. O avanço mede a distância da frente da hitbox até o centro da saída. A saída fica no eixo da máquina e a projeção da broca fica fora da reserva de construção.

```text
minérios/s | valor do minério  | entrega | hitbox  | avanço da saída

1          | $7,5·10^8 ($750M) | 5º      | 6x6x5   | 2,5
1          | $10^11 ($100B)    | 10º     | 7x7x6   | 3,5
1          | $10^14 ($100T)    | 15º     | 10x10x8 | 4,5
1          | $10^18 ($1Qn)     | 20º     | 6x6x5   | 2,5
1          | $10^23 ($100Sx)   | 30º     | 7x6x6   | 3,5
1          | $10^29 ($100O)    | 40º     | 8x8x6   | 3,5
1          | $10^36 ($1UDe)    | 50º     | 9x9x7   | 4,5
```

## Fornalhas

A bandeja recebe o minério, e a venda aplica o multiplicador e consome o minério. Todas as bandejas têm **2×2 blocos**, na altura padrão de **0,9375 stud** acima da base. A tabela mostra os multiplicadores antes do upgrade de fundição.

```text
multiplicador de venda | entrega | hitbox | bandeja L×C / nível / desvio

x10^2 (x100)           | 5º      | 5x4x4  | 2x2 / piso
x10^4 (x10K)           | 10º     | 4x5x5  | 2x2 / piso
x10^7 (x10M)           | 15º     | 5x5x5  | 2x2 / piso
x10^11 (x100B)         | 20º     | 4x4x2  | 2x2 / piso
x10^16 (x10Qd)         | 30º     | 5x5x4  | 2x2 / piso / -0,5
x10^23 (x100Sx)        | 40º     | 4x6x5  | 2x2 / piso
x10^31 (x10N)          | 50º     | 6x5x6  | 2x2 / piso
```

## Modificadores

**De quatro a oito aplicações por tipo, por minério.** A coluna Limite indica o máximo de cada modelo. Cada unidade física conta uma vez. O uso começa quando a primeira faixa válida aplica o efeito. As outras faixas completam a mesma passagem. Se o minério voltar pela mesma unidade, a correia continua transportando.

A tabela usa o limite base. A Calibração acrescenta 20% por nível, até 100%, com arredondamento ao inteiro mais próximo. Qualquer minério válido pode receber a primeira aplicação.

```text
Uso do mesmo tipo         | Efeito

1º                        | Aplica os fatores principais da tabela.
2º até o limite do modelo | Soma +50 pontos percentuais por unidade adicional.
```

Os bônus de tipos diferentes se somam. **Valor de venda = valor processado × (1 + bônus de cópias) × fator da fornalha.** Quatro unidades de um tipo resultam em **×2,5** sobre o valor processado. Oito resultam em **×4,5**. O dimensionamento original limita a ×`10^3` (×1K) o efeito combinado com as cópias do limite base. A Porta do Meridiano aplica ×`4·10^2` (×400) na primeira unidade, chega a ×`10^3` (×1K) com quatro e a ×`1,8·10^3` (×1,8K) com oito após Calibração máxima. A linha pode combinar efeitos de tipos diferentes. Uma cópia com duas faixas reparte os 50 pontos percentuais em **25 + 25**. Com três faixas, a divisão é **16 + 17 + 17**. Cada faixa aplica sua parte quando o minério a atravessa. O jogo mostra o valor efetivo durante o trajeto. Os cálculos usam aritmética decimal inteira, com arredondamento ao inteiro mais próximo e meio para cima.

Todos os modificadores têm correia própria. **L×C / nível / desvio** indica largura, comprimento, nível acima do piso e posição lateral em X local, em blocos. O desvio só aparece quando a correia fica fora do eixo da hitbox. Piso, +1 e +2 correspondem a **0,9375**, **3,9375** e **6,9375 studs** acima da base. A velocidade base de referência do catálogo é **6 studs/s** ou **2 blocos/s**.

Os modificadores compactos, com até 12 blocos cúbicos de hitbox ou correia de um bloco de largura, têm **8 usos**. Os demais têm **7** até 24 blocos cúbicos, **6** até 48, **5** até 75 e **4** acima disso. **37 dos 46** têm multiplicador principal de até **×`10^2` (×100)**. Os nove acima de ×100 reservam pelo menos **75 blocos cúbicos** e chegam nos lotes do 40º ao 50º. Os multiplicadores por faixa seguem a ordem de passagem. O produto deles dá o efeito principal da travessia completa.

```text
limite | multiplicadores por faixa na 1ª aplicação                 | entrega | hitbox | correia L×C / nível / desvio | faixas | multiplicador total

5      | x2·10^1 (x20)                                             | 5º      | 5x4x3  | 2x4 / piso / +0,5            | 1      | x2·10^1 (x20)
4      | x2,4·10^1 (x24)                                           | 10º     | 5x4x5  | 2x4 / +1 / +0,5              | 1      | x2,4·10^1 (x24)
4      | x3·10^1 (x30)                                             | 15º     | 5x5x5  | 2x5 / +1 / +0,5              | 1      | x3·10^1 (x30)
8      | x3,2·10^1 (x32)                                           | 20º     | 2x1x1  | 2x1 / piso                   | 1      | x3,2·10^1 (x32)
8      | x3,6·10^1 (x36)                                           | 20º     | 3x2x2  | 2x2 / piso / -0,5            | 1      | x3,6·10^1 (x36)
8      | x4·10^1 (x40)                                             | 20º     | 4x2x1  | 2x2 / piso                   | 1      | x4·10^1 (x40)
8      | x6·10^0 (x6), depois x7·10^0 (x7)                         | 20º     | 2x3x1  | 2x3 / piso                   | 2      | x4,2·10^1 (x42)
7      | x4,8·10^1 (x48)                                           | 20º     | 3x2x3  | 2x2 / piso / -0,5            | 1      | x4,8·10^1 (x48)
7      | x5,4·10^1 (x54)                                           | 25º     | 4x2x2  | 2x2 / piso                   | 1      | x5,4·10^1 (x54)
7      | x7·10^0 (x7), depois x8·10^0 (x8)                         | 25º     | 4x3x2  | 2x3 / piso                   | 2      | x5,6·10^1 (x56)
8      | x4,8·10^1 (x48)                                           | 25º     | 3x1x1  | 2x1 / piso / -0,5            | 1      | x4,8·10^1 (x48)
7      | x6·10^1 (x60)                                             | 25º     | 4x2x3  | 2x2 / piso                   | 1      | x6·10^1 (x60)
8      | x8·10^0 (x8), depois x8·10^0 (x8)                         | 25º     | 3x3x1  | 2x3 / piso / -0,5            | 2      | x6,4·10^1 (x64)
7      | x6·10^0 (x6), depois x1,1·10^1 (x11)                      | 25º     | 4x3x2  | 2x3 / piso                   | 2      | x6,6·10^1 (x66)
7      | x7,2·10^1 (x72)                                           | 25º     | 4x2x2  | 2x2 / piso                   | 1      | x7,2·10^1 (x72)
6      | x7,5·10^1 (x75)                                           | 30º     | 5x2x3  | 2x2 / piso / -0,5            | 1      | x7,5·10^1 (x75)
7      | x7·10^0 (x7), depois x1,1·10^1 (x11)                      | 30º     | 3x3x2  | 2x3 / piso / -0,5            | 2      | x7,7·10^1 (x77)
6      | x4·10^0 (x4), depois x4·10^0 (x4), depois x5·10^0 (x5)    | 30º     | 4x4x2  | 2x4 / piso                   | 3      | x8·10^1 (x80)
8      | x7,2·10^1 (x72)                                           | 30º     | 1x1x1  | 1x1 / piso                   | 1      | x7,2·10^1 (x72)
7      | x3·10^0 (x3), depois x4·10^0 (x4), depois x7·10^0 (x7)    | 30º     | 4x3x2  | 2x3 / piso                   | 3      | x8,4·10^1 (x84)
5      | x9·10^0 (x9), depois x10^1 (x10)                          | 30º     | 4x4x4  | 2x4 / +1                     | 2      | x9·10^1 (x90)
7      | x3·10^0 (x3), depois x4·10^0 (x4), depois x7·10^0 (x7)    | 35º     | 4x5x1  | 2x5 / piso                   | 3      | x8,4·10^1 (x84)
8      | x5·10^0 (x5), depois x1,5·10^1 (x15)                      | 35º     | 2x2x1  | 1x2 / piso / -0,5            | 2      | x7,5·10^1 (x75)
6      | x8·10^0 (x8), depois x1,1·10^1 (x11)                      | 35º     | 5x3x3  | 2x3 / piso / -0,5            | 2      | x8,8·10^1 (x88)
6      | x3·10^0 (x3), depois x5·10^0 (x5), depois x6·10^0 (x6)    | 35º     | 4x4x3  | 2x4 / piso                   | 3      | x9·10^1 (x90)
6      | x8·10^0 (x8), depois x1,2·10^1 (x12)                      | 35º     | 4x4x3  | 2x4 / +1                     | 2      | x9,6·10^1 (x96)
6      | x9·10^0 (x9), depois x10^1 (x10)                          | 35º     | 5x3x2  | 2x3 / piso / -0,5            | 2      | x9·10^1 (x90)
6      | x10^2 (x100)                                              | 35º     | 4x2x5  | 2x2 / +2                     | 1      | x10^2 (x100)
5      | x3·10^0 (x3), depois x5·10^0 (x5), depois x6·10^0 (x6)    | 40º     | 5x4x3  | 2x4 / piso / -0,5            | 3      | x9·10^1 (x90)
7      | x4·10^0 (x4), depois x2,3·10^1 (x23)                      | 40º     | 4x3x2  | 2x3 / piso                   | 2      | x9,2·10^1 (x92)
5      | x5·10^0 (x5), depois x5·10^0 (x5), depois x5·10^0 (x5)    | 40º     | 5x5x3  | 2x5 / piso / -0,5            | 3      | x1,25·10^2 (x125)
8      | x8·10^0 (x8), depois x10^1 (x10)                          | 40º     | 2x3x2  | 1x3 / piso / -0,5            | 2      | x8·10^1 (x80)
6      | x4·10^0 (x4), depois x4·10^0 (x4), depois x6·10^0 (x6)    | 40º     | 4x4x2  | 2x4 / piso                   | 3      | x9,6·10^1 (x96)
4      | x5·10^0 (x5), depois x5·10^0 (x5), depois x8·10^0 (x8)    | 40º     | 5x5x4  | 2x5 / +1 / -0,5              | 3      | x2·10^2 (x200)
7      | x4·10^0 (x4), depois x4·10^0 (x4), depois x6·10^0 (x6)    | 45º     | 3x4x2  | 2x4 / piso / -0,5            | 3      | x9,6·10^1 (x96)
4      | x5·10^0 (x5), depois x6·10^0 (x6), depois x10^1 (x10)     | 45º     | 5x5x5  | 2x5 / +2 / -0,5              | 3      | x3·10^2 (x300)
6      | x10^1 (x10), depois x10^1 (x10)                           | 45º     | 4x4x3  | 2x4 / piso                   | 2      | x10^2 (x100)
6      | x4·10^0 (x4), depois x4·10^0 (x4), depois x6·10^0 (x6)    | 45º     | 4x5x2  | 2x5 / piso                   | 3      | x9,6·10^1 (x96)
8      | x9·10^0 (x9), depois x10^1 (x10)                          | 45º     | 3x3x4  | 1x3 / +1                     | 2      | x9·10^1 (x90)
6      | x4·10^0 (x4), depois x5·10^0 (x5), depois x5·10^0 (x5)    | 45º     | 5x4x2  | 2x4 / piso / -0,5            | 3      | x10^2 (x100)
5      | x5·10^0 (x5), depois x5·10^0 (x5), depois x6·10^0 (x6)    | 45º     | 5x5x3  | 2x5 / piso / -0,5            | 3      | x1,5·10^2 (x150)
4      | x6·10^0 (x6), depois x6·10^0 (x6), depois x6·10^0 (x6)    | 50º     | 5x4x4  | 2x4 / +2 / -0,5              | 3      | x2,16·10^2 (x216)
4      | x5·10^0 (x5), depois x5·10^0 (x5), depois x10^1 (x10)     | 50º     | 5x5x4  | 2x5 / +1 / -0,5              | 3      | x2,5·10^2 (x250)
5      | x5·10^0 (x5), depois x6·10^0 (x6), depois x6·10^0 (x6)    | 50º     | 5x5x3  | 2x5 / piso / -0,5            | 3      | x1,8·10^2 (x180)
4      | x5·10^0 (x5), depois x5·10^0 (x5), depois x1,5·10^1 (x15) | 50º     | 6x5x5  | 2x5 / +2                     | 3      | x3,75·10^2 (x375)
4      | x5·10^0 (x5), depois x8·10^0 (x8), depois x10^1 (x10)     | 50º     | 6x6x5  | 2x6 / +2                     | 3      | x4·10^2 (x400)
```

## Referência de produção

A [rota de compra por reinício](Progressao_renascimento_loja_intermediaria.md) detalha os 50 marcos usando os multiplicadores atuais, a loja existente, as novas máquinas e alternativas de craft.

## Referências no projeto

- [Definições das nove recompensas atuais](../src/shared/RecompensasRenascimento.luau) e [modelos originais](../modelos/renascimento/assets).
- [Definições de modelagem da nova leva](../modelos/renascimento/novas/definicoes.luau), [arquivos individuais](../modelos/renascimento/novas/assets) e [galeria dos 51 modelos](../modelos/renascimento/novas/Galeria51Renascimento.rbxm).
- [Catálogo da loja](../src/shared/CatalogoMaquinas.luau), [regra atual de renascimento](../src/shared/RegraReencarnacao.luau) e [formatador de abreviações](../src/shared/AbreviarInteiro.luau).
