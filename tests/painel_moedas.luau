-- Executa a classe real com elementos simulados; o enquadramento e conferido no editor.
local roblox = require("@lune/roblox")
local suporte = require("./suporte/interface")
local carregar = require("./suporte/carregador")({
	Instance = { new = suporte.NovaInstancia }, Enum = roblox.Enum, Color3 = roblox.Color3,
	Vector2 = roblox.Vector2, UDim = roblox.UDim, UDim2 = roblox.UDim2, ColorSequence = roblox.ColorSequence,
})
local Painel = carregar("src/client/PainelMoedas")
local pai = suporte.NovaInstancia("Folder")
local painel = Painel.new(pai)
local raiz = painel._instancia
assert(painel._gui.Parent == pai and raiz.Parent == painel._gui)
assert(painel._gui.IgnoreGuiInset and not painel._gui.ResetOnSpawn)
assert(raiz.Position.Y.Offset == 6 and raiz:FindFirstChildOfClass("UIScale").Scale == 0.9)
assert(raiz.Size.X.Scale == 1 and raiz.Size.X.Offset == -32)
assert(raiz:FindFirstChildOfClass("UISizeConstraint").MaxSize == roblox.Vector2.new(600, 46))
assert(raiz.Size.Y.Offset == 46, "O HUD deve ocupar apenas uma linha.")
local layout = raiz:FindFirstChildOfClass("UIListLayout")
assert(layout.FillDirection == roblox.Enum.FillDirection.Horizontal and layout.Padding.Offset == 8)
for ordem, nome in { "Dinheiro", "Moeda2", "Moeda3" } do
	local cartao = raiz:FindFirstChild(nome)
	assert(cartao.LayoutOrder == ordem and cartao.Size.Y.Scale == 1 and cartao.Size.Y.Offset == 0)
end
assert(painel._valores.Dinheiro.Text == "Carregando...")
assert(painel._valores.Dinheiro.TextSize == 24 and painel._valores.Moeda2.TextSize == 19)
assert(painel._valores.Dinheiro.TextScaled and painel._valores.Dinheiro.TextWrapped)
for _, invalido in { false, 100, "-1", "1.5", "abc", "" } do
	painel:AtualizarDinheiro(invalido)
	assert(painel._valores.Dinheiro.Text == "Indisponível")
end
for _, valido in { "0", "1234567", "100000000000000000001" } do
	painel:AtualizarDinheiro(valido)
	assert(painel._valores.Dinheiro.Text == valido, "Nao pode arredondar o saldo ao converte-lo para number.")
end
for _, nome in { "Moeda2", "Moeda3" } do
	assert(painel._valores[nome].Text == "—", "Reserva visual nao pode inventar um saldo.")
	assert(raiz:FindFirstChild(nome):FindFirstChild("Icone"))
end
painel:Destruir(); painel:Destruir()
painel:AtualizarDinheiro("5")
assert(painel._gui.destruido and raiz.destruido and painel._valores.Dinheiro.Text == "100000000000000000001")
print("PASS: tres campos, reservas sem saldo ficticio, dinheiro decimal, estados e limpeza.")
