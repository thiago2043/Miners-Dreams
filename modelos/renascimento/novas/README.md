# 51 novos modelos de renascimento

A galeria contém 4 mineradoras, 4 fornalhas e 43 modificadores. Os arquivos de `assets` podem ser importados individualmente no Studio. A galeria já organiza as peças por categoria para revisão.

- As mineradoras usam brocas helicoidais com avanços de 2,5 a 4,5 blocos. A saída cai no eixo da máquina e no centro da célula à frente da reserva.
- As fornalhas têm uma bandeja de 2×2 blocos na altura da esteira padrão.
- Todos os modificadores têm correia própria. A maioria tem dois blocos de largura útil. Quatro usam um bloco. As correias elevadas encaixam em esteiras um ou dois níveis acima da base. Cada faixa tem um sensor do mesmo tamanho, na ordem de entrada para saída.

As dimensões das folhas estão em largura × comprimento × altura, com 3 studs por bloco. Os 51 modelos estão integrados ao catálogo de recompensas e mapeados no Rojo. Os efeitos e a progressão ficam em `src/shared/RecompensasRenascimento.luau`; as regras de entrega são descritas em `../README.md`.

Para regenerar a partir da raiz do projeto, execute `lune run modelos/renascimento/novas/gerar.luau` e `python modelos/renascimento/novas/renderizar.py`. O renderizador reutiliza Pillow e NumPy. Para conferir os arquivos exportados, execute `lune run tests/modelos_novos_renascimento.luau`.
