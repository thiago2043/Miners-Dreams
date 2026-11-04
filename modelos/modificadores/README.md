# Modificadores — modelagem

Os 55 tipos de `../../analises/Proposta_2_progressao_por_faixas.md` estão modelados em arquivos RBXM editáveis e integrados ao catálogo do jogo. O trabalho usa as nove referências enviadas: três de Drillbit, três de Mechanical Ascension X e três de Mini Miners, além da referência de uso compartilhado de esteiras.

A revisão de modelagem incorporou transporte próprio em V3, N15, N17, N21, N23, N24 e N28 e acrescentou N35, N36, V10 e N37–N40. As formas e reservas foram preservadas na revisão da progressão descrita abaixo.

## Distribuição na progressão

Os modelos sem esteira e os que têm correia de um bloco de largura aparecem a partir de $5T. Para conservar todos os preços, efeitos e limites da progressão, seis pares trocaram suas configurações econômicas: Jato mineral ↔ Câmara de fissão; Laser básico ↔ Núcleo de antimatéria; Ionizador ↔ Anel de partículas; Banho de cobre ↔ Laser quântico; Bobina dupla ↔ Pulso estelar; Polarizador ↔ Anel gravitacional. Os códigos e identificadores continuam pertencendo aos modelos originais. Por isso, peças desses pares já possuídas passam a aplicar os novos efeitos, sem alterar sua posição ou tamanho.

Após essa troca, o Laser quântico recebeu bônus de +$25 por aplicação para se diferenciar da Câmara de fissão (+$10). Mantém preço de $150, três usos por minério e entrada abaixo de $100, ampliável pelo upgrade de calibração. A tabela da proposta histórica conserva o bônus antigo de +$10.

## Regras confirmadas

- Apenas A0, N02, N04, N09, N27 e N32 ficam sem esteira. Novos modificadores devem ter esteira própria; os testes conferem a lista exata das seis exceções.
- Todo tipo com restrição por valor, incluindo V e híbridos H, tem esteira própria. A V3 mantém sua restrição de $25K até menos de $100K; a alteração foi no modelo.
- Das 55 peças, 49 têm esteira e seis usam transporte externo. Entre as 49, 45 usam a largura padrão de dois blocos; H1, N03, N11 e N33 usam um bloco.
- Cada faixa representa uma etapa de upgrade. O limite de usos conta a peça modificadora completa, sem consumir um uso separado por faixa interna.

## Escala e passagem

**1 bloco = 3 studs.** As dimensões das tabelas e prévias seguem **largura × comprimento × altura**. Há 32 combinações de dimensões nesta revisão, de 1 × 1 × 1 até 5 × 5 × 5. Esse intervalo descreve os modelos atuais e não impõe um limite aos próximos modelos.

As quatro bordas utilizáveis de cada correia coincidem com linhas da grade de três studs. Largura e comprimento são inteiros em blocos, e as guias laterais não retiram largura da superfície útil. Quando o corpo tem largura ímpar e a correia tem largura par, o canal fica deslocado meio bloco dentro da reserva para manter as bordas na grade.

A altura padrão da superfície de transporte é 0,9375 stud. As correias elevadas ficam a 3,9375 e 6,9375 studs: um ou dois blocos acima da esteira comum. Assim, a entrada e a saída encaixam em esteiras colocadas nos níveis inteiros da grade. O Refinador atômico, o Túnel de horizonte e a Câmara de singularidade têm transporte a dois blocos de altura, com pilares e travessas até o chão.

Os seis modelos sem esteira ficam ao lado do transporte comum ou da correia de outra peça. A reserva do corpo não inclui a esteira externa. O Ionizador e o Feixe de singularidade projetam cabeçotes apoiados acima da linha. O Laser básico e o Catalisador térmico deixam um bloco livre entre as reservas na demonstração; o Feixe de fótons deixa dois. O minério continua na altura padrão, sem exigir uma elevação para alcançar o efeito.

