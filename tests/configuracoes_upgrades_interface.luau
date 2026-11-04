local r=require("@lune/roblox")
local s=require("./suporte/interface")
local input=s.Sinal()
local carregar=require("./suporte/carregador")({Instance={new=s.NovaInstancia},Enum=r.Enum,Color3=r.Color3,
	Vector2=r.Vector2,UDim=r.UDim,UDim2=r.UDim2,task=require("@lune/task")},{UserInputService={InputBegan=input,InputChanged=s.Sinal(),InputEnded=s.Sinal(),WindowFocusReleased=s.Sinal()}})
local nav=carregar("src/client/NavegacaoEstados").new()
local pai=s.NovaInstancia("ScreenGui")
local atributos,sinais={},{}
local jogador={}
function jogador:GetAttribute(id) return atributos[id] end
function jogador:GetAttributeChangedSignal(id) sinais[id]=sinais[id] or s.Sinal(); return sinais[id] end
function jogador:SetAttribute(id,v) atributos[id]=v; self:GetAttributeChangedSignal(id):Fire() end
local C=carregar("src/shared/Configuracoes")
assert(C.Obter(jogador,"AnimarVendaMinerios")); jogador:SetAttribute("AnimarVendaMinerios",false); assert(not C.Obter(jogador,"AnimarVendaMinerios"))
local painel=carregar("src/client/PainelConfiguracoes").new(pai,jogador,nav)
nav:Abrir("Configuracoes"); painel:Atualizar()
painel._atalhos.R:ObterInstancia().Activated:Fire()
input:Fire({UserInputType=r.Enum.UserInputType.Keyboard,KeyCode=r.Enum.KeyCode.E})
assert(atributos.Atalho_R==nil and atributos.CapturandoAtalho)
input:Fire({UserInputType=r.Enum.UserInputType.Keyboard,KeyCode=r.Enum.KeyCode.J})
require("@lune/task").wait()
assert(atributos.Atalho_R=="J" and not atributos.CapturandoAtalho)
assert(C.ResolverTecla(jogador,r.Enum.KeyCode.J).Name=="R" and C.ResolverTecla(jogador,r.Enum.KeyCode.R).Name=="Unknown")
assert(not C.ValidarTecla(jogador,"R","Q") and not C.ValidarTecla(jogador,"R","W"))
local confirmacao=carregar("src/client/Confirmacao").new(pai,jogador,nav)
local execucoes=0
local function acao() execucoes+=1 end
confirmacao:Pedir("Venda",1,acao); assert(execucoes==1)
confirmacao:Pedir("Venda",2,acao); assert(execucoes==1 and nav:Atual()=="Confirmacao")
nav:Voltar(); assert(execucoes==1 and not confirmacao._fundo.Visible)
confirmacao:Pedir("Renascimento",1,acao); confirmacao._sim:ObterInstancia().Activated:Fire(); assert(execucoes==2)
confirmacao._sim:ObterInstancia().Activated:Fire(); assert(execucoes==2,"Confirmacao nao pode repetir uma operacao.")
jogador:SetAttribute("ConfirmarRenascimento",false); confirmacao:Pedir("Renascimento",1,acao); assert(execucoes==3)
jogador:SetAttribute("ConfirmarVenda","Nunca")
confirmacao:Pedir("LimparPlot",0,acao,"Devolver todas ao inventário?")
assert(execucoes==3 and confirmacao._fundo.Visible,"Limpar a plot sempre exige confirmação.")
nav:Voltar(); assert(execucoes==3)
confirmacao:Pedir("LimparPlot",0,acao); confirmacao._sim:ObterInstancia().Activated:Fire()
assert(execucoes==4)
local U=carregar("src/shared/Upgrades")
for _,i in U.Itens do jogador:SetAttribute("Upgrade_"..i.Id,0) end
jogador:SetAttribute("Reencarnacoes",1)
local pedidos=0
local rede={fetch=function(_,metodo,id,nivel,ciclo)
	pedidos+=1; assert(metodo=="Comprar" and id=="Extracao" and nivel==0 and ciclo==1)
	jogador:SetAttribute("Upgrade_Extracao",1); return true,"Adquirido."
end}
local upgrades=carregar("src/client/PainelUpgrades").new(pai,jogador,nav,rede)
assert(not upgrades._linhas.Calibracao.Botao:ObterInstancia().Active and not upgrades._linhas.Expansao.Botao:ObterInstancia().Active)
assert(upgrades._linhas.Extracao.Botao:ObterInstancia().Active)
upgrades._linhas.Extracao.Botao:ObterInstancia().Activated:Fire()
assert(pedidos==1 and upgrades._linhas.Extracao.Estado.Text:find("20%%"))
jogador:SetAttribute("Upgrade_Extracao",5); assert(not upgrades._linhas.Extracao.Botao:ObterInstancia().Active)
jogador:SetAttribute("Reencarnacoes",5)
assert(upgrades._linhas.Calibracao.Botao:ObterInstancia().Active and upgrades._linhas.Expansao.Botao:ObterInstancia().Active)
assert(upgrades._linhas.Expansao.Estado.Text:find("12 × 12 × 12",1,true))
upgrades:Destruir(); painel:Destruir(); confirmacao:Destruir()
for _,signal in sinais do for _,c in signal.conexoes do assert(not c.ativa) end end
print("CONFIG_UPGRADES_INTERFACE_OK: todas as preferencias, remapeamento sem conflitos, confirmacoes cancelaveis/unicas, compra e limpeza.")
