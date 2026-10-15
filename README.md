# Miners Dreams

Projeto configurado para Rojo 7.7.1. O arquivo `Miners Dreams.rbxl` foi preservado; os arquivos externos abaixo passam a ser a origem dos elementos mapeados pelo Rojo.

## Arquivos e caminhos no Studio

| Origem | Destino |
| --- | --- |
| `src/server` | `ServerScriptService`, preservando os nomes dos scripts, `Data` e `Libraries` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared` | `ReplicatedStorage.Shared` |
| `Packages` e `ServerPackages` | Pastas de pacotes existentes |
| `modelos/rojo/*.rbxm` | Três máquinas, chão, SpawnLocation e Lighting |
| `default.project.json` | Também define os eventos `UpdateGold` e `UpdateGems` |

`Server.server.luau` mantém o script `ServerScriptService.Server`. O script `Script.server.luau` continua sendo o teste que adiciona Gold; a lógica dos scripts foi preservada.

## Construção de teste

| Tecla | Peça selecionada | Preço de teste |
| --- | --- | --- |
| 1 | Mineradora básica | 100 |
| 2 | Esteira básica | 25 |
| 3 | Fornalha básica | 100 |

`B` alterna a colocação da peça selecionada; `G` alterna o recolhimento. Os modos continuam ativos após cada clique. A colocação usa uma unidade guardada ou compra uma se o inventário estiver vazio. O painel de compra acompanha a seleção.

`X`, `Y` e `Z` giram a prévia em passos de 90°; `F` alterna o travamento de altura. Trocar o tipo de peça durante a construção inicia uma nova prévia, com rotação inicial e altura liberada.

Os preços ficam em `src/shared/CatalogoMaquinas.luau`. As três máquinas iniciais de teste são recriadas ao entrar e não podem ser recolhidas. As peças colocadas pelo inventário são salvas e restauradas.

## Organização por objetos

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

Para editar uma máquina no Studio, desconecte o Rojo, faça a alteração e exporte o modelo para seu arquivo correspondente em `modelos/rojo` antes de reconectar ou gerar outro build. As peças dentro dos modelos continuam vindo dos `.rbxm`.

Referências: [formato de projeto](https://rojo.space/docs/v7/project-format/) e [sincronização de arquivos](https://rojo.space/docs/v7/sync-details/).
