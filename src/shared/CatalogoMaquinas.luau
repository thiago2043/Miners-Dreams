return {
	MineradoraBasica = {
		Atalho = "One",
		Nome = "Mineradora básica",
		Preco = "100",
		Componentes = {
			{
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
		Componentes = {
			{ Tipo = "Transportador", Parte = "Correia", Velocidade = 6 },
		},
	},
	FornalhaBasica = {
		Atalho = "Three",
		Nome = "Fornalha básica",
		Preco = "100",
		Componentes = {
			{ Tipo = "Transportador", Parte = "BandejaEntrada", Velocidade = 6 },
			{ Tipo = "Vendedor", Sensor = "SensorEntrada", Multiplicador = "1", Bonus = "0" },
		},
	},
}
