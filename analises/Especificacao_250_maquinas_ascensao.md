# Especificação das 250 máquinas de Ascensão

Proposta de balanceamento. A tabela cobre os 250 IDs dos manifestos de modelagem. Os valores em dinheiro são da escala local do ciclo. Para converter para a escala exibida, some **B** ao expoente de preços, minérios, custo de compras e receitas. As taxas e os multiplicadores são os próprios números da tabela. A [progressão das 50 Ascensões](Progressao_ascensao.md) define **B**.

- As hitboxes usam largura × comprimento × altura em blocos de 3 studs. O avanço da saída mede blocos além da frente da hitbox. As mineradoras geram cubos de 0,75 stud de lado. Taxa é a média de geração antes dos upgrades.
- Correias e bandejas operam a 2 blocos/s de base. Piso, +1 e +2 correspondem a 0,9375, 3,9375 e 6,9375 studs acima da base. O desvio lateral, quando presente, está em blocos.
- **Limite** é a quantidade de aplicações por tipo e por minério. A primeira faixa que aplica inicia o uso. O total mostra o produto das faixas na primeira aplicação. A primeira unidade de recompensa aplica o fator da ficha. Cada cópia física adicional soma 50 pontos percentuais ao bônus de cópias, repartidos entre as faixas. As recompensas têm de 4 a 8 usos base. A Calibração aumenta o limite em 20% por nível. Cada faixa arredonda o valor do minério ao inteiro mais próximo, com meio para cima.
- Em craft, **Asc.** é o mínimo proposto de Ascensões concluídas e **Ren.** é a última entrega garantida de Renascimento entre as dependências. **Compras** estima o custo de adquirir os ingredientes de loja a partir do estoque vazio, contando as repetições entre ramos. Cada receita consome as peças indicadas na [árvore de receitas modelada](../modelos/ascensao/Receitas.md).
- A Síntese de modificação é a única exceção de escala entre os modificadores. Seu fator inclui a contribuição dos melhores modificadores legados que a receita consome. As outras peças mantêm ganhos por faixa modestos em relação ao ponto da progressão.


## Recompensas de Ascensão · 50 peças

### Mineradoras

```text
Código | Máquina                       | Minérios/s | Minério local       | Hitbox | Avanço | Transição garantida
AM01   | Mineradora do zênite          | 1,1        | $2·10^39 ($2DDe)    | 4×4×3  | 1,5    | 1
AM02   | Escavadora coroa de ferro     | 1          | $3·10^43 ($30TDe)   | 4×5×4  | 1,5    | 6
AM03   | Mineradora abóbada azul       | 1,25       | $2·10^47 ($200QaDe) | 5×4×4  | 2,5    | 11
AM04   | Escavadora da falha negra     | 1,1        | $3·10^51 ($3SxDe)   | 5×5×5  | 2,5    | 16
AM05   | Mineradora arco de luz        | 1          | $2·10^55 ($20SpDe)  | 6×5×4  | 2,5    | 21
AM06   | Escavadora do polo celeste    | 1,25       | $3·10^59 ($300ODe)  | 5×6×5  | 3,5    | 26
AM07   | Mineradora da coroa rubra     | 1,1        | $2·10^63 ($2Vi)     | 6×6×6  | 3,5    | 31
AM08   | Escavadora de horizonte duplo | 1          | $3·10^67 ($30UVi)   | 7×6×5  | 3,5    | 36
AM09   | Mineradora da órbita clara    | 1,25       | $2·10^71 ($200DVi)  | 7×7×6  | 4,5    | 41
AM10   | Escavadora do vazio dourado   | 1,1        | $3·10^75 ($3QaVi)   | 8×7×7  | 4,5    | 46
```

### Fornalhas

```text
Código | Máquina                   | Multiplicador de venda | Hitbox | Bandeja / nível / desvio | Transição garantida
AF01   | Fornalha do alvorecer     | ×3·10^35 (×300De)      | 3×3×2  | 2×2 / piso / −0,5        | 3
AF02   | Fornalha da vigília       | ×4·10^39 (×4DDe)       | 4×3×3  | 2×2 / piso               | 8
AF03   | Fornalha do vento polar   | ×3·10^43 (×30TDe)      | 3×4×3  | 2×2 / piso / −0,5        | 13
AF04   | Fornalha de chama rosa    | ×4·10^47 (×400QaDe)    | 4×4×4  | 2×2 / piso               | 18
AF05   | Fornalha da dobra clara   | ×3·10^51 (×3SxDe)      | 5×4×4  | 2×2 / piso / −0,5        | 23
AF06   | Fornalha do craterio      | ×4·10^55 (×40SpDe)     | 5×5×3  | 2×2 / piso / −0,5        | 28
AF07   | Fornalha da aurora escura | ×3·10^59 (×300ODe)     | 6×5×4  | 2×2 / piso               | 33
AF08   | Fornalha da borda branca  | ×4·10^63 (×4Vi)        | 5×6×5  | 2×2 / piso / −0,5        | 38
AF09   | Fornalha da estrela oca   | ×3·10^67 (×30UVi)      | 6×6×6  | 2×2 / piso               | 43
AF10   | Fornalha do sol imóvel    | ×4·10^71 (×400DVi)     | 7×6×6  | 2×2 / piso / −0,5        | 48
```

### Modificadores

```text
Código | Máquina                   | Limite | Efeito por faixa em ordem                                             | Total da passagem       | Hitbox | Correia / nível / desvio | Transição garantida
AX01   | Filtro da aurora verde    | 8      | ×4,8·10^2 (×480)                                                      | ×4,8·10^2 (×480)        | 2×2×1  | 2×2 / piso               | 2
AX02   | Garra de luz fria         | 8      | ×6·10^2 (×600)                                                        | ×6·10^2 (×600)          | 3×2×2  | 2×2 / piso / −0,5        | 4
AX03   | Câmara da agulha solar    | 7      | ×8·10^2 (×800)                                                        | ×8·10^2 (×800)          | 3×3×2  | 2×3 / piso / −0,5        | 5
AX04   | Vetor da nebulosa         | 7      | ×2,6·10^1 (×26) → ×2,8·10^1 (×28)                                     | ×7,28·10^2 (×728)       | 4×2×2  | 2×2 / piso               | 7
AX05   | Polarizador do zéfiro     | 6      | ×3·10^1 (×30) → ×3·10^1 (×30)                                         | ×9·10^2 (×900)          | 3×4×3  | 2×4 / piso / −0,5        | 9
AX06   | Prisma de brasa azul      | 7      | ×1,2·10^3 (×1,2K)                                                     | ×1,2·10^3 (×1,2K)       | 4×3×2  | 2×3 / piso               | 10
AX07   | Condutor da orla          | 7      | ×3,2·10^1 (×32) → ×3,4·10^1 (×34)                                     | ×1,088·10^3 (×1,088K)   | 3×4×2  | 2×4 / piso / −0,5        | 12
AX08   | Malha do alto vácuo       | 6      | ×3,6·10^1 (×36) → ×3,8·10^1 (×38)                                     | ×1,368·10^3 (×1,368K)   | 4×4×3  | 2×4 / piso               | 14
AX09   | Membrana luminosa         | 8      | ×4,2·10^1 (×42) → ×4,3·10^1 (×43)                                     | ×1,806·10^3 (×1,806K)   | 4×3×1  | 2×3 / piso               | 15
AX10   | Fole da borda solar       | 6      | ×4·10^1 (×40) → ×4,1·10^1 (×41)                                       | ×1,64·10^3 (×1,64K)     | 4×4×3  | 2×4 / piso               | 17
AX11   | Trefila do eclipse        | 5      | ×4,5·10^1 (×45) → ×4,5·10^1 (×45)                                     | ×2,025·10^3 (×2,025K)   | 4×5×3  | 2×5 / +1                 | 19
AX12   | Ponte de luz polar        | 5      | ×5,1·10^1 (×51) → ×5,3·10^1 (×53)                                     | ×2,703·10^3 (×2,703K)   | 5×4×3  | 2×4 / +1 / −0,5          | 20
AX13   | Peneira da magnetosfera   | 6      | ×2,43·10^3 (×2,43K)                                                   | ×2,43·10^3 (×2,43K)     | 5×3×3  | 2×3 / piso / −0,5        | 22
AX14   | Campo de vitrificação     | 6      | ×1,4·10^1 (×14) → ×1,4·10^1 (×14) → ×1,6·10^1 (×16)                   | ×3,136·10^3 (×3,136K)   | 4×5×2  | 2×5 / piso               | 24
AX15   | Válvula de plasma claro   | 4      | ×6,3·10^1 (×63) → ×6,5·10^1 (×65)                                     | ×4,095·10^3 (×4,095K)   | 5×4×4  | 2×4 / +1 / −0,5          | 25
AX16   | Fenda do solstício        | 4      | ×1,5·10^1 (×15) → ×1,5·10^1 (×15) → ×1,7·10^1 (×17)                   | ×3,825·10^3 (×3,825K)   | 5×5×4  | 2×5 / +1 / −0,5          | 27
AX17   | Anel da maré ionizada     | 5      | ×6,7·10^1 (×67) → ×6,8·10^1 (×68)                                     | ×4,556·10^3 (×4,556K)   | 4×4×4  | 2×4 / +2                 | 29
AX18   | Freio de partículas       | 5      | ×7,7·10^1 (×77) → ×7,9·10^1 (×79)                                     | ×6,083·10^3 (×6,083K)   | 5×5×3  | 2×5 / +1 / −0,5          | 30
AX19   | Crivo de cristal azul     | 5      | ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,9·10^1 (×19)                   | ×5,491·10^3 (×5,491K)   | 5×4×3  | 2×4 / piso / −0,5        | 32
AX20   | Cascata da penumbra       | 4      | ×1,8·10^1 (×18) → ×1,8·10^1 (×18) → ×2,2·10^1 (×22)                   | ×7,128·10^3 (×7,128K)   | 6×5×4  | 2×5 / +1                 | 34
AX21   | Estação da coroa violeta  | 4      | ×2·10^1 (×20) → ×2·10^1 (×20) → ×2,3·10^1 (×23)                       | ×9,2·10^3 (×9,2K)       | 5×6×4  | 2×6 / +1 / −0,5          | 35
AX22   | Bolha de heliopausa       | 4      | ×2·10^1 (×20) → ×2·10^1 (×20) → ×2,1·10^1 (×21)                       | ×8,4·10^3 (×8,4K)       | 6×4×4  | 2×4 / +2                 | 37
AX23   | Retificador da luz negra  | 4      | ×2,1·10^1 (×21) → ×2,1·10^1 (×21) → ×2,4·10^1 (×24)                   | ×1,0584·10^4 (×10,584K) | 6×5×5  | 2×5 / piso               | 39
AX24   | Reator do norte magnético | 4      | ×2,3·10^1 (×23) → ×2,3·10^1 (×23) → ×2,6·10^1 (×26)                   | ×1,3754·10^4 (×13,754K) | 6×6×3  | 2×6 / piso               | 40
AX25   | Dobradiça da órbita       | 4      | ×2,3·10^1 (×23) → ×2,3·10^1 (×23) → ×2,4·10^1 (×24)                   | ×1,2696·10^4 (×12,696K) | 5×6×5  | 2×6 / +2 / −0,5          | 42
AX26   | Obelisco de chama fria    | 4      | ×2,4·10^1 (×24) → ×2,4·10^1 (×24) → ×2,7·10^1 (×27)                   | ×1,5552·10^4 (×15,552K) | 6×6×5  | 2×6 / +2                 | 44
AX27   | Colisor da coroa branca   | 4      | ×2,7·10^1 (×27) → ×2,7·10^1 (×27) → ×2,9·10^1 (×29)                   | ×2,1141·10^4 (×21,141K) | 7×5×5  | 2×5 / +1 / −0,5          | 45
AX28   | Câmara de auroras gêmeas  | 4      | ×1,1·10^1 (×11) → ×1,1·10^1 (×11) → ×1,1·10^1 (×11) → ×1,4·10^1 (×14) | ×1,8634·10^4 (×18,634K) | 6×7×5  | 2×7 / +1                 | 47
AX29   | Torre da magnetocauda     | 4      | ×1,2·10^1 (×12) → ×1,2·10^1 (×12) → ×1,2·10^1 (×12) → ×1,4·10^1 (×14) | ×2,4192·10^4 (×24,192K) | 7×6×6  | 2×6 / +2 / −0,5          | 49
AX30   | Núcleo da órbita dourada  | 4      | ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,4·10^1 (×14) | ×3,0758·10^4 (×30,758K) | 7×7×6  | 2×7 / +2 / −0,5          | 50
```

