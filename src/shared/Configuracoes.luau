local C={}
local Beta = require(script.Parent.RecompensasBeta)
local quantidades={}
for n=0,5000,100 do table.insert(quantidades,n) end
C.Opcoes={
{Id="LimiteMineriosVisiveis",Nome="Minérios visíveis por plot",Valores={0,5000},Passo=1,Padrao=5000},
{Id="MostrarValoresMinerios",Nome="Valores dos minérios",Valores={"Sempre","Perto","Oculto"},Padrao="Sempre"},
{Id="DistanciaValores",Nome="Distância dos valores",Valores={15,30,60},Passo=1,Padrao=30,Sufixo=" studs"},
{Id="TamanhoValores",Nome="Texto dos valores",Valores={12,16,20,24},Passo=1,Padrao=16},
{Id="AnimarVendaMinerios",Nome="Animação de venda",Valores={true,false},Padrao=true},
{Id="EfeitosMaquinas",Nome="Efeitos das máquinas",Valores={"Completo","Reduzido","Oculto"},Padrao="Completo"},
{Id="MineriosOutrasPlots",Nome="Minérios de outras plots",Valores={true,false},Padrao=true},
{Id="TransparenciaPrevia",Nome="Transparência da prévia",Valores={.1,.3,.55,.8,.95},Passo=.01,Padrao=.55,Percentual=true},
{Id="TransparenciaForaAltura",Nome="Transparência fora da altura",Valores={0,.8,.95},Passo=.01,Padrao=.8,Percentual=true},
{Id="IntensidadeGrade",Nome="Intensidade da grade",Valores={0,.5,1},Passo=.01,Padrao=.5,Percentual=true,Deslizante=true},
{Id="EscalaInterface",Nome="Escala da interface",Valores={.5,.8,.9,1,1.1,1.2,1.5},Passo=.01,Padrao=1,Percentual=true},
	{ Id = "LODPlots", Nome = "Otimização de plots distantes (LOD)", Valores = { "Médio", "Máximo", "Desativado", "Baixo" }, Padrao = "Médio" },
{Id="ConfirmarVenda",Nome="Confirmar venda de peças",Valores={"Nunca","Várias peças","Sempre"},Padrao="Várias peças"},
{Id="ConfirmarRenascimento",Nome="Confirmar renascimento",Valores={true,false},Padrao=true},
{Id="IntensidadeSetas",Nome="Setas de colocação",Valores={0,.5,1},Passo=.01,Padrao=1,Percentual=true,Deslizante=true},
{Id="TemaBeta",Nome="Tema do teste beta",Valores={Beta.Padrao,Beta.Participacao,Beta.E308},Padrao=Beta.Padrao},
}
C.Atalhos={{"W","Andar para frente"},{"S","Andar para trás"},{"A","Andar para a esquerda"},{"D","Andar para a direita"},{"Q","Cancelar / voltar"},
	{"E","Inventário"},{"F","Loja"},{"B","Blueprints"},{"U","Upgrades"},{"P","Prestígio"},
{"Z","Recolher"},{"X","Mover / inclinar"},{"C","Copiar"},{"V","Vender"},{"R","Girar"},{"T","Altura"},
{"Desfazer","Desfazer na plot","Ctrl+Z"},{"Refazer","Refazer na plot","Ctrl+Shift+Z"},
{"CopiarPlot","Copiar seleção (plot)","Ctrl+C"},{"ColarPlot","Colar na plot","Ctrl+V"},
{"HistoricoPlot","Histórico de cópia","Shift+V"}}
local Input=game:GetService("UserInputService")
local modificadores={
  LeftControl=true,RightControl=true,LeftShift=true,RightShift=true,
  LeftAlt=true,RightAlt=true,LeftSuper=true,RightSuper=true,
}
function C.EhModificador(tecla)
  return tecla~=nil and modificadores[tecla.Name]==true
end
function C.CombinacaoTecla(tecla)
  if not tecla or C.EhModificador(tecla) then return nil end
  local prefixo=""
  if Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl) then prefixo..="Ctrl+" end
  if Input:IsKeyDown(Enum.KeyCode.LeftShift) or Input:IsKeyDown(Enum.KeyCode.RightShift) then prefixo..="Shift+" end
  if Input:IsKeyDown(Enum.KeyCode.LeftAlt) or Input:IsKeyDown(Enum.KeyCode.RightAlt) then prefixo..="Alt+" end
  if Input:IsKeyDown(Enum.KeyCode.LeftSuper) or Input:IsKeyDown(Enum.KeyCode.RightSuper) then prefixo..="Win+" end
  return prefixo..tecla.Name
