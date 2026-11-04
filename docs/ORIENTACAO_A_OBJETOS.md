# Objetos e criação de peças

A definição de uma peça fica em `src/shared/CatalogoMaquinas.luau`. Ela descreve o preço, o atalho, o volume opcional em blocos e os parâmetros dos comportamentos existentes. Os módulos de comportamento não precisam conhecer os nomes das peças que os utilizam.

## Criar uma variante

Este é um exemplo de definição para uma peça nova, ainda não adicionada ao jogo:

```luau
MineradoraCobre = {
	Nome = "Mineradora de cobre",
	Preco = "250",
	Atalho = "Five",
	Blocos = { 3, 3, 3 },
	Componentes = {
		{
			Tipo = "Soltador",
			Saida = "SaidaMinerio",
			Intervalo = 3,
			TempoVida = 10,
			Minerio = { Valor = "30", Tamanho = { 2, 2, 2 } },
		},
	},
},
```

Nesse exemplo, o modelo precisa caber em 12 × 12 × 12 studs e conter uma parte chamada `SaidaMinerio`. Cada bloco de construção mede 4 × 4 × 4 studs. O tamanho do minério é informado em studs; seu valor e o preço usam strings de inteiros, como no sistema anterior.

Para disponibilizar essa peça, acrescente a definição ao catálogo, exporte o modelo com o mesmo identificador e mapeie o arquivo em `ReplicatedStorage.ModelosMaquinas` de `default.project.json`:

```json
"MineradoraCobre": {
  "$path": "modelos/rojo/MineradoraCobre.rbxm"
}
```

Isso registra um recurso no Rojo; não exige alterar a lógica de geração, inventário, compra, construção ou seleção. O inventário inicial é criado a partir do catálogo e reconciliado pelo ProfileStore. Um `Atalho` cadastrado passa a selecionar a peça e atualizar o painel. Também é possível chamar `controlador:SelecionarMaquina("MineradoraCobre")` em uma interface que já tenha acesso ao controlador.

`ControladorConstrucao:_MaquinaSobMouse` usa um raio Include restrito à pasta de máquinas do jogador e valida dono e terreno do modelo atingido. A consulta tem `RespectCanCollide=false`: o que torna o corpo selecionável é `CanQuery`, mesmo quando toda a peça é não colidível. Esse mesmo caminho atende destaque, menu e atalhos. O teste local de cliente passou com os 82 modelos; no Studio, a regressão nativa verificou 246 raios, abertura do menu e as recusas de propriedade/terreno, reproduzindo a falha anterior dos seis emissores sem esteira. O Jato mineral também foi clicado na interface normal; o menu aberto foi confirmado antes de remover a cópia temporária.

`FichaMaquina.Descrever` transforma os parâmetros dos quatro comportamentos existentes em texto para o jogador, sem procurar nomes de peças. Variantes desses comportamentos recebem a ficha automaticamente. Um comportamento novo precisa de uma descrição nesse módulo; enquanto não houver, a ficha informa explicitamente que sua descrição não está disponível. `ControladorConstrucao:ObterDefinicaoSelecionada(aba)` consulta o catálogo na loja e, no inventário, usa a mesma personalização da prévia, com prioridade para a cópia ativa e depois para a configuração publicada do estoque. `PainelPecas` apresenta essa definição e solicita as ações ao controlador ou à rede da loja; o servidor determina preços e alterações de dados.

`PainelPecas` é reutilizado por duas instâncias independentes, uma para inventário e outra para loja; cada uma mantém lista, ficha, resposta e detecção de clique duplo. `SelecionarMaquina(id, aba)` abre `FichaInventario` ou `FichaLoja` sem fechar a outra seleção. `ColocarSelecionada(aba)` inicia a colocação pelo botão ou clique duplo; `AbrirAba` abre e foca um painel. `NavegacaoEstados:Focar` muda a ordem de retorno por Q sem encerrar o estado. A loja solicita a configuração padrão ao servidor; o cliente não fornece suas estatísticas. A venda continua passando por `ServicoLoja`, `DataManager.VenderMaquina` e `DadosJogador:VenderMaquina`, consumindo a unidade exibida e devolvendo o preço integral do catálogo.

`GradePecas` é a classe de apresentação compartilhada por loja e inventário. Cada instância tem pesquisa, ordenação, cartões e miniaturas independentes; `MiniaturaPeca` possui o clone visual, o viewport e a câmera de cada cartão. O inventário mostra quantidades e esconde estoque zero; a loja mostra preços e permite filtrar os componentes de geração, transporte, modificação e venda. Uma peça com mais de um comportamento aparece em mais de uma categoria. `IconesAbas` desenha os símbolos dos botões e categorias com funções sem estado; o objeto `Botao` continua responsável pela conexão de ativação.

`GradePecas:_AtualizarMiniatura` só cria o retrato se a aba e o cartão estiverem visíveis e o retângulo do cartão intersectar a área `AbsoluteWindowSize` da rolagem. Dimensões zeradas aguardam o layout. `CanvasPosition`, posição/tamanho dos cartões, posição/tamanho útil da área e abertura da aba provocam reavaliação; os sinais dos cartões também atendem ordenações que mantêm o tamanho total da grade. Não há callback contínuo por quadro. Os retratos criados são reutilizados e todos os sinais e miniaturas são encerrados por `Destruir`.

