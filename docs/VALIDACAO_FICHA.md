# Ficha das peças: validação da etapa

> Registro histórico da ficha anterior. A separação atual em Inventário [E], Loja [F] e subaba de detalhes substitui esse layout e a ficha durante a colocação. Esta alteração foi verificada localmente; os resultados visuais do Studio abaixo não confirmam a interface atual.

Escopo: ficha do inventário e da colocação, seus textos, layout e integração com a seleção existente. Não é uma auditoria visual do jogo inteiro nem uma direção de arte final.

## Direção e decisões

Leitura: informações de construção para jogadores, preservando o painel de protótipo existente. ENERGY 1 / RHYTHM 1 / MOTION 1. O visual permanece um rascunho funcional, sem nova direção de arte.

- Painel escuro e texto branco: manter a leitura sobre o cenário 3D e a aparência já usada.
- Amarelo: preservar a indicação da seleção; não foi acrescentada outra cor de destaque.
- Fonte SourceSans de 16: diferenciar a ficha dos títulos/botões em negrito e acomodar os dados sem reduzir letras.
- Espaçamento de 8 e margens de 12: separar ficha, lista, quantidade e compra sem sobreposição.
- Lista vertical e rolagem: acomodar números extensos e diferentes quantidades de estatísticas.
- Altura da ficha da prévia pelo texto: ocupar menos cenário quando a peça tem poucas informações.
- Sem imagens, ícones ou animação nova: a tarefa depende de leitura de parâmetros existentes.
- Q continua cancelando por níveis, conforme a instrução explícita do usuário; Escape continua pertencendo ao menu do Roblox.

## Evidências

- `ficha_maquinas.luau`: quatro comportamentos, combinações, variantes, bônus, decimais e 101 dígitos preservados como string.
- `cliente_objetos.luau`: carregamento, erro, seleção, prioridade da cópia, estoque personalizado, retorno ao original, compra/colocação e encerramento dos eventos, com serviços e widgets simulados.
- Também passaram: `controladores_maquinas`, `compra_colocacao`, `terrenos_vazios`, `rotacao_arraste`, `rotacao_construcao` e `parede_terreno`.
- Build Rojo temporário aprovado; fontes de `FichaMaquina` e `InterfaceJogo` presentes. O arquivo salvo do jogo não foi sobrescrito.
- Studio: teclas 1/2/3/4 exibiram as fichas correspondentes; Q voltou ao inventário; clique na lista abriu a prévia; rolagem alcançou o botão de compra inteiro.
- Studio: `FICHA_LAYOUT_PASS` em quadros de 1280×720, 320×568 e 568×320, fonte da ficha a 100%/200% e valor de 101 dígitos; sem corte, sobreposição ou alcance insuficiente da rolagem. O teste clona a interface e usa os métodos reais de medição, sem alterar perfis.
- Contraste calculado: branco/#191919 = 17,58:1; branco/#373737 = 11,90:1; #191919/#FFD246 = 12,19:1.

## Antislop: gate no escopo alterado

- R-02 PASS: textos novos sem travessão.
- R-03 PASS: quadros estreitos/retrato/paisagem medidos no Studio, com largura e rolagem verificadas.
- R-17 PASS: estatísticas vêm dos componentes reais, sem estimativas de renda.
- R-18 PASS: não há depoimentos nesta funcionalidade.
- R-23 PASS: nenhum ativo visual foi criado; estrutura e cores do protótipo foram preservadas.
- R-24 PASS: a ficha não acrescenta destinos ou navegação.
- R-25 PASS: os três pares de texto/fundo foram medidos acima.
- R-26 PASS: nenhuma ação nova; seleção/compra existentes verificadas nos testes do cliente, e seleção conferida no Studio.
- R-27 PASS: seleção ausente, carregamento e erro de configuração têm mensagens distintas nos testes.
- R-28 PASS: nenhuma FAQ foi criada.
- R-32 PASS: ficha estática acessível pelos atalhos existentes; 1/2/3/4 e Q conferidos no Studio, sem controle novo exclusivo do mouse.
- R-33 PASS: implementação feita diretamente nos módulos Luau.
- R-34 PASS: nenhuma troca de tema foi introduzida.
- R-35 PASS: build, execução real, seleção, retorno e rolagem registrados acima; compra e cópia também exercitadas no teste isolado do cliente.
- R-36 PASS: nenhuma promessa de desempenho, segurança ou resultado inventado.
- R-37 PASS: preservação explícita do protótipo; sem apresentação como arte final.
- R-38 PASS: dados reais; comportamentos sem descrição são identificados explicitamente.
- R-01 PASS: cores existentes, com função de leitura e seleção registrada.
- R-04 PASS: nenhum ícone foi adicionado.
- R-06 PASS: fonte e hierarquia justificadas acima.
- R-07 PASS: nenhum fundo decorativo foi adicionado.
- R-08 PASS: nenhuma seta decorativa foi adicionada.
- R-09 PASS: “cópia” identifica a origem real da configuração, sem badge ornamental.
- R-10 PASS: nenhum desfoque foi adicionado.
- R-12 PASS: nenhuma sombra foi adicionada.
- R-13 PASS: nenhum brilho foi adicionado.
- R-14 PASS: não foram criados cards de funcionalidades.
- R-19 PASS: nenhum movimento novo na interface.
- R-22 PASS: nenhuma ilustração foi adicionada.
- Liveliness PASS: dials 1/1/1, seleção amarela como foco e vocabulário de produção/transporte/modificação/venda próprios do jogo; espaçamento organiza os blocos de informação.
- C-1 PASS: decisões relevantes e seus motivos registrados acima.
- C-2 PASS: ficha consulta a configuração usada pela prévia, com cópia e estoque exercitados.
- C-3 PASS: cada linha corresponde a um parâmetro ou regra de um componente existente.
- C-4 PASS: erro/carregamento, dados extensos e tamanhos de quadro testados; limite de dispositivos informado abaixo.
- C-5 PASS: os resultados relatados distinguem teste isolado e Studio.
- R-05 PASS: composição segue o conteúdo da construção, sem template de página.
- R-11 PASS: não foi alterada a geometria dos botões.
- R-15 PASS: ação de compra continua nomeando a peça e seu preço.
- R-16 PASS: textos descrevem operações concretas do jogo.
- R-20 PASS: a ficha usa os comportamentos e a seleção do jogo; sem alegação de identidade visual final.
- R-21 PASS: preservado o tema do protótipo já utilizado sobre o cenário.
- R-29 PASS: neutros e o amarelo existente.
- R-30 PASS: nenhuma interface externa foi copiada.
- R-31 PASS: motivos de cor, composição, fonte, espaço e ausência de decoração registrados acima.

Limites: os quadros do Studio não equivalem a uso num celular físico. A compra não foi repetida na conta real apenas para revisar a ficha; essa integração foi exercitada com os módulos reais e serviços simulados no teste do cliente. Um novo tipo de comportamento precisa ter sua descrição acrescentada em `FichaMaquina`; novas variantes dos quatro tipos existentes não precisam disso.
