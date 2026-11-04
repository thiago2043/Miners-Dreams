# Controles e administração

O código usa a mesma construção e as mesmas validações do servidor nas três plataformas. Movimento, salto e câmera do Roblox continuam ativos.

## Jogar

- **PC:** em Configurações, os atalhos incluem frente, trás, esquerda, direita e cancelar/voltar. Letras podem ser redistribuídas sem conflitos; movimento também aceita as setas do teclado. Esc cancela a captura. Os atalhos e as demais preferências atuais valem para a sessão.
- **Celular:** toque no cenário para apontar a prévia e confirme pelo botão de construção. Sem prévia, toque na peça para abrir suas ações, ou toque no chão da plot para marcar o primeiro canto de uma seleção por área. Toque no outro canto e use **Confirmar** ou **Concluir área**. A caixa acompanha o ponto escolhido e a câmera; subir/descer altera a altura da seleção. Os botões de giro aparecem somente durante a colocação. Arrastar a câmera e usar o joystick continuam disponíveis. Em telas estreitas, loja e inventário mostram uma lista ou uma ficha por vez.
- **Controle:** Y alterna o foco dos menus e a mira central. Nos menus, use o direcional/analógico e A para ativar. Na construção: R2 confirma/seleciona, L2 inicia ou conclui linha/área, R1 gira Y, L1 gira X, X gira Z, direcional para cima/baixo ajusta altura e B volta. Os rótulos aparecem na tela. A continua sendo salto fora dos menus.

## Abrir o painel administrativo

O botão **ADM**, na coluna direita, aparece somente para o dono da experiência. Em experiências de grupo, somente o dono do grupo é autorizado. Os métodos de leitura e edição verificam essa permissão no servidor; alterar a interface localmente não concede acesso.

Não há lista de administradores adicionais nem acesso público. Os jogadores fictícios de um teste de vários clientes no Studio não recebem permissão automaticamente. Para conferir o painel, use a conta dona e uma experiência com o criador identificado pelo Roblox.

## Acompanhar e editar

- **Jogadores:** mostra jogadores online de outros servidores, além dos locais. A lista online atualiza a cada 10 segundos e mostra até 100 registros recentes. A busca por nome de usuário ou UserId continua disponível para qualquer perfil. Os perfis salvos são paginados em grupos de 40.
- **Progresso:** dinheiro, dinheiro/s, vidas, renascimentos, tempo acompanhado, contagens de peças, upgrades, próximo preço e recordes. A amostra tem data. Se o jogador estiver em outro servidor, os valores ao vivo vêm do MemoryStore; inventário, plot e histórico detalhados vêm do último salvamento do perfil, cuja data é exibida. “Atualizar” relê esses detalhes.
- **Histórico:** medidas a cada minuto, entradas/saídas, compras de upgrades e renascimentos. O tempo e as amostras começam com a ativação desta versão; progresso anterior não é reconstruído. O histórico permanece após renascer e reconectar.
- **Editar:** permite definir dinheiro, vidas, níveis de upgrades e quantidades no inventário. Dinheiro é informado como inteiro completo, sem abreviação, e preserva os dígitos até `1e308`. Quantidades e vidas usam inteiros de precisão segura. Não é permitido diminuir o inventário abaixo do número de variantes personalizadas que ele contém.
- **Plot:** aba própria com botões de adicionar sem custo, reposicionar, recolher para o inventário e remover sem pagamento. Escolha a peça pelo nome. Posições são coordenadas X/Y/Z em blocos, relativas ao canto da plot; rotações usam graus. Grade, ocupação, orientação e limites continuam sendo validados. Peças antigas recebem identificadores na primeira restauração desta versão.
- **Registro:** edições aplicadas e recusadas mostram identificador, autor, horário, motivo, resultado e valores anteriores/posteriores. Toda edição pede motivo e confirmação, mesmo se as confirmações comuns estiverem desativadas. Reduzir a expansão devolve ao inventário as peças que deixarem de caber; não apaga essas peças.