## Loja pós-Ascensão · 100 peças

Os valores são os preços base. A [tabela da loja](Precos_loja_por_ciclo.md) mostra os preços completos na estreia e na 50ª Ascensão. Os conceitos adicionais têm [fichas próprias](Conceitos_fim_de_ciclo.md).

### Mineradoras

```text
Código | Máquina                           | Minérios/s | Minério local       | Hitbox | Avanço | Asc. | Preço local               | Preço completo na estreia
LAM01  | Mineradora de cerâmica orbital    | 1,2        | $3·10^39 ($3DDe)    | 3×3×2  | 1,5    | 1    | $1,65·10^155 ($165Qig)    | $1,65·10^384 ($1,65e384)
LAM02  | Escavadora de caulim polar        | 0,8        | $10^40 ($10DDe)     | 4×4×3  | 1,5    | 1    | $1,85·10^166 ($18,5QaQig) | $1,85·10^395 ($1,85e395)
LAM03  | Mineradora de hélio superfluido   | 1,25       | $3·10^43 ($30TDe)   | 4×3×3  | 1,5    | 5    | $3,01·10^175 ($30,1SpQig) | $3,01·10^1328 ($3,01e1328)
LAM04  | Escavadora de banho criogênico    | 0,8        | $10^44 ($100TDe)    | 3×5×3  | 2,5    | 5    | $1,72·10^185 ($172Sxg)    | $1,72·10^1338 ($1,72e1338)
LAM05  | Mineradora de escória solar       | 1,2        | $3·10^47 ($300QaDe) | 5×4×3  | 1,5    | 10   | $4,98·10^187 ($49,8USxg)  | $4,98·10^10777 ($4,98e10777)
LAM06  | Escavadora de tungstênio solar    | 0,8        | $10^48 ($1QiDe)     | 5×5×4  | 2,5    | 10   | $7,07·10^194 ($707TSxg)   | $7,07·10^10784 ($7,07e10784)
LAM07  | Mineradora de espinélio de fase   | 1,25       | $3·10^51 ($3SxDe)   | 4×6×3  | 2,5    | 15   | $1,11·10^197 ($111QaSxg)  | $1,11·10^(4,88·10^10−23) ($1,11e(4,88e10−23))
LAM08  | Escavadora de quartzo de fase     | 0,8        | $10^52 ($10SxDe)    | 5×4×5  | 2,5    | 15   | $1,46·10^204 ($1,46SpSxg) | $1,46·10^(4,88·10^10−16) ($1,46e(4,88e10−16))
LAM09  | Mineradora de gravidade inversa   | 1,2        | $3·10^55 ($30SpDe)  | 5×5×5  | 2,5    | 20   | $1,95·10^206 ($195SpSxg)  | $1,95·10^(7,02·10^26−24) ($1,95e(7,02e26−24))
LAM10  | Escavadora de lentes gravíticas   | 0,8        | $10^56 ($100SpDe)   | 6×5×4  | 3,5    | 20   | $2,46·10^213 ($2,46Spg)   | $2,46·10^(7,02·10^26−17) ($2,46e(7,02e26−17))
LAM11  | Mineradora de vácuo pressurizado  | 1,25       | $3·10^59 ($300ODe)  | 6×4×5  | 2,5    | 25   | $3,36·10^215 ($336Spg)    | $3,36·10^(3,23·10^52−28) ($3,36e(3,23e52−28))
LAM12  | Escavadora de cavidade evacuada   | 0,8        | $10^60 ($1NDe)      | 5×6×5  | 3,5    | 25   | $4,42·10^222 ($4,42TSpg)  | $4,42·10^(3,23·10^52−21) ($4,42e(3,23e52−21))
LAM13  | Mineradora de neutrinos lentos    | 1,2        | $3·10^63 ($3Vi)     | 6×5×6  | 3,5    | 30   | $5,78·10^224 ($578TSpg)   | $5,78·10^(4,76·10^87−28) ($5,78e(4,76e87−28))
LAM14  | Escavadora de antineutrinos       | 0,8        | $10^64 ($10Vi)      | 7×6×5  | 3,5    | 30   | $7,24·10^231 ($7,24SxSpg) | $7,24·10^(4,76·10^87−21) ($7,24e(4,76e87−21))
LAM15  | Mineradora de horizonte refratado | 1,25       | $3·10^67 ($30UVi)   | 6×6×6  | 3,5    | 35   | $9,04·10^233 ($904SxSpg)  | $9,04·10^(2,24·10^132−29) ($9,04e(2,24e132−29))
LAM16  | Escavadora de horizonte de vidro  | 0,8        | $10^68 ($100UVi)    | 7×6×6  | 4,5    | 35   | $1,19·10^241 ($11,9NSpg)  | $1,19·10^(2,24·10^132−21) ($1,19e(2,24e132−21))
LAM17  | Mineradora de entropia dirigida   | 1,2        | $3·10^71 ($300DVi)  | 7×6×6  | 3,5    | 40   | $1,41·10^243 ($1,41Og)    | $1,41·10^(3,37·10^186−29) ($1,41e(3,37e186−29))
LAM18  | Escavadora de decaimento reverso  | 0,8        | $10^72 ($1TVi)      | 8×6×7  | 4,5    | 40   | $1,78·10^250 ($17,8DOg)   | $1,78·10^(3,37·10^186−22) ($1,78e(3,37e186−22))
LAM19  | Mineradora do núcleo sem tempo    | 1,25       | $3·10^75 ($3QaVi)   | 7×7×6  | 3,5    | 45   | $2,38·10^252 ($2,38TOg)   | $2,38·10^(1,62·10^250−31) ($2,38e(1,62e250−31))
LAM20  | Escavadora da eternidade          | 0,8        | $10^76 ($10QaVi)    | 8×7×7  | 4,5    | 45   | $3,14·10^259 ($31,4QiOg)  | $3,14·10^(1,62·10^250−24) ($3,14e(1,62e250−24))
```

### Fornalhas

