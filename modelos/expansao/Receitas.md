# Receitas de craft

As 50 receitas incluem máquinas da loja atual, da nova leva, de renascimento e de craft. Cada ingrediente representa **uma unidade**.

Os modelos novos da loja usam os códigos LM, LF e LX. Os crafts usam CM, CF e CX. Os ingredientes sem código já estão no catálogo.

## Árvore de dependências

Os recuos mostram quais crafts entram diretamente em cada receita. Os nós sem outros crafts usam os ingredientes de loja e renascimento listados abaixo. Cada ingrediente listado é consumido uma vez. A Convergência consome os três crafts diretamente ligados a ela, que já incorporam as peças dos níveis anteriores.

O número ao lado de cada craft é o primeiro renascimento em que seus ingredientes de recompensa podem ter sido entregues pelo cronograma garantido. O valor é a soma estimada para comprar os ingredientes da loja desde o início da receita. Veja os efeitos e os valores em expoentes na [tabela de valores](Tabela_de_valores.md).

### Mineradoras

```text
CM10 Escavadora convergência · 46º · ≈ $100UQag
├─ CM07 Extratora cordilheira · 11º · ≈ $102T
│  ├─ CM01 Escavadora de estratos · 6º · ≈ $10,1M
│  └─ CM02 Escavadora de caldeira · 11º · ≈ $102T
├─ CM08 Extratora da magnetosfera · 26º · ≈ $5,02DDe
│  ├─ CM03 Mineradora eixo polar · 16º · ≈ $2,53Sx
│  └─ CM04 Mineradora contrapeso · 26º · ≈ $5,02DDe
└─ CM09 Extratora núcleo de estrela · 46º · ≈ $100UQag
   ├─ CM05 Escavadora do limiar · 36º · ≈ $10Vi
   └─ CM06 Escavadora do afélio · 46º · ≈ $100UQag
```

### Fornalhas

```text
CF10 Fornalha convergência · 47º · ≈ $10QaQag
├─ CF07 Fornalha coroa refratária · 12º · ≈ $1,03Qd
│  ├─ CF01 Fornalha crisol duplo · 7º · ≈ $501M
│  └─ CF02 Fornalha espelho fundido · 12º · ≈ $1,03Qd
├─ CF08 Fornalha bifurcação · 27º · ≈ $1QaDe
│  ├─ CF03 Fornalha cerâmica iônica · 17º · ≈ $750De
│  └─ CF04 Fornalha câmara de hélio · 27º · ≈ $1QaDe
└─ CF09 Fornalha aurora tripla · 47º · ≈ $10QaQag
   ├─ CF05 Fornalha arco abissal · 37º · ≈ $100DVi
   └─ CF06 Fornalha chama fria · 47º · ≈ $10QaQag
```

### Modificadores

```text
CX30 Modificador convergência · 50º · ≈ $1OQag
├─ CX27 Reator da coroa solar · 30º · ≈ $443Qn
│  ├─ CX21 Matriz de amplificação · 23º · ≈ $5,01T
│  │  ├─ CX01 Comutador ferro-prisma · 13º · ≈ $61K
│  │  ├─ CX02 Peneira pressurizada · 19º · ≈ $2,48M
│  │  ├─ CX03 Ponte dos cristais · 20º · $595M
│  │  └─ CX04 Coletor de marfim · 23º · $5,01T
│  └─ CX22 Nave de irradiação · 30º · ≈ $443Qn
│     ├─ CX05 Dobra térmica · 25º · $5,43Qd
│     ├─ CX06 Bobina criomagnética · 24º · $940Qd
│     └─ CX07 Refletor de cobalto · 30º · ≈ $443Qn
├─ CX28 Arco dos horizontes · 40º · ≈ $44,9UDe
│  ├─ CX23 Coroa de cisalha · 34º · ≈ $158O
│  │  ├─ CX08 Cadinho de sol · 29º · ≈ $4,01Sp
│  │  ├─ CX09 Estrangulador de campo · 30º · ≈ $4,35O
│  │  └─ CX10 Fenda de quartzo · 34º · ≈ $154O
│  └─ CX24 Coletor de duas fases · 40º · ≈ $44,9UDe
│     ├─ CX11 Cascata de indução · 35º · $12,1N
│     ├─ CX12 Relé de vapor · 33º · $370N
│     ├─ CX13 Linha radiante · 39º · $920De
│     └─ CX14 Ampola de espectro · 40º · $44UDe
└─ CX29 Câmara do ponto zero · 50º · ≈ $1OQag
   ├─ CX25 Condutor de eclipse · 45º · ≈ $1NDe
   │  ├─ CX15 Garra da magnetopausa · 44º · $40,6DDe
   │  ├─ CX16 Ressonador de basalto · 45º · ≈ $101QaDe
   │  └─ CX17 Sonda do antipolo · 45º · ≈ $1NDe
   └─ CX26 Malha do zênite · 50º · ≈ $1OQag
      ├─ CX18 Retificador de maré · 48º · ≈ $100QaVi
      ├─ CX19 Pórtico da forja · 50º · ≈ $100QaTg
      └─ CX20 Circuito de antimatéria · 50º · ≈ $1OQag
```

