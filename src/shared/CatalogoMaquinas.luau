-- Definicoes compartilhadas: nome, preco, volume e parametros dos comportamentos. Variantes existentes
-- reutilizam as mesmas classes.
local escala = require(script.Parent.Medidas).Bloco / 4
local function mineradora(nome, preco, blocos, intervalo, valor, atalho)
	return {
		Nome = "Mineradora " .. nome, Preco = preco, Blocos = blocos, Atalho = atalho,
		Componentes = { {
			Tipo = "Soltador", Saida = "SaidaMinerio", Intervalo = intervalo,
			Minerio = { Valor = valor, Tamanho = { escala, escala, escala } },
		} },
	}
end

local function modificador(codigo, nome, preco, blocos, etapas, multiplicador, bonus, limite, minimo, maximo, temEsteira)
	local componentes = {}
	if temEsteira then table.insert(componentes, { Tipo = "Transportador", Parte = "Correia", Velocidade = 6 }) end
	table.insert(componentes, {
		Tipo = "Modificador", Sensor = "SensorEntrada", TipoModificador = codigo, Etapas = etapas,
		Multiplicador = multiplicador, Bonus = bonus, LimiteUsos = limite, ValorMinimo = minimo, ValorMaximo = maximo,
	})
	return { Nome = nome, Preco = preco, Blocos = blocos, Componentes = componentes }
end

local function fornalha(nome, preco, blocos, multiplicador, atalho)
	return {
		Nome = "Fornalha " .. nome, Preco = preco, Blocos = blocos, Atalho = atalho,
		Componentes = {
			{ Tipo = "Transportador", Parte = "BandejaEntrada", Velocidade = 6, ExibirSeta = false },
			{ Tipo = "Vendedor", Sensor = "SensorEntrada", Multiplicador = multiplicador, Bonus = "0" },
		},
	}
end