```text
Código | Máquina                              | Multiplicador de venda | Hitbox | Bandeja / nível / desvio | Asc. | Preço local               | Preço completo na estreia
LAF01  | Fornalha de zircônia                 | ×2·10^34 (×20De)       | 3×3×1  | 2×2 / piso / −0,5        | 1    | $2,41·10^160 ($24,1DQig)  | $2,41·10^389 ($2,41e389)
LAF02  | Fornalha de casca sinterizada        | ×10^35 (×100De)        | 4×4×3  | 2×2 / piso               | 1    | $4,13·10^166 ($41,3QaQig) | $4,13·10^395 ($4,13e395)
LAF03  | Fornalha de circulação criogênica    | ×2·10^38 (×200UDe)     | 4×3×2  | 2×2 / piso               | 5    | $1,42·10^179 ($142OQig)   | $1,42·10^1332 ($1,42e1332)
LAF04  | Fornalha de hélio comprimido         | ×10^39 (×1DDe)         | 4×4×3  | 2×2 / piso               | 5    | $3,65·10^185 ($365Sxg)    | $3,65·10^1338 ($3,65e1338)
LAF05  | Fornalha de têmpera solar            | ×2·10^42 (×2TDe)       | 5×4×2  | 2×2 / piso / −0,5        | 10   | $2,24·10^191 ($224DSxg)   | $2,24·10^10781 ($2,24e10781)
LAF06  | Fornalha de arco de tungstênio       | ×10^43 (×10TDe)        | 5×4×4  | 2×2 / piso / −0,5        | 10   | $1,57·10^195 ($1,57QaSxg) | $1,57·10^10785 ($1,57e10785)
LAF07  | Fornalha de gema birrefringente      | ×2·10^46 (×20QaDe)     | 4×5×3  | 2×2 / piso               | 15   | $5,19·10^200 ($519QiSxg)  | $5,19·10^(4,88·10^10−20) ($5,19e(4,88e10−20))
LAF08  | Fornalha de espelhos de fase         | ×10^47 (×100QaDe)      | 5×5×4  | 2×2 / piso / −0,5        | 15   | $2,83·10^204 ($2,83SpSxg) | $2,83·10^(4,88·10^10−16) ($2,83e(4,88e10−16))
LAF09  | Fornalha de lastro invertido         | ×2·10^50 (×200QiDe)    | 5×4×4  | 2×2 / piso / −0,5        | 20   | $8,75·10^209 ($875OSxg)   | $8,75·10^(7,02·10^26−21) ($8,75e(7,02e26−21))
LAF10  | Fornalha de poço gravítico           | ×10^51 (×1SxDe)        | 5×6×5  | 2×2 / piso / −0,5        | 20   | $5·10^213 ($5Spg)         | $5·10^(7,02·10^26−17) ($5e(7,02e26−17))
LAF11  | Fornalha de expansão adiabática      | ×2·10^54 (×2SpDe)      | 5×5×4  | 2×2 / piso / −0,5        | 25   | $1,57·10^219 ($1,57DSpg)  | $1,57·10^(3,23·10^52−24) ($1,57e(3,23e52−24))
LAF12  | Fornalha de pulso ultravácuo         | ×10^55 (×10SpDe)       | 6×5×5  | 2×2 / piso               | 25   | $8,48·10^222 ($8,48TSpg)  | $8,48·10^(3,23·10^52−21) ($8,48e(3,23e52−21))
LAF13  | Fornalha de feixe de neutrinos       | ×2·10^58 (×20ODe)      | 5×6×4  | 2×2 / piso / −0,5        | 30   | $2,6·10^228 ($2,6QiSpg)   | $2,6·10^(4,76·10^87−24) ($2,6e(4,76e87−24))
LAF14  | Fornalha de captura de antineutrinos | ×10^59 (×100ODe)       | 6×6×5  | 2×2 / piso               | 30   | $1,41·10^232 ($14,1SxSpg) | $1,41·10^(4,76·10^87−20) ($1,41e(4,76e87−20))
LAF15  | Fornalha de horizonte focal          | ×2·10^62 (×200NDe)     | 6×5×5  | 2×2 / piso               | 35   | $4,23·10^237 ($4,23OSpg)  | $4,23·10^(2,24·10^132−25) ($4,23e(2,24e132−25))
LAF16  | Fornalha de horizonte de vidro       | ×10^63 (×1Vi)          | 6×6×6  | 2×2 / piso               | 35   | $2,27·10^241 ($22,7NSpg)  | $2,27·10^(2,24·10^132−21) ($2,27e(2,24e132−21))
LAF17  | Fornalha de gradiente entrópico      | ×2·10^66 (×2UVi)       | 6×6×5  | 2×2 / piso               | 40   | $6,35·10^246 ($6,35UOg)   | $6,35·10^(3,37·10^186−26) ($6,35e(3,37e186−26))
LAF18  | Fornalha de decaimento reverso       | ×10^67 (×10UVi)        | 7×7×6  | 2×2 / piso / −0,5        | 40   | $3,59·10^250 ($35,9DOg)   | $3,59·10^(3,37·10^186−22) ($3,59e(3,37e186−22))
LAF19  | Fornalha de ignição atemporal        | ×2·10^70 (×20DVi)      | 7×6×6  | 2×2 / piso / −0,5        | 45   | $1,12·10^256 ($11,2QaOg)  | $1,12·10^(1,62·10^250−27) ($1,12e(1,62e250−27))
LAF20  | Fornalha da eternidade               | ×10^71 (×100DVi)       | 8×7×7  | 2×2 / piso               | 45   | $6,1·10^259 ($61QiOg)     | $6,1·10^(1,62·10^250−24) ($6,1e(1,62e250−24))
```

### Modificadores