`HitboxConstrucao` reserva o corpo. `TemEsteira`, `AlturaPassagem`, `LarguraPassagem` e `CentroPassagemX` descrevem o transporte. `AlturaCorreia` e `LarguraCorreiaBlocos` só existem nas peças com esteira própria. `CampoExterno` identifica os seis emissores externos; `ProjecaoExterna` marca seus cabeçotes e efeitos que podem avançar fora da reserva. Os modelos usam Parts e WedgeParts, materiais nativos Metal e DiamondPlate e efeitos Neon sem colisão.

## Etapas, guias e contato

Os 49 modificadores com esteira mantêm faixas volumétricas visíveis de 1,2 stud de profundidade. Os seis sem esteira usam uma guia oculta após colocar e uma emissão visível durante a operação. A visibilidade continua sendo uma escolha por modelo.

Cada guia externa tem `GuiaPosicionamento=true`, `TransparenciaPrevia=0.65` e transparência padrão 1. `PreviaConstrucao` mostra a guia no clone temporário, oculta as partes `EfeitoOperacao` e desliga suas partículas; o modelo definitivo preserva o efeito visível e a guia oculta.

Nos seis efeitos externos, sensor, guia e emissão têm exatamente o mesmo Size e CFrame. Não há uma região invisível maior por trás de um laser fino. O Jato mineral usa núcleo contínuo com ParticleEmitter decorativo; a detecção não depende da presença aleatória de partículas. Nos modelos com esteira, os sensores ficam dentro das faixas visíveis e atravessam o percurso sobre a correia.

`FaixaUpgrade01` até `FaixaUpgrade04` apontam pelo atributo `Sensor` para `SensorEntrada` e, quando existem outras etapas, `SensorEtapa02`, `SensorEtapa03` e `SensorEtapa04`. Cada faixa e sensor têm `EtapaUpgrade`; o modelo informa `QuantidadeEtapasUpgrade`. A ordem corresponde ao avanço de Z negativo para Z positivo no asset.

Há 100 etapas com sensores próprios, incluindo seis guias externas ocultas. As 2.771 BaseParts incluem correias, peças visíveis, sensores, guias e hitboxes. Os assets individuais têm `SomenteModelagem=false` e entram em `ReplicatedStorage.ModelosMaquinas` pelo Rojo; a galeria continua sendo uma cena de apresentação sem script de funcionamento embutido.

No jogo, o componente `Modificador` registra as etapas e aplica os dados econômicos de `CatalogoMaquinas`. Cada etapa arredonda o valor do próprio minério, com 0,5 para cima, usando cálculo decimal exato em texto. O limite por tipo é compartilhado entre cópias e conta a peça inteira; reaplicar em uma nova passagem exige sair do corpo ou, no caso externo, sair da emissão. Faixas monetárias são conferidas antes de cada etapa.

## Modelos e medidas

