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

`FichaMaquina.Descrever` transforma os parâmetros dos quatro comportamentos existentes em texto para o jogador, sem procurar nomes de peças. Variantes desses comportamentos recebem a ficha automaticamente. Um comportamento novo precisa de uma descrição nesse módulo; enquanto não houver, a ficha informa explicitamente que sua descrição não está disponível. `ControladorConstrucao:ObterDefinicaoSelecionada(aba)` consulta o catálogo na loja e, no inventário, usa a mesma personalização da prévia, com prioridade para a cópia ativa e depois para a configuração publicada do estoque. `PainelPecas` apresenta essa definição e solicita as ações ao controlador ou à rede da loja; o servidor determina preços e alterações de dados.

`PainelPecas` é reutilizado por duas instâncias independentes, uma para inventário e outra para loja; cada uma mantém lista, ficha, resposta e detecção de clique duplo. `SelecionarMaquina(id, aba)` abre `FichaInventario` ou `FichaLoja` sem fechar a outra seleção. `ColocarSelecionada(aba)` inicia a colocação pelo botão ou clique duplo; `AbrirAba` abre e foca um painel. `NavegacaoEstados:Focar` muda a ordem de retorno por Q sem encerrar o estado. A loja solicita a configuração padrão ao servidor; o cliente não fornece suas estatísticas. A venda continua passando por `ServicoLoja`, `DataManager.VenderMaquina` e `DadosJogador:VenderMaquina`, consumindo a unidade exibida e devolvendo o preço integral do catálogo.

Cada lista e ficha possui seu próprio `UIListLayout`, conteúdo de altura automática e rolagem calculada por `AbsoluteContentSize`. A ficha do inventário fica à sua direita e a da loja à sua esquerda. Um clique duplo fecha os quatro painéis e inicia a colocação com a seleção capturada; o botão Colocar conserva os painéis abertos.

Se `Blocos` for omitido, `VolumeConstrucao` calcula a ocupação arredondando as dimensões do modelo para a grade. Se for declarado, precisa comportar o modelo; um volume menor causa um erro de configuração. As rotações também giram esse volume. Os atributos `VolumeMinimo` e `VolumeOcupado` das cópias colocadas são gerados no servidor para que a colisão e a prévia usem o mesmo espaço reservado.

## Comportamentos disponíveis

| Tipo | Configuração | Operação |
| --- | --- | --- |
| `Soltador` | `Saida`, `Intervalo`, `TempoVida`, `Minerio.Valor`, `Minerio.Tamanho` | Cria minério na parte de saída, com o dono do terreno. |
| `Transportador` | `Parte`, `Velocidade` | Move minério no sentido oposto ao `LookVector` da parte. |
| `Modificador` | `Sensor`, `Multiplicador`, `Bonus` | Aplica `valor × multiplicador + bonus` uma vez por minério e por componente. |
| `Vendedor` | `Sensor`, `Multiplicador`, `Bonus` | Calcula o pagamento, credita o dono e consome o minério uma única vez. |

`Multiplicador` e `Bonus` são strings de inteiros não negativos e têm valores padrão `"1"` e `"0"`. Isso permite variantes de modificadores e vendedores sem reescrever suas classes. Os quatro modelos disponíveis usam os comportamentos acima. `ModificadorBasico` custa 200, usa o atalho `Four`, transporte de velocidade 6 e multiplicador `"2"` sem bônus. Cada cópia afeta o minério apenas uma vez; duas cópias podem multiplicar 10 por 2 e novamente por 2, chegando a 40.

A esteira declara `{ 2, 1, 3 }` blocos e o modificador declara `{ 2, 2, 1 }`. A largura de dois blocos alinha seus centros à fornalha. Os modelos mantêm uma passagem central de 3 studs com superfície de transporte a 1,25 stud do piso. O sensor do modificador não colide e ocupa a passagem acima da correia. A peça nova usa as classes existentes, sem scripts internos no modelo. O template do inventário acompanha o catálogo; `profile:Reconcile()` inclui o item ausente nos perfis existentes. Perfis novos recebem uma mineradora, uma esteira e uma fornalha no inventário, sem modificador e sem peças colocadas. `Reconcile` preserva quantidades já salvas; o kit não é reaplicado em cada entrada.

`FuncionamentoMaquinas` recebe o tempo do Heartbeat e o entrega a `Fabrica:Avancar`. `SimulacaoMinerios` acumula esse tempo e executa passos fixos de 1/120 s; a fábrica atualiza os componentes a cada segundo desse relógio, mantendo os intervalos de geração de pelo menos um segundo. O relógio de expiração também é o da simulação, sem `Debris` ou `os.clock` para decidir resultados físicos.

Os minérios são partes ancoradas, sem colisão, toque ou consulta no motor padrão. `CorpoRigido` calcula sua gravidade, orientação, momento angular e contatos contra caixas orientadas. Os impactos aplicam impulsos normais, elasticidade e atrito; o atrito com a correia pode produzir rotação. Não existe sorteio de direção ou giro, nem travamento artificial da orientação. Os minérios atravessam outros minérios e personagens. A consulta espacial inclui o próprio terreno e a Baseplate; as partes sólidas dessas máquinas e do chão são os obstáculos. Os candidatos são ordenados pela geometria e nome antes da resolução.

`TransportadorMinerio` registra a velocidade da superfície na simulação; não move mais a peça pelo motor físico padrão. `ContatoMinerio` registra um sensor geométrico e valida dono, terreno e disponibilidade antes de chamar `AoTocar`. Modificadores continuam aplicando uma vez por minério; vendedores continuam consumindo e pagando uma vez. Sensores coincidentes processam modificações antes da venda. Subpassos limitam o deslocamento linear e angular por etapa para reduzir atravessamentos de superfícies e sensores finos.

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
| `Maquina` | Representa uma peça do terreno, possui seu volume e seus comportamentos. |
| `VolumeConstrucao` | Representa as dimensões e calcula a ocupação em blocos sob rotação. |
| `Minerio` | Representa o minério e sua parte visual; oferece operações sobre valor, tamanho, dono e consumo. |
| Classes de componentes | Executam a geração, o transporte, a modificação ou a venda. |
| `ControladorConstrucao` | Coordena comandos, navegação, alvo de colocação e pedidos ao servidor. |
| `PreviaConstrucao` | Possui o modelo temporário, caixas, consulta de ocupação e animação; libera esses recursos ao encerrar. |
| `SelecaoPecas` | Guarda seleções em estado privado e publica visões imutáveis com identificadores. |
| `InterfaceJogo` | Constrói o HUD e os dois painéis, atualizando-os pelos atributos replicados. |
| `PainelPecas` | Possui uma lista e sua ficha; interpreta clique simples/duplo e acompanha a resposta da loja. |
| `Botao` | Possui um botão, controla sua disponibilidade e encerra a conexão da ação. |

Velocidade, valor e tamanho são propriedades dos objetos apropriados. Seus métodos concentram as operações e validações. Assim, ajustar uma estatística não exige criar uma classe para cada número.

## Relação com as aulas

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
