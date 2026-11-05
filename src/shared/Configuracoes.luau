local C={}
local quantidades={}
for n=0,5000,100 do table.insert(quantidades,n) end
C.Opcoes={
	{Id="LimiteMineriosVisiveis",Nome="Minérios visíveis por plot",Valores=quantidades,Padrao=5000},
	{Id="MostrarValoresMinerios",Nome="Valores dos minérios",Valores={"Sempre","Perto","Oculto"},Padrao="Sempre"},
	{Id="DistanciaValores",Nome="Distância dos valores",Valores={15,30,60},Padrao=30,Sufixo=" studs"},
	{Id="TamanhoValores",Nome="Texto dos valores",Valores={12,16,20,24},Padrao=16},
	{Id="AnimarVendaMinerios",Nome="Animação de venda",Valores={true,false},Padrao=true},
	{Id="EfeitosMaquinas",Nome="Efeitos das máquinas",Valores={"Completo","Reduzido","Oculto"},Padrao="Completo"},
	{Id="MineriosOutrasPlots",Nome="Minérios de outras plots",Valores={true,false},Padrao=true},
	{Id="TransparenciaPrevia",Nome="Transparência da prévia",Valores={.3,.55,.8},Padrao=.55,Percentual=true},
	{Id="IntensidadeGrade",Nome="Intensidade da grade",Valores={"Suave","Normal","Forte"},Padrao="Normal",Deslizante=true},
	{Id="EscalaInterface",Nome="Escala da interface",Valores={.8,.9,1,1.1,1.2},Padrao=1,Percentual=true},
	{Id="ConfirmarVenda",Nome="Confirmar venda de peças",Valores={"Nunca","Várias peças","Sempre"},Padrao="Várias peças"},
	{Id="ConfirmarRenascimento",Nome="Confirmar renascimento",Valores={true,false},Padrao=true},
	{Id="IntensidadeSetas",Nome="Setas de colocação",Valores={"Suave","Normal","Forte"},Padrao="Forte",Deslizante=true},
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
function C.Obter(jogador,id)
  local valor=jogador and jogador:GetAttribute(id)
  if id=="MostrarValoresMinerios" and type(valor)=="boolean" then return valor and "Sempre" or "Oculto" end
  for _,opcao in C.Opcoes do if opcao.Id==id then
    if table.find(opcao.Valores,valor) then return valor end
    return opcao.Padrao
  end end
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
function C.ValidarTecla(jogador,original,nova)
  if type(nova)~="string" then return false end
  local movimento=original=="W" or original=="A" or original=="S" or original=="D"
  if movimento then
    if not (nova:match("^[A-Z]$") or table.find({"Up","Down","Left","Right"},nova)) then return false end
  else
    local base=nova:gsub("^Ctrl%+",""):gsub("^Shift%+",""):gsub("^Alt%+",""):gsub("^Win%+","")
    if not base:match("^[A-Z]$") then return false end
  end
  for _,acao in C.Atalhos do if acao[1]~=original and C.Tecla(jogador,acao[1])==nova then return false end end
  return true
end
return C