```text
Código | Máquina                        | Limite                  | Efeito por faixa em ordem                                                   | Total da passagem       | Hitbox | Correia / nível / desvio | Asc. | Preço local               | Preço completo na estreia
LAX01  | Raspador de caulim                 | 2        | ×1,2·10^2 (×120)                                                            | ×1,2·10^2 (×120)                | 2×1×1  | 2×1 / piso                | 1    | $4,82·10^161 ($482DQig)      | $4,82·10^390 ($4,82e390)
LAX02  | Pinça de zircônia              | 2                       | ×1,6·10^2 (×160)                                                            | ×1,6·10^2 (×160)        | 3×2×2  | 2×2 / piso / −0,5        | 1    | $5,4·10^161 ($540DQig)    | $5,4·10^390 ($5,4e390)
LAX03  | Peneira de magnesita           | 2                       | ×1,5·10^1 (×15) → ×1,6·10^1 (×16)                                           | ×2,4·10^2 (×240)        | 4×2×1  | 2×2 / piso               | 1    | $7,72·10^163 ($77,2TQig)  | $7,72·10^392 ($7,72e392)
LAX04  | Revestidor de porcelana        | 1                       | ×1,8·10^1 (×18) → ×1,9·10^1 (×19)                                           | ×3,42·10^2 (×342)       | 3×3×2  | 2×3 / piso / −0,5        | 1    | $2,07·10^167 ($207QaQig)  | $2,07·10^396 ($2,07e396)
LAX05  | Arco cerâmico de têmpera       | 1                       | ×2,2·10^1 (×22) → ×2,3·10^1 (×23)                                           | ×5,06·10^2 (×506)       | 4×3×2  | 2×3 / piso               | 1    | $7,05·10^169 ($70,5QiQig) | $7,05·10^398 ($7,05e398)
LAX06  | Crivo de alumina azul          | 1                       | ×2,6·10^1 (×26) → ×2,8·10^1 (×28)                                           | ×7,28·10^2 (×728)       | 4×4×2  | 2×4 / piso               | 1    | $3,56·10^172 ($35,6SxQig) | $3,56·10^401 ($3,56e401)
LAX07  | Dosador de hélio líquido           | 2        | ×1,912·10^2 (×191,2)                                                        | ×1,912·10^2 (×191,2)            | 3×2×1  | 2×2 / piso / −0,5         | 5    | $2,82·10^182 ($282NQig)      | $2,82·10^1335 ($2,82e1335)
LAX08  | Chave de fluxo frio            | 2                       | ×1,5·10^1 (×15) → ×1,7·10^1 (×17)                                           | ×2,55·10^2 (×255)       | 3×3×2  | 2×3 / piso / −0,5        | 5    | $3,17·10^182 ($317NQig)   | $3,17·10^1335 ($3,17e1335)
LAX09  | Trilho de gás rarefeito        | 2                       | ×1,9·10^1 (×19) → ×2·10^1 (×20)                                             | ×3,8·10^2 (×380)        | 2×3×2  | 2×3 / piso               | 5    | $7,22·10^184 ($72,2Sxg)   | $7,22·10^1337 ($7,22e1337)
LAX10  | Condensador de hélio verde     | 1                       | ×2,2·10^1 (×22) → ×2,4·10^1 (×24)                                           | ×5,28·10^2 (×528)       | 4×3×3  | 2×3 / piso               | 5    | $1,82·10^186 ($1,82USxg)  | $1,82·10^1339 ($1,82e1339)
LAX11  | Prensa superfluida             | 1                       | ×2,8·10^1 (×28) → ×2,9·10^1 (×29)                                           | ×8,12·10^2 (×812)       | 4×4×3  | 2×4 / +1                 | 5    | $4,01·10^186 ($4,01USxg)  | $4,01·10^1339 ($4,01e1339)
LAX12  | Anel de choque criogênico      | 1                       | ×3,3·10^1 (×33) → ×3,5·10^1 (×35)                                           | ×1,155·10^3 (×1,155K)   | 4×4×3  | 2×4 / piso               | 5    | $1,28·10^187 ($12,8USxg)  | $1,28·10^1340 ($1,28e1340)
LAX13  | Garra de tungstênio solar          | 2        | ×2,992·10^2 (×299,2)                                                        | ×2,992·10^2 (×299,2)            | 3×2×2  | 2×2 / piso / −0,5         | 10   | $4,49·10^194 ($449TSxg)      | $4,49·10^10784 ($4,49e10784)
LAX14  | Bobina de cobre solar          | 2                       | ×1,9·10^1 (×19) → ×2,1·10^1 (×21)                                           | ×3,99·10^2 (×399)       | 4×3×2  | 2×3 / piso               | 10   | $5,02·10^194 ($502TSxg)   | $5,02·10^10784 ($5,02e10784)
LAX15  | Lacre de escória radiante      | 2                       | ×2,4·10^1 (×24) → ×2,5·10^1 (×25)                                           | ×6·10^2 (×600)          | 4×3×1  | 2×3 / piso               | 10   | $5,62·10^194 ($562TSxg)   | $5,62·10^10784 ($5,62e10784)
LAX16  | Fole de carbeto dourado        | 1                       | ×2,8·10^1 (×28) → ×3·10^1 (×30)                                             | ×8,4·10^2 (×840)        | 4×4×2  | 2×4 / piso               | 10   | $7,87·10^195 ($7,87QaSxg) | $7,87·10^10785 ($7,87e10785)
LAX17  | Trefila de arco de tungstênio  | 1                       | ×3,5·10^1 (×35) → ×3,6·10^1 (×36)                                           | ×1,26·10^3 (×1,26K)     | 5×4×3  | 2×4 / +1 / −0,5          | 10   | $1,3·10^196 ($13QaSxg)    | $1,3·10^10786 ($1,3e10786)
LAX18  | Portal de fundente solar       | 1                       | ×1,2·10^1 (×12) → ×1,2·10^1 (×12) → ×1,3·10^1 (×13)                         | ×1,872·10^3 (×1,872K)   | 5×5×3  | 2×5 / +1 / −0,5          | 10   | $3,12·10^196 ($31,2QaSxg) | $3,12·10^10786 ($3,12e10786)
LAX19  | Prisma de espinélio                | 2        | ×2,16·10^1 (×21,6) → ×2,16·10^1 (×21,6)                                     | ×4,6656·10^2 (×466,56)          | 3×3×2  | 2×3 / piso / −0,5         | 15   | $1,04·10^204 ($1,04SpSxg)    | $1,04·10^(4,88·10^10−16) ($1,04e(4,88e10−16))
LAX20  | Colimador de granada rosa      | 2                       | ×2,4·10^1 (×24) → ×2,6·10^1 (×26)                                           | ×6,24·10^2 (×624)       | 4×3×2  | 2×3 / piso               | 15   | $1,16·10^204 ($1,16SpSxg) | $1,16·10^(4,88·10^10−16) ($1,16e(4,88e10−16))
LAX21  | Ressonador de quartzo rosa     | 2                       | ×3·10^1 (×30) → ×3,1·10^1 (×31)                                             | ×9,3·10^2 (×930)        | 3×4×3  | 2×4 / +1 / −0,5          | 15   | $1,3·10^204 ($1,3SpSxg)   | $1,3·10^(4,88·10^10−16) ($1,3e(4,88e10−16))
LAX22  | Separador birrefringente       | 1                       | ×10^1 (×10) → ×10^1 (×10) → ×1,3·10^1 (×13)                                 | ×1,3·10^3 (×1,3K)       | 4×4×3  | 2×4 / piso               | 15   | $1,41·10^205 ($14,1SpSxg) | $1,41·10^(4,88·10^10−15) ($1,41e(4,88e10−15))
LAX23  | Matriz de espelhos de fase     | 1                       | ×1,2·10^1 (×12) → ×1,2·10^1 (×12) → ×1,4·10^1 (×14)                         | ×2,016·10^3 (×2,016K)   | 5×4×4  | 2×4 / +1 / −0,5          | 15   | $2,27·10^205 ($22,7SpSxg) | $2,27·10^(4,88·10^10−15) ($2,27e(4,88e10−15))
LAX24  | Cascata de espinélio rosa      | 1                       | ×1,4·10^1 (×14) → ×1,4·10^1 (×14) → ×1,5·10^1 (×15)                         | ×2,94·10^3 (×2,94K)     | 5×5×3  | 2×5 / +1 / −0,5          | 15   | $5,45·10^205 ($54,5SpSxg) | $5,45·10^(4,88·10^10−15) ($5,45e(4,88e10−15))
LAX25  | Lastro de gravidade inversa        | 2        | ×2,73·10^1 (×27,3) → ×2,73·10^1 (×27,3)                                     | ×7,4529·10^2 (×745,29)          | 4×3×2  | 2×3 / piso                | 20   | $1,76·10^213 ($1,76Spg)      | $1,76·10^(7,02·10^26−17) ($1,76e(7,02e26−17))
LAX26  | Pêndulo gravítico              | 2                       | ×3,1·10^1 (×31) → ×3,2·10^1 (×32)                                           | ×9,92·10^2 (×992)       | 4×3×3  | 2×3 / +1                 | 20   | $1,97·10^213 ($1,97Spg)   | $1,97·10^(7,02·10^26−17) ($1,97e(7,02e26−17))
LAX27  | Prisma de lente gravitacional  | 2                       | ×3,8·10^1 (×38) → ×3,9·10^1 (×39)                                           | ×1,482·10^3 (×1,482K)   | 4×4×3  | 2×4 / +1                 | 20   | $2,19·10^213 ($2,19Spg)   | $2,19·10^(7,02·10^26−17) ($2,19e(7,02e26−17))
LAX28  | Válvula de poço gravítico      | 1                       | ×1,2·10^1 (×12) → ×1,2·10^1 (×12) → ×1,4·10^1 (×14)                         | ×2,016·10^3 (×2,016K)   | 5×4×4  | 2×4 / +1 / −0,5          | 20   | $2,49·10^214 ($24,9Spg)   | $2,49·10^(7,02·10^26−16) ($2,49e(7,02e26−16))
LAX29  | Malha de massa aparente        | 1                       | ×1,4·10^1 (×14) → ×1,4·10^1 (×14) → ×1,6·10^1 (×16)                         | ×3,136·10^3 (×3,136K)   | 4×5×3  | 2×5 / piso               | 20   | $3,99·10^214 ($39,9Spg)   | $3,99·10^(7,02·10^26−16) ($3,99e(7,02e26−16))
LAX30  | Colisor de marés gravíticas    | 1                       | ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,8·10^1 (×18)                         | ×4,608·10^3 (×4,608K)   | 5×5×4  | 2×5 / +2 / −0,5          | 20   | $9,63·10^214 ($96,3Spg)   | $9,63·10^(7,02·10^26−16) ($9,63e(7,02e26−16))
LAX31  | Vácuostato de néon                 | 2        | ×3,42·10^1 (×34,2) → ×3,42·10^1 (×34,2)                                     | ×1,16964·10^3 (×1169,64)        | 4×3×3  | 2×3 / piso                | 25   | $3,15·10^222 ($3,15TSpg)     | $3,15·10^(3,23·10^52−21) ($3,15e(3,23e52−21))
LAX32  | Ejetor de pulso ultravácuo     | 2                       | ×3,9·10^1 (×39) → ×4·10^1 (×40)                                             | ×1,56·10^3 (×1,56K)     | 4×4×3  | 2×4 / +1                 | 25   | $3,52·10^222 ($3,52TSpg)  | $3,52·10^(3,23·10^52−21) ($3,52e(3,23e52−21))
LAX33  | Grade de expansão adiabática   | 2                       | ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,4·10^1 (×14)                         | ×2,366·10^3 (×2,366K)   | 5×4×3  | 2×4 / +1 / −0,5          | 25   | $3,94·10^222 ($3,94TSpg)  | $3,94·10^(3,23·10^52−21) ($3,94e(3,23e52−21))
LAX34  | Válvula de cavidade evacuada   | 1                       | ×1,4·10^1 (×14) → ×1,4·10^1 (×14) → ×1,7·10^1 (×17)                         | ×3,332·10^3 (×3,332K)   | 4×5×4  | 2×5 / +1                 | 25   | $4,26·10^223 ($42,6TSpg)  | $4,26·10^(3,23·10^52−20) ($4,26e(3,23e52−20))
LAX35  | Câmara de emissão de vácuo     | 1                       | ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,9·10^1 (×19)                         | ×4,864·10^3 (×4,864K)   | 5×5×4  | 2×5 / +2 / −0,5          | 25   | $7,01·10^223 ($70,1TSpg)  | $7,01·10^(3,23·10^52−20) ($7,01e(3,23e52−20))
LAX36  | Reator de pressão negativa     | 1                       | ×1,9·10^1 (×19) → ×1,9·10^1 (×19) → ×2·10^1 (×20)                           | ×7,22·10^3 (×7,22K)     | 6×5×4  | 2×5 / +1                 | 25   | $1,7·10^224 ($170TSpg)    | $1,7·10^(3,23·10^52−19) ($1,7e(3,23e52−19))
LAX37  | Sonda de neutrinos lentos          | 2        | ×4,24·10^1 (×42,4) → ×4,24·10^1 (×42,4)                                     | ×1,79776·10^3 (×1797,76)        | 4×4×3  | 2×4 / +1                  | 30   | $5,19·10^231 ($5,19SxSpg)    | $5,19·10^(4,76·10^87−21) ($5,19e(4,76e87−21))
LAX38  | Janela de antineutrinos        | 2                       | ×4,8·10^1 (×48) → ×5·10^1 (×50)                                             | ×2,4·10^3 (×2,4K)       | 5×3×3  | 2×3 / piso / −0,5        | 30   | $5,78·10^231 ($5,78SxSpg) | $5,78·10^(4,76·10^87−21) ($5,78e(4,76e87−21))
LAX39  | Retificador de pulsos neutros  | 2                       | ×1,5·10^1 (×15) → ×1,5·10^1 (×15) → ×1,6·10^1 (×16)                         | ×3,6·10^3 (×3,6K)       | 5×5×3  | 2×5 / +1 / −0,5          | 30   | $6,46·10^231 ($6,46SxSpg) | $6,46·10^(4,76·10^87−21) ($6,46e(4,76e87−21))
LAX40  | Lente de captura rubra         | 1                       | ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,8·10^1 (×18)                         | ×5,202·10^3 (×5,202K)   | 5×4×4  | 2×4 / +2 / −0,5          | 30   | $7,07·10^232 ($70,7SxSpg) | $7,07·10^(4,76·10^87−20) ($7,07e(4,76e87−20))
LAX41  | Ciclotron de neutrinos         | 1                       | ×1,9·10^1 (×19) → ×1,9·10^1 (×19) → ×2,1·10^1 (×21)                         | ×7,581·10^3 (×7,581K)   | 6×5×4  | 2×5 / +1                 | 30   | $1,17·10^233 ($117SxSpg)  | $1,17·10^(4,76·10^87−19) ($1,17e(4,76e87−19))
LAX42  | Ressonador de antineutrinos    | 1                       | ×10^1 (×10) → ×10^1 (×10) → ×10^1 (×10) → ×1,1·10^1 (×11)                   | ×1,1·10^4 (×11K)        | 6×6×5  | 2×6 / +2                 | 30   | $2,67·10^233 ($267SxSpg)  | $2,67·10^(4,76·10^87−19) ($2,67e(4,76e87−19))
LAX43  | Limiar de refração                 | 2        | ×5,36·10^1 (×53,6) → ×5,36·10^1 (×53,6)                                     | ×2,87296·10^3 (×2872,96)        | 5×3×3  | 2×3 / piso / −0,5         | 35   | $8,48·10^240 ($8,48NSpg)     | $8,48·10^(2,24·10^132−22) ($8,48e(2,24e132−22))
LAX44  | Prisma do horizonte focal      | 2                       | ×1,5·10^1 (×15) → ×1,5·10^1 (×15) → ×1,7·10^1 (×17)                         | ×3,825·10^3 (×3,825K)   | 5×4×4  | 2×4 / +1 / −0,5          | 35   | $9,5·10^240 ($9,5NSpg)    | $9,5·10^(2,24·10^132−22) ($9,5e(2,24e132−22))
LAX45  | Fenda de espelho esférico      | 2                       | ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×2·10^1 (×20)                           | ×5,78·10^3 (×5,78K)     | 5×5×4  | 2×5 / +1 / −0,5          | 35   | $1,07·10^241 ($10,7NSpg)  | $1,07·10^(2,24·10^132−21) ($1,07e(2,24e132−21))
LAX46  | Canal de vidro focal           | 1                       | ×1,9·10^1 (×19) → ×1,9·10^1 (×19) → ×2,2·10^1 (×22)                         | ×7,942·10^3 (×7,942K)   | 6×5×4  | 2×5 / +2                 | 35   | $1,13·10^242 ($113NSpg)   | $1,13·10^(2,24·10^132−20) ($1,13e(2,24e132−20))
LAX47  | Estação de lentes duplas       | 1                       | ×10^1 (×10) → ×10^1 (×10) → ×10^1 (×10) → ×1,2·10^1 (×12)                   | ×1,2·10^4 (×12K)        | 6×5×5  | 2×5 / +2                 | 35   | $1,85·10^242 ($185NSpg)   | $1,85·10^(2,24·10^132−20) ($1,85e(2,24e132−20))
LAX48  | Janela de horizonte de vidro   | 1                       | ×1,1·10^1 (×11) → ×1,1·10^1 (×11) → ×1,1·10^1 (×11) → ×1,3·10^1 (×13)       | ×1,7303·10^4 (×17,303K) | 6×6×5  | 2×6 / +1                 | 35   | $4,28·10^242 ($428NSpg)   | $4,28·10^(2,24·10^132−20) ($4,28e(2,24e132−20))
LAX49  | Pente de entropia dirigida         | 2        | ×1,67·10^1 (×16,7) → ×1,67·10^1 (×16,7) → ×1,67·10^1 (×16,7)                | ×4,657463·10^3 (×4657,463)      | 4×5×3  | 2×5 / piso                | 40   | $1,27·10^250 ($12,7DOg)      | $1,27·10^(3,37·10^186−22) ($1,27e(3,37e186−22))
LAX50  | Seletor de gradiente entrópico | 2                       | ×1,8·10^1 (×18) → ×1,8·10^1 (×18) → ×1,9·10^1 (×19)                         | ×6,156·10^3 (×6,156K)   | 5×5×4  | 2×5 / +1 / −0,5          | 40   | $1,42·10^250 ($14,2DOg)   | $1,42·10^(3,37·10^186−22) ($1,42e(3,37e186−22))
LAX51  | Reator de decaimento curto     | 2                       | ×2·10^1 (×20) → ×2·10^1 (×20) → ×2,3·10^1 (×23)                             | ×9,2·10^3 (×9,2K)       | 6×5×5  | 2×5 / +2                 | 40   | $1,59·10^250 ($15,9DOg)   | $1,59·10^(3,37·10^186−22) ($1,59e(3,37e186−22))
LAX52  | Cascata de ordenação térmica   | 1                       | ×10^1 (×10) → ×10^1 (×10) → ×10^1 (×10) → ×1,3·10^1 (×13)                   | ×1,3·10^4 (×13K)        | 6×6×5  | 2×6 / +2                 | 40   | $1,8·10^251 ($180DOg)     | $1,8·10^(3,37·10^186−21) ($1,8e(3,37e186−21))
LAX53  | Câmara de entropia dirigida    | 1                       | ×1,1·10^1 (×11) → ×1,1·10^1 (×11) → ×1,1·10^1 (×11) → ×1,4·10^1 (×14)       | ×1,8634·10^4 (×18,634K) | 7×5×5  | 2×5 / +1 / −0,5          | 40   | $3,08·10^251 ($308DOg)    | $3,08·10^(3,37·10^186−21) ($3,08e(3,37e186−21))
LAX54  | Arco de decaimento reverso     | 1                       | ×1,2·10^1 (×12) → ×1,2·10^1 (×12) → ×1,2·10^1 (×12) → ×1,6·10^1 (×16)       | ×2,7648·10^4 (×27,648K) | 7×6×6  | 2×6 / +2 / −0,5          | 40   | $7,22·10^251 ($722DOg)    | $7,22·10^(3,37·10^186−21) ($7,22e(3,37e186−21))
LAX55  | Lente de fase atemporal            | 2        | ×1,94·10^1 (×19,4) → ×1,94·10^1 (×19,4) → ×1,94·10^1 (×19,4)                | ×7,301384·10^3 (×7301,384)      | 5×4×4  | 2×4 / +1 / −0,5           | 45   | $2,24·10^259 ($22,4QiOg)     | $2,24·10^(1,62·10^250−24) ($2,24e(1,62e250−24))
LAX56  | Prensa do núcleo sem tempo     | 2                       | ×2,1·10^1 (×21) → ×2,1·10^1 (×21) → ×2,2·10^1 (×22)                         | ×9,702·10^3 (×9,702K)   | 6×5×5  | 2×5 / +1                 | 45   | $2,5·10^259 ($25QiOg)     | $2,5·10^(1,62·10^250−24) ($2,5e(1,62e250−24))
LAX57  | Crisol de ignição atemporal    | 2                       | ×10^1 (×10) → ×10^1 (×10) → ×10^1 (×10) → ×1,4·10^1 (×14)                   | ×1,4·10^4 (×14K)        | 6×6×5  | 2×6 / +2                 | 45   | $2,8·10^259 ($28QiOg)     | $2,8·10^(1,62·10^250−24) ($2,8e(1,62e250−24))
LAX58  | Reator de fase imutável        | 1                       | ×1,1·10^1 (×11) → ×1,1·10^1 (×11) → ×1,1·10^1 (×11) → ×1,5·10^1 (×15)       | ×1,9965·10^4 (×19,965K) | 7×5×6  | 2×5 / +2 / −0,5          | 45   | $3,04·10^260 ($304QiOg)   | $3,04·10^(1,62·10^250−23) ($3,04e(1,62e250−23))
LAX59  | Pórtico do último horizonte    | 1                       | ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,4·10^1 (×14)       | ×3,0758·10^4 (×30,758K) | 7×7×6  | 2×7 / +2 / −0,5          | 45   | $5,04·10^260 ($504QiOg)   | $5,04·10^(1,62·10^250−23) ($5,04e(1,62e250−23))
LAX60  | Modificador da eternidade      | 1                       | ×8·10^0 (×8) → ×8·10^0 (×8) → ×8·10^0 (×8) → ×8·10^0 (×8) → ×1,1·10^1 (×11) | ×4,5056·10^4 (×45,056K) | 8×8×7  | 2×8 / +2                 | 45   | $1,2·10^261 ($1,2SxOg)    | $1,2·10^(1,62·10^250−22) ($1,2e(1,62e250−22))
```