local catalogo = {
	-- A chave deve corresponder ao nome do Model em ModelosMaquinas. Nome e texto da interface; Atalho usa o
	-- nome da tecla no Enum.KeyCode; Preco e um inteiro decimal em texto.
	-- Valores da proposta revisada; precos e valores de minerio permanecem inteiros decimais exatos.
	MineradoraBasica        = mineradora("básica",        "100",                      { 2, 2, 2 },   2,    "5"),
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
	Esteira2x2 = {
		Nome = "Esteira 2×2", Preco = "25", Blocos = { 2, 1, 2 },
		Componentes = { { Tipo = "Transportador", Parte = "Correia", Velocidade = 6 } },
	},
	Esteira1x1 = {
		Nome = "Esteira 1×1", Preco = "25", Blocos = { 1, 1, 1 },
		Componentes = { { Tipo = "Transportador", Parte = "Correia", Velocidade = 6 } },
	},
	Centralizadora2x2 = {
		Nome = "Centralizadora 2×2", Preco = "25", Blocos = { 2, 1, 2 },
		Componentes = {
			{ Tipo = "Transportador", Parte = "CorreiaEsquerda", Velocidade = 6 },
			{ Tipo = "Transportador", Parte = "CorreiaDireita", Velocidade = 6 },
		},
	},
	Centralizadora1x1 = {
		Nome = "Centralizadora 1×1", Preco = "25", Blocos = { 1, 1, 1 },
		Componentes = {
			{ Tipo = "Transportador", Parte = "CorreiaEsquerda", Velocidade = 6 },
			{ Tipo = "Transportador", Parte = "CorreiaDireita", Velocidade = 6 },
		},
	},
	Parede1x1 = {
		Nome = "Parede 1×1×1", Preco = "25", Blocos = { 1, 1, 1 }, Componentes = {},
	},
	FornalhaBasica      = fornalha("básica",     "100",                  { 2, 1, 2 }, "1"),
	FornalhaReforcada   = fornalha("reforçada",  "3000",                 { 2, 2, 2 }, "1.5"),
	FornalhaIndustrial  = fornalha("industrial", "1000000",              { 3, 2, 3 }, "3"),
	FornalhaTermica     = fornalha("térmica",    "500000000",            { 4, 3, 3 }, "5"),
	FornalhaPlasma      = fornalha("de plasma",  "250000000000",         { 3, 3, 4 }, "8"),
	FornalhaMolecular   = fornalha("molecular",  "25000000000000",       { 4, 4, 4 }, "12"),
	FornalhaQuantica    = fornalha("quântica",   "1000000000000000",     { 5, 4, 4 }, "20"),
	FornalhaEstelar     = fornalha("estelar",    "100000000000000000",   { 4, 5, 5 }, "35"),
	FornalhaGalactica   = fornalha("galáctica",  "10000000000000000000", { 5, 5, 5 }, "60"),
	-- Tipos da proposta revisada: usos contam a peca inteira, nao cada etapa.
	JatoMineral               = modificador("A0", "Jato mineral", "100000000000000000000", { 1, 1, 1 }, 1, "2.5", "0", 1, "0", nil, false),
	BanhoCobre                = modificador("H1", "Banho de cobre", "3000000000000000000000000", { 3, 1, 2 }, 1, "2", "0", 1, "0", nil, true),
	PrensaTripla              = modificador("N01", "Prensa tripla", "750", { 4, 2, 4 }, 3, "1.75", "0", 3, "0", nil, true),
	PrensaMinerio             = modificador("V1", "Prensa de minério", "10000", { 3, 2, 2 }, 1, "2", "0", nil, "0", "100", true),
	LaserBasico               = modificador("N02", "Laser básico", "300000000000000000000", { 1, 1, 1 }, 1, "4", "0", 1, "0", nil, false),
	RefinadorCobre            = modificador("H2", "Refinador de cobre", "75000", { 4, 2, 3 }, 2, "1.3", "0", 12, "0", "1000", true),
	BobinaDupla               = modificador("N03", "Bobina dupla", "40000000000000000000000000", { 3, 1, 3 }, 1, "4.5", "0", 1, "0", nil, true),
	Ionizador                 = modificador("N04", "Ionizador", "1000000000000000000000000", { 2, 3, 2 }, 1, "1.4", "0", 4, "0", nil, false),
	RefinadorIndustrial       = modificador("V2", "Refinador industrial", "1500000", { 4, 3, 4 }, 2, "1.25", "0", nil, "0", "2500", true),
	LaserIndustrial           = modificador("N05", "Laser industrial", "20000000", { 4, 1, 2 }, 2, "2", "0", 1, "0", nil, true),
	RaioPlasma                = modificador("N06", "Raio de plasma", "75000000", { 4, 3, 3 }, 1, "2.75", "0", 1, "0", nil, true),
	BobinaInducao             = modificador("N07", "Bobina de indução", "250000000", { 4, 3, 3 }, 2, "1.8", "0", 2, "0", nil, true),
	CamaraMagnetica           = modificador("V3", "Câmara magnética", "250000000", { 4, 2, 2 }, 2, "1.5", "0", nil, "25000", "100000", true),
	RefinadorMolecular        = modificador("V4", "Refinador molecular", "1000000000", { 4, 2, 3 }, 3, "1.3", "0", nil, "0", "1000000", true),
	TunelCompressao           = modificador("N08", "Túnel de compressão", "4000000000", { 4, 3, 4 }, 4, "1.25", "0", 4, "0", nil, true),
	ProcessadorTermico        = modificador("H3", "Processador térmico", "5000000000", { 4, 2, 3 }, 2, "1.75", "0", 7, "0", "3500000", true),
	CatalisadorTermico        = modificador("N09", "Catalisador térmico", "5000000000000", { 2, 2, 2 }, 1, "3", "0", 1, "0", nil, false),
	CamaraPlasma              = modificador("V5", "Câmara de plasma", "5000000000000", { 5, 4, 4 }, 2, "1.6", "0", nil, "500000", "5000000", true),
	LaserDuplo                = modificador("N10", "Laser duplo", "25000000000000", { 4, 2, 3 }, 2, "2", "0", 2, "0", nil, true),
	Polarizador               = modificador("N11", "Polarizador", "250000000000000000000000000", { 3, 2, 3 }, 1, "1.6", "0", 4, "0", nil, true),
	RessonadorPlasma          = modificador("N12", "Ressonador de plasma", "300000000000000", { 4, 2, 4 }, 2, "3", "0", 2, "0", nil, true),
	RefinadorAtomico          = modificador("V6", "Refinador atômico", "5000000000000000", { 5, 5, 5 }, 3, "1.25", "0", nil, "0", "50000000", true),
	AceleradorModular         = modificador("N13", "Acelerador modular", "40000000000000000", { 4, 1, 5 }, 4, "1.15", "0", 10, "0", nil, true),
	TunelMolecular            = modificador("N14", "Túnel molecular", "150000000000000000", { 5, 4, 5 }, 3, "1.5", "0", 3, "0", nil, true),
	ProcessadorParticulas     = modificador("H4", "Processador de partículas", "250000000000000000", { 4, 2, 4 }, 3, "1.3", "0", 12, "0", "500000000", true),
	FeixeMolecular            = modificador("N15", "Feixe molecular", "500000000000000000", { 4, 3, 3 }, 1, "3.25", "0", 1, "0", nil, true),
	CamaraQuantica            = modificador("V7", "Câmara quântica", "2500000000000000000", { 5, 4, 3 }, 2, "1.5", "0", nil, "100000000", "2500000000", true),
	CompressorAtomico         = modificador("N16", "Compressor atômico", "40000000000000000000", { 4, 2, 2 }, 2, "2", "0", 2, "0", nil, true),
	CamaraFissao              = modificador("N17", "Câmara de fissão", "50", { 4, 4, 3 }, 1, "1", "10", nil, "0", nil, true),
	NucleoAntimateria         = modificador("N18", "Núcleo de antimatéria", "50000", { 4, 3, 3 }, 1, "2", "0", 1, "0", nil, true),
	RessonadorQuantico        = modificador("N19", "Ressonador quântico", "1500000000000000000000", { 5, 2, 2 }, 2, "3", "0", 2, "0", nil, true),
	CamaraEstelar             = modificador("V8", "Câmara estelar", "5000000000000000000000", { 5, 5, 5 }, 3, "1.75", "0", nil, "1000000000", "25000000000", true),
	AnelParticulas            = modificador("N20", "Anel de partículas", "750000", { 4, 3, 1 }, 1, "2.4", "0", 1, "0", nil, true),
	LaserQuantico             = modificador("N21", "Laser quântico", "150", { 4, 2, 1 }, 1, "1", "25", 3, "0", "100", true),
	AmplificadorFase          = modificador("N22", "Amplificador de fase", "6000000000000000000000000", { 4, 1, 5 }, 2, "2.75", "0", 2, "0", nil, true),
	PulsoEstelar              = modificador("N23", "Pulso estelar", "150000", { 4, 5, 3 }, 1, "1.5", "0", 2, "0", nil, true),
	RefinadorGalactico        = modificador("V9", "Refinador galáctico", "50000000000000000000000000", { 5, 3, 4 }, 3, "1.35", "0", nil, "0", "1000000000000", true),
	AnelGravitacional         = modificador("N24", "Anel gravitacional", "100000000000000", { 4, 3, 2 }, 1, "2.25", "0", 1, "0", nil, true),
	BobinaEstelar             = modificador("N25", "Bobina estelar", "4000000000000000000000000000", { 5, 4, 3 }, 2, "2", "0", 2, "0", nil, true),
	TunelFase                 = modificador("N26", "Túnel de fase", "6000000000000000000000000000", { 4, 2, 5 }, 3, "1.5", "0", 3, "0", nil, true),
	FeixeFotons               = modificador("N27", "Feixe de fótons", "7500000000000000000000000000", { 2, 1, 1 }, 1, "3.5", "0", 1, "0", nil, false),
	RessonadorEstelar         = modificador("N28", "Ressonador estelar", "40000000000000000000000000000", { 4, 2, 3 }, 2, "2.5", "0", 2, "0", nil, true),
	NucleoQuasar              = modificador("N29", "Núcleo de quasar", "100000000000000000000000000000", { 5, 3, 4 }, 1, "5", "0", 1, "0", nil, true),
	CompressorGalactico       = modificador("N30", "Compressor galáctico", "600000000000000000000000000000", { 5, 3, 3 }, 2, "3", "0", 2, "0", nil, true),
	TunelHorizonte            = modificador("N31", "Túnel de horizonte", "1500000000000000000000000000000", { 5, 5, 3 }, 3, "1.75", "0", 3, "0", nil, true),
	FeixeSingularidade        = modificador("N32", "Feixe de singularidade", "4000000000000000000000000000000", { 1, 5, 2 }, 1, "4", "0", 1, "0", nil, false),
	LaserGalactico            = modificador("N33", "Laser galáctico", "6000000000000000000000000000000", { 3, 1, 1 }, 1, "2", "0", 1, "0", nil, true),
	PolarizadorCosmico        = modificador("N34", "Polarizador cósmico", "10000000000000000000000000000000", { 4, 2, 4 }, 1, "2.25", "0", 1, "0", nil, true),
	RessonadorVacuo           = modificador("N35", "Ressonador de vácuo", "20000000000000000000000000000000", { 4, 2, 4 }, 2, "3", "0", 2, "0", nil, true),
	NucleoHorizonte           = modificador("N36", "Núcleo de horizonte", "90000000000000000000000000000000", { 5, 5, 4 }, 1, "6", "0", 1, "0", nil, true),
	CamaraSingularidade       = modificador("V10", "Câmara de singularidade", "250000000000000000000000000000000", { 5, 5, 5 }, 3, "2.5", "0", nil, "250000000000", "25000000000000", true),
	AmplificadorVacuo         = modificador("N37", "Amplificador de vácuo", "5000000000000000000000000000000000", { 4, 1, 5 }, 2, "2.5", "0", 2, "0", nil, true),
	PulsoDimensional          = modificador("N38", "Pulso dimensional", "15000000000000000000000000000000000", { 4, 3, 2 }, 1, "4", "0", 1, "0", nil, true),
	RessonadorDimensional     = modificador("N39", "Ressonador dimensional", "50000000000000000000000000000000000", { 5, 3, 3 }, 2, "3.5", "0", 2, "0", nil, true),
	NucleoDimensional         = modificador("N40", "Núcleo dimensional", "250000000000000000000000000000000000", { 5, 5, 5 }, 1, "5", "0", 1, "0", nil, true),
}

