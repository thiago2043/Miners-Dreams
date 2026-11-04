local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Gui=game:GetService("GuiService")
local CAS=game:GetService("ContextActionService")
local Config=require(game:GetService("ReplicatedStorage").Shared.Configuracoes)
local Bloco=require(game:GetService("ReplicatedStorage").Shared.Medidas).Bloco
local Botao=require(script.Parent.Botao)
local Controles={}; Controles.__index=Controles
local clique={UserInputType=Enum.UserInputType.MouseButton1,KeyCode=Enum.KeyCode.Unknown}
local direcoes={W=Vector3.new(0,0,-1),S=Vector3.new(0,0,1),A=Vector3.new(-1,0,0),D=Vector3.new(1,0,0)}
local acoes={
	{"Confirmar","R2",Enum.KeyCode.ButtonR2}, {"Linha / área","L2",Enum.KeyCode.ButtonL2},
	{"Girar Y","R1",Enum.KeyCode.ButtonR1},{"Girar X","L1",Enum.KeyCode.ButtonL1},
	{"Girar Z","X",Enum.KeyCode.ButtonX},{"Subir","↑",Enum.KeyCode.DPadUp},
	{"Descer","↓",Enum.KeyCode.DPadDown},{"Voltar","B",Enum.KeyCode.ButtonB},
}

function Controles.new(jogador,construcao,interface)
	local self=setmetatable({_jogador=jogador,_c=construcao,_interface=interface,_conexoes={},_botoes={}},Controles)
	self._tipo=Input:GetLastInputType()
	self._gui=Instance.new("ScreenGui")
	self._gui.Name,self._gui.ResetOnSpawn="ControlesConstrucao",false
	self._gui.IgnoreGuiInset=true
	self._gui.Parent=jogador:WaitForChild("PlayerGui")
	self._barra=Instance.new("Frame")
	self._barra.BackgroundTransparency,self._barra.AnchorPoint=1,Vector2.new(.5,1)
	self._barra.Position,self._barra.Size=UDim2.new(.5,0,1,-130),UDim2.fromOffset(332,100)
	self._barra.Parent=self._gui
	self._instrucao=Instance.new("TextLabel")
	self._instrucao.Position,self._instrucao.Size=UDim2.fromOffset(0,-30),UDim2.new(1,0,0,26)
	self._instrucao.BackgroundTransparency,self._instrucao.TextSize=1,15
	self._instrucao.TextColor3,self._instrucao.TextStrokeTransparency=Color3.new(1,1,1),.35
	self._instrucao.Font,self._instrucao.Parent=Enum.Font.SourceSansBold,self._barra
	for i,item in acoes do
		local b=Botao.new(self._barra,item[1],function() self:Acao(item[1]) end)
		local instancia=b:ObterInstancia()
		instancia.Position=UDim2.fromOffset(((i-1)%4)*84,math.floor((i-1)/4)*52)
		instancia.Size,instancia.BackgroundColor3=UDim2.fromOffset(80,48),Color3.fromRGB(24,32,40)
		instancia.TextColor3,instancia.Font,instancia.TextSize=Color3.new(1,1,1),Enum.Font.SourceSansBold,15
		instancia.TextWrapped,instancia.BorderSizePixel=true,0
		local canto=Instance.new("UICorner"); canto.CornerRadius,canto.Parent=UDim.new(0,7),instancia
		b:DefinirDisponivel(true); self._botoes[item[1]]=b
		CAS:BindAction("Fabrica_"..item[1],function(_,estado)
			if estado~=Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
			if Input:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
			if item[1]~="Voltar" and (Gui.SelectedObject or Input:GetFocusedTextBox()) then return Enum.ContextActionResult.Pass end
			if not self:Acao(item[1]) then return Enum.ContextActionResult.Pass end
			return Enum.ContextActionResult.Sink
		end,false,item[3])
	end
	self._mira=Instance.new("TextLabel")
	self._mira.Text,self._mira.TextSize,self._mira.TextColor3="+",26,Color3.new(1,1,1)
	self._mira.TextStrokeTransparency,self._mira.BackgroundTransparency=.3,1
	self._mira.AnchorPoint,self._mira.Position,self._mira.Size=Vector2.new(.5,.5),UDim2.fromScale(.5,.5),UDim2.fromOffset(28,28)
	self._mira.Parent=self._gui
	local menu=Botao.new(self._gui,"Menus",function() self:AlternarFoco() end)
	self._menu=menu
	local b=menu:ObterInstancia()
	b.AnchorPoint,b.Position,b.Size=Vector2.new(.5,0),UDim2.new(.5,0,0,48),UDim2.fromOffset(120,44)
	b.Text,b.BackgroundColor3,b.TextColor3,b.TextSize="Y • Menus",Color3.fromRGB(24,32,40),Color3.new(1,1,1),17
	menu:DefinirDisponivel(true)
	CAS:BindAction("Fabrica_Menus",function(_,estado)
		if estado==Enum.UserInputState.Begin then self:AlternarFoco() end
		return Enum.ContextActionResult.Sink
	end,false,Enum.KeyCode.ButtonY)
	construcao._ponteiro=function() return self:Ponteiro() end
	table.insert(self._conexoes,Input.LastInputTypeChanged:Connect(function(tipo)
		self._tipo=tipo; self._toque=nil; self:Atualizar()
	end))
	table.insert(self._conexoes,Input.TouchTapInWorld:Connect(function(posicao,processado)
		if processado or Input:GetFocusedTextBox() then return end
		self._tipo=Enum.UserInputType.Touch
		self._toque=posicao
		construcao:Atualizar(0)
		if construcao._arrasteSelecao then
			construcao:_AtualizarArrasteSelecao(posicao)
		elseif not construcao._previa and construcao:_EncontrarTerreno(true) then
			if construcao:_MaquinaSobMouse() then self:Acao("Confirmar")
			else
				construcao.Navegacao:Fechar("MenuPeca")
				self:Acao("Linha / área")
			end
		end
		self:Atualizar()
	end))
	table.insert(self._conexoes,construcao.Navegacao.Alterado:Connect(function()
		self:Atualizar()
		if self:Controle() then task.defer(function() if not self._destruido then self:Focar() end end) end
	end))
	table.insert(self._conexoes,Gui:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		self:Atualizar()
		if self:Controle() and self._emMenus and not Gui.SelectedObject then
			task.defer(function() if not self._destruido and self._emMenus and not Gui.SelectedObject then self:Focar() end end)
		end
	end))
	self._foco=true
	table.insert(self._conexoes,Input.WindowFocusReleased:Connect(function() self._foco=false end))
	table.insert(self._conexoes,Input.WindowFocused:Connect(function() self._foco=true end))
	-- O controle nativo continua cuidando do salto, camera, toque e analogico.
	Run:BindToRenderStep("Fabrica_TeclasMovimento",Enum.RenderPriority.Input.Value+1,function() self:Movimentar() end)
	self:Atualizar()
	return self