end
function C.InterpolarIntensidade(valor,suave,normal,forte)
local t=if valor=="Suave" then 0 elseif valor=="Normal" then .5 elseif valor=="Forte" then 1 elseif type(valor)=="number" then math.clamp(valor,0,1) else .5
local function interp(s,n,f)
if type(n)=="number" then
if t<=.5 then return s+(n-s)*(t/.5) end
return n+(f-n)*((t-.5)/.5)
elseif type(n)=="table" then
local res={}
for k,vn in n do res[k]=interp(s and s[k] or vn,vn,f and f[k] or vn) end
return res
end
return n
end
return interp(suave,normal,forte)
end
function C.TabelaIntensidade(tabela)
return setmetatable(tabela,{
__index=function(self,chave)
return C.InterpolarIntensidade(chave,rawget(self,"Suave"),rawget(self,"Normal"),rawget(self,"Forte"))
end,
})
end
function C.NormalizarOpcao(id,valor)
if id=="MostrarValoresMinerios" and type(valor)=="boolean" then valor=valor and "Sempre" or "Oculto" end
if (id=="IntensidadeGrade" or id=="IntensidadeSetas") and type(valor)=="string" then
valor=if valor=="Suave" then 0 elseif valor=="Normal" then .5 elseif valor=="Forte" then 1 else nil
end
for _,opcao in C.Opcoes do
if opcao.Id==id then
if type(opcao.Valores[1])=="number" then
if type(valor)~="number" or valor~=valor then return nil,opcao end
local minimo,maximo=opcao.Valores[1],opcao.Valores[#opcao.Valores]
if valor<minimo-1e-6 or valor>maximo+1e-6 then return nil,opcao end
local passo=opcao.Passo or (if minimo%1==0 and maximo%1==0 then 1 else .01)
local ajustado=math.clamp(math.round(valor/passo)*passo,minimo,maximo)
if passo<1 then
ajustado=tonumber(string.format("%.4f",ajustado)) or ajustado
else
ajustado=math.round(ajustado)
end
return ajustado,opcao
end
for _,permitido in opcao.Valores do
if permitido==valor then return permitido,opcao end
end
return nil,opcao
end
end
return nil,nil
end
function C.Obter(jogador,id)
  local valor=jogador and jogador:GetAttribute(id)
  local normalizado,opcao=C.NormalizarOpcao(id,valor)
  if normalizado~=nil then return normalizado end
  return opcao and opcao.Padrao or nil
end
function C.Tecla(jogador,original)
  local atributo=jogador and jogador:GetAttribute("Atalho_"..original)
  if type(atributo)=="string" and atributo~="" then return atributo end
  for _,acao in C.Atalhos do if acao[1]==original then return acao[3] or acao[1] end end
  return original
end
function C.ResolverAtalho(jogador,tecla)
  local combinacao=C.CombinacaoTecla(tecla)
  if not combinacao then return nil end
  for _,acao in C.Atalhos do
    if acao[3] and combinacao==C.Tecla(jogador,acao[1]) then return acao[1] end
  end
  return nil
end
function C.ResolverTecla(jogador,tecla)
  if not tecla then return tecla end
  local combinacao=C.CombinacaoTecla(tecla) or tecla.Name
  for _,acao in C.Atalhos do
    if not acao[3] and combinacao==C.Tecla(jogador,acao[1]) then return Enum.KeyCode[acao[1]] end
  end
  for _,acao in C.Atalhos do
    if combinacao==C.Tecla(jogador,acao[1]) or (not acao[3] and tecla.Name==acao[1]) then return Enum.KeyCode.Unknown end
  end
  return tecla
end
function C.FormatoTeclaValido(original,nova)
  if type(original)~="string" or type(nova)~="string" then return false end
  local existe=false
  for _,acao in C.Atalhos do
    if acao[1]==original then existe=true; break end
  end
  if not existe then return false end
  local movimento=original=="W" or original=="A" or original=="S" or original=="D"
  if movimento then
    return nova:match("^[A-Z]$")~=nil or table.find({"Up","Down","Left","Right"},nova)~=nil
  end
  local base=nova:gsub("^Ctrl%+",""):gsub("^Shift%+",""):gsub("^Alt%+",""):gsub("^Win%+","")
  return base:match("^[A-Z]$")~=nil
end
function C.ValidarTecla(jogador,original,nova)
  if not C.FormatoTeclaValido(original,nova) then return false end
  for _,acao in C.Atalhos do if acao[1]~=original and C.Tecla(jogador,acao[1])==nova then return false end end
  return true
end
return C
