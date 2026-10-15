# Objetos e criação de peças

A definição de uma peça fica em `src/shared/CatalogoMaquinas.luau`. Ela descreve o preço, o atalho, o volume opcional em blocos e os parâmetros dos comportamentos existentes. Os módulos de comportamento não precisam conhecer os nomes das peças que os utilizam.

## Criar uma variante

Este é um exemplo de definição para uma peça nova, ainda não adicionada ao jogo:

```luau
MineradoraCobre = {
	Nome = "Mineradora de cobre",
	Preco = "250",
	Atalho = "Four",
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

Para disponibilizar essa peça, acrescente a definição ao catálogo, exporte o modelo com o mesmo identificador e mapeie o arquivo no `Workspace` de `default.project.json`:

```json
"MineradoraCobre": {
  "$path": "modelos/rojo/MineradoraCobre.rbxm"
}
```

Isso registra um recurso no Rojo; não exige alterar a lógica de geração, inventário, compra, construção ou seleção. O inventário inicial é criado a partir do catálogo e reconciliado pelo ProfileStore. Um `Atalho` cadastrado passa a selecionar a peça e atualizar o painel. Também é possível chamar `controlador:SelecionarMaquina("MineradoraCobre")` em uma interface que já tenha acesso ao controlador.

Se `Blocos` for omitido, `VolumeConstrucao` calcula a ocupação arredondando as dimensões do modelo para a grade. Se for declarado, precisa comportar o modelo; um volume menor causa um erro de configuração. As rotações também giram esse volume. Os atributos `VolumeMinimo` e `VolumeOcupado` das cópias colocadas são gerados no servidor para que a colisão e a prévia usem o mesmo espaço reservado. Os modelos iniciais de teste conservam o cálculo pelas suas dimensões reais.

## Comportamentos disponíveis

| Tipo | Configuração | Operação |
| --- | --- | --- |
| `Soltador` | `Saida`, `Intervalo`, `TempoVida`, `Minerio.Valor`, `Minerio.Tamanho` | Cria minério na parte de saída, com o dono do terreno. |
| `Transportador` | `Parte`, `Velocidade` | Move minério no sentido oposto ao `LookVector` da parte. |
| `Modificador` | `Sensor`, `Multiplicador`, `Bonus` | Aplica `valor × multiplicador + bonus` uma vez por minério e por componente. |
| `Vendedor` | `Sensor`, `Multiplicador`, `Bonus` | Calcula o pagamento, credita o dono e consome o minério uma única vez. |

`Multiplicador` e `Bonus` são strings de inteiros não negativos e têm valores padrão `"1"` e `"0"`. Isso permite variantes de modificadores e vendedores sem reescrever suas classes. Atualmente os modelos de teste usam soltador, transportador e vendedor. O modificador está implementado e exercitado nos testes locais, mas ainda não tem um modelo nem um item de loja no jogo.

O ciclo do servidor continua rodando uma vez por segundo. Por isso, os soltadores aceitam intervalos de pelo menos um segundo; a geração não faz compensação de minérios perdidos durante atrasos. Minérios ainda usam partes físicas, `Touched` e `Debris`, como antes.

A lista `Componentes` admite uma ou mais capacidades. A fornalha atual utiliza transporte na bandeja e venda no sensor. Para criar uma variante com uma única capacidade, basta manter uma entrada na lista. O objetivo de reutilização é configurar uma peça nova com os comportamentos já existentes.

Um comportamento realmente diferente precisa de implementação própria. Nesse caso, crie sua classe em `src/server/Componentes` e registre o construtor na tabela `tiposComponentes` de `Maquina.luau`. O contrato exige `Atualizar(agora)` e `Destruir()`. O restante da fábrica chama esses métodos sem distinguir os tipos concretos.

## Responsabilidades dos objetos

| Objeto | Responsabilidade |
| --- | --- |
| `DadosJogador` | Saldo, inventário, compra, registro de colocação/recolhimento e sincronização dos atributos. |
| `DataManager` | Liga a sessão do ProfileStore ao objeto do jogador e mantém a API usada pelos exercícios de Gold/Gems. |
| `ServicoConstrucao` | Valida dono, posição, rotação, ocupação e frequência dos pedidos; coordena os dados e os modelos. |
| `ServicoLoja` | Valida o pedido de compra e aplica o intervalo já existente da loja. |
| `Terreno` | Cria o terreno, atribui o dono, posiciona o personagem e libera o espaço. |
| `Fabrica` | Mantém os objetos das peças existentes e encerra os objetos removidos. |
| `Maquina` | Representa uma peça do terreno, possui seu volume e seus comportamentos. |
| `VolumeConstrucao` | Representa as dimensões e calcula a ocupação em blocos sob rotação. |
| `Minerio` | Representa a parte física e oferece operações sobre valor, tamanho, dono e consumo. |
| Classes de componentes | Executam a geração, o transporte, a modificação ou a venda. |
| `ControladorConstrucao` | Possui o estado da prévia, seleção, rotação, altura, colocação e recolhimento do cliente. |
| `InterfaceJogo` | Constrói e atualiza o HUD e o painel de compra. |
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

As funções puras de interseção e aritmética continuam em módulos de funções. Os objetos não são inseridos em `profile.Data`: apenas os mesmos saldos, quantidades e registros serializáveis são persistidos. `ObterConstrucoes` devolve uma cópia da lista, preservando a identidade dos registros usada no recolhimento; esses registros devem ser tratados como leitura pelos chamadores.

## Verificação e uso no Studio

Os testes em `tests` usam Lune e simulam recursos ausentes do Roblox. `compra_colocacao.luau` lê os modelos reais e verifica compra, ocupação, 72 orientações e restauração. `controladores_maquinas.luau` verifica geração, pagamento, sensores e variantes definidas por configuração. `cliente_objetos.luau` verifica os módulos reais de cliente com entrada/rede/widgets simulados. `parede_terreno.luau` verifica a geometria das bordas.

Com Lune disponível no terminal, execute os arquivos a partir da raiz do projeto:

```powershell
lune run tests/compra_colocacao.luau
lune run tests/controladores_maquinas.luau
lune run tests/cliente_objetos.luau
lune run tests/parede_terreno.luau
```

Para testar no jogo, pare a sessão antes de sincronizar pelo Rojo e inicie uma sessão nova. Isso carrega novamente os ModuleScripts e encerra os controladores anteriores. Confirme o HUD, as compras, B/G contínuos, F/XYZ, a venda física dos minérios e a saída/entrada com restauração. Os testes locais não demonstram a física nem a aparência final do Studio.
