# Elevador vertical

O modelo usado no jogo começa com 1×1×2 blocos. A prévia ilustra a altura de 4 blocos. `H` conta o volume reservado, então o desnível entre as bocas é `H − 1` blocos. A reserva cobre a coluna inteira. As duas bocas encostam na face da célula e alinham com o topo da esteira 1×1 no respectivo nível.

Na colocação, gire a entrada com **R** e clique para fixar a célula. Mova o mouse para escolher o nível de saída acima ou abaixo da entrada. Use **R** para girar a saída e clique para colocar. As setas mostram a entrada em âmbar, a saída em turquesa e o sentido vertical em branco.

Na plot, selecione a peça e abra **Configurar elevador** para ajustar as faces, a altura e o sentido. Cada ajuste é salvo com a unidade assim que o servidor valida o espaço da coluna. A bandeja leva os minérios por lotes e retorna à entrada.

Para gerar outra configuração, execute da raiz do projeto:

```powershell
lune run modelos/elevador/gerar.luau 7 +X -Z descer modelos/elevador/Exemplo.rbxm
```

As faces aceitas são `+X`, `-X`, `+Z` e `-Z`. A altura pode ser de 2 blocos até o limite geral da plot. Sem argumentos, o gerador exporta o modelo padrão e verifica as combinações de faces e sentidos nas alturas extremas. Para refazer a imagem, passe um caminho de JSON ao gerador e depois o mesmo caminho a `python modelos/elevador/renderizar.py` com Pillow e NumPy.