`miniaturas_visiveis.luau` verifica 82 cartões com só quatro retratos no recorte simulado, além de rolagem, cache, aba fechada, recorte parcial/exato, tamanho zero, reordenação, filtros e limpeza. Os 37 testes locais passaram. `studio_miniaturas_visiveis.luau` passou no cliente do Play com os modelos reais e o layout nativo: 24 retratos e 1.191 partes na abertura de uma grade de 568×520, frente a 82 modelos e 6.349 partes no catálogo completo. O teste cria uma GUI isolada sem realizar compras; ela é removida ao terminar. A loja do jogo também foi conferida visualmente durante a rolagem. Essas contagens não medem FPS.

`FichaPeca` possui a apresentação dos detalhes, com uma instância independente por aba: retrato, nome, faixa dos comportamentos e estatísticas roláveis. No inventário mostra quantidade e personalizações da unidade, com Colocar/Vender no rodapé. Na loja mostra o preço e o modelo padrão, com Comprar num rodapé verde. Cada ficha fica no lado interno de sua lista; disponibilidade e transações continuam em `PainelPecas`. O retrato conserva uma única miniatura até mudar de tipo ou configuração, sem recriá-la por mudança de quantidade. Nenhuma raridade é atribuída pela interface.

O retrato se limita a 20% da altura da ficha e a 96 pixels, preservando espaço para as estatísticas em janelas baixas. As ações dividem uma única linha fixa; informações longas continuam acessíveis pela rolagem. A antiga faixa inferior de instruções foi removida do HUD, sem alterar os controles do jogo.

As grades usam `UIGridLayout` e as fichas usam `UIListLayout`, com conteúdo de altura automática e rolagem calculada por `AbsoluteContentSize`. A ficha do inventário fica à sua direita e a da loja à sua esquerda. O clique duplo e o botão Colocar fecham as abas e iniciam a colocação com a seleção capturada. Alterar pesquisa, categoria ou ordenação invalida o primeiro clique de uma possível sequência de clique duplo.

Se `Blocos` for omitido, `VolumeConstrucao` calcula a ocupação arredondando as dimensões do modelo para a grade. Se for declarado, precisa comportar o modelo; um volume menor causa um erro de configuração. As rotações também giram esse volume. Os atributos `VolumeMinimo` e `VolumeOcupado` das cópias colocadas são gerados no servidor para que a colisão e a prévia usem o mesmo espaço reservado.

## Comportamentos disponíveis

| Tipo | Configuração | Operação |
| --- | --- | --- |
| `Soltador` | `Saida`, `Intervalo`, `TempoVida`, `Minerio.Valor`, `Minerio.Tamanho` | Cria minério na parte de saída, com o dono do terreno. |
| `Transportador` | `Parte`, `Velocidade` | Move minério no sentido oposto ao `LookVector` da parte. |
| `Modificador` | `Sensor`, `Multiplicador`, `Bonus` | Aplica `valor × multiplicador + bonus` uma vez por minério e por componente. |
| `Vendedor` | `Sensor`, `Multiplicador`, `Bonus` | Calcula o pagamento, credita o dono e consome o minério uma única vez. |

`Multiplicador` e `Bonus` são strings de inteiros não negativos e têm valores padrão `"1"` e `"0"`. Isso permite variantes de modificadores e vendedores sem reescrever suas classes. Os modelos atuais combinam esses comportamentos. A Prensa de minério usa transporte e multiplicação por 2, com faixa de entrada de 0 até menos de 100. Cada passagem processa o minério uma vez; duas peças podem transformar 10 em 20 e depois em 40.

A Esteira 2×2 declara `{ 2, 1, 2 }` blocos em X/Y/Z e tem passagem útil de 6 studs, com a superfície a 0,9375 stud do piso. Cada modificador define sua reserva e seus sensores; os sensores não colidem com o minério. Os modelos usam as classes existentes, sem scripts internos. O template do inventário acompanha o catálogo. Perfis novos recebem uma mineradora, dez Esteiras 2×2 e uma fornalha, sem modificador e sem peças colocadas. `Reconcile` preserva quantidades já salvas; o kit não é reaplicado em cada entrada.

`FuncionamentoMaquinas` recebe o tempo do Heartbeat e o entrega a `Fabrica:Avancar`. `SimulacaoMinerios` acumula esse tempo e executa passos fixos de 1/120 s, até oito por chamada, preservando todo o atraso restante. A fábrica descobre modelos a cada segundo e atualiza os componentes em cada passo físico. Geração, expiração e sensores usam esse relógio; limitar o trabalho de uma chamada não descarta tempo nem minérios.

Os minérios são partes ancoradas, sem colisão, toque ou consulta no motor padrão. `CorpoRigido` calcula sua gravidade, orientação, momento angular e contatos contra caixas orientadas. Os impactos aplicam impulsos normais, elasticidade e atrito; o atrito com a correia pode produzir rotação. Não existe sorteio de direção ou giro, nem travamento artificial da orientação. Os minérios atravessam outros minérios e personagens. A consulta espacial inclui o próprio terreno e a Baseplate; as partes sólidas dessas máquinas e do chão são os obstáculos. Os candidatos são ordenados pela geometria e nome antes da resolução.

`TransportadorMinerio` registra a velocidade da superfície na simulação; não move mais a peça pelo motor físico padrão. `ContatoMinerio` registra um sensor geométrico e valida dono, terreno e disponibilidade antes de chamar `AoTocar`. Modificadores continuam aplicando uma vez por minério; vendedores continuam consumindo e pagando uma vez. Sensores coincidentes processam modificações antes da venda. Subpassos limitam o deslocamento linear e angular por etapa para reduzir atravessamentos de superfícies e sensores finos.