```text
ID  | Modelo                    | Reserva L x C x A | Correia L x C | Altura* | Etapas | Partes
----|---------------------------|-------------------|---------------|---------|--------|-------
A0  | Jato mineral              | 1 x 1 x 1         | Sem esteira   |   0,9375|      1 |     13
H1  | Banho de cobre            | 3 x 2 x 1         | 1 x 2         |   0,9375|      1 |     31
N01 | Prensa tripla             | 4 x 4 x 2         | 2 x 4         |   0,9375|      3 |     45
V1  | Prensa de minério         | 3 x 2 x 2         | 2 x 2         |   0,9375|      1 |     18
N02 | Laser básico              | 1 x 1 x 1         | Sem esteira   |   0,9375|      1 |      9
H2  | Refinador de cobre        | 4 x 3 x 2         | 2 x 3         |   0,9375|      2 |     46
N03 | Bobina dupla              | 3 x 3 x 1         | 1 x 3         |   0,9375|      1 |     45
N04 | Ionizador                 | 2 x 2 x 3         | Sem esteira   |   0,9375|      1 |     14
V2  | Refinador industrial      | 4 x 4 x 3         | 2 x 4         |   3,9375|      2 |     53
N05 | Laser industrial          | 4 x 2 x 1         | 2 x 2         |   0,9375|      2 |     37
N06 | Raio de plasma            | 4 x 3 x 3         | 2 x 3         |   3,9375|      1 |     46
N07 | Bobina de indução         | 4 x 3 x 3         | 2 x 3         |   0,9375|      2 |     67
V3  | Câmara magnética          | 4 x 2 x 2         | 2 x 2         |   0,9375|      2 |     63
V4  | Refinador molecular       | 4 x 3 x 2         | 2 x 3         |   0,9375|      3 |     61
N08 | Túnel de compressão       | 4 x 4 x 3         | 2 x 4         |   0,9375|      4 |     63
H3  | Processador térmico       | 4 x 3 x 2         | 2 x 3         |   0,9375|      2 |     55
N09 | Catalisador térmico       | 2 x 2 x 2         | Sem esteira   |   0,9375|      1 |     45
V5  | Câmara de plasma          | 5 x 4 x 4         | 2 x 4         |   3,9375|      2 |     66
N10 | Laser duplo               | 4 x 3 x 2         | 2 x 3         |   0,9375|      2 |     57
N11 | Polarizador               | 3 x 3 x 2         | 1 x 3         |   0,9375|      1 |     41
N12 | Ressonador de plasma      | 4 x 4 x 2         | 2 x 4         |   0,9375|      2 |     57
V6  | Refinador atômico         | 5 x 5 x 5         | 2 x 5         |   6,9375|      3 |     85
N13 | Acelerador modular        | 4 x 5 x 1         | 2 x 5         |   0,9375|      4 |     63
N14 | Túnel molecular           | 5 x 5 x 4         | 2 x 5         |   3,9375|      3 |     66
H4  | Processador de partículas | 4 x 4 x 2         | 2 x 4         |   0,9375|      3 |     57
N15 | Feixe molecular           | 4 x 3 x 3         | 2 x 3         |   0,9375|      1 |     42
V7  | Câmara quântica           | 5 x 3 x 4         | 2 x 3         |   0,9375|      2 |     49
N16 | Compressor atômico        | 4 x 2 x 2         | 2 x 2         |   0,9375|      2 |     53
N17 | Câmara de fissão          | 4 x 3 x 4         | 2 x 3         |   0,9375|      1 |     38
N18 | Núcleo de antimatéria     | 4 x 3 x 3         | 2 x 3         |   0,9375|      1 |     52
N19 | Ressonador quântico       | 5 x 2 x 2         | 2 x 2         |   0,9375|      2 |     53
V8  | Câmara estelar            | 5 x 5 x 5         | 2 x 5         |   3,9375|      3 |     70
N20 | Anel de partículas        | 4 x 1 x 3         | 2 x 1         |   0,9375|      1 |     37
N21 | Laser quântico            | 4 x 1 x 2         | 2 x 1         |   0,9375|      1 |     39
N22 | Amplificador de fase      | 4 x 5 x 1         | 2 x 5         |   0,9375|      2 |     49
N23 | Pulso estelar             | 4 x 3 x 5         | 2 x 3         |   0,9375|      1 |     48
V9  | Refinador galáctico       | 5 x 4 x 3         | 2 x 4         |   0,9375|      3 |     61
N24 | Anel gravitacional        | 4 x 2 x 3         | 2 x 2         |   0,9375|      1 |     41
N25 | Bobina estelar            | 5 x 3 x 4         | 2 x 3         |   0,9375|      2 |     71
N26 | Túnel de fase             | 4 x 5 x 2         | 2 x 5         |   0,9375|      3 |     53
N27 | Feixe de fótons           | 2 x 1 x 1         | Sem esteira   |   0,9375|      1 |     16
N28 | Ressonador estelar        | 4 x 3 x 2         | 2 x 3         |   0,9375|      2 |     65
N29 | Núcleo de quasar          | 5 x 4 x 3         | 2 x 4         |   0,9375|      1 |     54
N30 | Compressor galáctico      | 5 x 3 x 3         | 2 x 3         |   3,9375|      2 |     55
N31 | Túnel de horizonte        | 5 x 3 x 5         | 2 x 3         |   6,9375|      3 |     66
N32 | Feixe de singularidade    | 1 x 2 x 5         | Sem esteira   |   0,9375|      1 |     26
N33 | Laser galáctico           | 3 x 1 x 1         | 1 x 1         |   0,9375|      1 |     33
N34 | Polarizador cósmico       | 4 x 4 x 2         | 2 x 4         |   0,9375|      1 |     65
N35 | Ressonador de vácuo       | 4 x 4 x 2         | 2 x 4         |   0,9375|      2 |     69
N36 | Núcleo de horizonte       | 5 x 4 x 5         | 2 x 4         |   3,9375|      1 |     60
V10 | Câmara de singularidade   | 5 x 5 x 5         | 2 x 5         |   6,9375|      3 |     67
N37 | Amplificador de vácuo     | 4 x 5 x 1         | 2 x 5         |   0,9375|      2 |     53
N38 | Pulso dimensional         | 4 x 2 x 3         | 2 x 2         |   0,9375|      1 |     50
N39 | Ressonador dimensional    | 5 x 3 x 3         | 2 x 3         |   0,9375|      2 |     69
N40 | Núcleo dimensional        | 5 x 5 x 5         | 2 x 5         |   3,9375|      1 |     64
```

