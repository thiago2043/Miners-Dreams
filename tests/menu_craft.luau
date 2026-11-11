local r = require("@lune/roblox")
local ui = require("./suporte/interface")
local ignorados = {}
for _, nome in {"PainelPecas", "PainelBlueprints", "PainelConfiguracoes", "PainelUpgrades",
	"PainelClassificacao", "PainelTutorial", "PainelAdministracao", "PainelHistoricoCopia", "Confirmacao",
	"PainelPrestigio", "PainelMoedas", "PreviaConstrucao", "GradeTerreno", "SetasTransporte", "SelecaoPecas"} do
	ignorados["src/client/"..nome] = {}
end
ignorados["Packages/Networker"] = {}
ignorados["src/client/GerenciadorJanelas"] = {Registrar=function() end, TrazerParaFrente=function() end}
ignorados["src/client/AnimacaoInterface"] = {DefinirVisivel=function(g, visivel) g.Visible=visivel end}
local function novo(classe)
	local objeto = ui.NovaInstancia(classe)
	local atributos = {}
	function objeto:SetAttribute(k,v) atributos[k]=v end
	function objeto:GetAttribute(k) return atributos[k] end
	return objeto
end
local carregar = require("./suporte/carregador")({Instance={new=novo}, Enum=r.Enum,
	Vector2=r.Vector2, Vector3=r.Vector3, CFrame=r.CFrame, Color3=r.Color3,
	ColorSequence=r.ColorSequence, ColorSequenceKeypoint=r.ColorSequenceKeypoint,
	UDim=r.UDim, UDim2=r.UDim2, typeof=function(v) return if type(v)=="table" and v.ClassName then "Instance" else typeof(v) end},
	{ContextActionService={}, GuiService={}, UserInputService={GetFocusedTextBox=function() return nil end, IsKeyDown=function() return false end}}, ignorados)
local Navegacao = carregar("src/client/NavegacaoEstados")
local Controlador = carregar("src/client/ControladorConstrucao")
local Interface = carregar("src/client/InterfaceJogo")
local PainelCraft = carregar("src/client/PainelCraft")
local Catalogo = carregar("src/shared/CatalogoMaquinas")
local atributos = {Administrador=false}
local jogador = {GetAttribute=function(_,id) return atributos[id] end, GetAttributeChangedSignal=function() return ui.Sinal() end}
local nav = Navegacao.new()
local c = setmetatable({_jogador=jogador, Navegacao=nav}, Controlador)
local interface = setmetatable({_jogador=jogador, _construcao=c, _conexoes={}, _interface=novo("ScreenGui")}, Interface)
interface:_CriarMenuAbas()
local botoes = interface._botoesAbas
local craft, blueprint = botoes.Craft:ObterInstancia(), botoes.Blueprints:ObterInstancia()
assert(craft.Parent==interface._menuAbas and craft.LayoutOrder==5)
assert(blueprint.Parent==interface._menuDireito)
assert(blueprint.LayoutOrder==botoes.Configuracoes:ObterInstancia().LayoutOrder+1)
assert(#craft:FindFirstChild("Icone"):FindFirstChild("Simbolo"):GetChildren()>0)
local confirmar, chamadas = nil, 0
local painel = PainelCraft.new(interface._interface, jogador, nav, {
	fetch = function(_, acao, id, ciclo, estoque)
		assert(acao=="Fabricar" and id=="EscavadoraEstratos" and ciclo==6)
		assert(#estoque==#Catalogo[id].Receita and estoque[1].Quantidade==1)
		chamadas += 1
		return true, "Peça fabricada."
	end,
}, {
	Pedir = function(_, tipo, quantidade, callback, texto)
		assert(tipo=="Craft" and quantidade==6 and texto:find("consumidas",1,true))
		confirmar = callback
	end,
})
nav.Alterado:Connect(function() painel:Atualizar() end)
craft.Activated:Fire()
assert(nav:Atual()=="Craft" and painel._grupo.Visible)
assert(#painel._listas.Soltador.Linhas==10 and #painel._listas.Vendedor.Linhas==10 and #painel._listas.Modificador.Linhas==30)
painel._listas.Soltador.Linhas[7].Botao:ObterInstancia().Activated:Fire()
assert(painel._id=="ExtratoraCordilheira")
painel._ingredientes[1]:ObterInstancia().Activated:Fire()
assert(painel._id=="EscavadoraEstratos" and not painel._fabricar:EstaDisponivel())
assert(painel._raridade.Text == "Forjada")
painel._voltar:ObterInstancia().Activated:Fire()
assert(painel._id=="ExtratoraCordilheira")
painel._ingredientes[1]:ObterInstancia().Activated:Fire()
for _, id in Catalogo.EscavadoraEstratos.Receita do
	atributos["Inventario_"..id] = 1
	atributos["ConfiguracaoInventario_"..id] = "{}"
end
atributos.Reencarnacoes = 6
painel:Atualizar()
assert(painel._fabricar:EstaDisponivel())
painel._fabricar:ObterInstancia().Activated:Fire()
assert(chamadas==0 and confirmar)
confirmar()
assert(chamadas==1 and painel._resposta.Text=="Peça fabricada.")
for _, tipo in {r.Enum.UserInputType.MouseButton1, r.Enum.UserInputType.MouseButton3} do
	c:ProcessarEntrada({UserInputType=tipo, KeyCode=r.Enum.KeyCode.Unknown}, false)
	assert(nav:Atual()=="Craft" and not c._modoSelecao and not c._previa)
end
c:ProcessarEntrada({UserInputType=r.Enum.UserInputType.Keyboard, KeyCode=r.Enum.KeyCode.Q}, false)
assert(nav:Atual()==nil and not painel._grupo.Visible)
craft.Activated:Fire(); painel._janela._fechar:ObterInstancia().Activated:Fire()
assert(nav:Atual()==nil)
blueprint.Activated:Fire(); assert(nav:Atual()=="Blueprints")
craft.Activated:Fire(); assert(nav:Atual()=="Craft")
botoes.Tutorial:ObterInstancia().MouseEnter:Fire()
assert(interface._dicaAba.Position.Y.Offset==-99)
atributos.Administrador=true
botoes.Tutorial:ObterInstancia().SelectionGained:Fire()
assert(interface._dicaAba.Position.Y.Offset==-132)
painel:Destruir(); nav:Destruir()
for _, botao in botoes do botao:Destruir() end
print("MENU_CRAFT_OK: atalhos, 50 receitas, navegação entre ingredientes, confirmação e resposta; GUI simulada.")
