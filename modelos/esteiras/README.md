# Esteiras e parede

Cinco modelos RBXM editáveis. Um bloco equivale a três studs; as medidas abaixo são largura × comprimento × altura da reserva. As rampas próprias foram retiradas. As quatro esteiras podem fazer a subida e a descida pela inclinação no X local.

| Modelo | Plano | Inclinado em 45° | Desnível inclinado |
|---|---|---|---|
| Esteira2x2 | 2×2×1 | 2×2×3 | 2 blocos |
| Esteira1x1 | 1×1×1 | 1×1×2 | 1 bloco |
| Centralizadora2x2 | 2×2×1 | 2×2×3 | 2 blocos |
| Centralizadora1x1 | 1×1×1 | 1×1×2 | 1 bloco |
| Parede1x1 | 1×1×1 | — | — |

A superfície plana fica a 0,9375 studs, acompanhando a passagem padrão dos modificadores. Suas bordas utilizáveis coincidem com as bordas dos blocos. Os detalhes do chassi ficam abaixo da correia e não diminuem a largura útil. As correias são lisas, sem sulcos ou setas permanentes. As centralizadoras têm duas superfícies orientadas para o eixo central e uma linha fina turquesa no meio, sem colisão, para distingui-las das esteiras comuns.

Uma seta branca por correia indica o sentido de transporte durante a colocação, cópia, movimento ou prévia de blueprint. Os indicadores são criados pelo cliente para qualquer peça com componente Transportador, incluindo modificadores; as bandejas coletoras das fornalhas não recebem setas. Cada um acompanha o centro, o topo, as dimensões e a inclinação da respectiva correia, sem alterar o volume reservado. Ao colocar qualquer peça, as correias já instaladas também recebem indicadores locais, incluindo novas peças colocadas durante esse modo. Todos são escondidos ao encerrar a colocação.

Ao inclinar, o jogo adapta o comprimento e o corpo da mesma esteira para manter as pontas nas faces da grade. A ocupação vertical inclui o desnível e a folga do corpo. Não são tipos adicionais de rampa. O componente de transporte aplica tração enquanto o minério toca a correia; as centralizadoras corrigem a posição e a rolagem lateral no contato.

Os cinco assets individuais têm `SomenteModelagem=false` e estão mapeados no Rojo. Na loja, a Esteira 1×1 e a Centralizadora 1×1 custam $1M cada. As duas versões 2×2 e a parede custam $25 cada. As quatro esteiras usam velocidade 6 studs/s. As centralizadoras têm um transportador para cada metade. A parede usa colisão e não possui componentes de minério. O kit atual inclui dez Esteiras 2×2. As outras peças deste grupo começam zeradas. A esteira básica provisória permanece apenas para estoques e construções salvas, sem novas compras.

- `assets/*.rbxm`: cinco peças individuais, sem assets de rampa.
- `GaleriaEsteiras.rbxm`: as cinco peças planas para inspeção.
- `DemonstracaoInclinacaoEsteiras.rbxm`: cópias dos quatro tipos de esteira, em subida e descida de 45°.
- `geometria.json` e `geometria-inclinadas.json`: geometria relida dos arquivos exportados.
- `previa-atual.txt`: pasta das prévias atuais, identificada pelo hash das geometrias e do renderizador.
- `gerar.luau` e `renderizar.py`: geração e prévias usando as ferramentas já existentes no projeto.

`../../tests/modelos_esteiras.luau` confere os cinco RBXM e 16 percursos planos no solver local. `../../tests/inclinacao_esteiras.luau` usa as definições do catálogo, os componentes e o solver do jogo para outros 24 percursos planos e inclinados, nos dois sentidos. Nas centralizadoras, o centro do minério deve sair a menos de 0,1 bloco do eixo, considerando seu tombamento na junção. A suíte também confere grade, dados antigos, cópia, movimento, blueprint e recolhimento. `../../tests/integracao_esteiras.luau` verifica os cinco tipos nos fluxos de compra, colocação/prévia, cópia, movimento, recolhimento, venda, salvamento/restauração e colocação de blueprint.

O teste nativo `../../tests/studio_integracao_esteiras.luau` passou no contexto Servidor do Play: `STUDIO_INTEGRACAO_ESTEIRAS_OK 5`, com 12 percursos planos/inclinados e consulta espacial da parede. Foi uma cena isolada, destruída ao terminar, sem consultar o perfil do jogador. A centralização com tração no contato vale tanto para a correia plana quanto para a inclinada.

As prévias aproximam os materiais do Studio e ampliam as peças individualmente. `04_MesmaEscala.png` usa escala comum. `02_Inclinacao45.png` mostra a geometria real da demonstração, gerada com o mesmo adaptador usado na colocação; não é uma captura de execução.