## Craft de Ascensão · 50 peças

### Mineradoras

```text
Código | Máquina                        | Minérios/s | Minério local            | Hitbox | Avanço | Asc. | Ren. | Compras locais
CAM01  | Escavadora de arco forjado     | 1,15       | $1,6·10^11 ($160B)       | 5×4×4  | 1,5    | 1    | 6    | $0
CAM02  | Mineradora das duas marés      | 0,9        | $1,6·10^18 ($1,6Qn)      | 5×5×4  | 2,5    | 1    | 16   | $0
CAM03  | Escavadora de cobalto branco   | 1,2        | $1,6·10^29 ($160O)       | 6×4×5  | 2,5    | 1    | 36   | $0
CAM04  | Mineradora de liga eclipse     | 1          | $1,6·10^36 ($1,6UDe)     | 6×5×5  | 2,5    | 1    | 46   | $0
CAM05  | Escavadora de relé triplo      | 1,15       | $1,6·10^23 ($160Sx)      | 6×6×5  | 3,5    | 1    | 26   | $0
CAM06  | Mineradora da trama polar      | 0,9        | $2,56·10^29 ($256O)      | 7×5×5  | 3,5    | 1    | 36   | $0
CAM07  | Escavadora de contrafase       | 1,2        | $2,56·10^36 ($2,56UDe)   | 7×6×6  | 3,5    | 1    | 46   | $0
CAM08  | Mineradora de nexo interno     | 1          | $4,096·10^36 ($4,096UDe) | 7×7×7  | 4,5    | 1    | 46   | $0
CAM09  | Mineradora de nexo externo     | 1,15       | $1,6·10^38 ($160UDe)     | 8×6×7  | 4,5    | 1    | 46   | ≈ $8·10^127 ($80UQag)
CAM10  | Mineradora síntese da ascensão | 0,9        | $10^77 ($100QaVi)        | 9×8×8  | 3,5    | 45   | 46   | ≈ $3,14·10^259 ($31,4QiOg)
```