Edições usam o estado mostrado como condição: se dinheiro, estoque, nível ou posição mudarem antes da aplicação, a operação é recusada e deve ser revisada. Não se editam dados diretamente por cima de uma sessão ativa. Para outro servidor ou jogador offline, o pedido vai pela fila de mensagens do ProfileStore, é validado ao chegar e expira após 24 horas. O painel informa “enviado”; o resultado efetivo aparece no registro e no status da última edição. Mensagens repetidas são reconhecidas pelo identificador.

A edição administrativa de dinheiro/vidas participa dos recordes normais; adicionar dinheiro administrativamente não é contado como produção de minério por segundo.

## Zerar um jogador

Em **ADM → Progresso → Zerar todos os dados do jogador**, digite o UserId do jogador selecionado e um motivo, depois confirme a revisão. O perfil volta ao estado de jogador novo: dinheiro zero, vida inicial, nenhum renascimento/upgrade, plot inicial vazia, blueprints/recompensas/histórico anteriores removidos e o kit de dez esteiras, uma mineradora e uma fornalha básicas. Os recordes antigos também deixam a classificação. A limpeza passa a ser o primeiro registro administrativo do perfil novo.

Antes de alterar os dados, o servidor suspende operações de progresso daquele jogador e grava uma cópia completa em `Recuperacao_Test_v1` ou `Recuperacao_Live_v1`. Se a gravação falhar, a limpeza é cancelada e as operações são liberadas. A chave da cópia aparece no Registro; a restauração dessa cópia é uma operação de manutenção do servidor, sem botão nesta interface.

Pedidos de edição anteriores à limpeza não podem modificar o perfil novo. A classificação conserva a versão de progresso por jogador, inclusive fora do top 50, para impedir a volta de recordes antigos por cache. Outros servidores atualizam a classificação no ciclo normal de até 60 segundos. Ao publicar esta versão, reinicie os servidores antigos: o leitor novo aceita o formato anterior, mas o código antigo não conhece a versão de progresso.

## Persistência e limites

O histórico e o registro administrativo são salvos junto ao perfil, preservando o bloqueio de sessão já existente. Edições solicitam um salvamento imediato. Há até **1.440 medidas**, **1.000 marcos** e **1.000 edições** por jogador. Cada lista também tem um orçamento de bytes; ao atingir qualquer limite, saem os registros mais antigos. Os três orçamentos somam aproximadamente 1,55 MB. O contador total de tempo continua acumulando.

O coletor atualiza somente um resumo a cada 10 segundos por jogador e uma medida histórica por minuto; não faz requisições de armazenamento por minério. Falhas do MemoryStore mantêm os dados locais acessíveis e são indicadas na lista. Studio usa os perfis `Test` e memória separada de `Live`.

As APIs usadas seguem a documentação de [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService), [MemoryStoreSortedMap](https://create.roblox.com/docs/cloud-services/memory-stores/sorted-map) e [DataStore](https://create.roblox.com/docs/cloud-services/data-stores). As mensagens de edição usam a implementação do ProfileStore já presente no projeto.

## Conferência manual

1. Reinicie o Play na janela atual. No emulador de celular, confira seleção, colocação, linha, área, rotações e altura, em retrato e paisagem. Confira se os botões deixam joystick, salto e ponto de mira livres.
2. Com um controle conectado, confira câmera/movimento, Y, navegação por A, construção pelos gatilhos e retorno por B. Abra e feche fichas, configurações e confirmações.
3. No PC, remapeie movimento e cancelamento. Confira conflito de teclas, digitação no chat e perda de foco da janela.
4. Com a conta dona, abra ADM e edite um perfil de teste. Confira motivo, confirmação, recusas quando o estado muda e os registros depois de sair/voltar. Confira adição, reposicionamento, recolhimento, remoção e redução de plot.
   Para a limpeza total, use somente um perfil de teste: confira o UserId digitado, o kit inicial, a plot vazia, os recordes novos e a chave da cópia no Registro. Nenhum perfil real foi zerado durante os testes locais.
5. Na experiência publicada, confira dois servidores e uma edição offline. Esta é a verificação necessária para confirmar MemoryStore e entrega de mensagens reais. Verifique também se celular e console estão habilitados como dispositivos compatíveis no Creator Dashboard.

Os testes locais cobrem lógica, interface simulada, ciclo de dados, segurança e geometria; não substituem a conferência de controles reais nem dos serviços publicados.
