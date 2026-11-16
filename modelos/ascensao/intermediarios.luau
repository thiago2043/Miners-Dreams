local categorias = {"Mineradoras", "Fornalhas", "Modificadores", "Modificadores", "Modificadores"}
local siglas = {"M", "F", "X", "X", "X"}
local series = {
	{
		{"Escavadora de zircônia laminada", 4, 3, 3, 0xA2E8FF, "prisma", 1.5},
		{"Fornalha de sinterização dupla", 4, 3, 2, 0xFFD7A2, "cadinho"},
		{"Laminador de caulim", 3, 2, 2, 0x8DE5C5, "laminas", {"rasante", "cadinho"}, 0},
		{"Pórtico de têmpera cerâmica", 4, 3, 3, 0xD3A3F1, "gaiola", {"garra", "portal"}, 0},
		{"Crivo de magnesita fundida", 3, 3, 2, 0xFFF1AD, "colmeia", {"sonda", "rasante"}, 0},
	},
	{
		{"Escavadora de banho sinterizado", 4, 5, 3, 0x7EFFD9, "torres", 1.5},
		{"Fornalha de contrafluxo criogênico", 5, 3, 3, 0x93C9FF, "turbina"},
		{"Injetor de hélio vitrificado", 4, 3, 3, 0x8EF6CA, "trilhos", {"bobina", "jato"}, 0},
		{"Prensa de zircônia superfluida", 4, 4, 3, 0xFBACFF, "laminas", {"garra", "prensa"}, 1},
		{"Anel de magnesita criogênica", 3, 4, 2, 0xB6F4FF, "satelites", {"anel", "rasante"}, 0},
	},
	{
		{"Escavadora de liga solar", 5, 5, 4, 0xFFCD75, "leque", 2.5},
		{"Fornalha de tungstênio radiante", 5, 4, 3, 0xFFAB85, "chamine"},
		{"Trefila de tungstênio fundido", 4, 3, 2, 0xFFBC67, "colmeia", {"garra", "prensa"}, 0},
		{"Bobina de sopro solar", 3, 4, 3, 0xE5F398, "trilhos", {"bobina", "jato", "lente"}, 0},
		{"Selo de fundente dourado", 5, 3, 3, 0xFC906E, "laminas", {"rasante", "portal"}, 0},
	},
	{
		{"Escavadora de quartzo temperado", 5, 6, 5, 0xDDA9FF, "anel", 2.5},
		{"Fornalha de faces birrefringentes", 6, 4, 4, 0xF0A9D9, "arco"},
		{"Prisma de tungstênio birrefringente", 4, 4, 3, 0xE7AEFF, "gaiola", {"cristal", "rasante", "lente"}, 1},
		{"Colimador de cobre facetado", 5, 4, 3, 0xFFBFA8, "satelites", {"sonda", "lente", "garra"}, 0},
		{"Cascata de quartzo solar", 4, 5, 3, 0xFF84BD, "colmeia", {"rasante", "bobina", "cristal"}, 1},
	},
	{
		{"Escavadora de lastro refratário", 6, 5, 5, 0xB1ACFF, "asa", 2.5},
		{"Fornalha de poço refratário", 5, 5, 4, 0xC5DAFF, "obelisco"},
		{"Balança de massa facetada", 5, 4, 4, 0x9DB4FF, "satelites", {"prensa", "cristal", "turbina"}, 1},
		{"Pêndulo de liga lapidada", 4, 5, 4, 0xA9E1FB, "gaiola", {"anel", "bobina", "prensa"}, 1},
		{"Colisor de espelhos criogênicos", 5, 5, 4, 0xC5A2F5, "trilhos", {"lente", "garra", "portal"}, 2},
	},
	{
		{"Escavadora de cavidades gêmeas", 5, 5, 5, 0xA1F9A5, "prisma", 3.5},
		{"Fornalha de expansão pulsada", 6, 5, 4, 0x9BE5E0, "turbina"},
		{"Válvula de néon rarefeito", 4, 4, 3, 0xD3FF8C, "trilhos", {"sonda", "rasante", "cadinho"}, 0},
		{"Ejetor de feixe rarefeito", 5, 5, 3, 0x9CFFD2, "laminas", {"jato", "rasante", "lente"}, 1},
		{"Reator de pulso adiabático", 6, 4, 4, 0x80DBED, "gaiola", {"cristal", "portal", "turbina"}, 1},
	},
	{
		{"Escavadora de partículas rarefeitas", 7, 5, 5, 0xFF9B9B, "leque", 3.5},
		{"Fornalha de aniquilação pulsada", 6, 6, 5, 0xE59BC7, "chamine"},
		{"Sonda de cavidade neutra", 5, 4, 4, 0xFF9279, "colmeia", {"sonda", "lente", "garra"}, 1},
		{"Janela de captura reversa", 6, 4, 4, 0xFFBB73, "satelites", {"portal", "turbina", "lente"}, 1},
		{"Retificador de antineutrinos", 6, 6, 5, 0xF69ABF, "laminas", {"bobina", "anel", "prensa", "sonda"}, 2},
	},
	{
		{"Escavadora de espelhos convergentes", 6, 7, 6, 0xA7D5FF, "torres", 3.5},
		{"Fornalha de foco duplo", 7, 5, 5, 0xBDE8FE, "arco"},
		{"Colimador de vidro esférico", 5, 5, 4, 0xB8F0FF, "laminas", {"lente", "jato", "cristal"}, 1},
		{"Estação de foco coaxial", 6, 5, 5, 0xDCC4FF, "gaiola", {"sonda", "lente", "portal", "cristal"}, 2},
		{"Janela de refração concêntrica", 7, 4, 5, 0x9DFADF, "trilhos", {"garra", "lente", "anel", "portal"}, 1},
	},
	{
		{"Escavadora do horizonte reverso", 8, 6, 7, 0xCCFF8C, "anel", 3.5},
		{"Fornalha de gradiente focal", 7, 6, 6, 0xF6EB9C, "cadinho"},
		{"Ordenador de reflexos térmicos", 6, 6, 5, 0xB5FF73, "gaiola", {"prensa", "rasante", "bobina", "garra"}, 2},
		{"Câmara de espelhos entrópicos", 7, 5, 5, 0xAAEF9E, "colmeia", {"sonda", "lente", "prensa", "portal"}, 2},
		{"Arco de decaimento refratado", 6, 7, 5, 0xD8FFAE, "satelites", {"turbina", "cadinho", "anel", "cristal"}, 2},
	},
	{
		{"Escavadora de passado imóvel", 8, 7, 7, 0xFFE5AB, "asa", 3.5},
		{"Fornalha de ignição imutável", 8, 7, 7, 0xFFCC85, "obelisco"},
		{"Reator de óptica imutável", 7, 7, 6, 0xEAFFBD, "trilhos", {"lente", "cristal", "bobina", "lente", "turbina"}, 2},
		{"Pórtico de massa atemporal", 8, 7, 7, 0xFFE7A8, "gaiola", {"prensa", "garra", "lente", "portal", "cristal"}, 2},
		{"Crisol do tempo suspenso", 8, 8, 7, 0xFFC39D, "colmeia", {"cadinho", "jato", "anel", "prensa", "portal"}, 2},
	},
}

local grupos = {Mineradoras = {}, Fornalhas = {}, Modificadores = {}}
for _, serie in series do
	assert(#serie == #categorias)
	for i, def in serie do
		local grupo = grupos[categorias[i]]
		local id = "CraftLojaAsc" .. siglas[i] .. string.format("%02d", #grupo + 1)
		table.insert(grupo, {id, table.unpack(def)})
	end
end

return grupos
