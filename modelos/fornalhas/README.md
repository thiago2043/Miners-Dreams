# Fornalhas F1–F9

Nove modelos RBXM editáveis, baseados na sequência de fornalhas de `analises/Proposta_2_progressao_por_faixas.md` e nas referências visuais fornecidas na conversa. As três vistas de cada grupo foram consideradas em conjunto: Drillbit, MAX e MM. Os modelos usam bandejas luminosas, corpos industriais escuros, chapas, radiadores, reservatórios e câmaras de reação com formas distintas.

| Código | Modelo | Largura × comprimento × altura | Entrada útil | Corpo |
|---|---|---|---|---|
| F1 | Básica | 2×2×1 | 2×2 | Coletora baixa com reforços laterais |
| F2 | Reforçada | 2×2×2 | 2×1 | Câmara compacta com ombreiras e tampa reforçada |
| F3 | Industrial | 3×3×2 | 2×1 | Câmara refratária, ventilador e dissipadores |
| F4 | Térmica | 4×3×3 | 2×2 | Dois tanques laterais e banco de radiadores |
| F5 | Plasma | 3×4×3 | 2×2 | Reator com anel de contenção e quatro capacitores |
| F6 | Molecular | 4×4×4 | 2×2 | Três torres de alturas diferentes e tubulações |
| F7 | Quântica | 5×4×4 | 2×2 | Câmara circular inclinada e reservatórios laterais |
| F8 | Estelar | 4×5×5 | 2×2 | Coluna de reação afunilada com dissipadores laterais |
| F9 | Galáctica | 5×5×5 | 2×2 | Estrutura orbital escorada, núcleo e bases segmentadas |

Todas as medidas da tabela estão em blocos; cada bloco equivale a três studs. A entrada fica na face −Z, recebe minério no sentido +Z e possui superfície a 0,9375 stud do piso. Suas dimensões horizontais são inteiras e a borda frontal coincide com a face da reserva. A bandeja tem sustentação abaixo da superfície; sua moldura não estreita a passagem útil. Os sensores ocupam o volume imediatamente acima da bandeja. Os corpos maiores possuem pés, escoras e tubulações conectadas à estrutura.

Os materiais são propriedades nativas das peças: Metal, DiamondPlate, Slate, Granite e Neon. Partes curvas e detalhes não possuem colisão; os sólidos de apoio usam caixas compatíveis com o solver atual do projeto. Os assets não possuem scripts internos.

As paletas foram diferenciadas após a revisão no Studio: F1 coral e aço neutro; F2 laranja e bronze; F3 amarelo e aço quente; F4 verde e metal esverdeado; F5 azul-cobalto e aço azulado; F6 turquesa e metal oxidado; F7 branco-gelo e prata; F8 violeta e metal roxo; F9 magenta e metal vinho. A estrutura inferior continua escura, enquanto chapas e detalhes metálicos acompanham a identidade de cada modelo. `07_Paletas.png` compara os nove modelos juntos.

As cores também foram aplicadas à galeria já importada na janela existente do Studio, em edição, com pontos de desfazer: `FORNALHAS_PALETAS_STUDIO_OK 9`. O violeta da F8 recebeu intensidade menor para permanecer distinto do magenta da F9 sob o Neon nativo. Essa conferência é visual; não constitui teste de venda ou de integração ao catálogo.

- `assets/*.rbxm`: nove modelos integrados com `SomenteModelagem=false`.
- `GaleriaFornalhas.rbxm`: os nove modelos na mesma escala, organizados em três fileiras.
- `geometria.json`: geometria relida dos RBXM exportados, com medidas, materiais e identificadores.
- `gerar.luau`: gerador dos modelos e da galeria.
- `renderizar.py`: usa o renderizador de geometria existente para gerar frente, costas, vista superior e comparação na mesma escala.
- `previa-atual.txt`: pasta das prévias atuais, identificada pelo hash da geometria e do renderizador.

`tests/modelos_fornalhas.luau` relê os nove RBXM, confere medidas/reservas, peças ancoradas, alinhamento e altura das bandejas, sensores, acesso frontal de um cubo de minério e colisões de caixas. O teste passou com `FORNALHAS_GEOMETRIA_OK 9`.

As nove fornalhas estão integradas ao catálogo e ao Rojo, com os preços e multiplicadores da proposta. Cada uma usa transporte na bandeja e venda no sensor, com arredondamento inteiro após o multiplicador. Loja, inventário, prévia, compra/colocação, recolhimento, venda da peça, cópia, movimento, salvamento e blueprints usam os fluxos comuns do jogo.

O kit inicial contém dez Esteiras 2×2, uma Fornalha básica F1 e uma Mineradora básica. Ele vale para perfis novos e para o reinício por reencarnação; reconectar não concede itens novamente. O catálogo e os assets contêm somente as peças atuais. Antes de reconciliar o perfil, `MigracaoCatalogo` remove registros de tipos que não existem no catálogo, preservando saldo e peças atuais.

`tests/integracao_fornalhas.luau` confere os nove tipos, pagamentos, arredondamento, compra/colocação/prévia, recolhimento, restauração, blueprint colocado, kit e migração. `tests/studio_integracao_fornalhas.luau` passou no servidor do Play com nove percursos nativos de transporte e venda: `STUDIO_FORNALHAS_OK 9`. O terreno e a carteira desse teste são isolados do perfil do jogador e removidos ao terminar. A conexão Rojo existente foi renovada para aplicar a troca do asset F1, sem abrir outra janela do Studio.

As prévias mostram a geometria exportada e aproximam a iluminação e a textura do Studio; não são capturas de execução nativa.
