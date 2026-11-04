-- Executa a classe real com elementos simulados; o enquadramento e conferido no editor.
local roblox = require("@lune/roblox")
local suporte = require("./suporte/interface")
local animacoes,descartes={},{}
local carregar = require("./suporte/carregador")({
	Instance = { new = suporte.NovaInstancia }, Enum = roblox.Enum, Color3 = roblox.Color3,
	Vector2 = roblox.Vector2, UDim = roblox.UDim, UDim2 = roblox.UDim2, ColorSequence = roblox.ColorSequence, task=require("@lune/task"),
	TweenInfo={new=function(duracao) return {Time=duracao} end},
}, {TweenService={Create=function(_,objeto,info,destino)
	table.insert(animacoes,{Objeto=objeto,Info=info,Destino=destino}); return {Play=function() end}
end},Debris={AddItem=function(_,objeto,prazo) table.insert(descartes,{objeto,prazo}) end}})
local Painel = carregar("src/client/PainelMoedas")
local pai = suporte.NovaInstancia("Folder")
local painel = Painel.new(pai)
local raiz = painel._instancia
assert(painel._gui.Parent == pai and raiz.Parent == painel._gui)
assert(painel._gui.IgnoreGuiInset and not painel._gui.ResetOnSpawn)
assert(raiz.Position.Y.Offset == 6 and raiz:FindFirstChildOfClass("UIScale").Scale == 0.9)
assert(raiz.Size.X.Scale == 1 and raiz.Size.X.Offset == -32)
assert(raiz:FindFirstChildOfClass("UISizeConstraint").MaxSize == roblox.Vector2.new(220, 38))
assert(raiz.Size.Y.Offset == 38, "O HUD deve ocupar apenas uma linha.")
local layout = raiz:FindFirstChildOfClass("UIListLayout")
assert(layout.FillDirection == roblox.Enum.FillDirection.Horizontal and layout.Padding.Offset == 8)
for ordem, nome in { "Dinheiro" } do
	local cartao = raiz:FindFirstChild(nome)
	assert(cartao.LayoutOrder == ordem and cartao.Size.Y.Scale == 1 and cartao.Size.Y.Offset == 0)
end
assert(painel._valores.Dinheiro.Text == "Carregando...")
painel:AtualizarTaxa("12500")
assert(painel._taxa.Text == "+$12,5K/s")
painel:AtualizarTaxa(nil)
assert(painel._taxa.Text == "—/s")
assert(painel._valores.Dinheiro.TextSize == 20)
assert(painel._valores.Dinheiro.TextScaled and painel._valores.Dinheiro.TextWrapped)
for _, invalido in { false, 100, "-1", "1.5", "abc", "" } do
	painel:AtualizarDinheiro(invalido)
	assert(painel._valores.Dinheiro.Text == "Indisponível")
end
for _, caso in { {"0", "0"}, {"1234567", "1,23M"}, {"100000000000000000001", "100Qn"} } do
	painel:AtualizarDinheiro(caso[1])
	assert(painel._valores.Dinheiro.Text == caso[2])
end
assert(not raiz:FindFirstChild("Moeda2") and not raiz:FindFirstChild("Moeda3"))
painel:AtualizarDinheiro("1234567")
painel._valores.Dinheiro.MouseEnter:Fire()
assert(painel._dica._caixa.Visible and painel._dica._texto.Text=="um milhão, duzentos e trinta e quatro mil, quinhentos e sessenta e sete")
painel:AtualizarDinheiro("100000000000000000001")
assert(painel._dica._texto.Text=="cem quintilhões e um")
painel:AtualizarDinheiro(string.rep("9",309))
assert(painel._dica._caixa.Size.Y.Offset==160 and painel._dica._rolagem.AutomaticCanvasSize==roblox.Enum.AutomaticSize.Y)
assert(painel._dica._rolagem.CanvasSize.Y.Offset>160)
painel._valores.Dinheiro.MouseLeave:Fire(); painel._dica._caixa.MouseEnter:Fire()
require("@lune/task").wait(.3)
assert(painel._dica._caixa.Visible,"A caixa deve permanecer aberta enquanto o mouse entra para rolar.")
painel._dica._caixa.MouseLeave:Fire(); require("@lune/task").wait(.3)
assert(not painel._dica._caixa.Visible)
painel:AtualizarTaxa("12500"); painel._taxa.MouseEnter:Fire()
assert(painel._dica._texto.Text=="doze mil e quinhentos por segundo")
painel:AtualizarTaxa(nil); assert(not painel._dica._caixa.Visible)
painel:AtualizarDinheiro("100000000000000000001")
painel:AtualizarRecebimentos("0"); assert(#animacoes==0)
painel:AtualizarRecebimentos("2500")
local animacao=animacoes[1]
assert(animacao.Objeto.Text=="+$2,5K" and animacao.Objeto.TextColor3==roblox.Color3.fromRGB(69,255,139))
assert(animacao.Objeto.Parent==painel._gui and animacao.Info.Time==.75 and animacao.Destino.TextTransparency==1)
assert(descartes[1][2]==.8)
painel:AtualizarRecebimentos("2500"); painel:AtualizarRecebimentos("0"); painel:AtualizarRecebimentos("invalido")
assert(#animacoes==1,"Repetição, queda ou dado inválido não geram recebimentos.")
painel:Destruir(); painel:Destruir()
painel:AtualizarDinheiro("5")
assert(painel._gui.destruido and raiz.destruido and painel._valores.Dinheiro.Text == "100Qn")
print("PASS: somente dinheiro no HUD, dinheiro decimal, estados e limpeza.")
