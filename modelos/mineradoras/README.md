# Mineradoras — corpos preenchidos, cabeçotes curtos e brocas externas

Coleção de 13 modelos Roblox editáveis, organizada na classe `Modelador`. As referências fornecidas são Mini Miners, Drillbit e Mechanical Ascension X, incluindo as novas vistas frontais e laterais. Os modelos são interpretações próprias; não contêm assets importados desses jogos.

## Revisão atual

- Saídas representadas por blocos brancos/cinza com transparência de 57%, sem bocais metálicos. Nas primeiras nove máquinas, a face superior inteira do indicador encosta sob o cabeçote, dentro das bordas e sem atravessar outras partes. Nas quatro brocas, o centro do indicador coincide com a ponta.
- M1–M5 com a saída a 0,5 bloco após a face frontal da hitbox. M6–M9 avançam 1,5 bloco. Os indicadores ficam no centro longitudinal de um bloco à frente, mantendo o eixo central da máquina.
- Larguras físicas dos cabeçotes: 1 bloco em M1–M2; 1,5 bloco em M3–M5; 2 blocos em M6–M7; 2,5 blocos em M8–M9. As medidas incluem as juntas e travas do conjunto.
- M1–M9 com a coluna traseira entrando no cabeçote, mesa de fixação, dois apoios triangulares sob o braço, longarinas, pinos e travessa frontal. Os apoios terminam antes do indicador cinza, preservando a queda livre.
- Bases dos 13 corpos preenchidas. O núcleo sólido tem 0,5 bloco a menos que a hitbox em largura e comprimento; ombros e apoios chegam mais perto das bordas.
- M1 conserva a hitbox original. M2 perde um bloco de comprimento, de 2 × 3 para 2 × 2; M3 passa de 3 × 3 para 3 × 2. As demais dimensões de hitbox foram preservadas.
- Hastes da segunda inicial encaixadas no cabeçote.
- Intermediárias com construções superiores diferentes: cabeça transversal, compressor compacto, braço longitudinal, armação energética, cabeçote largo e cabeça em degrau.
- M10–M13 com a raiz da broca na face frontal da hitbox. Os comprimentos externos são, respectivamente, 2,5 / 3,5 / 3,5 / 4,5 blocos até o centro do indicador.
- M10 com corpo baixo, motores longitudinais expostos, aro octogonal e apoios laterais chanfrados.
- M11 com pilares inclinados, ponte elevada, câmara criogênica e seis garras de contenção.
- M12 com carcaça pesada, motores transversais, descargas inclinadas, pistões sob a montagem frontal e quatro garras.
- M13 com quatro módulos ao redor de um núcleo central, braços de sustentação e três garras radiais.
- M10 e M11 têm uma espiral com passos diferentes; M12 tem hélice dupla e M13, tripla. As lâminas continuam como superfícies helicoidais de Parts/WedgeParts editáveis.
- Acoplamento volumoso entre o reator e o eixo de cada broca, com núcleo sólido, ombros, dorso inclinado, chapas e travas. A estrutura atravessa o mancal e alcança o eixo, preenchendo o vão anterior.
- Hitbox de construção separada do alcance visual. O cabeçote e a saída avançam sobre a área da próxima peça, sem deslocar a base.

## Abrir e comparar

Abra `GaleriaMineradoras.rbxlx` no Roblox Studio. A galeria independente contém as 13 máquinas, esteiras básicas reais para recepção, um exemplo estático de minério por esteira, câmera, iluminação, placas e grade.

Cada bloco mede **3 studs**, conforme `VolumeConstrucao.Passo` do projeto. `HitboxConstrucao` é uma Part invisível, sem colisão física e sem consulta por raycast. Seu volume indica a reserva de construção; o modelo visual pode projetar-se para a frente. O contorno no chão e a linha laranja das prévias indicam a projeção horizontal dessa hitbox.

O avanço abaixo mede a distância do **centro do indicador** até a face frontal da hitbox, dividida por 3 studs. Nas brocas, essa também é a extensão longitudinal inteira da broca, cuja raiz está na face frontal do corpo. Os alcances terminam no centro de um bloco à frente: 0,5 / 1,5 / 2,5 / 3,5 / 4,5.