end

function Controles:Controle() return self._tipo and self._tipo.Name:match("^Gamepad")~=nil end

function Controles:Ponteiro()
	if self:Controle() or self._tipo==Enum.UserInputType.Touch then
		local camera=workspace.CurrentCamera
		return self._toque or (camera and camera.ViewportSize/2) or Vector2.zero
	end
	return Input:GetMouseLocation()
end

function Controles:Movimentar()
	local camera=workspace.CurrentCamera
	if camera and camera.ViewportSize~=self._viewport then self:Atualizar() end
	if self:Controle() or self._tipo==Enum.UserInputType.Touch then return end
	local mudou=false
	for original in direcoes do if Config.Tecla(self._jogador,original)~=original then mudou=true end end
	if not mudou then return end
	local movimento=Vector3.zero
	if self._foco and not Input:GetFocusedTextBox() and not self._jogador:GetAttribute("CapturandoAtalho") then
		for original,direcao in direcoes do
			if Input:IsKeyDown(Enum.KeyCode[Config.Tecla(self._jogador,original)]) then movimento+=direcao end
		end
	end
	if movimento.Magnitude>1 then movimento=movimento.Unit end
	self._jogador:Move(movimento,true)
end

function Controles:Focar()
	local nav=self._c.Navegacao
	local estado=nav:Atual()
	local grupo
	if nav:Contem("Confirmacao") then grupo=self._interface._confirmacao._fundo
	elseif estado=="MenuPeca" then grupo=self._interface._menuPeca
	else
		local painel=self._interface._paineisProgressao[estado]
		if painel then grupo=painel._grupo end
		if estado=="Blueprints" then grupo=self._interface._painelBlueprints._grupo end
		local aba=estado and estado:gsub("^Ficha","")
		painel=aba and self._interface._paineis[aba]
		if painel then grupo=estado==aba and painel._painelLista or painel._painelFicha end
	end
	if not grupo then
		self._emMenus=false
		Gui.SelectedObject=nil
		return
	end
	self._emMenus=true
	local atual=Gui.SelectedObject
	if atual and atual:IsDescendantOf(grupo) and self:Visivel(atual) then return end
	Gui.SelectedObject=nil
	for _,objeto in grupo:GetDescendants() do
		if objeto:IsA("GuiButton") and objeto.Selectable and objeto.Active and self:Visivel(objeto) then Gui.SelectedObject=objeto; break end
	end
