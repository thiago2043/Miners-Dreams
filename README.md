# Miners Dreams

Projeto configurado para Rojo 7.7.1. O arquivo `Miners Dreams.rbxl` foi preservado; os arquivos externos abaixo passam a ser a origem dos elementos mapeados pelo Rojo.

## Arquivos e caminhos no Studio

| Origem | Destino |
| --- | --- |
| `src/server` | `ServerScriptService`, preservando os nomes dos scripts, `Data` e `Libraries` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared` | `ReplicatedStorage.Shared` |
| `Packages` e `ServerPackages` | Pastas de pacotes existentes |
| `modelos/rojo/*.rbxm` | Peças em `ReplicatedStorage.ModelosMaquinas`; chão e SpawnLocation no `Workspace`; Lighting em `Lighting` |
| `default.project.json` | Também define os eventos `UpdateGold` e `UpdateGems` |

`Server.server.luau` mantém o script `ServerScriptService.Server`. O script `Script.server.luau` continua sendo o teste que adiciona Gold; a lógica dos scripts foi preservada.

## Construção de teste

| Tecla | Peça selecionada | Preço de teste |
| --- | --- | --- |
| 1 | Mineradora básica | 100 |
| 2 | Esteira básica | 25 |
| 3 | Fornalha básica | 100 |
| 4 | Modificador básico ×2 | 200 |

`E` abre ou fecha o inventário à esquerda; `F` abre ou fecha a loja à direita, de forma independente. As duas listas podem permanecer abertas simultaneamente, inclusive durante a colocação e o recolhimento. Um clique em uma peça abre sua ficha ao lado da lista: à direita do inventário ou à esquerda da loja, voltada para o centro da tela. Ambas as fichas podem permanecer abertas sem substituir as listas. Os painéis têm rolagem própria.

Um clique duplo na mesma peça fecha inventário, loja e ambas as fichas, iniciando diretamente a colocação com a configuração selecionada. Cancelar essa colocação com Q não reabre os painéis. Na loja, usa a configuração padrão do catálogo e só compra ao confirmar uma posição válida no terreno, se não houver uma unidade padrão compatível no estoque. Variantes diferentes são preservadas. Clicar uma vez ou usar o atalho numérico abre apenas a ficha na aba usada por último; o botão Colocar mantém os painéis abertos.

Na ficha da loja, **Comprar** adquire uma unidade pelo preço do catálogo. Na ficha do inventário, **Colocar** inicia a prévia e **Vender** vende uma unidade por **100% do preço de compra**. Sem estoque, essas ações do inventário ficam indisponíveis. A venda consome primeiro uma unidade comum; quando só há variantes personalizadas, consome a variante exibida e preserva as demais. A venda é validada pelo servidor e recusa uma configuração desatualizada. Ela não remove peças colocadas no terreno.

A ficha mostra valor, intervalo, tamanho e duração do minério, velocidade de transporte e fórmula de modificação/venda, conforme os componentes da peça. A loja apresenta a configuração padrão que vende; o inventário apresenta a configuração da unidade disponível ou da cópia selecionada. As estatísticas ficam apenas na subaba da seleção. Textos longos têm rolagem; o visual continua sendo o protótipo atual.

`Q` cancela primeiro a ação atual e depois fecha a ficha ou painel usado mais recentemente. Fechar um lado por E/F ou seu botão preserva o outro lado. Retornar da colocação à ficha conserva a seleção; sair da ficha descarta sua orientação e cópia temporárias. Cancelar a rotação mantém os passos já aplicados à prévia e impede um giro extra quando R for solto. `T` alterna o travamento de altura e é liberado ao cancelar a colocação. B e G deixam de ativar modos; digitar Q em uma caixa de texto não cancela ações.

`X` alterna o recolhimento e `M` alterna a movimentação de peças já colocadas. Em M, clique numa peça própria para abrir a prévia; R gira, T trava a altura, clique confirma e Q cancela a prévia voltando à seleção. Um segundo Q encerra M. Mover não altera dinheiro ou inventário, mantém a peça original até confirmar e preserva as modificações; a nova posição e rotação ficam salvas. A colocação e o recolhimento continuam ativos após cada clique. A colocação usa uma unidade compatível do inventário ou compra uma quando necessário, como antes; o aviso na tela informa o preço dessa compra automática.

Respostas de rede atrasadas não reabrem modos cancelados. Q encerra a ação/interface local; uma compra, colocação ou retirada já aceita pelo servidor continua válida.

Toque em `R` para girar 90° no eixo Y (o giro ocorre ao soltar a tecla). Para girar pelo mouse, segure `R`, pressione o botão esquerdo sobre a prévia e arraste. O controle usa uma esfera virtual centrada na prévia e a orientação real da câmera: arrastar pela região central inclina a peça; fazer um arco ao redor do centro permite acessar também o eixo mais voltado para a câmera, como Y em uma vista de cima. Um movimento reto mantém o mesmo eixo, e mudar a direção permite combinar giros sem soltar o botão. A direção depende do deslocamento atual e da posição do cursor em relação à peça, sem exigir retorno ao ponto inicial do clique. Cada giro continua em um único eixo da grade, em passos de 90°.

Um deslocamento de 48 pixels inicia o giro ou confirma uma mudança de direção; continuar no mesmo sentido repete o giro a cada 96 pixels. Ir e voltar na mesma faixa preserva o eixo, incluindo pequenas correções na volta. Uma troca exige deslocamento resultante de pelo menos 48 pixels em uma nova direção, sem soltar o botão. Oscilações pequenas não redefinem a referência; inverter o sentido não exige voltar ao ponto inicial do clique. A orientação e o tamanho da caixa ocupada mudam no primeiro quadro do passo de 90°, enquanto o deslocamento da prévia e da caixa continua suave.

Durante R, o controlador procura manter o centro da peça na posição de início do giro e encaixa o resultado na grade, no piso e nas bordas do terreno. Se as dimensões trocarem entre quantidades pares e ímpares de blocos, a grade pode exigir até meia célula de ajuste por eixo antes dos limites do terreno. Com T ativo, a altura travada tem prioridade. A ocupação apenas troca suas dimensões de eixo, sem acrescentar blocos. Soltar o botão esquerdo ou perder o foco da janela encerra o arraste.

O botão do meio copia uma peça do próprio terreno e abre sua ficha no inventário, mantendo a original. **Colocar** inicia a nova colocação com orientação, diferenças visuais suportadas e dados de personalização registrados. Esse fluxo permite colocar usando estoque ou compra automática mesmo sem uma cópia compatível no inventário; o cliente não envia os valores das melhorias para o servidor. A venda fica desativada nessa ficha de cópia: para vender uma unidade do estoque, selecione-a na lista. Selecionar uma peça por seu atalho encerra a seleção de cópia.

A orientação permanece entre colocações consecutivas e ao voltar à ficha da mesma seleção, incluindo atualizações da prévia pelo estoque. Abrir o outro painel preserva essa seleção. Fechar a ficha ou seu painel descarta sua orientação e cópia temporárias; escolher outra peça nessa lista também substitui a seleção. A orientação e as personalizações das peças já colocadas continuam salvas. Cancelar a colocação libera o travamento de altura.

Registros antigos com ângulos menores continuam sendo restaurados sem alterações. Ao copiar uma dessas peças, a nova prévia usa a orientação de 90° mais próxima; a original é preservada. O servidor aceita somente orientações da grade para novas colocações.

Os preços ficam em `src/shared/CatalogoMaquinas.luau`. As plots começam vazias, com piso e spawn. Um perfil novo recebe uma mineradora, uma esteira e uma fornalha no inventário, com dinheiro zero e nenhum modificador. Nenhuma dessas peças é colocada automaticamente. As construções salvas de jogadores que já possuem uma fábrica continuam sendo restauradas; seus dados não são apagados nem o kit é concedido novamente a cada entrada.

O modificador tem uma correia própria de velocidade 6 e um sensor atravessável: cada cópia aplica ×2 uma vez por minério. Duas cópias diferentes transformam 10 em 20 e depois em 40. Ele é comprado/colocado pelo fluxo normal e não faz parte do kit inicial do inventário.

A esteira básica reserva `Blocos = { 2, 1, 3 }` (8 × 4 × 12 studs); o modificador reserva `{ 2, 2, 1 }` (8 × 8 × 4 studs). Os modelos visuais conservam correias de 3 studs de largura e superfície a 1,25 stud do piso, permitindo alinhar o centro com a fornalha na grade. O modelo provisório do modificador mede 4 × 8 × 4 studs, com espaço reservado maior nas laterais. Esteiras salvas usam a nova ocupação ao restaurar; layouts que encostavam na borda ou em outra peça podem precisar de reposicionamento. Registros que não couberem continuam preservados pelo restaurador existente.

## Organização por objetos

Os minérios usam uma simulação própria no servidor, com passos fixos de 1/120 s, gravidade, atrito, elasticidade e torque dos impactos. Continuam tombando, quicando e girando, mas atravessam outros minérios e personagens. Correias e sensores participam dessa simulação, sem depender de `Touched`; o tempo de vida usa o mesmo relógio físico. A mesma geometria e estado inicial geram os mesmos passos, independentemente do agrupamento das atualizações de tempo testado.

O contato considera os vértices da face que penetrou a superfície. Movimentos residuais abaixo de 0,02 stud/s, incluindo a velocidade de giro na extremidade do bloco, são zerados quando o apoio está parado, sustenta o centro de massa e tem atrito suficiente para o repouso. Os contatos são recalculados a cada passo: retirar o apoio permite cair novamente, e uma correia em movimento continua transportando o minério.

A colisão suporta caixas `Part/Block` giradas, como as dos quatro modelos atuais. Formas curvas ou malhas em modelos futuros precisam de colisores em caixas ou de suporte próprio. `Atrito` e `Elasticidade` podem ser configurados no campo `Minerio` do soltador, entre 0 e 1. A repetição numérica é testada no runtime local; a imagem no cliente ainda depende da replicação.

O cliente separa a prévia e os volumes em `PreviaConstrucao`, e as seleções protegidas em `SelecaoPecas`. As consultas de seleção são imutáveis, inclusive suas personalizações, e a interface usa identificadores para descartar respostas antigas. Os scripts próprios têm comentários sobre responsabilidades e decisões; a documentação de objetos inclui um roteiro de leitura.

O catálogo também define os comportamentos e suas estatísticas. O funcionamento usa `Maquina`, `VolumeConstrucao`, `Minerio` e componentes reutilizáveis; dados, terrenos, construção, interface e botão têm objetos próprios. Os scripts de entrada criam esses objetos e ligam os eventos.

Veja [como criar variantes e como as classes se relacionam](docs/ORIENTACAO_A_OBJETOS.md), incluindo a relação com os conceitos das aulas e os limites dos testes locais.

## Gerar o arquivo do jogo

Execute os comandos na pasta deste projeto:

```powershell
rojo build default.project.json -o "Miners Dreams.rbxlx"
rojo sourcemap default.project.json --include-non-scripts -o sourcemap.json
```

O `.rbxlx` é um arquivo gerado e pode ser reconstruído. Ele inclui os elementos mapeados, incluindo as três máquinas e os scripts de mineração e de teste de dados. Terrain e configurações de publicação não fazem parte desta migração.

## Sincronizar com o Studio

1. Pare o teste no Studio.
2. Abra `Miners Dreams.rbxlx`, ou use o `.rbxl` preservado para conectar o mapeamento ampliado.
3. Inicie o servidor na pasta do projeto:

```powershell
rojo serve default.project.json
```

4. No plugin Rojo do Studio, conecte ao servidor local.

Edite os scripts mapeados nos arquivos de `src`. O Rojo aplica o conteúdo desses arquivos ao Studio; salvar uma alteração somente no `.rbxl` não atualiza os arquivos externos. Scripts novos em `src/server` entram em `ServerScriptService`; use `.server.luau` para Script e `.luau` para ModuleScript.

O serviço `ServerScriptService` preserva filhos que não estejam no mapeamento, para manter experimentos criados diretamente no Studio. Isso não altera a origem dos scripts já mapeados.

Os quatro modelos de referência ficam em `ReplicatedStorage.ModelosMaquinas`, fora do mundo renderizado. A prévia e o servidor clonam esses recursos apenas para usar/colocar uma peça. O script dos terrenos não depende desses modelos para criar e atribuir as plots; a restauração é iniciada separadamente e confirma se o jogador continua sendo o dono do terreno.

Ao atualizar de uma versão com modelos no `Workspace`, pare o teste, reinicie `rojo serve default.project.json`, reconecte o plugin e aplique a sincronização completa para mover os recursos. Antes de testar, confira a pasta `ReplicatedStorage.ModelosMaquinas`.

Para editar uma máquina no Studio, desconecte o Rojo, edite o modelo em `ReplicatedStorage.ModelosMaquinas` e exporte-o para seu arquivo correspondente em `modelos/rojo` antes de reconectar ou gerar outro build. As peças dentro dos modelos continuam vindo dos `.rbxm`.

Referências: [formato de projeto](https://rojo.space/docs/v7/project-format/) e [sincronização de arquivos](https://rojo.space/docs/v7/sync-details/).