O indicador acompanha o cabeçote; não fica solto no espaço. `SaidaMinerio` continua como Attachment, situado 0,4125 stud abaixo da face inferior do indicador, deixando livre o volume inicial de um minério de 0,75 stud. Conforme a definição confirmada, a saída fica no eixo central da máquina também nas larguras pares; a centralização no bloco se aplica somente à distância para a frente da hitbox.

```text
ID  | Mineradora    | Hitbox XxYxZ  | Núcleo XxZ    | Cabeçote X  | Saída à frente  | Partes
----|---------------|---------------|---------------|-------------|-----------------|-------
M1  | Básica        | 2 x 2 x 2     | 1,5 x 1,5     | 1           | 0,5             |     89
M2  | Cobre         | 2 x 3 x 2     | 1,5 x 1,5     | 1           | 0,5             |    105
M3  | Ferro         | 3 x 3 x 2     | 2,5 x 1,5     | 1,5         | 0,5             |     97
M4  | Industrial    | 3 x 3 x 3     | 2,5 x 2,5     | 1,5         | 0,5             |    126
M5  | Pressurizada  | 3 x 3 x 3     | 2,5 x 2,5     | 1,5         | 0,5             |    112
M6  | Cristalina    | 4 x 4 x 4     | 3,5 x 3,5     | 2           | 1,5             |    137
M7  | Ressonante    | 4 x 5 x 3     | 3,5 x 2,5     | 2           | 1,5             |    137
M8  | Plasma        | 5 x 5 x 4     | 4,5 x 3,5     | 2,5         | 1,5             |    123
M9  | Atômica       | 5 x 5 x 4     | 4,5 x 3,5     | 2,5         | 1,5             |    128
M10 | Quântica      | 6 x 5 x 6     | 5,5 x 5,5     | -           | 2,5             |    257
M11 | Singularidade | 7 x 6 x 7     | 6,5 x 6,5     | -           | 3,5             |    261
M12 | Estelar       | 9 x 8 x 9     | 8,5 x 8,5     | -           | 3,5             |    317
M13 | Galáctica     | 10 x 8 x 10   | 9,5 x 9,5     | -           | 4,5             |    373
```

As dimensões da tabela estão em blocos. A coluna Núcleo XxZ mede a peça sólida central da base; os ombros e apoios chanfrados se aproximam mais das bordas, permanecendo dentro da hitbox. Cabeçote X mede o conjunto do braço de saída em M1–M9; as quatro brocas têm seus comprimentos externos na coluna Saída à frente.

O conjunto contém 2.262 Parts/WedgeParts, incluindo os 13 indicadores e as 13 hitboxes invisíveis. Os modelos não contêm scripts, luzes ou uma plataforma plana cobrindo toda a base. Materiais e cores permanecem editáveis.

## Prévias atuais

Os arquivos são renderizados com a geometria relida dos RBXM. O hash do manifesto identifica a pasta de revisão, evitando reutilizar no chat o caminho de uma geometria anterior.

- [Iniciais, frente e costas](previas/d6466451f4/PreviaGrupoInicial.png)
- [M1 a M9 de lado, apoios dos cabeçotes](previas/d6466451f4/PreviaGrupoApoios.png)
- [Intermediárias](previas/d6466451f4/PreviaGrupoIntermediario.png)
- [Avançadas](previas/d6466451f4/PreviaGrupoAvancado.png)
- [Comparação das brocas sem cores](previas/d6466451f4/PreviaGrupoSilhuetas.png)
- [Brocas de lado e comprimentos externos](previas/d6466451f4/PreviaGrupoLaterais.png)
- [Encaixes da Básica e da Estelar, frente e lado](previas/d6466451f4/PreviaGrupoEncaixes.png)
- [Básica e avançadas na mesma escala física](previas/d6466451f4/PreviaEscala.png)
- [Todos os modelos](previas/d6466451f4/PreviaMineradoras.png)
- [Galáctica ampliada](previas/d6466451f4/PreviaGalactica.png)

Cada quadro individual tem enquadramento próprio. `PreviaEscala.png` conserva a mesma escala entre a Básica e as quatro avançadas. Os arquivos `Previa*.png` da raiz são cópias da última renderização. A textura, a iluminação e a transparência do renderizador local são aproximações; não substituem a inspeção nativa no Studio.

## Gerar e verificar