### Fornalhas

```text
Código | Máquina                      | Multiplicador de venda | Hitbox | Bandeja / nível / desvio | Asc. | Ren. | Compras locais
CAF01  | Fornalha de arco forjado     | ×1,6·10^4 (×16K)       | 4×4×2  | 2×2 / piso               | 1    | 7    | $0
CAF02  | Fornalha de nácar iônico     | ×1,6·10^11 (×160B)     | 4×4×4  | 2×2 / piso               | 1    | 17   | $0
CAF03  | Fornalha da trama carmim     | ×1,6·10^23 (×160Sx)    | 5×5×3  | 2×2 / piso / −0,5        | 1    | 37   | $0
CAF04  | Fornalha de liga celeste     | ×1,6·10^31 (×16N)      | 4×5×4  | 2×2 / piso               | 1    | 47   | $0
CAF05  | Fornalha da caldeira polar   | ×1,6·10^16 (×16Qd)     | 6×5×4  | 2×2 / piso               | 1    | 27   | $0
CAF06  | Fornalha de canais triplos   | ×2,56·10^23 (×256Sx)   | 6×5×5  | 2×2 / piso               | 1    | 37   | $0
CAF07  | Fornalha da forja branca     | ×2,56·10^31 (×25,6N)   | 6×6×5  | 2×2 / piso               | 1    | 47   | $0
CAF08  | Fornalha de nexo térmico     | ×4,096·10^31 (×40,96N) | 7×6×5  | 2×2 / piso / −0,5        | 1    | 47   | $0
CAF09  | Fornalha de nexo iônico      | ×1,6·10^33 (×1,6De)    | 7×7×6  | 2×2 / piso / −0,5        | 1    | 47   | ≈ $8·10^135 ($8QaQag)
CAF10  | Fornalha síntese da ascensão | ×10^72 (×1TVi)         | 8×7×7  | 2×2 / piso               | 45   | 47   | ≈ $6,1·10^259 ($61QiOg)
```

### Modificadores

```text
Código | Máquina                         | Limite | Efeito por faixa em ordem                                                                | Total da passagem     | Hitbox | Correia / nível / desvio | Asc. | Ren. | Compras locais
CAX01  | Lacre de prata forjada          | 2      | ×4,8·10^1 (×48)                                                                          | ×4,8·10^1 (×48)       | 3×2×2  | 2×2 / piso / −0,5        | 1    | 13   | $0
CAX02  | Grampo de liga polar            | 2      | ×8·10^0 (×8) → ×8·10^0 (×8)                                                              | ×6,4·10^1 (×64)       | 3×3×2  | 2×3 / piso / −0,5        | 1    | 19   | $0
CAX03  | Relé de brasa branca            | 2      | ×8,6·10^1 (×86)                                                                          | ×8,6·10^1 (×86)       | 4×2×2  | 2×2 / piso               | 1    | 21   | $0
CAX04  | Pente de luz forjada            | 2      | ×9·10^0 (×9) → ×1,1·10^1 (×11)                                                           | ×9,9·10^1 (×99)       | 4×3×2  | 2×3 / piso               | 1    | 24   | $0
CAX05  | Cruzeta de nácar                | 2      | ×10^1 (×10) → ×1,2·10^1 (×12)                                                            | ×1,2·10^2 (×120)      | 3×4×3  | 2×4 / piso / −0,5        | 1    | 25   | $0
CAX06  | Prisma de liga solar            | 2      | ×1,1·10^1 (×11) → ×1,2·10^1 (×12)                                                        | ×1,32·10^2 (×132)     | 4×4×3  | 2×4 / piso               | 1    | 29   | $0
CAX07  | Fatia de cobalto branco         | 2      | ×1,1·10^1 (×11) → ×1,3·10^1 (×13)                                                        | ×1,43·10^2 (×143)     | 4×4×2  | 2×4 / piso               | 1    | 30   | $0
CAX08  | Gerador de maré forjada         | 2      | ×1,2·10^1 (×12) → ×1,2·10^1 (×12)                                                        | ×1,44·10^2 (×144)     | 4×5×3  | 2×5 / piso               | 1    | 31   | $0
CAX09  | Lâmina do eclipse forjado       | 2      | ×1,1·10^1 (×11) → ×1,3·10^1 (×13)                                                        | ×1,43·10^2 (×143)     | 5×3×3  | 2×3 / piso / −0,5        | 1    | 33   | $0
CAX10  | Gaiola de argônio claro         | 2      | ×1,2·10^1 (×12) → ×1,3·10^1 (×13)                                                        | ×1,56·10^2 (×156)     | 5×4×3  | 2×4 / +1 / −0,5          | 1    | 34   | $0
CAX11  | Fenda do relé triplo            | 2      | ×5·10^0 (×5) → ×5·10^0 (×5) → ×7·10^0 (×7)                                               | ×1,75·10^2 (×175)     | 4×5×3  | 2×5 / +1                 | 1    | 35   | $0
CAX12  | Célula de liga clara            | 2      | ×5·10^0 (×5) → ×5·10^0 (×5) → ×6·10^0 (×6)                                               | ×1,5·10^2 (×150)      | 5×4×4  | 2×4 / +1 / −0,5          | 1    | 38   | $0
CAX13  | Arco de vapor forjado           | 2      | ×5·10^0 (×5) → ×5·10^0 (×5) → ×8·10^0 (×8)                                               | ×2·10^2 (×200)        | 5×5×3  | 2×5 / +1 / −0,5          | 1    | 39   | $0
CAX14  | Crivo da trama violeta          | 2      | ×6·10^0 (×6) → ×6·10^0 (×6) → ×9·10^0 (×9)                                               | ×3,24·10^2 (×324)     | 5×4×4  | 2×4 / +1 / −0,5          | 1    | 40   | $0
CAX15  | Matriz de hélio branco          | 2      | ×7·10^0 (×7) → ×7·10^0 (×7) → ×10^1 (×10)                                                | ×4,9·10^2 (×490)      | 5×5×4  | 2×5 / +2 / −0,5          | 1    | 42   | $0
CAX16  | Pórtico de liga iônica          | 2      | ×5·10^0 (×5) → ×5·10^0 (×5) → ×7·10^0 (×7)                                               | ×1,75·10^2 (×175)     | 6×4×4  | 2×4 / +1                 | 1    | 44   | $0
CAX17  | Bobina da forja rubra           | 2      | ×5·10^0 (×5) → ×5·10^0 (×5) → ×7·10^0 (×7)                                               | ×1,75·10^2 (×175)     | 5×6×4  | 2×6 / +1 / −0,5          | 1    | 45   | $0
CAX18  | Polarizador de nexo claro       | 2      | ×7·10^0 (×7) → ×7·10^0 (×7) → ×8·10^0 (×8)                                               | ×3,92·10^2 (×392)     | 6×5×4  | 2×5 / +2                 | 1    | 48   | $0
CAX19  | Trefila de nexo rubra           | 2      | ×7·10^0 (×7) → ×7·10^0 (×7) → ×9·10^0 (×9)                                               | ×4,41·10^2 (×441)     | 6×5×5  | 2×5 / +1                 | 1    | 49   | $0
CAX20  | Turbina de nexo polar           | 2      | ×8·10^0 (×8) → ×8·10^0 (×8) → ×10^1 (×10)                                                | ×6,4·10^2 (×640)      | 6×6×4  | 2×6 / +1                 | 1    | 50   | $0
CAX21  | Relicário de condutores         | 2      | ×5·10^0 (×5) → ×5·10^0 (×5) → ×6·10^0 (×6)                                               | ×1,5·10^2 (×150)      | 6×6×5  | 2×6 / +2                 | 1    | 21   | $0
CAX22  | Relicário de processadores      | 2      | ×3·10^0 (×3) → ×3·10^0 (×3) → ×3·10^0 (×3) → ×8·10^0 (×8)                                | ×2,16·10^2 (×216)     | 6×7×5  | 2×7 / +1                 | 1    | 29   | $0
CAX23  | Relicário de emissores          | 2      | ×3·10^0 (×3) → ×3·10^0 (×3) → ×3·10^0 (×3) → ×10^1 (×10)                                 | ×2,7·10^2 (×270)      | 7×5×5  | 2×5 / +1 / −0,5          | 1    | 34   | $0
CAX24  | Relicário de ressonadores       | 2      | ×4·10^0 (×4) → ×4·10^0 (×4) → ×4·10^0 (×4) → ×5·10^0 (×5)                                | ×3,2·10^2 (×320)      | 7×6×5  | 2×6 / +2 / −0,5          | 1    | 39   | $0
CAX25  | Relicário de compressores       | 2      | ×5·10^0 (×5) → ×5·10^0 (×5) → ×5·10^0 (×5) → ×7·10^0 (×7)                                | ×8,75·10^2 (×875)     | 6×7×6  | 2×7 / +2                 | 1    | 45   | $0
CAX26  | Relicário de portais            | 2      | ×5·10^0 (×5) → ×5·10^0 (×5) → ×5·10^0 (×5) → ×9·10^0 (×9)                                | ×1,125·10^3 (×1,125K) | 7×7×5  | 2×7 / +1 / −0,5          | 1    | 50   | $0
CAX27  | Nexo da forja solar             | 2      | ×4·10^0 (×4) → ×4·10^0 (×4) → ×4·10^0 (×4) → ×6·10^0 (×6)                                | ×3,84·10^2 (×384)     | 7×7×6  | 2×7 / +2 / −0,5          | 1    | 29   | $0
CAX28  | Nexo da forja polar             | 2      | ×4·10^0 (×4) → ×4·10^0 (×4) → ×4·10^0 (×4) → ×8·10^0 (×8)                                | ×5,12·10^2 (×512)     | 8×6×6  | 2×6 / +2                 | 1    | 39   | $0
CAX29  | Nexo da forja astral            | 2      | ×6·10^0 (×6) → ×6·10^0 (×6) → ×6·10^0 (×6) → ×9·10^0 (×9)                                | ×1,944·10^3 (×1,944K) | 8×7×6  | 2×7 / +2                 | 1    | 50   | $0
CAX30  | Modificador síntese da ascensão | 1      | ×10^22 (×10Sx) → ×10^23 (×100Sx) → ×10^23 (×100Sx) → ×10^23 (×100Sx) → ×4·10^23 (×400Sx) | ×4·10^114 (×4SpTg)    | 9×8×7  | 2×8 / +2 / −0,5          | 45   | 50   | ≈ $2,08·10^261 ($2,08SxOg)
```

