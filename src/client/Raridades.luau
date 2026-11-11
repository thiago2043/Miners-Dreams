local Raridades = {}
local function estilo(nome, inicio, fim)
	return { Nome = nome, Cores = ColorSequence.new(Color3.fromRGB(unpack(inicio)), Color3.fromRGB(unpack(fim))) }
end
Raridades.Estilos = {
	Comum = estilo("Comum", {160, 170, 185}, {211, 218, 227}),
	Incomum = estilo("Incomum", {66, 191, 113}, {145, 236, 150}),
	Rara = estilo("Rara", {83, 151, 244}, {135, 211, 255}),
	["Épica"] = estilo("Épica", {175, 117, 235}, {222, 168, 255}),
	["Lendária"] = estilo("Lendária", {230, 164, 47}, {255, 226, 132}),
	["Mítico"] = estilo("Mítico", {250, 91, 108}, {255, 163, 111}),
	Renascimento = estilo("Renascimento", {104, 232, 223}, {242, 159, 230}),
	["Exótica"] = estilo("Exótica", {92, 211, 207}, {207, 255, 231}),
	["Anômala"] = estilo("Anômala", {169, 134, 233}, {250, 206, 255}),
	Singular = estilo("Singular", {109, 176, 250}, {216, 243, 255}),
	Superior = estilo("Superior", {232, 126, 153}, {255, 222, 173}),
	Elite = estilo("Elite", {235, 181, 81}, {255, 249, 217}),
	Despertar = estilo("Despertar", {86, 215, 183}, {208, 252, 166}),
	["Avanço"] = estilo("Avanço", {107, 198, 241}, {204, 223, 255}),
	Apogeu = estilo("Apogeu", {151, 140, 248}, {245, 199, 255}),
	["Domínio"] = estilo("Domínio", {217, 143, 233}, {255, 201, 195}),
	Meridiano = estilo("Meridiano", {111, 228, 223}, {255, 217, 248}),
	Forjada = estilo("Forjada", {218, 149, 108}, {247, 218, 184}),
	Composta = estilo("Composta", {239, 172, 88}, {255, 224, 144}),
	["Núcleo"] = estilo("Núcleo", {242, 137, 112}, {255, 223, 190}),
	Convergente = estilo("Convergente", {255, 194, 135}, {255, 253, 242}),
}
function Raridades.Obter(definicao)
	return Raridades.Estilos[definicao and definicao.Raridade] or Raridades.Estilos.Comum
end
function Raridades.ColorirBorda(borda, estiloRaridade)
	borda.Color = Color3.new(1, 1, 1)
	local gradiente = borda:FindFirstChild("Raridade")
	if not gradiente then
		gradiente = Instance.new("UIGradient")
		gradiente.Name, gradiente.Parent = "Raridade", borda
	end
	gradiente.Color = estiloRaridade.Cores
end
return Raridades
