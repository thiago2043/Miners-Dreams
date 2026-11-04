local r=require("@lune/roblox")
local suporte=require("./suporte/interface")
local carregar=require("./suporte/carregador")({Instance={new=suporte.NovaInstancia},Enum=r.Enum,Color3=r.Color3,
	Vector2=r.Vector2,UDim=r.UDim,UDim2=r.UDim2,task=require("@lune/task")},{UserInputService={InputBegan=suporte.Sinal(),InputChanged=suporte.Sinal(),InputEnded=suporte.Sinal(),WindowFocusReleased=suporte.Sinal()}})
local nav=carregar("src/client/NavegacaoEstados").new()
local pai=suporte.NovaInstancia("ScreenGui")
local Janela=carregar("src/client/PainelProgressao")
local Config=carregar("src/client/PainelConfiguracoes")
local Blueprint=carregar("src/client/PainelBlueprints")
local atributos,sinais={},{}
local jogador={}
function jogador:GetAttribute(id) return atributos[id] end
function jogador:GetAttributeChangedSignal(id) sinais[id]=sinais[id] or suporte.Sinal(); return sinais[id] end
function jogador:SetAttribute(id,valor) atributos[id]=valor; self:GetAttributeChangedSignal(id):Fire() end
local config=Config.new(pai,jogador,nav)
nav:Abrir("Configuracoes"); config:Atualizar(); assert(config._grupo.Visible)
for _,opcao in carregar("src/shared/Configuracoes").Opcoes do
	local id,botao=opcao.Id,config._opcoes[opcao.Id]
	if config._deslizantes[id] then botao:_Escolher((table.find(opcao.Valores,opcao.Padrao) or 1)%#opcao.Valores+1) else botao:ObterInstancia().Activated:Fire() end
	assert(atributos[id]~=nil and atributos[id]~=opcao.Padrao)
end
config._janela._fechar:ObterInstancia().Activated:Fire(); config:Atualizar(); assert(not config._grupo.Visible)
local upgrades=Janela.new(pai,nav,"Upgrades","Upgrades","U","Nenhum upgrade disponível.")
nav:Abrir("Upgrades"); upgrades:Atualizar()
assert(upgrades._grupo.Visible and upgrades._mensagem.Text=="Nenhum upgrade disponível.")
assert(#upgrades._botoes==1,"Nao deve haver compras sem regras definidas.")
nav:Voltar(); upgrades:Atualizar(); assert(not upgrades._grupo.Visible)
local lista,resultado,erroLista={},nil,false
local chamadas=0
local c={Navegacao=nav}
function c:ListarBlueprints() chamadas+=1; return not erroLista,"Falha ao carregar",lista end
function c:ObterResultadoBlueprint() local atual=resultado; resultado=nil; return atual end
function c:IniciarCriacaoBlueprint(nome) assert(nome=="Minha fábrica"); self.criou=true; return false,"Teste de recusa" end
function c:ColocarBlueprint(id) self.colocou=id; return true end
local bp=Blueprint.new(pai,c)
nav:Abrir("Blueprints"); bp:Atualizar()
assert(bp._vazio.Visible and #bp._listaBlueprints==0 and bp._janela._titulo.Parent==bp._grupo)
bp._nome.Text="Minha fábrica"; bp._botaoCriar:ObterInstancia().Activated:Fire()
assert(c.criou and bp._status.Text=="Teste de recusa")
lista={{Id="b1",Nome="Minha fábrica",Quantidade=8},{Id="b2",Nome="Linha curta",Quantidade=2}}
resultado={Sucesso=true,Mensagem="Blueprint salvo."}; bp:Atualizar()
assert(#bp._listaBlueprints==2 and not bp._vazio.Visible and bp._nome.Text=="" and bp._status.Text=="Blueprint salvo.")
bp._listaBlueprints[2]:ObterInstancia().Activated:Fire(); assert(c.colocou=="b2")
bp:Atualizar(); assert(chamadas==2,"Nao repetir pedidos a cada atualizacao da GUI.")
local antigo=bp._listaBlueprints[1]
erroLista=true; nav:Fechar("Blueprints"); bp:Atualizar(); nav:Abrir("Blueprints"); bp:Atualizar()
assert(bp._vazio.Visible and bp._vazio.Text=="Falha ao carregar" and #bp._listaBlueprints==0)
antigo:ObterInstancia().Activated:Fire(); assert(c.colocou=="b2")
local botoes=table.clone(bp._botoes)
bp:Destruir(); bp:Destruir(); upgrades:Destruir(); config:Destruir()
for _,b in botoes do assert(b._conexao.ativa==false) end
for _,s in sinais do for _,conexao in s.conexoes do assert(not conexao.ativa) end end
print("PAINEIS_CENTRAIS_OK: blueprints vazios/salvos/erros/colocacao, preferencias imediatas, upgrades sem compra, navegacao e limpeza.")