## Craft intermediário de Ascensão · 50 peças

### Mineradoras

```text
Código | Máquina                             | Minérios/s | Minério local       | Hitbox | Avanço | Asc. | Ren. | Compras locais
CIM01  | Escavadora de zircônia laminada     | 1,15       | $2·10^40 ($20DDe)   | 4×3×3  | 1,5    | 1    | —    | ≈ $1,85·10^166 ($18,5QaQig)
CIM02  | Escavadora de banho sinterizado     | 0,9        | $2·10^44 ($200TDe)  | 4×5×3  | 1,5    | 5    | —    | ≈ $1,72·10^185 ($172Sxg)
CIM03  | Escavadora de liga solar            | 1,2        | $2·10^48 ($2QiDe)   | 5×5×4  | 2,5    | 10   | —    | ≈ $7,07·10^194 ($707TSxg)
CIM04  | Escavadora de quartzo temperado     | 1          | $2·10^52 ($20SxDe)  | 5×6×5  | 2,5    | 15   | —    | ≈ $1,46·10^204 ($1,46SpSxg)
CIM05  | Escavadora de lastro refratário     | 1,15       | $2·10^56 ($200SpDe) | 6×5×5  | 2,5    | 20   | —    | ≈ $2,46·10^213 ($2,46Spg)
CIM06  | Escavadora de cavidades gêmeas      | 0,9        | $2·10^60 ($2NDe)    | 5×5×5  | 3,5    | 25   | —    | ≈ $4,42·10^222 ($4,42TSpg)
CIM07  | Escavadora de partículas rarefeitas | 1,2        | $2·10^64 ($20Vi)    | 7×5×5  | 3,5    | 30   | —    | ≈ $7,24·10^231 ($7,24SxSpg)
CIM08  | Escavadora de espelhos convergentes | 1          | $2·10^68 ($200UVi)  | 6×7×6  | 3,5    | 35   | —    | ≈ $1,19·10^241 ($11,9NSpg)
CIM09  | Escavadora do horizonte reverso     | 1,15       | $2·10^72 ($2TVi)    | 8×6×7  | 3,5    | 40   | —    | ≈ $1,78·10^250 ($17,8DOg)
CIM10  | Escavadora de passado imóvel        | 0,9        | $2·10^76 ($20QaVi)  | 8×7×7  | 3,5    | 45   | —    | ≈ $3,14·10^259 ($31,4QiOg)
```

### Fornalhas

```text
Código | Máquina                            | Multiplicador de venda | Hitbox | Bandeja / nível / desvio | Asc. | Ren. | Compras locais
CIF01  | Fornalha de sinterização dupla     | ×2·10^35 (×200De)      | 4×3×2  | 2×2 / piso               | 1    | —    | ≈ $4,13·10^166 ($41,3QaQig)
CIF02  | Fornalha de contrafluxo criogênico | ×2·10^39 (×2DDe)       | 5×3×3  | 2×2 / piso / −0,5        | 5    | —    | ≈ $3,65·10^185 ($365Sxg)
CIF03  | Fornalha de tungstênio radiante    | ×2·10^43 (×20TDe)      | 5×4×3  | 2×2 / piso / −0,5        | 10   | —    | ≈ $1,57·10^195 ($1,57QaSxg)
CIF04  | Fornalha de faces birrefringentes  | ×2·10^47 (×200QaDe)    | 6×4×4  | 2×2 / piso               | 15   | —    | ≈ $2,83·10^204 ($2,83SpSxg)
CIF05  | Fornalha de poço refratário        | ×2·10^51 (×2SxDe)      | 5×5×4  | 2×2 / piso / −0,5        | 20   | —    | ≈ $5·10^213 ($5Spg)
CIF06  | Fornalha de expansão pulsada       | ×2·10^55 (×20SpDe)     | 6×5×4  | 2×2 / piso               | 25   | —    | ≈ $8,48·10^222 ($8,48TSpg)
CIF07  | Fornalha de aniquilação pulsada    | ×2·10^59 (×200ODe)     | 6×6×5  | 2×2 / piso               | 30   | —    | ≈ $1,41·10^232 ($14,1SxSpg)
CIF08  | Fornalha de foco duplo             | ×2·10^63 (×2Vi)        | 7×5×5  | 2×2 / piso / −0,5        | 35   | —    | ≈ $2,27·10^241 ($22,7NSpg)
CIF09  | Fornalha de gradiente focal        | ×2·10^67 (×20UVi)      | 7×6×6  | 2×2 / piso / −0,5        | 40   | —    | ≈ $3,59·10^250 ($35,9DOg)
CIF10  | Fornalha de ignição imutável       | ×2·10^71 (×200DVi)     | 8×7×7  | 2×2 / piso               | 45   | —    | ≈ $6,1·10^259 ($61QiOg)
```

### Modificadores

