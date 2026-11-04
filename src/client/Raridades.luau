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