Esses dois componentes usam `Componente:ObservarPartes` para invalidar suas referências quando os filhos do modelo entram, saem ou mudam de nome; o transporte também observa `ParteTransporteOrigem`. Cada componente conserva suas partes já resolvidas. As correias comparam apenas o estado das superfícies conhecidas para atualizar registros de transporte quando necessário; sensores estáveis dispensam novas buscas. `Destruir` desconecta os observadores antes de retirar os registros da simulação. Isso separa a manutenção das referências do avanço físico em 120 Hz.

`ContatoMinerio` informa o terreno ao registrar cada sensor. `SimulacaoMinerios` mantém uma lista de partes por terreno e o índice inverso de cada parte, sem repetir uma parte compartilhada por vários componentes. O filtro `OverlapParams` de uma plot só recebe outra lista quando seu grupo muda; remover o último sensor elimina o grupo e seu filtro. A consulta confere o pertencimento dos sensores encontrados antes de devolver os componentes, preservando a barreira entre plots mesmo se uma parte for reparentada indevidamente. A ordenação dos efeitos continua ocorrendo depois dessa seleção.

`ModificadorMinerio` conserva a pose e o tamanho físicos de cada passagem retida e uma versão dos seus volumes de saída. Só repete a interseção de saída quando um desses dados muda; as caixas do corpo ou das emissões externas são conferidas uma vez por atualização do componente. `PrecisaReceber` antecipa a recusa por etapa concluída, faixa de valor e limite de usos. `AoTocar` chama a mesma validação antes de aplicar o efeito, preservando os recebimentos diretos; uma passagem iniciada pode concluir suas etapas sem consumir outro uso. O valor é consultado novamente a cada verificação, sem guardar uma recusa que ficaria desatualizada após outro modificador. `Destruir` limpa passagens e volumes além do encerramento herdado.

O estado físico atual deve ser consultado por `SimulacaoMinerios:ObterCorpo(parte)`. O avanço sobre um apoio estável pode ser agrupado, mas essa consulta materializa os mesmos passos numéricos até o instante atual antes de devolver o corpo. As consultas espaciais compartilham descritores ordenados por região e por sólido dentro do mesmo passo. A consulta de sólidos usa `RespectCanCollide` e confere o terreno; outra consulta inclui apenas os sensores registrados. A margem espacial cresce em meios blocos conforme o tamanho e o deslocamento do minério. Uma nova geometria ou um percurso bloqueado impede reutilizar o apoio. O repouso confirmado também pode ser reutilizado sobre vários apoios: mudar a pose, o tamanho, o transporte, o atrito, a gravidade, a velocidade ou a lista de obstáculos obriga a recalcular os contatos.

`MineriosVisuais` atualiza o desenho local de trechos uniformes, sem decidir colisão, valor ou venda. `MovimentoMinerio` serializa origem, velocidade e tempo físico em um único atributo; um relógio por plot sincroniza a apresentação. A pose visual da Part no servidor pode ficar na origem do trecho, enquanto `ObterCorpo` continua avançando. Ao sair desse movimento, o servidor publica a parada e retoma as atualizações em lote. Portanto, componentes de jogabilidade não devem usar `Part.CFrame` como posição física de um minério registrado.

Os movimentos locais ficam também separados por plot. `MineriosVisuais` reutiliza um volume conservador, avançado pelos extremos de velocidade, para recusar grupos fora do campo de visão antes de calcular cada pose ou montar o lote. Trajetórias, tamanhos e integrantes alterados invalidam os limites; recuo do relógio também exige reconstrução. O tamanho dos minérios participa da margem e a câmera é relida a cada quadro. Grupos que intersectam o enquadramento continuam atualizando todos os seus movimentos; não há limite fixo de distância nem teste de oclusão por obstáculos. Poses suspensas usam `LocalTransparencyModifier`, cujo valor anterior é restaurado na retomada, parada, remoção e destruição. Entrada/saída e transferência mantêm os grupos e as conexões consistentes.

Após essa mudança, os 37 testes locais passaram. O teste de apresentação verifica 5.000 minérios em duas plots, atualizando 2.500 poses por quadro simulado, além de bordas, tamanho, entrada automática no enquadramento, transferência, câmera e relógio. No cliente do Studio, `studio_minerios_visiveis.luau` confirmou 300.000 poses em 120 atualizações controladas, frente a 600.000 no caminho anterior, e giros durante o `RenderStepped` com partes nativas. A cena local e suas conexões foram removidas e a câmera restaurada. Isso comprova a redução de trabalho nesse cenário, sem medição nova de FPS.

`Minerio.Atrito` e `Minerio.Elasticidade`, opcionais na definição do soltador, aceitam números de 0 a 1 e têm padrões 0.6 e 0.25. `Tamanho` continua determinando o volume e a inércia do minério. Para resultados repetíveis, mantenha a mesma geometria, configuração e estado inicial em cada execução; alterações de máquinas durante a passagem são novas entradas da simulação.

O colisor atual suporta `Part` com `Shape = Block`, inclusive girado nos três eixos. Todos os sólidos dos quatro modelos atuais usam esse formato. Um modelo futuro com esfera, cilindro, wedge ou malha precisa de caixas de colisão apropriadas, ou de implementação explícita para sua forma; o código acusa uma forma não suportada em vez de substituir sua geometria silenciosamente. Os testes comparam estados numéricos na mesma execução do runtime; não demonstram igualdade bit a bit entre plataformas diferentes. Replicação e apresentação visual no cliente também não fazem parte dessa igualdade numérica.

A lista `Componentes` admite uma ou mais capacidades. A fornalha atual utiliza transporte na bandeja e venda no sensor. Para criar uma variante com uma única capacidade, basta manter uma entrada na lista. O objetivo de reutilização é configurar uma peça nova com os comportamentos já existentes.

