local r = require("@lune/roblox")
local ui = require("./suporte/interface")
local function novo(classe)
	local objeto = ui.NovaInstancia(classe)
	local atributos = {}
	function objeto:SetAttribute(k, v) atributos[k] = v end
	function objeto:GetAttribute(k) return atributos[k] end
	return objeto
end
local carregar = require("./suporte/carregador")({
	Instance={new=novo}, Enum=r.Enum, Color3=r.Color3, Vector2=r.Vector2, UDim=r.UDim, UDim2=r.UDim2,
	typeof=function(v) return if type(v)=="table" and v.ClassName then "Instance" else typeof(v) end,
}, {GuiService={}}, {
	["src/client/GerenciadorJanelas"]={Registrar=function() end},
	["src/client/SetasTransporte"]={Criar=function() return novo("Folder") end},
})
local nav = carregar("src/client/NavegacaoEstados").new()
local atributos = {IdUnidade="elevador-1", AlturaBlocos=2, FaceEntrada="+Z", FaceSaida="+X", Sentido="subir"}
local pasta = novo("Folder")
local modelo = novo("Model")
for nome, valor in atributos do modelo:SetAttribute(nome, valor) end
modelo.Parent = pasta
local pedidos = {}
local painel = carregar("src/client/PainelElevador").new(ui.NovaInstancia("ScreenGui"), {
	Navegacao=nav,
	ConfigurarElevador=function(_, alvo, h, entrada, saida, sentido)
		assert(alvo == atributos.IdUnidade)
		table.insert(pedidos, {h, entrada, saida, sentido})
		if #pedidos == 1 then coroutine.yield(); return true end
		return h == 3, "Sem espaço na coluna."
	end,
})
local function clicar(botao) botao:ObterInstancia().Activated:Fire() end
nav:Abrir("MenuPeca")
painel:Abrir(modelo)
painel:Atualizar()
assert(nav:Atual() == "Elevador" and not nav:Contem("MenuPeca") and painel._grupo.Size.X.Offset == 208)
assert(not painel._menos:EstaDisponivel())
local envio = coroutine.create(function() clicar(painel._mais) end)
assert(coroutine.resume(envio))
clicar(painel._faces.Entrada)
clicar(painel._faces.Saida)
clicar(painel._sentido)
assert(#pedidos == 1 and pedidos[1][1] == 3)
assert(coroutine.resume(envio))
assert(#pedidos == 2 and pedidos[2][1] == 3 and pedidos[2][2] == "+X" and pedidos[2][3] == "-Z" and pedidos[2][4] == "descer")
assert(nav:Atual() == "Elevador" and painel._sessao.Confirmado.Sentido == "descer")
clicar(painel._mais)
assert(#pedidos == 3 and painel._resposta.Text == "Sem espaço na coluna." and painel._altura.Text == "3 blocos")
nav:Voltar()
assert(not painel._grupo.Visible and painel._sessao == nil)
painel:Destruir(); nav:Destruir()
print("MENU_ELEVADOR_OK", "edição imediata, fila de ajustes, recusa e fechamento em GUI simulada")
