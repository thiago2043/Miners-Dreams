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
	["src/client/AnimacaoInterface"]={DefinirVisivel=function(g, visivel) g.Visible=visivel end},
})
local nav = carregar("src/client/NavegacaoEstados").new()
local atributos = {AlturaBlocos=2, FaceEntrada="+Z", FaceSaida="+X", Sentido="subir"}
local modelo = {GetAttribute=function(_, nome) return atributos[nome] end}
local tentativas = 0
local painel = carregar("src/client/PainelElevador").new(ui.NovaInstancia("ScreenGui"), {}, {
	Navegacao=nav,
	ConfigurarElevador=function(_, alvo, h, entrada, saida, sentido)
		assert(alvo == modelo and h == 3 and entrada == "+X" and saida == "-Z" and sentido == "descer")
		tentativas += 1
		return tentativas == 2, "A coluna está ocupada."
	end,
})
local function clicar(botao) botao:ObterInstancia().Activated:Fire() end
nav:Abrir("MenuPeca")
painel:Abrir(modelo)
painel:Atualizar()
assert(nav:Atual() == "Elevador" and not nav:Contem("MenuPeca") and painel._grupo.Visible)
assert(not painel._menos:EstaDisponivel())
clicar(painel._mais)
clicar(painel._faces.Entrada)
clicar(painel._faces.Saida)
clicar(painel._sentido)
clicar(painel._aplicar)
assert(nav:Atual() == "Elevador" and painel._resposta.Text == "A coluna está ocupada.")
clicar(painel._aplicar)
painel:Atualizar()
assert(nav:Atual() == nil and not painel._grupo.Visible and tentativas == 2)
painel:Destruir(); nav:Destruir()
print("MENU_ELEVADOR_OK", "altura, faces, sentido, recusa e confirmação em GUI simulada")