Um comportamento realmente diferente precisa de implementação própria. Nesse caso, crie sua classe em `src/server/Componentes` e registre o construtor na tabela `tiposComponentes` de `Maquina.luau`. O contrato exige `Atualizar(agora)` e `Destruir()`. O restante da fábrica chama esses métodos sem distinguir os tipos concretos.

## Responsabilidades dos objetos

| Objeto | Responsabilidade |
| --- | --- |
| `DadosJogador` | Saldo, inventário, compra, registro de colocação/recolhimento e sincronização dos atributos. |
| `DataManager` | Liga a sessão do ProfileStore ao objeto do jogador e mantém a API usada pelos exercícios de Gold/Gems. |
| `ServicoConstrucao` | Valida dono, posição, rotação, ocupação e frequência dos pedidos; coordena os dados e os modelos. |
| `ServicoLoja` | Valida o pedido de compra e aplica o intervalo já existente da loja. |
| `Terreno` | Cria a plot vazia, atribui o dono, posiciona o personagem e libera o espaço. |
| `Fabrica` | Mantém os objetos das peças existentes e encerra os objetos removidos. |
| `SimulacaoMinerios` | Relógio fixo, corpos, consultas de obstáculos, transporte, sensores e tempo de vida. |
| `CorpoRigido` | Caixa orientada, inércia, rotação e resposta dos contatos com atrito e elasticidade. |
| `MineriosVisuais` | Desenha no cliente o movimento uniforme publicado pelo servidor e libera suas conexões ao encerrar. |
| `Maquina` | Representa uma peça do terreno, possui seu volume e seus comportamentos. |
| `VolumeConstrucao` | Representa as dimensões e calcula a ocupação em blocos sob rotação. |
| `Minerio` | Representa o minério e sua parte visual; oferece operações sobre valor, tamanho, dono e consumo. |
| Classes de componentes | Executam a geração, o transporte, a modificação ou a venda. |
| `ControladorConstrucao` | Coordena comandos, navegação, alvo de colocação e pedidos ao servidor. |
| `PreviaConstrucao` | Possui o modelo temporário, caixas, consulta de ocupação e animação; libera esses recursos ao encerrar. |
| `GradeTerreno` | Desenha a grade local do piso e das laterais durante a colocação, acompanhando tamanho, pose e altura em uso; libera os visuais ao trocar de plot ou encerrar o controlador. |
| `SelecaoPecas` | Guarda seleções em estado privado e publica visões imutáveis com identificadores. |
| `InterfaceJogo` | Constrói o HUD e os dois painéis, atualizando-os pelos atributos replicados. |
| `PainelMoedas` | Possui os três campos do HUD; apresenta o dinheiro decimal e reserva espaço para duas moedas ainda não definidas. |
| `ProgressaoLogaritmica` | Compara marcos decimais exatos e calcula a fração visual entre eles. |
| `RegraReencarnacao` | Calcula vidas disponíveis com custo que aumenta por operação, independentemente das vidas puladas. |
| `ReinicioProgresso` | Prepara dados iniciais preservando somente as categorias escolhidas pela mecânica chamadora. |
| `ServicoPrestigio` | Valida o pedido remoto e coordena o reinício com o serviço de construção. |
| `PainelPrestigio` / `BarraProgressao` | Apresentam o estado e a estimativa; a barra pode receber qualquer escala calculada. |
| `PainelPecas` | Possui uma lista e sua ficha; interpreta clique simples/duplo e acompanha a resposta da loja. |
| `Botao` | Possui um botão, controla sua disponibilidade e encerra a conexão da ação. |

Velocidade, valor e tamanho são propriedades dos objetos apropriados. Seus métodos concentram as operações e validações. Assim, ajustar uma estatística não exige criar uma classe para cada número.

## Relação com as aulas

A reencarnação inicial exige 1qd (`10^15`) de saldo disponível. `Reencarnacoes` conta operações e aumenta o expoente do custo em um por operação. `Vidas` começa em 1 e recebe uma vida por marco completo a partir do requisito atual. Assim, com `10^19` no primeiro ciclo, a vida passa de 1 para 6, a contagem de reencarnações passa para 1 e o novo requisito é `10^16`. A barra mostra o progresso logarítmico até o requisito ou, quando ele já foi atingido, até o próximo salto.

O reinício volta ao template inicial, incluindo o kit no inventário. A política de reencarnação preserva `Blueprints` e `RecompensasReencarnacao`; outra mecânica pode criar sua própria instância de `ReinicioProgresso` sem preservar as recompensas. Cada vida ganha sorteia uma das nove peças de `RecompensasRenascimento`, com chances iguais e cópias acumuláveis. `PremiosRenascimento` restaura as quantidades permanentes ao inventário, preserva personalizações e acrescenta os sorteios antes de confirmar o reinício. Essas peças não podem ser compradas ou vendidas. O servidor recalcula os saltos, recusa ciclos antigos e remove máquinas, minérios e tokens antes de sincronizar o novo estado. O ProfileStore continua responsável pela persistência; os testes locais não acessam perfis reais.