```text
Código | Máquina                             | Limite | Efeito por faixa em ordem                                                   | Total da passagem         | Hitbox | Correia / nível / desvio | Asc. | Ren. | Compras locais
CIX01  | Laminador de caulim                 | 1      | ×2,6·10^1 (×26) → ×2,7·10^1 (×27)                                           | ×7,02·10^2 (×702)         | 3×2×2  | 2×2 / piso / −0,5        | 1    | —    | ≈ $2,07·10^167 ($207QaQig)
CIX02  | Pórtico de têmpera cerâmica         | 1      | ×3,1·10^1 (×31) → ×3,3·10^1 (×33)                                           | ×1,023·10^3 (×1,023K)     | 4×3×3  | 2×3 / piso               | 1    | —    | ≈ $7,05·10^169 ($70,5QiQig)
CIX03  | Crivo de magnesita fundida          | 1      | ×3,8·10^1 (×38) → ×3,9·10^1 (×39)                                           | ×1,482·10^3 (×1,482K)     | 3×3×2  | 2×3 / piso / −0,5        | 1    | —    | ≈ $3,56·10^172 ($35,6SxQig)
CIX04  | Injetor de hélio vitrificado        | 1      | ×3,7·10^1 (×37) → ×3,8·10^1 (×38)                                           | ×1,406·10^3 (×1,406K)     | 4×3×3  | 2×3 / piso               | 5    | —    | ≈ $1,82·10^186 ($1,82USxg)
CIX05  | Prensa de zircônia superfluida      | 1      | ×4,5·10^1 (×45) → ×4,6·10^1 (×46)                                           | ×2,07·10^3 (×2,07K)       | 4×4×3  | 2×4 / +1                 | 5    | —    | ≈ $4,01·10^186 ($4,01USxg)
CIX06  | Anel de magnesita criogênica        | 1      | ×5,4·10^1 (×54) → ×5,5·10^1 (×55)                                           | ×2,97·10^3 (×2,97K)       | 3×4×2  | 2×4 / piso / −0,5        | 5    | —    | ≈ $1,29·10^187 ($12,9USxg)
CIX07  | Trefila de tungstênio fundido       | 1      | ×4·10^1 (×40) → ×4,2·10^1 (×42)                                             | ×1,68·10^3 (×1,68K)       | 4×3×2  | 2×3 / piso               | 10   | —    | ≈ $8,32·10^195 ($8,32QaSxg)
CIX08  | Bobina de sopro solar               | 1      | ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,5·10^1 (×15)                         | ×2,535·10^3 (×2,535K)     | 3×4×3  | 2×4 / piso / −0,5        | 10   | —    | ≈ $1,35·10^196 ($13,5QaSxg)
CIX09  | Selo de fundente dourado            | 1      | ×6,1·10^1 (×61) → ×6,2·10^1 (×62)                                           | ×3,782·10^3 (×3,782K)     | 5×3×3  | 2×3 / piso / −0,5        | 10   | —    | ≈ $3,18·10^196 ($31,8QaSxg)
CIX10  | Prisma de tungstênio birrefringente | 1      | ×1,4·10^1 (×14) → ×1,4·10^1 (×14) → ×1,8·10^1 (×18)                         | ×3,528·10^3 (×3,528K)     | 4×4×3  | 2×4 / +1                 | 15   | —    | ≈ $1,51·10^205 ($15,1SpSxg)
CIX11  | Colimador de cobre facetado         | 1      | ×1,7·10^1 (×17) → ×1,7·10^1 (×17) → ×1,8·10^1 (×18)                         | ×5,202·10^3 (×5,202K)     | 5×4×3  | 2×4 / piso / −0,5        | 15   | —    | ≈ $2,39·10^205 ($23,9SpSxg)
CIX12  | Cascata de quartzo solar            | 1      | ×1,9·10^1 (×19) → ×1,9·10^1 (×19) → ×2,1·10^1 (×21)                         | ×7,581·10^3 (×7,581K)     | 4×5×3  | 2×5 / +1                 | 15   | —    | ≈ $5,58·10^205 ($55,8SpSxg)
CIX13  | Balança de massa facetada           | 1      | ×1,9·10^1 (×19) → ×1,9·10^1 (×19) → ×2·10^1 (×20)                           | ×7,22·10^3 (×7,22K)       | 5×4×4  | 2×4 / +1 / −0,5          | 20   | —    | ≈ $2,67·10^214 ($26,7Spg)
CIX14  | Pêndulo de liga lapidada            | 1      | ×2,1·10^1 (×21) → ×2,1·10^1 (×21) → ×2,4·10^1 (×24)                         | ×1,0584·10^4 (×10,584K)   | 4×5×4  | 2×5 / +1                 | 20   | —    | ≈ $4,19·10^214 ($41,9Spg)
CIX15  | Colisor de espelhos criogênicos     | 1      | ×2,4·10^1 (×24) → ×2,4·10^1 (×24) → ×2,7·10^1 (×27)                         | ×1,5552·10^4 (×15,552K)   | 5×5×4  | 2×5 / +2 / −0,5          | 20   | —    | ≈ $9,85·10^214 ($98,5Spg)
CIX16  | Válvula de néon rarefeito           | 1      | ×1,8·10^1 (×18) → ×1,8·10^1 (×18) → ×2,1·10^1 (×21)                         | ×6,804·10^3 (×6,804K)     | 4×4×3  | 2×4 / piso               | 25   | —    | ≈ $4,58·10^223 ($45,8TSpg)
CIX17  | Ejetor de feixe rarefeito           | 1      | ×2,1·10^1 (×21) → ×2,1·10^1 (×21) → ×2,3·10^1 (×23)                         | ×1,0143·10^4 (×10,143K)   | 5×5×3  | 2×5 / +1 / −0,5          | 25   | —    | ≈ $7,36·10^223 ($73,6TSpg)
CIX18  | Reator de pulso adiabático          | 1      | ×2,4·10^1 (×24) → ×2,4·10^1 (×24) → ×2,6·10^1 (×26)                         | ×1,4976·10^4 (×14,976K)   | 6×4×4  | 2×4 / +1                 | 25   | —    | ≈ $1,74·10^224 ($174TSpg)
CIX19  | Sonda de cavidade neutra            | 1      | ×2,3·10^1 (×23) → ×2,3·10^1 (×23) → ×2,6·10^1 (×26)                         | ×1,3754·10^4 (×13,754K)   | 5×4×4  | 2×4 / +1 / −0,5          | 30   | —    | ≈ $7,59·10^232 ($75,9SxSpg)
CIX20  | Janela de captura reversa           | 1      | ×2,7·10^1 (×27) → ×2,7·10^1 (×27) → ×2,8·10^1 (×28)                         | ×2,0412·10^4 (×20,412K)   | 6×4×4  | 2×4 / +1                 | 30   | —    | ≈ $1,23·10^233 ($123SxSpg)
CIX21  | Retificador de antineutrinos        | 1      | ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,4·10^1 (×14)       | ×3,0758·10^4 (×30,758K)   | 6×6×5  | 2×6 / +2                 | 30   | —    | ≈ $2,73·10^233 ($273SxSpg)
CIX22  | Colimador de vidro esférico         | 1      | ×2,5·10^1 (×25) → ×2,5·10^1 (×25) → ×2,6·10^1 (×26)                         | ×1,625·10^4 (×16,25K)     | 5×5×4  | 2×5 / +1 / −0,5          | 35   | —    | ≈ $1,21·10^242 ($121NSpg)
CIX23  | Estação de foco coaxial             | 1      | ×1,2·10^1 (×12) → ×1,2·10^1 (×12) → ×1,2·10^1 (×12) → ×1,4·10^1 (×14)       | ×2,4192·10^4 (×24,192K)   | 6×5×5  | 2×5 / +2                 | 35   | —    | ≈ $1,95·10^242 ($195NSpg)
CIX24  | Janela de refração concêntrica      | 1      | ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,6·10^1 (×16)       | ×3,5152·10^4 (×35,152K)   | 7×4×5  | 2×4 / +1 / −0,5          | 35   | —    | ≈ $4,39·10^242 ($439NSpg)
CIX25  | Ordenador de reflexos térmicos      | 1      | ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,3·10^1 (×13) → ×1,5·10^1 (×15)       | ×3,2955·10^4 (×32,955K)   | 6×6×5  | 2×6 / +2                 | 40   | —    | ≈ $1,93·10^251 ($193DOg)
CIX26  | Câmara de espelhos entrópicos       | 1      | ×1,4·10^1 (×14) → ×1,4·10^1 (×14) → ×1,4·10^1 (×14) → ×1,8·10^1 (×18)       | ×4,9392·10^4 (×49,392K)   | 7×5×5  | 2×5 / +2 / −0,5          | 40   | —    | ≈ $3,22·10^251 ($322DOg)
CIX27  | Arco de decaimento refratado        | 1      | ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,6·10^1 (×16) → ×1,8·10^1 (×18)       | ×7,3728·10^4 (×73,728K)   | 6×7×5  | 2×7 / +2                 | 40   | —    | ≈ $7,38·10^251 ($738DOg)
CIX28  | Reator de óptica imutável           | 1      | ×9·10^0 (×9) → ×9·10^0 (×9) → ×9·10^0 (×9) → ×9·10^0 (×9) → ×1,1·10^1 (×11) | ×7,2171·10^4 (×72,171K)   | 7×7×6  | 2×7 / +2 / −0,5          | 45   | —    | ≈ $3,26·10^260 ($326QiOg)
CIX29  | Pórtico de massa atemporal          | 1      | ×9·10^0 (×9) → ×9·10^0 (×9) → ×9·10^0 (×9) → ×9·10^0 (×9) → ×1,6·10^1 (×16) | ×1,04976·10^5 (×104,976K) | 8×7×7  | 2×7 / +2                 | 45   | —    | ≈ $5,29·10^260 ($529QiOg)
CIX30  | Crisol do tempo suspenso            | 1      | ×10^1 (×10) → ×10^1 (×10) → ×10^1 (×10) → ×10^1 (×10) → ×1,5·10^1 (×15)     | ×1,5·10^5 (×150K)         | 8×8×7  | 2×8 / +2                 | 45   | —    | ≈ $1,23·10^261 ($1,23SxOg)
```
