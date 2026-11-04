local Janela=require(script.Parent.PainelProgressao)
local Config=require(game:GetService("ReplicatedStorage").Shared.Configuracoes)
local Input=game:GetService("UserInputService")
local Deslizante=require(script.Parent.ControleDeslizante)
local Painel={}; Painel.__index=Painel
function Painel.new(pai,jogador,navegacao)
	local janela=Janela.new(pai,navegacao,"Configuracoes","Configurações",nil,nil,520,jogador)
	local self=setmetatable({_janela=janela,_grupo=janela._grupo,_jogador=jogador,_opcoes={},_deslizantes={},_rotulos={},_atalhos={},_rotulosAtalhos={},_conexoes={}},Painel)
	for i,opcao in Config.Opcoes do
		self._rotulos[opcao.Id]=janela:Texto(janela.Conteudo,opcao.Id,opcao.Nome,UDim2.fromOffset(0,(i-1)*64),UDim2.new(1,-162,0,54),17,true)
		if type(opcao.Valores[1])=="number" or opcao.Deslizante then
			local controle=Deslizante.new(janela.Conteudo,opcao.Id,opcao.Valores,janela.Cor,function(valor) jogador:SetAttribute(opcao.Id,valor) end)
			self._opcoes[opcao.Id],self._deslizantes[opcao.Id]=controle,controle
		else
		self._opcoes[opcao.Id]=janela:Botao(janela.Conteudo,opcao.Id,UDim2.new(1,-156,0,(i-1)*64+10),UDim2.fromOffset(148,36),function()
			local indice=table.find(opcao.Valores,Config.Obter(jogador,opcao.Id)) or 1
			jogador:SetAttribute(opcao.Id,opcao.Valores[indice%#opcao.Valores+1])
		end)
		end
		table.insert(self._conexoes,jogador:GetAttributeChangedSignal(opcao.Id):Connect(function() self:Atualizar() end))
	end
	local y=#Config.Opcoes*64+10
	self._aviso=janela:Texto(janela.Conteudo,"Atalhos","Teclado • Esc cancela a captura",UDim2.fromOffset(0,y),UDim2.new(1,-8,0,40),17,true)
	for i,acao in Config.Atalhos do
		local topo=y+46+(i-1)*48
		self._rotulosAtalhos[acao[1]]=janela:Texto(janela.Conteudo,"Acao_"..acao[1],acao[2],UDim2.fromOffset(0,topo),UDim2.new(1,-130,0,38),17)
		self._atalhos[acao[1]]=janela:Botao(janela.Conteudo,"Tecla_"..acao[1],UDim2.new(1,-120,0,topo),UDim2.fromOffset(112,36),function()
			self._captura=acao[1]; jogador:SetAttribute("CapturandoAtalho",true); self:Atualizar()
		end)
	end
	local fim=y+46+#Config.Atalhos*48
	self._nota=janela:Texto(janela.Conteudo,"Nota","Preferências desta sessão. Toque: aponte no cenário e use os botões de construção. Controle: Y alterna menus e mira; R2 seleciona ou coloca; B volta.",UDim2.fromOffset(0,fim),UDim2.new(1,-8,0,86),14)
	janela.Conteudo.CanvasSize=UDim2.fromOffset(0,fim+66)
	table.insert(self._conexoes,Input.InputBegan:Connect(function(entrada)
		if not self._captura or entrada.UserInputType~=Enum.UserInputType.Keyboard then return end
		local tecla=entrada.KeyCode.Name
		if tecla=="Escape" then self:_CancelarCaptura(); return end
		if not Config.ValidarTecla(jogador,self._captura,tecla) then self._aviso.Text="Tecla reservada ou já utilizada. Escolha outra."; return end
		jogador:SetAttribute("Atalho_"..self._captura,tecla); self:_CancelarCaptura()
	end))
	table.insert(self._conexoes,navegacao.Alterado:Connect(function()
		if not navegacao:Contem("Configuracoes") then
			self:_CancelarCaptura()
			for _,controle in self._deslizantes do controle:_Soltar() end
		end
	end))
	table.insert(self._conexoes,janela.Conteudo:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_Layout() end))
	self:_Layout(); self:Atualizar(); return self
end
function Painel:_Layout()
	local estreita=self._janela.Conteudo.AbsoluteSize.X<360
	local altura=estreita and 90 or 64
	for i,opcao in Config.Opcoes do
		local texto=self._rotulos[opcao.Id]
		texto.Position=UDim2.fromOffset(0,(i-1)*altura)
		texto.Size=UDim2.new(1,estreita and -8 or -162,0,estreita and 36 or 54)
		local b=self._opcoes[opcao.Id]:ObterInstancia()
		b.Position=estreita and UDim2.new(0,0,0,(i-1)*altura+40) or UDim2.new(1,-156,0,(i-1)*altura+10)
		b.Size=estreita and UDim2.new(1,-8,0,36) or UDim2.fromOffset(148,36)
	end
	local y=#Config.Opcoes*altura+10
	self._aviso.Position=UDim2.fromOffset(0,y)
	for i,acao in Config.Atalhos do
		local topo=y+46+(i-1)*48
		self._rotulosAtalhos[acao[1]].Position=UDim2.fromOffset(0,topo)
		self._atalhos[acao[1]]:ObterInstancia().Position=UDim2.new(1,-120,0,topo)
	end
	local fim=y+46+#Config.Atalhos*48
	self._nota.Position=UDim2.fromOffset(0,fim)
	self._janela.Conteudo.CanvasSize=UDim2.fromOffset(0,fim+94)
end
function Painel:_CancelarCaptura()
	local estavaCapturando=self._captura
	self._captura=nil
	-- A entrada capturada termina antes de liberar os demais ouvintes de teclado.
	if estavaCapturando then task.defer(function() self._jogador:SetAttribute("CapturandoAtalho",false) end) end
	self._aviso.Text="Teclado • Esc cancela a captura"; self:Atualizar()
end
function Painel:Atualizar()
	if self._destruido then return end
	self._janela:Atualizar()
	for _,opcao in Config.Opcoes do
		local valor=Config.Obter(self._jogador,opcao.Id)
		local texto=if type(valor)=="boolean" then (valor and "Ativado" or "Desativado") elseif opcao.Percentual then tostring(math.round(valor*100)).."%" else tostring(valor)..(opcao.Sufixo or "")
		if self._deslizantes[opcao.Id] then self._deslizantes[opcao.Id]:DefinirValor(valor,texto)
		else self._opcoes[opcao.Id]:ObterInstancia().Text=texto end
	end
	for original,botao in self._atalhos do
		botao:DefinirDisponivel(Input.KeyboardEnabled~=false)
		botao:ObterInstancia().Text=self._captura==original and "Pressione..." or Config.Tecla(self._jogador,original)
	end
end
function Painel:Destruir()
	if self._destruido then return end
	self._destruido=true; self._jogador:SetAttribute("CapturandoAtalho",false)
	for _,c in self._conexoes do c:Disconnect() end
	for _,controle in self._deslizantes do controle:Destruir() end
	self._janela:Destruir()
end
return Painel