- **Construtor:** `DadosJogador.new(jogador, perfil)` cria uma instância ligada à sessão do jogador. Em C++ seria o papel do construtor.
- **Método de instância:** `dados:ComprarMaquina(id)` passa `dados` implicitamente como `self`. É equivalente a `dados.ComprarMaquina(dados, id)`.
- **Encapsulamento:** os chamadores usam operações como `AdicionarDinheiro` e `RegistrarRecolhimento`; as mutações e a replicação ficam concentradas na classe. Campos com `_` são internos por convenção. Luau não oferece o modificador `private` do Java/C++; o prefixo não impede acesso tecnicamente.
- **Composição:** uma peça possui volume e comportamento; uma interface possui um botão. Novas peças são instâncias configuradas dos comportamentos existentes.
- **Herança:** `TransportadorMinerio` e `SoltadorMinerio` reutilizam a base `Componente`. `VendedorMinerio` e `ModificadorMinerio` especializam `ContatoMinerio`, que centraliza o sensor e a verificação de minério/dono.
- **Polimorfismo:** `Maquina` chama `Atualizar` e `Destruir` de cada componente; o comportamento concreto responde à mesma operação.
- **Contrato:** `Componente.Contrato` descreve os métodos em Luau, e o construtor de `Maquina` confere sua presença em execução. Luau usa tipos estruturais; não foi criada uma simulação do `implements` do Java. A verificação de tipos por um analisador separado não foi executada.

As funções puras de interseção e aritmética continuam em módulos de funções. Os objetos não são inseridos em `profile.Data`: apenas saldos, quantidades, registros e personalizações serializáveis são persistidos. `ObterConstrucoes` devolve uma cópia da lista, preservando a identidade dos registros usada no recolhimento; esses registros devem ser tratados como leitura pelos chamadores.

## Verificação e uso no Studio

Os modelos de referência são armazenados em `ReplicatedStorage.ModelosMaquinas`. O servidor e o cliente buscam os recursos nessa pasta; não existe uma fábrica inicial no `Workspace`. `Terrenos.server.luau` cria/atribui as plots independentemente de `Construcao` e agenda a restauração com uma verificação do dono atual. Jogadores com construções salvas continuam restaurando sua fábrica.

Os testes em `tests` usam Lune e simulam recursos ausentes do Roblox. `terrenos_vazios.luau` executa o bootstrap real sem modelos no mundo, verifica plots vazias, kit inicial e restauração adiada após saída/troca de dono. `compra_colocacao.luau` lê os modelos reais e verifica compra, ocupação, 96 orientações e restauração, incluindo o alinhamento físico da esteira, modificador e fornalha antes/depois de restaurar. `controladores_maquinas.luau` verifica geração, pagamento, sensores, variantes e os valores 10/20/40 no circuito com zero/um/dois modificadores. `cliente_objetos.luau` verifica os módulos reais de cliente com entrada/rede/widgets simulados, seleção do modificador por 4, compra automática e recolhimento. `parede_terreno.luau` verifica a geometria das bordas. Esses testes não executam a física real do Studio nem acessam DataStores.

Com Lune disponível no terminal, execute os arquivos a partir da raiz do projeto:

```powershell
lune run tests/terrenos_vazios.luau
lune run tests/compra_colocacao.luau
lune run tests/controladores_maquinas.luau
lune run tests/fisica_minerios.luau
lune run tests/repouso_minerios.luau
lune run tests/cliente_objetos.luau
lune run tests/selecao_pecas.luau
lune run tests/ficha_maquinas.luau
lune run tests/parede_terreno.luau
lune run tests/rotacao_construcao.luau
lune run tests/rotacao_arraste.luau
```

Para testar no jogo, pare a sessão antes de sincronizar pelo Rojo e inicie uma sessão nova. Isso carrega novamente os ModuleScripts e encerra os controladores anteriores. Confirme o HUD, a lista em E, compras, colocação/recolhimento contínuos, X, os retornos por Q, R/arraste/T, o clique do meio, a venda física dos minérios e a saída/entrada com restauração. Os testes locais não demonstram a física nem a aparência final do Studio.

`fisica_minerios.luau` executa o solver e a fábrica reais, com a consulta espacial do Roblox simulada. Compara a trajetória completa em 30/60/120/144 FPS, inverte a ordem dos candidatos, sobrepõe minérios e testa quicada, torque, parede girada, parede fina em alta velocidade, expiração e o circuito de geração/transporte/modificação/venda. É uma verificação numérica local; não substitui a integração no Studio ou um teste de carga em servidor publicado.

`repouso_minerios.luau` verifica pose constante e velocidades zeradas após dez segundos, para cubos inicialmente parados, giro residual em Y, queda inclinada e minério retangular. Também verifica remoção do apoio, transporte, giro livre no ar, piso sem atrito e queda pela beirada. `studio_fisica_minerios.luau` é exclusivo da Command Bar do servidor do Studio: monta uma cena temporária fora das plots e compara 1.200 estados em 30/60/120/144 FPS, incluindo repouso com pose constante no último segundo. A cena temporária é destruída ao terminar, sem alterar perfis ou inventários.

Em 28/10/2026, `studio_cache_componentes.luau` passou no servidor do Studio com os eventos nativos de árvore, nome e atributo, alterações das superfícies e encerramento das conexões. `studio_sensores_terrenos.luau` passou com cinco plots, 500 sensores e 120 passos, incluindo sensores sobrepostos de plots distintas, filtros reutilizados, compartilhamento, transferência e limpeza. A mesma versão passou nas regressões nativas de física, modificadores e esteiras. São verificações funcionais em cenas isoladas, sem medição nova de FPS ou acesso a perfis; os 33 testes locais também passaram.

Na otimização seguinte, `modificadores_otimizados.luau` verificou a reutilização das saídas, invalidação por geometria, valor reavaliado, fronteiras monetárias, usos, várias etapas e limpeza. Os 34 testes locais passaram. `studio_otimizacao_modificadores.luau` confirmou, com modelos nativos, 100 testes de saída para 100 passagens durante 120 passos, além das regras de valor e uso; as regressões nativas de física e dos 55 modificadores também passaram. Essa validação usou cenas temporárias fora das plots dos jogadores e não mediu FPS.