## Mineradoras

| Resultado | Ingredientes |
| --- | --- |
| CM01 Escavadora de estratos | Mineradora básica + Mineradora de cobre + Mineradora de ferro + Mineradora industrial + Mineradora aurora + Mineradora pulsar |
| CM02 Escavadora de caldeira | Mineradora pressurizada + Mineradora cristalina + Mineradora ressonante + Mineradora de plasma + Mineradora eterna |
| CM03 Mineradora eixo polar | Mineradora atômica + Mineradora quântica + Mineradora singularidade + Mineradora estelar + Mineradora abissal |
| CM04 Mineradora contrapeso | Mineradora galáctica + LM01 Mineradora de magnetita + LM02 Mineradora de granito + LM03 Mineradora de xisto + Mineradora coroa solar |
| CM05 Escavadora do limiar | LM04 Mineradora de carbeto + LM05 Mineradora tectônica + LM06 Mineradora criogênica + LM07 Mineradora piroclástica + Mineradora umbra |
| CM06 Escavadora do afélio | LM08 Mineradora antigravitacional + LM09 Mineradora periastro + LM10 Mineradora paralaxe + Mineradora meridiano |
| CM07 Extratora cordilheira | CM01 Escavadora de estratos + CM02 Escavadora de caldeira |
| CM08 Extratora da magnetosfera | CM03 Mineradora eixo polar + CM04 Mineradora contrapeso |
| CM09 Extratora núcleo de estrela | CM05 Escavadora do limiar + CM06 Escavadora do afélio |
| CM10 Escavadora convergência | CM07 Extratora cordilheira + CM08 Extratora da magnetosfera + CM09 Extratora núcleo de estrela |

## Fornalhas

| Resultado | Ingredientes |
| --- | --- |
| CF01 Fornalha crisol duplo | Fornalha básica + Fornalha reforçada + Fornalha industrial + Fornalha térmica + Fornalha aurora + Fornalha supernova |
| CF02 Fornalha espelho fundido | Fornalha de plasma + Fornalha molecular + Fornalha quântica + Fornalha eterna |
| CF03 Fornalha cerâmica iônica | Fornalha estelar + Fornalha galáctica + LF01 Fornalha de reverbero + Fornalha bastião |
| CF04 Fornalha câmara de hélio | LF02 Fornalha de basalto + LF03 Fornalha de ar quente + LF04 Fornalha contrafluxo + Fornalha mar de vidro |
| CF05 Fornalha arco abissal | LF05 Fornalha espiral térmica + LF06 Fornalha safira + LF07 Fornalha de arco solar + Fornalha cíclotron |
| CF06 Fornalha chama fria | LF08 Fornalha planalto + LF09 Fornalha de nácar + LF10 Fornalha limite polar + Fornalha catedral |
| CF07 Fornalha coroa refratária | CF01 Fornalha crisol duplo + CF02 Fornalha espelho fundido |
| CF08 Fornalha bifurcação | CF03 Fornalha cerâmica iônica + CF04 Fornalha câmara de hélio |
| CF09 Fornalha aurora tripla | CF05 Fornalha arco abissal + CF06 Fornalha chama fria |
| CF10 Fornalha convergência | CF07 Fornalha coroa refratária + CF08 Fornalha bifurcação + CF09 Fornalha aurora tripla |

## Modificadores