*Altura da superfície de transporte em studs. Reservas e correias em blocos.

## Sete modelos remodelados

A Câmara magnética (V3) passa a processar na correia entre quatro eletroímãs e mantém duas etapas. O Feixe molecular (N15) usa um canhão em uma lateral e um receptor na outra, com uma etapa sobre a correia. A Câmara de fissão (N17) tem reator lateral, pilar oposto e cabeçote apoiado sobre o transporte.

O Laser quântico (N21) é curto, com dois emissores e correia de dois blocos de largura por um de comprimento. O Pulso estelar (N23) tem torre lateral, contrapeso, pilares e cabeçote alto sobre a própria esteira. O Anel gravitacional (N24) usa dois arcos ao redor do canal; sua única faixa define uma etapa. O Ressonador estelar (N28) tem dois pares de emissores, escoras e duas etapas em sequência.

## Últimos sete tipos

O Ressonador de vácuo (N35) usa câmaras laterais com anéis e duas etapas. O Núcleo de horizonte (N36) tem dois arcos altos, garras e núcleo suspenso sobre transporte próprio. A Câmara de singularidade (V10) tem blindagens, três conjuntos de colunas e um núcleo longitudinal elevado; suas três faixas processam sobre a correia a oito studs.

O Amplificador de vácuo (N37) é baixo e comprido, com discos laterais e dois estágios. O Pulso dimensional (N38) é curto, com quatro torres, braços de foco e um núcleo angular. O Ressonador dimensional (N39) tem quatro rotores em berços e duas etapas. O Núcleo dimensional (N40) tem torres inclinadas, coroa octogonal e núcleo central; mantém uma etapa sobre sua esteira.

## Arquivos e prévias