`ficha_maquinas.luau` verifica descrições, combinações, variantes, bônus e preservação de valores grandes como strings. `cliente_objetos.luau` também verifica carregamento, erro de configuração, seleção, prioridade da cópia, atualização do estoque e limpeza dos eventos da ficha. `studio_ficha_maquinas.luau` é uma verificação manual opcional na Command Bar do cliente: mede cópias dos quatro painéis em quadros de 1366×768, 320×568 e 568×320, incluindo uma ficha com 101 dígitos e fonte a 100%/200%. Executá-lo usa o layout real do Studio; a refatoração atual não o executou nem verificou controles de toque em aparelho físico.

## Estados e retorno por Q

`ControladorConstrucao` possui uma instância de `NavegacaoEstados`, compartilhada com a interface pelo construtor. A mesma pilha guarda inventário, loja, suas fichas e as ações de colocação, rotação ou recolhimento. Os painéis consultam `Contem` para continuarem visíveis simultaneamente. O controlador trata Q uma única vez, chamando `Navegacao:Voltar()`. `Focar` coloca um estado no fim da pilha sem executar sua limpeza; assim, Q fecha primeiro o que foi usado mais recentemente.

Uma nova tela ou ação deve usar essa mesma instância e registrar sua saída. Por exemplo, em um controlador que recebeu `navegacao` e a referência de sua tela:

```luau
tela.Visible = true
navegacao:Abrir("DetalhesPeca", function()
	tela.Visible = false
end)
```

Q fecha esse estado e devolve o controle ao anterior, sem adicionar um caso específico para a tecla no controlador de construção. `Atual()` informa o estado ativo; o controlador da nova ação deve aceitar suas entradas apenas quando esse for seu estado. `Fechar(nome)` encerra uma ação que terminou por conta própria, preservando estados acima dela; `VoltarAte(nome)` remove os níveis acima de um estado existente. `Limpar()` encerra todos os níveis, chamando suas saídas. Não basta criar uma tela fora desse fluxo para ela participar do retorno por Q.

`cliente_objetos.luau` cobre E → seleção → Q → inventário → Q → jogo, cancelamento de R sem giro extra, X contínuo, M para selecionar e mover mantendo a mesma peça e suas modificações, cancelamento da prévia para voltar à seleção, um estado adicional sobreposto, bloqueio de entrada enquanto se digita e respostas de rede que chegam depois do cancelamento. Os widgets e a rede são simulados; a renderização precisa de verificação no Studio.

As prévias de um grupo recebem o mesmo recurso de volumes, que contém a pasta, o filtro, as caixas vizinhas, o contador de atualização e a quantidade de usuários. Cada prévia continua responsável por seu modelo e sua caixa de destino. O controlador atualiza o recurso uma vez por quadro; a revisão dos vizinhos mantém o intervalo de 0,2 s. `ForcarAtualizacao` de qualquer membro adianta o contador comum, e `Destruir` libera a pasta apenas quando o último usuário sai. A chamada pode ser repetida sem diminuir duas vezes a contagem. Prévia individual e grupos distintos não compartilham recursos.

`GradeTerreno` aplica `rbxasset://textures/grid2.png` diretamente à face Top do piso. A imagem nativa tem quatro células por repetição; StudsPerTileU/V de 12 mantêm células de 3 studs. A fase U acompanha o tamanho Z para preservar o alinhamento à origem de colocação. Não há geometria sobreposta ao piso, SurfaceGui ou uma Part por célula. Material e Reflectance do piso são guardados, trocados localmente durante a colocação por Neon e zero, e restaurados ao ocultar ou destruir a grade. Quatro Models agrupam as laterais: traços de 0,25 stud a cada 6 studs usam Decals em suportes invisíveis, com faces no plano das paredes, interiores vazios, sem colisão, toque, consulta ou sombra. O controlador mostra os desenhos somente enquanto há uma prévia de colocação, incluindo cópia e movimentação; ocultar e mostrar reaproveita as instâncias. A faixa vertical tem altura arredondada em múltiplos de 6, calculada a partir das dimensões atuais do piso, e sobe em passos de 6 conforme a altura em uso. Mudança de altura ou pose reaproveita os desenhos; somente mudança de tamanho reconstrói as laterais. A classe não altera o perfil nem implementa expansão de terreno. O servidor mantém o piso RGB 145 e os spawns invisíveis, com nascimento e atribuição preservados.

`PreviaConstrucao` soma as direções dos componentes Transportador para desenhar uma seta branca por peça. A seta fica no centro da superfície útil, 0,105 stud acima dela, com tamanho limitado pelas dimensões da correia. Nas centralizadoras, os centros das duas metades são combinados, as componentes laterais se anulam e o indicador aponta para a saída. O sentido usa `DirecaoSuperficie`, depois `DirecaoTransporte` e, na ausência desses atributos, o eixo +Z local, como o transporte real. A seta é criada depois de medir a caixa e fixar o pivô, inclusive quando a esteira inclinada é reconstruída. Suas três partes são locais à prévia, sem colisão, toque ou consulta, e são destruídas junto dela. Os assets das quatro esteiras não contêm mais os sulcos, relevos em V ou setas permanentes.

Sem cartão aberto, `ObterPecasFocadas` devolve as unidades válidas da seleção branca. `ExecutarAcaoPeca` usa a primeira como âncora quando não há peça focada; os atalhos Z/X/C/V aproveitam a mesma ação do cartão após terminar o arraste. Uma seleção vazia mantém a alternância dos modos coloridos, e uma caixa de texto focada continua impedindo ações na plot.

