-- Definicoes compartilhadas: nome, preco, volume e parametros dos comportamentos. Variantes existentes
-- reutilizam as mesmas classes.
local function mineradora(nome, preco, blocos, intervalo, valor, atalho)
	return {
		Nome = "Mineradora " .. nome, Preco = preco, Blocos = blocos, Atalho = atalho,
		Componentes = { {
			Tipo = "Soltador", Saida = "SaidaMinerio", Intervalo = intervalo, TempoVida = 10,
			Minerio = { Valor = valor, Tamanho = { 1, 1, 1 } },
		} },
	}
end

return {
	-- A chave deve corresponder ao nome do Model em ModelosMaquinas. Nome e texto da interface; Atalho usa o
	-- nome da tecla no Enum.KeyCode; Preco e um inteiro decimal em texto.
	-- Valores da proposta revisada; precos e valores de minerio permanecem inteiros decimais exatos.
	MineradoraBasica        = mineradora("básica",        "100",                      { 2, 2, 2 },   2,    "5",         "One"),
	MineradoraCobre         = mineradora("de cobre",      "1500",                     { 2, 3, 2 },   1.5,  "15"),
	MineradoraFerro         = mineradora("de ferro",      "100000",                   { 3, 3, 2 },   1.2,  "45"),
	MineradoraIndustrial    = mineradora("industrial",    "10000000",                 { 3, 3, 3 },   1,    "150"),
	MineradoraPressurizada  = mineradora("pressurizada",  "750000000",                { 3, 3, 3 },   1.5,  "1200"),
	MineradoraCristalina    = mineradora("cristalina",    "50000000000",              { 4, 4, 4 },   1.2,  "6000"),
	MineradoraRessonante    = mineradora("ressonante",    "2000000000000",            { 4, 5, 3 },   1.5,  "18000"),
	MineradoraPlasma        = mineradora("de plasma",     "100000000000000",          { 5, 5, 4 },   1,    "75000"),
	MineradoraAtomica       = mineradora("atômica",       "5000000000000000",         { 5, 5, 4 },   1.25, "350000"),
	MineradoraQuantica      = mineradora("quântica",      "250000000000000000",       { 6, 5, 6 },   1.5,  "2000000"),
	MineradoraSingularidade = mineradora("singularidade", "25000000000000000000",     { 7, 6, 7 },   1.2,  "15000000"),
	MineradoraEstelar       = mineradora("estelar",       "2500000000000000000000",   { 9, 8, 9 },   1,    "90000000"),
	MineradoraGalactica     = mineradora("galáctica",     "500000000000000000000000", { 10, 8, 10 }, 1.25, "500000000"),
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