-- A progressao de preco e relativa a cada categoria; transportes e parede permanecem comuns.
for id,ajuste in require(script.Parent.AjustesHitbox) do catalogo[id].Blocos=table.clone(ajuste[2]) end
for id,reducao in require(script.Parent.ReducoesAlturaHitbox) do
	local blocos=table.clone(catalogo[id].Blocos)
	assert(blocos[2]>reducao,"Altura inválida para "..id)
	blocos[2]-=reducao
	catalogo[id].Blocos=blocos
end
local raridades = { "Comum", "Incomum", "Rara", "Épica", "Lendária", "Mítico" }
local grupos = { Soltador = {}, Modificador = {}, Vendedor = {} }
for _, item in catalogo do
	item.Raridade = "Comum"
	for _, componente in item.Componentes do
		if grupos[componente.Tipo] then table.insert(grupos[componente.Tipo], item); break end
	end
end
for _, grupo in grupos do
	table.sort(grupo, function(a, b)
		if #a.Preco ~= #b.Preco then return #a.Preco < #b.Preco end
		if a.Preco ~= b.Preco then return a.Preco < b.Preco end
		return a.Nome < b.Nome
	end)
	for i, item in grupo do
		local anterior = grupo[i - 1]
		item.Raridade = if anterior and anterior.Preco == item.Preco then anterior.Raridade
			else raridades[math.floor((i - 1) * #raridades / #grupo) + 1]
	end
end

for _, premio in require(script.Parent.RecompensasRenascimento) do
	local item
	if premio.Tipo == "Soltador" then
		item = mineradora("", "0", premio.Blocos, premio.Intervalo, premio.Valor)
	elseif premio.Tipo == "Vendedor" then
		item = fornalha("", "0", premio.Blocos, premio.Multiplicador)
	else
		item = modificador(premio.Codigo, premio.Nome, "0", premio.Blocos, 1, premio.Multiplicador, "0", 3, "0", nil, true)
	end
	item.Nome, item.Renascimento = premio.Nome, true
	item.Raridade = "Renascimento"
	catalogo[premio.Id] = item
end
return catalogo
