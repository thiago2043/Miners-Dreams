# FornalhaBasica — criação por edição de arquivo

O projeto foi alterado diretamente no formato binário `.rbxl`, sem operar o Roblox Studio.

## Resultado

- Model adicionado em `Workspace.FornalhaBasica`.
- 33 Parts ancoradas: base, bandeja, paredes, entrada, grelha, núcleo Neon, chaminé oca e painel lateral.
- PointLight `LuzForno` dentro de `NucleoIncandescente`.
- `SensorEntrada`: Part invisível, ancorada, sem colisão e com CanTouch habilitado para programação futura.
- `PrimaryPart`: `BaseForno`.
- Superfície da bandeja em Y = 1.25; início em Z = 11.5, alinhados à correia.
- Seis Parts de `EsteiraBasica` ancoradas com autorização explícita do usuário.
- Nenhum Script, LocalScript ou ModuleScript inserido. O modelo ainda não processa minério nem paga dinheiro.

## Validação executada

1. Releitura independente do arquivo modificado com Lune 0.10.5.
2. Conferência das 33 peças contra o manifesto de nomes, posições, tamanhos, transparência e colisão.
3. Conferência de PrimaryPart, PointLight e SensorEntrada.
4. Conferência do alinhamento entre a ponta da correia e o início da bandeja.
5. Verificação geométrica de passagem central para um minério cúbico de 1 stud até Z = 17.25.
6. Contagem de 131 instâncias no resultado: 96 originais e 35 novas.
7. Comparação de 948 valores originais nas classes Part e Model estendidas. Somente os seis valores Anchored autorizados foram alterados.
8. Preservação dos relacionamentos entre todos os objetos originais.
9. Preservação literal dos blocos das demais propriedades, incluindo Terrain.VoxelGridAssetContentMap.
10. Contagem de scripts antes e depois: zero.

O Lune não reconhece o tipo recente 0x23 de Terrain.VoxelGridAssetContentMap. Por isso, o projeto inteiro não foi regravado por ele. A inserção foi feita por composição dos blocos binários, conservando os dados existentes e estendendo somente as classes necessárias.

## Limites da validação

Não houve abertura do resultado no Roblox Studio nem simulação de física no motor Roblox. A prévia PNG foi calculada a partir das medidas e cores do modelo; não é uma captura do Studio. Sua iluminação é ilustrativa.

## Arquivos

- `Miners Dreams.rbxl`: projeto atualizado.
- `modelos/FornalhaBasica.rbxm`: modelo separado em formato binário.
- `modelos/FornalhaBasica.rbxmx`: modelo separado em XML.
- `modelos/FornalhaBasica-preview.png`: prévia geométrica.
- `modelos/merge-report.json`: comparação dos dados originais e modificados.
- `modelos/verification.json`: verificações da releitura e geometria.
- `backups/Miners Dreams-antes-fornalha-20261008-020512.rbxl`: cópia original.

## Identificação

- SHA256 original: `4e6d9c0c9cb13ea41e878d0ea4fce30fc81c6d9b6c2f439b2845c25200141b0d`
- SHA256 atualizado: `60cec7546983e4ff5aaff93bb1d51af44ee721ae835a1d03eaa2bc8873bc2790`

Referências: [Lune — biblioteca Roblox](https://lune-org.github.io/docs/api-reference/roblox/) e [rbx-dom — formato binário](https://dom.rojo.space/binary.html).
