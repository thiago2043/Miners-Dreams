local R=game:GetService("ReplicatedStorage")
local U=require(R.Shared.Upgrades)
local Abreviar=require(R.Shared.AbreviarInteiro)
local Janela=require(script.Parent.PainelProgressao)
local Painel={}; Painel.__index=Painel
function Painel.new(pai,jogador,nav,rede)
	local janela=Janela.new(pai,nav,"Upgrades","Upgrades","U",nil,440,jogador)
	janela._grupo:FindFirstChildOfClass("UISizeConstraint").MaxSize=Vector2.new(460,440)
	local self=setmetatable({_janela=janela,_grupo=janela._grupo,_jogador=jogador,_rede=rede,_linhas={},_conexoes={}},Painel)
	for i,item in U.Itens do
		local y=(i-1)*88
		janela:Texto(janela.Conteudo,item.Id,item.Nome,UDim2.fromOffset(0,y),UDim2.new(1,-8,0,22),17,true)
		janela:Texto(janela.Conteudo,"Descricao",item.Descricao,UDim2.fromOffset(0,y+22),UDim2.new(1,-8,0,26),14)
		local estado=janela:Texto(janela.Conteudo,"Estado","",UDim2.fromOffset(0,y+50),UDim2.new(.48,-4,0,32),14)
		local botao=janela:Botao(janela.Conteudo,"Comprar_"..item.Id,UDim2.new(.48,0,0,y+50),UDim2.new(.52,-8,0,32),function() self:Comprar(item.Id) end)
		botao:ObterInstancia().TextSize=14
		self._linhas[item.Id]={Estado=estado,Botao=botao}
	end
	local y=#U.Itens*88
	self._velocidade=janela:Botao(janela.Conteudo,"Velocidade",UDim2.fromOffset(0,y),UDim2.new(1,-8,0,34),function()
		local maximo=jogador:GetAttribute("Upgrade_Motores") or 0
		self:_Enviar("Velocidade",((jogador:GetAttribute("VelocidadeMotores") or 0)+1)%(maximo+1))
	end)
	self._resposta=janela:Texto(janela.Conteudo,"Resposta","",UDim2.fromOffset(0,y+38),UDim2.new(1,-8,0,36),14)
	janela.Conteudo.CanvasSize=UDim2.fromOffset(0,y+78)
	for _,id in {"Dinheiro","Vidas","Reencarnacoes","Upgrade_Extracao","Upgrade_Fundicao","Upgrade_Motores","Upgrade_Calibracao","Upgrade_Expansao","VelocidadeMotores"} do
		table.insert(self._conexoes,jogador:GetAttributeChangedSignal(id):Connect(function() self:Atualizar() end))
	end
	self:Atualizar(); return self
end
function Painel:Comprar(id)
	return self:_Enviar("Comprar",id,self._jogador:GetAttribute("Upgrade_"..id),self._jogador:GetAttribute("Reencarnacoes"))
end
function Painel:_Enviar(metodo,...)
	if self._enviando or self._destruido then return end
	self._enviando=true; self:Atualizar()
	local ok,sucesso,msg=pcall(self._rede.fetch,self._rede,metodo,...)
	if self._destruido then return end
	self._enviando=false; self._resposta.Text=ok and type(msg)=="string" and msg or "Falha de comunicação. Tente novamente."
	self:Atualizar(); return ok and sucesso
end
function Painel:Atualizar()
	if self._destruido then return end
	self._janela:Atualizar()
	for id,linha in self._linhas do
		local nivel=self._jogador:GetAttribute("Upgrade_"..id)
		local item=U.Item(id)
		local pronto=U.Valido(nivel,id); nivel=pronto and nivel or 0
		local liberado=(self._jogador:GetAttribute("Reencarnacoes") or 0)>=item.Renascimentos
		local lado=U.TamanhosPlot[nivel+1]
		linha.Estado.Text=if id=="Expansao" then lado.." × "..lado.." × "..lado.." blocos • Permanente" else "Nível "..nivel.."/"..#item.Precos.." • +"..(nivel*U.PercentualPorNivel).."%"
		linha.Botao:DefinirDisponivel(pronto and liberado and nivel<#item.Precos and not self._enviando)
		local texto
		if self._enviando then texto="Aguarde..."
		elseif not pronto then texto="Carregando..."
		elseif not liberado then texto="Requer "..item.Renascimentos.." renascimento(s)"
		elseif nivel==#item.Precos then texto="Nível máximo"
		elseif id=="Expansao" then
			local proximo=U.TamanhosPlot[nivel+2]
			texto="Expandir: "..proximo.." × "..proximo.." × "..proximo.." • $"..Abreviar(item.Precos[nivel+1])
		else texto="Comprar • $"..Abreviar(item.Precos[nivel+1]) end
		linha.Botao:ObterInstancia().Text=texto
	end
	self._velocidade:DefinirDisponivel(not self._enviando and (self._jogador:GetAttribute("Upgrade_Motores") or 0)>0)
	self._velocidade:ObterInstancia().Text="Velocidade das esteiras: "..(100+(self._jogador:GetAttribute("VelocidadeMotores") or 0)*U.PercentualPorNivel).."% • alternar"
end
function Painel:Destruir()
	self._destruido=true; for _,c in self._conexoes do c:Disconnect() end; self._janela:Destruir()
end
return Painel