- `gerar.luau`: classe Modelador, construção dos 13 modelos e da galeria.
- `assets/*.rbxm`: modelos nativos individuais.
- `geometria.json`: geometria relida dos arquivos e avanços medidos.
- `renderizar.py`: renderizador local, usando NumPy e Pillow.
- `../../tests/modelos_mineradoras.luau`: verificações geométricas e teste local com o solver real do projeto.

Execute na raiz do projeto com os executáveis verificados nesta máquina:

```powershell
$luneMineradoras = 'C:\Users\thiagocraft\.codex\visualizations\2026\10\02\01a0fcb7-e891-7ac0-a9b9-cb13f6444603\fornalha-work\tools\lune.exe'
$pythonMineradoras = 'C:\Users\thiagocraft\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $luneMineradoras run modelos/mineradoras/gerar.luau
& $luneMineradoras run tests/modelos_mineradoras.luau
& $pythonMineradoras modelos/mineradoras/renderizar.py
```

O gerador regrava os assets, o manifesto e a galeria. Preserve edições manuais antes de regenerar. A revisão anterior às quatro construções de broca foi preservada em `../../backups/mineradoras-antes-silhuetas-brocas-20261023.zip`.

## Evidência e integração

As 13 mineradoras estão mapeadas em `../../default.project.json` e definidas em `../../src/shared/CatalogoMaquinas.luau`, com os dados da proposta econômica. A prévia e o serviço de construção usam `HitboxConstrucao` para reservar somente o corpo; os componentes emitem pelo Attachment `SaidaMinerio`. `../../tests/integracao_mineradoras.luau` verifica os caminhos de compra, reserva, prévia, salvamento, blueprint e geração usando esses assets.

O teste local passou nos 13 modelos: dimensões exatas de hitbox, alcances solicitados, centro longitudinal de bloco, núcleo da base no máximo 0,5 bloco menor que a hitbox em cada dimensão horizontal, ausência de bocais metálicos e tambores antigos, encaixe da haste da Cobre, coordenadas finitas, materiais, altura dos apoios, extremidades das hastes e corredor de queda livre. Nas brocas, o teste também verifica a raiz na face frontal do corpo, o comprimento inteiro para fora da hitbox, a orientação quase horizontal, a profundidade do corpo traseiro e a coincidência entre a ponta e o centro do indicador.

Nas primeiras nove, o teste confere a face superior inteira do indicador sob o suporte, centralização lateral, margem dentro das bordas e ausência de penetração nas demais peças opacas. O teste geométrico distingue a cunha real do espaço vazio dentro de sua caixa envolvente; a colisão entre caixa e cunha tem três autoverificações próprias.

O teste mede também a largura real do conjunto de peças de cada cabeçote e limita a largura das peças que avançam para fora da hitbox. Nas brocas, verifica o volume do acoplamento e amostra o eixo entre o reator e a raiz da broca para detectar trechos sem geometria sólida.

Em M1–M9, confere o contato entre corpo, coluna, mesa, travessa e cabeçote. Cada um dos dois apoios triangulares precisa intersectar a coluna e o cabeçote usando o volume real da cunha. São verificações geométricas de encaixe, sem simulação de esforço ou deformação.

A recepção e o transporte foram simulados pelo `CorpoRigido` real do projeto, usando a esteira básica real, para cada modelo em giros de 0 e 90 graus. Essa execução é local, sem executar o motor do Studio.

O build principal foi aberto e executado no Roblox Studio. A loja e a ficha da M1 foram inspecionadas; a colocação normal e a emissão de minérios de valor $5 passaram pela verificação no servidor (`STUDIO_MINERADORAS_OK 13 16 1 5`). A hitbox reservada da M1 foi confirmada como 8 × 8 × 8 studs. As 13 mineradoras estão no catálogo do build.

O teste isolado `../../tests/studio_integracao_mineradoras.luau` passou no servidor do Studio: `STUDIO_13_MINERADORAS_OK 13 34`. Ele verifica 34 emissões pelos Attachments nativos nos 13 modelos, dimensões, valores e intervalos, usando contexto de dono local aos clones. Os minérios são consumidos depois da observação; essa cena não testa transporte nem venda e não altera o perfil.

Desempenho com várias cópias e persistência em servidor publicado continuam sem verificação. A recepção física de todos os modelos foi verificada no solver local descrito acima.
