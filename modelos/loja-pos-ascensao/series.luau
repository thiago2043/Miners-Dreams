-- Cada série tem dois extratores, dois fornos e seis modificadores.
-- Cada linha define nome, largura, comprimento, altura e perfil ou sequência de faixas.
return {
	{
		Nome = "Cerâmica orbital", Expoente = 155, Cor = 0x72D9FF,
		Mineradoras = {
			{"Mineradora de cerâmica orbital", 3, 3, 2, "mandíbula", 1.5},
			{"Escavadora de caulim polar", 4, 4, 3, "trípode", 1.5},
		},
		Fornalhas = {
			{"Fornalha de zircônia", 3, 3, 1, "cadinho"},
			{"Fornalha de casca sinterizada", 4, 4, 3, "mufla"},
		},
		Modificadores = {
			{"Raspador de caulim", 2, 1, 1, "degraus", {"rasante"}, 0},
			{"Pinça de zircônia", 3, 2, 2, "cúpulas", {"garra"}, 0},
			{"Peneira de magnesita", 4, 2, 1, "cassetes", {"rasante", "rasante"}, 0},
			{"Revestidor de porcelana", 3, 3, 2, "dutos", {"jato", "cadinho"}, 0},
			{"Arco cerâmico de têmpera", 4, 3, 2, "nervuras", {"portal", "lente"}, 0},
			{"Crivo de alumina azul", 4, 4, 2, "escudos", {"sonda", "rasante"}, 0},
		},
	},
	{
		Nome = "Hélio superfluido", Expoente = 168, Cor = 0x53FCD2,
		Mineradoras = {
			{"Mineradora de hélio superfluido", 4, 3, 3, "aríete", 1.5},
			{"Escavadora de banho criogênico", 3, 5, 3, "braço", 2.5},
		},
		Fornalhas = {
			{"Fornalha de circulação criogênica", 4, 3, 2, "toróide"},
			{"Fornalha de hélio comprimido", 4, 4, 3, "ciclone"},
		},
		Modificadores = {
			{"Dosador de hélio líquido", 3, 2, 1, "dutos", {"rasante"}, 0},
			{"Chave de fluxo frio", 3, 3, 2, "escudos", {"garra", "rasante"}, 0},
			{"Trilho de gás rarefeito", 2, 3, 2, "nervuras", {"lente", "jato"}, 0},
			{"Condensador de hélio verde", 4, 3, 3, "cúpulas", {"bobina", "cristal"}, 0},
			{"Prensa superfluida", 4, 4, 3, "cassetes", {"prensa", "cadinho"}, 1},
			{"Anel de choque criogênico", 4, 4, 3, "degraus", {"anel", "turbina"}, 0},
		},
	},
	{
		Nome = "Metalurgia solar", Expoente = 183, Cor = 0xFFB957,
		Mineradoras = {
			{"Mineradora de escória solar", 5, 4, 3, "trípode", 1.5},
			{"Escavadora de tungstênio solar", 5, 5, 4, "turbina", 2.5},
		},
		Fornalhas = {
			{"Fornalha de têmpera solar", 5, 4, 2, "placas"},
			{"Fornalha de arco de tungstênio", 5, 4, 4, "risco"},
		},
		Modificadores = {
			{"Garra de tungstênio solar", 3, 2, 2, "escudos", {"garra"}, 0},
			{"Bobina de cobre solar", 4, 3, 2, "dutos", {"bobina", "lente"}, 0},
			{"Lacre de escória radiante", 4, 3, 1, "cassetes", {"rasante", "rasante"}, 0},
			{"Fole de carbeto dourado", 4, 4, 2, "nervuras", {"jato", "turbina"}, 0},
			{"Trefila de arco de tungstênio", 5, 4, 3, "degraus", {"prensa", "garra"}, 1},
			{"Portal de fundente solar", 5, 5, 3, "cúpulas", {"portal", "cadinho", "rasante"}, 1},
		},
	},
	{
		Nome = "Cristais de fase", Expoente = 200, Cor = 0xF56AD1,
		Mineradoras = {
			{"Mineradora de espinélio de fase", 4, 6, 3, "mandíbula", 2.5},
			{"Escavadora de quartzo de fase", 5, 4, 5, "braço", 2.5},
		},
		Fornalhas = {
			{"Fornalha de gema birrefringente", 4, 5, 3, "cadinho"},
			{"Fornalha de espelhos de fase", 5, 5, 4, "toróide"},
		},
		Modificadores = {
			{"Prisma de espinélio", 3, 3, 2, "cúpulas", {"cristal", "lente"}, 0},
			{"Colimador de granada rosa", 4, 3, 2, "nervuras", {"lente", "sonda"}, 0},
			{"Ressonador de quartzo rosa", 3, 4, 3, "degraus", {"bobina", "anel"}, 1},
			{"Separador birrefringente", 4, 4, 3, "dutos", {"rasante", "cristal", "rasante"}, 0},
			{"Matriz de espelhos de fase", 5, 4, 4, "escudos", {"portal", "lente", "garra"}, 1},
			{"Cascata de espinélio rosa", 5, 5, 3, "cassetes", {"sonda", "lente", "cristal"}, 1},
		},
	},
	{
		Nome = "Dinâmica gravítica", Expoente = 219, Cor = 0x9D8DFF,
		Mineradoras = {
			{"Mineradora de gravidade inversa", 5, 5, 5, "aríete", 2.5},
			{"Escavadora de lentes gravíticas", 6, 5, 4, "trípode", 3.5},
		},
		Fornalhas = {
			{"Fornalha de lastro invertido", 5, 4, 4, "mufla"},
			{"Fornalha de poço gravítico", 5, 6, 5, "ciclone"},
		},
		Modificadores = {
			{"Lastro de gravidade inversa", 4, 3, 2, "degraus", {"prensa", "rasante"}, 0},
			{"Pêndulo gravítico", 4, 3, 3, "escudos", {"anel", "garra"}, 1},
			{"Prisma de lente gravitacional", 4, 4, 3, "nervuras", {"lente", "cristal"}, 1},
			{"Válvula de poço gravítico", 5, 4, 4, "dutos", {"turbina", "cadinho", "jato"}, 1},
			{"Malha de massa aparente", 4, 5, 3, "cassetes", {"rasante", "bobina", "prensa"}, 0},
			{"Colisor de marés gravíticas", 5, 5, 4, "cúpulas", {"portal", "anel", "lente"}, 2},
		},
	},
	{
		Nome = "Vácuo de alta energia", Expoente = 242, Cor = 0x8AFFAF,
		Mineradoras = {
			{"Mineradora de vácuo pressurizado", 6, 4, 5, "turbina", 2.5},
			{"Escavadora de cavidade evacuada", 5, 6, 5, "mandíbula", 3.5},
		},
		Fornalhas = {
			{"Fornalha de expansão adiabática", 5, 5, 4, "placas"},
			{"Fornalha de pulso ultravácuo", 6, 5, 5, "risco"},
		},
		Modificadores = {
			{"Vácuostato de néon", 4, 3, 3, "cassetes", {"sonda", "rasante"}, 0},
			{"Ejetor de pulso ultravácuo", 4, 4, 3, "dutos", {"jato", "turbina"}, 1},
			{"Grade de expansão adiabática", 5, 4, 3, "nervuras", {"cristal", "sonda", "lente"}, 1},
			{"Válvula de cavidade evacuada", 4, 5, 4, "escudos", {"garra", "prensa", "cadinho"}, 1},
			{"Câmara de emissão de vácuo", 5, 5, 4, "degraus", {"lente", "bobina", "jato"}, 2},
			{"Reator de pressão negativa", 6, 5, 4, "cúpulas", {"portal", "turbina", "anel"}, 1},
		},
	},
	{
		Nome = "Engenharia de neutrinos", Expoente = 270, Cor = 0xFF877F,
		Mineradoras = {
			{"Mineradora de neutrinos lentos", 6, 5, 6, "braço", 3.5},
			{"Escavadora de antineutrinos", 7, 6, 5, "aríete", 3.5},
		},
		Fornalhas = {
			{"Fornalha de feixe de neutrinos", 5, 6, 4, "toróide"},
			{"Fornalha de captura de antineutrinos", 6, 6, 5, "cadinho"},
		},
		Modificadores = {
			{"Sonda de neutrinos lentos", 4, 4, 3, "nervuras", {"sonda", "lente"}, 1},
			{"Janela de antineutrinos", 5, 3, 3, "escudos", {"portal", "rasante"}, 0},
			{"Retificador de pulsos neutros", 5, 5, 3, "dutos", {"bobina", "sonda", "jato"}, 1},
			{"Lente de captura rubra", 5, 4, 4, "cúpulas", {"lente", "cristal", "anel"}, 2},
			{"Ciclotron de neutrinos", 6, 5, 4, "degraus", {"turbina", "anel", "prensa"}, 1},
			{"Ressonador de antineutrinos", 6, 6, 5, "cassetes", {"prensa", "lente", "anel", "sonda"}, 2},
		},
	},
	{
		Nome = "Óptica de horizontes", Expoente = 303, Cor = 0xBFE9FF,
		Mineradoras = {
			{"Mineradora de horizonte refratado", 6, 6, 6, "trípode", 3.5},
			{"Escavadora de horizonte de vidro", 7, 6, 6, "turbina", 4.5},
		},
		Fornalhas = {
			{"Fornalha de horizonte focal", 6, 5, 5, "ciclone"},
			{"Fornalha de horizonte de vidro", 6, 6, 6, "placas"},
		},
		Modificadores = {
			{"Limiar de refração", 5, 3, 3, "cúpulas", {"lente", "cristal"}, 0},
			{"Prisma do horizonte focal", 5, 4, 4, "degraus", {"lente", "sonda", "portal"}, 1},
			{"Fenda de espelho esférico", 5, 5, 4, "cassetes", {"garra", "prensa", "lente"}, 1},
			{"Canal de vidro focal", 6, 5, 4, "dutos", {"jato", "rasante", "anel"}, 2},
			{"Estação de lentes duplas", 6, 5, 5, "nervuras", {"lente", "cristal", "lente", "portal"}, 2},
			{"Janela de horizonte de vidro", 6, 6, 5, "escudos", {"portal", "anel", "turbina", "cristal"}, 1},
		},
	},
	{
		Nome = "Entropia dirigida", Expoente = 341, Cor = 0xBAFF64,
		Mineradoras = {
			{"Mineradora de entropia dirigida", 7, 6, 6, "mandíbula", 3.5},
			{"Escavadora de decaimento reverso", 8, 6, 7, "braço", 4.5},
		},
		Fornalhas = {
			{"Fornalha de gradiente entrópico", 6, 6, 5, "risco"},
			{"Fornalha de decaimento reverso", 7, 7, 6, "mufla"},
		},
		Modificadores = {
			{"Pente de entropia dirigida", 4, 5, 3, "escudos", {"rasante", "prensa", "rasante"}, 0},
			{"Seletor de gradiente entrópico", 5, 5, 4, "cassetes", {"sonda", "lente", "jato"}, 1},
			{"Reator de decaimento curto", 6, 5, 5, "dutos", {"turbina", "cadinho", "cristal"}, 2},
			{"Cascata de ordenação térmica", 6, 6, 5, "degraus", {"bobina", "garra", "prensa", "rasante"}, 2},
			{"Câmara de entropia dirigida", 7, 5, 5, "cúpulas", {"portal", "turbina", "prensa", "lente"}, 1},
			{"Arco de decaimento reverso", 7, 6, 6, "nervuras", {"anel", "cristal", "lente", "portal"}, 2},
		},
	},
	{
		Nome = "Eternidade", Expoente = 390, Cor = 0xFFDB87,
		Mineradoras = {
			{"Mineradora do núcleo sem tempo", 7, 7, 6, "turbina", 3.5},
			{"Escavadora da eternidade", 8, 7, 7, "aríete", 4.5},
		},
		Fornalhas = {
			{"Fornalha de ignição atemporal", 7, 6, 6, "cadinho"},
			{"Fornalha da eternidade", 8, 7, 7, "toróide"},
		},
		Modificadores = {
			{"Lente de fase atemporal", 5, 4, 4, "dutos", {"lente", "cristal", "sonda"}, 1},
			{"Prensa do núcleo sem tempo", 6, 5, 5, "escudos", {"prensa", "anel", "garra"}, 1},
			{"Crisol de ignição atemporal", 6, 6, 5, "cassetes", {"cadinho", "jato", "prensa", "anel"}, 2},
			{"Reator de fase imutável", 7, 5, 6, "degraus", {"cristal", "bobina", "lente", "turbina"}, 2},
			{"Pórtico do último horizonte", 7, 7, 6, "cúpulas", {"portal", "lente", "anel", "cristal"}, 2},
			{"Modificador da eternidade", 8, 8, 7, "nervuras", {"portal", "anel", "prensa", "lente", "cristal"}, 2},
		},
	},
}