`LimitesConstrucao.PecasPorGrupo` centraliza o máximo de 1.000 no cliente, serviço e dados. Cópia, movimento, recolhimento, venda, blueprints e colocação em lote mantêm as validações. A colocação de lotes aceita resultados parciais por obstáculo ou falta de saldo; no movimento, os destinos bloqueados devolvem as unidades ao inventário. Se nenhum destino estiver livre, o movimento permanece pendente. Recolhimento e venda conservam a transação do grupo inteiro. Lotes acima de 60 custam 60 tokens no limitador existente, preservando seu orçamento e reposição. Para não ultrapassar os 255 Highlights nativos, a seleção usa esse efeito nas primeiras 250 peças e SelectionBox sobre o volume nas demais, com a mesma cor do modo.

`ControladorConstrucao` guarda a célula e o ponto de projeção inicial do arraste de colocação. A diferença no plano da plot determina o eixo X ou Z e o sentido; o tamanho ocupado determina o espaçamento. Soltar envia `ColocarMultiplos` uma vez, com cantos e rotações. A configuração vem do inventário, padrão da loja ou token de captura no servidor, inclusive a captura de grupo com uma única peça usada pela cópia individual. As prévias adicionais recebem o recurso de volumes da primeira. Q, perda de foco e encerramento liberam essas prévias; a resposta de rede respeita a identidade da prévia ainda ativa.

`ServicoConstrucao:_ColocarCaptura` reúne a validação de destinos e a criação de linhas, cópias e blueprints. Destinos ocupados ou fora da plot são ignorados; coordenadas malformadas e rotações inválidas recusam o pedido. `DadosJogador:RegistrarColocacoes` devolve os registros aceitos, permitindo destruir os modelos que não tiveram estoque/saldo sem desfazer as unidades aceitas. Exceções internas conservam a recuperação da operação inteira. `_ConcluirMovimento` recria os destinos livres e usa os métodos existentes de recolhimento para devolver ao estoque as unidades bloqueadas, preservando o vínculo e a personalização de cada registro.

`previas_compartilhadas.luau` confere caixas, consultas, atualização, isolamento e ordem de destruição; `cliente_objetos.luau` confere 1.000 seleções, recusa de 1.001 e uma atualização de volumes por grupo. `grupos_1000.luau` executa os fluxos reais do serviço e dos dados em contexto isolado, com saldo e inventário conferidos. Os 36 testes locais passaram. `studio_previas_compartilhadas.luau` passou na janela existente com consultas e instâncias nativas e modelos simples de uma parte, sem perfis ou rede de construção; não mede FPS nem substitui um teste de renderização de mil modelos detalhados no cliente.


## Rotação, cópia e personalização por peça