| Resultado | Ingredientes |
| --- | --- |
| CX01 Comutador ferro-prisma | Câmara de fissão + Laser quântico + Prensa tripla + Prensa de minério + Núcleo de antimatéria + Selo da aurora + Prisma pulsar + Nexus eterno |
| CX02 Peneira pressurizada | Refinador de cobre + Pulso estelar + Anel de partículas + Refinador industrial + Cadinho cerâmico + Grampo de cobalto |
| CX03 Ponte dos cristais | Laser industrial + Raio de plasma + Bobina de indução + Câmara magnética + Lâmina fotovoltaica + Peneira luminosa |
| CX04 Coletor de marfim | Refinador molecular + Túnel de compressão + Processador térmico + Câmara de plasma + Sonda de ametista + Bico de irradiação + Bobina de maré |
| CX05 Dobra térmica | Catalisador térmico + Laser duplo + Anel gravitacional + Ressonador de plasma + Refinador atômico + Limiar de basalto + Matriz de impacto |
| CX06 Bobina criomagnética | Acelerador modular + Túnel molecular + Processador de partículas + Feixe molecular + Pórtico de safira + Trefila de titânio |
| CX07 Refletor de cobalto | Câmara quântica + Compressor atômico + Jato mineral + Laser básico + Triagem boreal + Aro de mercúrio + Cisalha de hélio |
| CX08 Cadinho de sol | Ressonador quântico + Câmara estelar + Ionizador + Banho de cobre + Microssonda fria + Polarizador de jade |
| CX09 Estrangulador de campo | Amplificador de fase + Bobina dupla + Refinador galáctico + Polarizador + Bobina estelar + Venturi violeta + Vigília iônica |
| CX10 Fenda de quartzo | Túnel de fase + Feixe de fótons + Ressonador estelar + Núcleo de quasar + Câmara de neve + Canal de marfim |
| CX11 Cascata de indução | Compressor galáctico + Túnel de horizonte + Feixe de singularidade + Laser galáctico + Cascata de âmbar + Obelisco de fase + Pulsador de neodímio |
| CX12 Relé de vapor | Polarizador cósmico + Ressonador de vácuo + Núcleo de horizonte + Câmara de singularidade + Relé de rubi + Ressonador azimutal |
| CX13 Linha radiante | Amplificador de vácuo + Pulso dimensional + Ressonador dimensional + Núcleo dimensional + LX01 Pente de magnetita + Corredor do solstício + Fatia de horizonte |
| CX14 Ampola de espectro | LX02 Morsa de cromo + LX03 Filtro de vermiculita + LX04 Duto de hidrogênio + LX05 Peneira de turmalina + Fole gravitacional + Injetor de argônio + Oscilador de quartzo |
| CX15 Garra da magnetopausa | LX06 Prensa de calcita + LX07 Reator de zinco + LX08 Leitor espectral + LX09 Tambor de separação + Retificador de irídio + Baliza ultravioleta |
| CX16 Ressonador de basalto | LX10 Banho refratário + LX11 Prisma de fluorita + LX12 Ponte de indução + LX13 Colimador boreal + Condensador de nácar + Crivo do periélio |
| CX17 Sonda do antipolo | LX14 Pórtico piezoelétrico + LX15 Cavidade de rubídio + LX16 Trilho de háfnio + LX17 Bobina de samário + LX18 Pulso de ferrofluido + Dínamo de platina + Garra do equinócio + Rasgo de espectro |
| CX18 Retificador de maré | LX19 Dobrador de luz + LX20 Ressonador de cobre branco + LX21 Malha de silício + LX22 Inversor de fluxo + Trilho de Apolônio + Baluarte magnético |
| CX19 Pórtico da forja | LX23 Gaveta de antimônio + LX24 Difusor de hélio + LX25 Limiar de irídio + LX26 Forquilha de césio + Cadência do eclipse + Coroa de antipartículas |
| CX20 Circuito de antimatéria | LX27 Cicatriz de plasma + LX28 Estação de penumbra + LX29 Divisor de marfim + LX30 Portal de Van Allen + Cúpula de inércia + Porta do meridiano |
| CX21 Matriz de amplificação | CX01 Comutador ferro-prisma + CX02 Peneira pressurizada + CX03 Ponte dos cristais + CX04 Coletor de marfim |
| CX22 Nave de irradiação | CX05 Dobra térmica + CX06 Bobina criomagnética + CX07 Refletor de cobalto |
| CX23 Coroa de cisalha | CX08 Cadinho de sol + CX09 Estrangulador de campo + CX10 Fenda de quartzo |
| CX24 Coletor de duas fases | CX11 Cascata de indução + CX12 Relé de vapor + CX13 Linha radiante + CX14 Ampola de espectro |
| CX25 Condutor de eclipse | CX15 Garra da magnetopausa + CX16 Ressonador de basalto + CX17 Sonda do antipolo |
| CX26 Malha do zênite | CX18 Retificador de maré + CX19 Pórtico da forja + CX20 Circuito de antimatéria |
| CX27 Reator da coroa solar | CX21 Matriz de amplificação + CX22 Nave de irradiação |
| CX28 Arco dos horizontes | CX23 Coroa de cisalha + CX24 Coletor de duas fases |
| CX29 Câmara do ponto zero | CX25 Condutor de eclipse + CX26 Malha do zênite |
| CX30 Modificador convergência | CX27 Reator da coroa solar + CX28 Arco dos horizontes + CX29 Câmara do ponto zero |