- `assets/*.rbxm`: os 55 modelos individuais.
- `GaleriaModificadores.rbxm`: galeria com piso, grade, limites dos corpos, blocos de escala e placas. Não está mapeada no projeto Rojo principal.
- `DemonstracaoSemEsteira.rbxm`: os seis emissores externos sobre uma linha de esteiras revisadas e um segundo N02 sobre a correia do H2. São sete montagens; não usa os modelos iniciais de `modelos/rojo`.
- `EsteiraDemonstracao.rbxm`: transporte demonstrativo com superfície útil de 8 × 12 studs, equivalente a 2 × 3 blocos. Seus apoios ficam abaixo da superfície útil. Não substitui a esteira do projeto principal.
- `gerar.luau`: gerador dos modelos, galeria, demonstração e manifestos.
- `geometria.json` e `geometria-uso.json`: geometria relida dos arquivos RBXM finais, com as partes de modificador e transporte identificadas.
- `renderizar.py`: reaproveita o renderizador das mineradoras sem alterar seus modelos.
- `previa-atual.txt`: pasta da revisão atual, identificada pelo hash da geometria e do renderizador. As pastas antigas não representam os modelos atuais.
- `previas/<hash>/25_Remodelados.png`: os sete modelos que receberam esteira própria. `27_RemodeladosFrente.png` mostra seus apoios e passagens.
- `previas/<hash>/26_UltimaLeva.png`: os sete tipos finais. `28_UltimaLevaSuperior.png` mostra a distribuição das etapas.
- `previas/<hash>/05_MesmaEscala.png`: os 55 modelos na mesma escala. `11_VariedadeEscala.png` compara seis peças sem ampliar individualmente as menores.
- `previas/<hash>/12_SemEsteiraEmUso.png` e `13_LinhaCompartilhada.png`: as seis exceções usando transporte externo. `14_GuiaEOperacao.png` compara colocação e operação de N02 e N04.
- `../../tests/modelos_modificadores.luau`: verificações de geometria e percursos locais.

## Validação e limites

O teste Lune relê os 55 assets e verifica IDs, dimensões, quantidade e ordem de etapas, altura das correias, bordas sobre a grade, ausência de scripts embutidos e canal livre. Confere exatamente as seis exceções sem esteira e exige transporte próprio em todo V ou H. Os corpos ficam dentro das reservas; apenas as projeções declaradas dos seis emissores externos podem avançar sobre transporte comum. Um grafo de contato entre caixas envolventes verifica apoio aproximado dos detalhes opacos até o chão.

O solver do projeto `CorpoRigido` executa 56 percursos locais: 42 nas sete montagens de transporte externo, com dois giros e três posições laterais, e 14 percursos centrais nas sete peças remodeladas e nos sete tipos novos com esteira própria. O minério precisa manter apoio, seguir o canal e tocar as etapas em ordem. Há verificações positivas dentro do efeito e negativas fora de sua largura. As reservas da demonstração não se sobrepõem.

`tests/cliente_objetos.luau` tem a verificação da visibilidade de guias, efeitos e partículas no clone de colocação. Essa revisão de modelagem não alterou o código da prévia.

As prévias usam a geometria real relida dos RBXM, com aproximações de textura, transparência e brilho. Os minérios são posições ilustrativas sobre os percursos verificados; as partículas são amostras estáticas dos parâmetros nativos. Não são capturas de execução no Studio.

Os 55 modelos estão cadastrados na loja e aplicam preços, multiplicadores, restrições monetárias e limites de uso. `../../tests/integracao_modificadores.luau` verifica esses caminhos com os serviços reais em ambiente local. O teste nativo `../../tests/studio_integracao_modificadores.luau` passou no modo Editar do Studio (`STUDIO_55_MODIFICADORES_OK 55 100 6`), incluindo as 100 etapas e o transporte de um minério de $10 para $40 em duas faixas, consumindo um uso. A cena isolada não acessa o perfil do jogador.

Execute na raiz do projeto com as ferramentas já usadas pelas mineradoras:

```powershell
& $luneMineradoras run modelos/modificadores/gerar.luau
& $luneMineradoras run tests/modelos_modificadores.luau
& $pythonMineradoras modelos/modificadores/renderizar.py
```

Regenerar substitui os assets desta pasta; preserve edições manuais antes de executar o gerador.