O controlador usa R para girar 90° em Y ao soltar a tecla. R + botão esquerdo sobre a prévia inicia `RotacaoArraste`. O controlador fornece o centro projetado e o raio da esfera que envolve a peça, em pixels, usando `Camera:WorldToViewportPoint`. O gesto usa uma esfera virtual com extensão hiperbólica fora dela: o produto vetorial entre sua normal sob o cursor e o movimento atual define a direção do giro, transformada pela orientação real da câmera no terreno. Só então o eixo dominante é escolhido entre X, Y e Z, com sinal. Isso permite inclinar pelo centro e acessar o terceiro eixo com arcos laterais, sem arredondar a câmera e eliminar eixos disponíveis. A referência anterior foi o [giro livre da Unity](https://docs.unity3d.com/6000.0/Documentation/ScriptReference/Handles.FreeRotateHandle.html); esta adaptação mantém somente passos de 90°. Ver também [projeção da câmera no Roblox](https://create.roblox.com/docs/reference/engine/classes/Camera#WorldToViewportPoint).

O eixo sugerido pelo movimento precisa acumular 48 pixels para iniciar ou substituir o gesto ativo. No mesmo sentido, os próximos passos exigem 96 pixels. A direção confirmada define uma faixa com tolerância de 25° para os dois sentidos: voltar por ela inverte somente o sinal do eixo, sem consultar novamente a esfera. Movimentos fora da faixa ficam pendentes como um vetor; só um deslocamento resultante de 48 pixels pode confirmar outra direção. Se o vetor resultante ainda seguir a faixa, o eixo é preservado, mesmo quando os eventos individuais oscilam na diagonal. Retomar a faixa descarta desvios pendentes pequenos, e a referência só muda após confirmar outro gesto. Arcos continuam podendo escolher os três eixos sem soltar o botão. Pequenos movimentos contrários descontam a distância de repetição para não produzir giros por tremores. `RotacaoConstrucao.ValidarNaGrade` confirma a matriz aplicada. A orientação visual recebe o passo no primeiro quadro; a interpolação fica apenas na posição. Não se aplica um giro extra ao soltar R depois do arraste. O foco perdido encerra o gesto.

Durante R, o centro da caixa visual no início do giro é a referência para recalcular o canto de construção. O novo canto é arredondado à grade e limitado pelo piso e pelas bordas. Há até meia célula de ajuste por eixo quando a troca de dimensões muda a paridade dos blocos; os limites podem exigir deslocamento maior. Com T ativo, a altura do canto permanece travada. As 24 orientações permutam as dimensões do volume em blocos, sem aumentar sua quantidade. Se o resultado encostar em outra ocupação, a prévia fica inválida até haver espaço. O servidor mantém a validação de novas colocações; registros antigos são preservados, e sua cópia é encaixada na orientação de 90° mais próxima. O resultado visual e a sensação do arraste precisam ser conferidos no Studio.

A orientação é conservada na seleção ativa quando uma atualização de estoque recria a prévia ou quando Q retorna à ficha. Fechar a ficha ou substituir sua seleção descarta esse estado temporário. No clique duplo, os painéis são fechados antes de iniciar a ação e a seleção é capturada para aquela colocação; Q a encerra sem reabrir os painéis. O registro das peças já colocadas permanece independente desse estado temporário.

O botão do meio seleciona uma cópia de uma peça do próprio terreno. O servidor captura o estado e guarda uma seleção de cópia por jogador; o cliente recebe seus dados para exibir a prévia e um identificador para confirmar as colocações. O servidor usa a sua própria captura, inclusive se a origem já foi recolhida. Alterar a configuração apenas no cliente não altera o estado que será colocado. Cada clique conserva as regras de estoque e compra existentes.

`PersonalizacaoMaquina` é o estado serializável da peça. Ele guarda:

- `Configuracao`: diferenças na definição de comportamentos, como velocidade, intervalo, valor/tamanho do minério e multiplicadores. Esses valores são lidos pelos objetos de comportamento.
- `Partes`: diferenças de cor, dimensões, transformação relativa, material, transparência e refletância das partes já existentes no modelo. Caminhos incluem a ocorrência do nome para distinguir irmãos com nomes iguais.
- `Dados`: informações de melhorias e outras características definidas pelo jogo. Novos campos serializáveis são conservados pela cópia e pelo salvamento; a lógica que utiliza uma característica nova continua precisando existir no seu comportamento.

A rotação continua no campo `Rotacao` do registro. `Modificacoes` é opcional e guarda o estado acima. Registros antigos sem esse campo continuam válidos. As personalizações de peças recolhidas ficam em `InventarioPersonalizado`, separadas da quantidade total existente em `Inventory`. Ao recolocar, uma variante compatível é consumida primeiro; uma unidade comum também pode receber a configuração selecionada na cópia. Uma variante diferente é preservada, e a compra normal só ocorre quando não há uma unidade compatível ou comum.

Para aplicar uma personalização por código de servidor, use a operação já ligada à construção:

```luau
local Construcao = require(game:GetService("ServerScriptService").Construcao)

local modificacoes = {
	Configuracao = {
		Componentes = { { Velocidade = 12 } }, -- Exemplo para uma esteira.
	},
	Dados = { Melhorias = { Nivel = 2 } },
}

local sucesso, mensagem, novaPeca = Construcao.Personalizar(jogador, peca, modificacoes)
```

A operação recebe o estado completo desejado, valida sua geometria e os construtores dos comportamentos e devolve a nova instância que substituiu a anterior. Ela atualiza o registro salvo imediatamente. Para preservar personalizações anteriores ao modificar apenas uma característica, comece com `PersonalizacaoMaquina.DoModelo(peca):ObterDados()` e altere os campos desejados. Essa operação é exclusiva do servidor; não faz parte das chamadas liberadas ao cliente.

Ainda não existe uma interface para editar cores ou melhorias. O trabalho atual permite preservá-las e copiá-las quando forem aplicadas pelo código do jogo. Novos tipos de alteração devem entrar no estado definido acima; a cópia não serializa automaticamente qualquer propriedade ou novo objeto arbitrário inserido no modelo. Mudanças de formato que adicionem/removam partes ou precisem de outras propriedades exigem ampliar a aplicação/captura nesse módulo.

## Leitura guiada do código comentado

1. Comece em `src/client/init.client.luau`: ele cria o controlador e a interface de cada jogador e encerra suas conexões.
2. Leia `Botao` e `SelecaoPecas` para comparar instância, métodos e estado com C++. O `self` recebido por um método com `:` tem o papel do objeto atual; `__index` compartilha os métodos entre instâncias.
3. Em `InterfaceJogo` e `PainelPecas`, acompanhe a mudança de atributos até a atualização do HUD, da lista e da ficha. Uma ação solicita a operação; o painel não decide o preço.
4. Em `ControladorConstrucao`, siga a seleção até `PreviaConstrucao`. A prévia cuida dos recursos visuais e da ocupação; `GeometriaColocacao` apenas calcula coordenadas e interseções.
5. No servidor, acompanhe `Construcao` → `ServicoConstrucao` → `DadosJogador`. A validação do cliente melhora a prévia, mas só o servidor autoriza a alteração dos dados.
6. Para entender a fábrica funcionando, siga `FuncionamentoMaquinas` → `Fabrica` → `Maquina` → componentes e `SimulacaoMinerios`.

`SelecaoPecas:Obter` devolve uma visão congelada, incluindo tabelas internas da cópia. `Definir` cria uma identidade nova; `GuardarRotacao` mantém a identidade e troca a visão. A interface compara o identificador, não a referência da tabela, para reconhecer respostas de rede antigas. O estado fica em um mapa privado do módulo, com chaves fracas para não impedir a coleta de instâncias sem uso.

Os contratos `SelecaoPecas.Selecao`, `SelecaoPecas.Copia`, `PreviaConstrucao.Alvo` e `Componente.Contrato` tornam os dados esperados explícitos. Os métodos do contrato de componentes identificam o receptor em vez de usar `any`. Os testes locais compilam e executam os módulos, mas não substituem uma análise estática de tipos completa com as definições do Roblox.

Os comentários dos scripts próprios explicam responsabilidade, propriedade de recursos, validação, concorrência e cálculos. ProfileStore e os pacotes externos foram preservados; o código deles não faz parte desta revisão de comentários.
