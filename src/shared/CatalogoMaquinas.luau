-- Definicoes compartilhadas: nome, preco, volume e parametros dos comportamentos. Variantes existentes
-- reutilizam as mesmas classes.
return {
	-- A chave deve corresponder ao nome do Model em ModelosMaquinas. Nome e texto da interface; Atalho usa o
	-- nome da tecla no Enum.KeyCode; Preco e um inteiro decimal em texto.
	MineradoraBasica = {
		Atalho = "One",
		Nome = "Mineradora básica",
		Preco = "100",
		Componentes = {
			{
				-- Tipo escolhe a classe do comportamento. Saida indica a parte do modelo; Intervalo e TempoVida sao
				-- segundos; Valor e texto e Tamanho lista dimensoes do minerio em studs.
				Tipo = "Soltador", Saida = "SaidaMinerio",
				Intervalo = 2, TempoVida = 10,
				Minerio = { Valor = "10", Tamanho = { 1, 1, 1 } },
			},
		},
	},
	EsteiraBasica = {
		Atalho = "Two",
		Nome = "Esteira básica",
		Preco = "25",
		-- Reserva 2 x 1 x 3 celulas de 4 studs: 8 x 4 x 12 studs antes do giro. Sem Blocos declarado, o volume e
		-- deduzido do tamanho visual e arredondado para a grade.
		Blocos = { 2, 1, 3 },
		Componentes = {
			-- Parte identifica a correia no modelo; Velocidade e medida em studs por segundo. A direcao usa -LookVector
			-- dessa parte, permitindo reaproveitar a classe ao girar a peca.
			{ Tipo = "Transportador", Parte = "Correia", Velocidade = 6 },
		},
	},
	FornalhaBasica = {
		Atalho = "Three",
		Nome = "Fornalha básica",
		Preco = "100",
		Componentes = {
			{ Tipo = "Transportador", Parte = "BandejaEntrada", Velocidade = 6 },
			-- O vendedor calcula valor do minerio vezes Multiplicador mais Bonus e credita o dono antes de consumir a
			-- unidade. Sensor e o nome da parte que detecta o contato.
			{ Tipo = "Vendedor", Sensor = "SensorEntrada", Multiplicador = "1", Bonus = "0" },
		},
	},
	ModificadorBasico = {
		Atalho = "Four",
		Nome = "Modificador básico ×2",
		Preco = "200",
		Blocos = { 2, 2, 1 },
		Componentes = {
			{ Tipo = "Transportador", Parte = "Correia", Velocidade = 6 },
			-- O modificador usa a mesma formula, mas grava o novo valor no minerio. Cada instancia aplica seu efeito
			-- uma vez por minerio e permite que ele siga para outras pecas.
			{ Tipo = "Modificador", Sensor = "SensorEntrada", Multiplicador = "2", Bonus = "0" },
		},
	},
}