end

function Controles:Visivel(objeto)
	while objeto and not objeto:IsA("ScreenGui") do
		if objeto:IsA("GuiObject") and not objeto.Visible then return false end
		objeto=objeto.Parent
	end
	return objeto~=nil
end

function Controles:AlternarFoco()
	if Gui.SelectedObject then self._emMenus=false; Gui.SelectedObject=nil
	else
		self:Focar()
		if not Gui.SelectedObject then self._emMenus=true; Gui.SelectedObject=self._interface._botoesAbas.Inventario:ObterInstancia() end
	end
	self:Atualizar()
end

function Controles:Acao(acao)
	local c=self._c
	if self._destruido or self._jogador:GetAttribute("CapturandoAtalho") then return false end
	if acao=="Voltar" then
		if c.Navegacao:Atual() then c:Cancelar() else Gui.SelectedObject=nil end
		return true
	end
	if Input:GetFocusedTextBox() or c.Navegacao:Contem("Confirmacao") then return false end
	if acao=="Confirmar" then
		if c._arrasteColocacao or c._arrasteSelecao then c:FinalizarEntrada(clique); return true end
		c:ProcessarEntrada(clique,false); c:FinalizarEntrada(clique)
	elseif acao=="Linha / área" then
		if c._arrasteColocacao or c._arrasteSelecao then c:FinalizarEntrada(clique)
		else
			c:ProcessarEntrada(clique,false)
			if c._arrasteSelecao then c._arrasteSelecao.PorComando=true; c:_AtualizarArrasteSelecao(self:Ponteiro()) end
		end
	elseif acao:sub(1,5)=="Girar" then
		if not c._previa then return false end
		c:Girar(acao:sub(-1))
	elseif acao=="Subir" or acao=="Descer" then
		local passo=acao=="Subir" and 1 or -1
		if c._arrasteSelecao then c:_AjustarAlturaSelecao(passo)
		elseif c._previa and c._alvoColocacao and not c._colocando then
			c._travamentoAltura={altura=math.max(0,c._alvoColocacao.minimo.Y+passo*Bloco),ancora=Vector3.zero}
		else return false end
	else return false end
	self:Atualizar()
	return true
end

function Controles:Atualizar()
	local controle=self:Controle()
	local especial=controle or self._tipo==Enum.UserInputType.Touch
	local camera=workspace.CurrentCamera
	local viewport=camera and camera.ViewportSize or Vector2.new(800,600)
	if viewport~=self._viewport then self._viewport=viewport; self._toque=nil end
	local recuo=if controle or (viewport.X>=600 and viewport.X>viewport.Y) then 36 else 160
	local largura=math.min(332,viewport.X-24)
	self._barra.Position,self._barra.Size=UDim2.new(.5,0,1,-recuo),UDim2.fromOffset(largura,100)
	self._barra.Visible=especial and not self._c.Navegacao:Contem("Confirmacao") and (self._c._previa~=nil or self._c._modoSelecao~=nil)
	self._mira.Visible=controle and not Gui.SelectedObject
	self._menu:ObterInstancia().Visible=controle
	self._instrucao.Visible=self._c._arrasteSelecao~=nil
	self._instrucao.Text=controle and "Aponte o outro canto e confirme" or "Toque no outro canto e confirme"
	local indice=0
	for i,item in acoes do
		local b=self._botoes[item[1]]:ObterInstancia()
		b.Visible=self._c._previa~=nil or item[1]:sub(1,5)~="Girar"
		local nome=item[1]
		if nome=="Linha / área" then
			nome=self._c._arrasteSelecao and "Concluir área" or self._c._arrasteColocacao and "Concluir linha"
				or self._c._previa and "Iniciar linha" or "Selecionar área"
		end
		b.Text=controle and (item[2].." • "..nome) or nome
		if b.Visible then
			b.Position,b.Size=UDim2.fromOffset((indice%4)*(largura+4)/4,math.floor(indice/4)*52),UDim2.fromOffset((largura+4)/4-4,48)
			indice+=1
		end
	end
end

function Controles:Destruir()
	self._destruido=true; self._c._ponteiro=nil
	for _,c in self._conexoes do c:Disconnect() end
	for _,item in acoes do CAS:UnbindAction("Fabrica_"..item[1]) end
	CAS:UnbindAction("Fabrica_Menus")
	Run:UnbindFromRenderStep("Fabrica_TeclasMovimento")
	for _,b in self._botoes do b:Destruir() end
	self._menu:Destruir(); self._gui:Destroy()
end
return Controles
