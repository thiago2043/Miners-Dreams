local Input=game:GetService("UserInputService")
local Controle={}; Controle.__index=Controle
function Controle.new(pai,nome,valores,cor,alterar,aoSoltar)
  local self=setmetatable({_valores=valores,_indice=1,_alterar=alterar,_aoSoltar=aoSoltar,_conexoes={},_pai=pai},Controle)
	local raiz=Instance.new("Frame"); raiz.Name,raiz.BackgroundTransparency,raiz.Size,raiz.Parent=nome,1,UDim2.fromOffset(148,36),pai
	self._raiz=raiz
	local texto=Instance.new("TextLabel")
	texto.Name,texto.Text,texto.BackgroundTransparency,texto.Size,texto.Parent="Valor","",1,UDim2.new(1,0,0,16),raiz
	texto.TextColor3,texto.Font,texto.TextSize=cor,Enum.Font.SourceSansBold,14
	local trilho=Instance.new("Frame")
	trilho.Name,trilho.Position,trilho.Size,trilho.BorderSizePixel,trilho.Parent="Trilho",UDim2.fromOffset(7,25),UDim2.new(1,-14,0,4),0,raiz
	trilho.BackgroundColor3=Color3.fromRGB(67,72,84)
	local preenchimento=Instance.new("Frame")
	preenchimento.BorderSizePixel,preenchimento.BackgroundColor3,preenchimento.Parent=0,cor,trilho
	local marcador=Instance.new("Frame")
	marcador.Name,marcador.AnchorPoint,marcador.Size,marcador.BorderSizePixel,marcador.Parent="Marcador",Vector2.new(.5,.5),UDim2.fromOffset(12,16),0,trilho
	marcador.BackgroundColor3=cor
	local captura=Instance.new("TextButton")
	captura.Name,captura.Size,captura.BackgroundTransparency,captura.Text,captura.Parent="Ajustar",UDim2.fromScale(1,1),1,"",raiz
	captura.Selectable,captura.ZIndex=true,2
	self._texto,self._trilho,self._preenchimento,self._marcador=texto,trilho,preenchimento,marcador
	local function conectar(sinal,funcao) table.insert(self._conexoes,sinal:Connect(funcao)) end
	conectar(captura.InputBegan,function(i)
		if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end
		self._arraste=i
		self._rolagem=pai.ScrollingEnabled; pai.ScrollingEnabled=false
		self:_PorX(i.Position.X)
	end)
	conectar(Input.InputChanged,function(i)
		if self._arraste and (i==self._arraste or i.UserInputType==Enum.UserInputType.MouseMovement) then self:_PorX(i.Position.X) end
	end)
	conectar(Input.InputEnded,function(i)
		if i==self._arraste or i.UserInputType==Enum.UserInputType.MouseButton1 then self:_Soltar() end
	end)
	conectar(Input.WindowFocusReleased,function() self:_Soltar() end)
	conectar(captura.SelectionGained,function() self._selecionado=true end)
	conectar(captura.SelectionLost,function() self._selecionado=false end)
	conectar(Input.InputBegan,function(i)
		if not self._selecionado then return end
		if i.KeyCode==Enum.KeyCode.Left or i.KeyCode==Enum.KeyCode.DPadLeft then self:_Escolher(self._indice-1)
		elseif i.KeyCode==Enum.KeyCode.Right or i.KeyCode==Enum.KeyCode.DPadRight then self:_Escolher(self._indice+1) end
	end)
	return self
end
function Controle:_Soltar()
  if not self._arraste then return end
  self._arraste=nil; self._pai.ScrollingEnabled=self._rolagem
  if self._aoSoltar then self._aoSoltar(self._valores[self._indice]) end
end
function Controle:_Escolher(indice)
  indice=math.clamp(indice,1,#self._valores)
  if indice~=self._indice then
    self._indice=indice
    local valor=self._valores[indice]
    self._alterar(valor)
    if not self._arraste and self._aoSoltar then self._aoSoltar(valor) end
  end
end
function Controle:_PorX(x)
	if self._trilho.AbsoluteSize.X<=0 then return end
	local t=math.clamp((x-self._trilho.AbsolutePosition.X)/self._trilho.AbsoluteSize.X,0,1)
	self:_Escolher(math.round(t*(#self._valores-1))+1)
end
function Controle:DefinirValor(valor,texto)
	self._indice=table.find(self._valores,valor) or 1
	local t=(self._indice-1)/math.max(1,#self._valores-1)
	self._texto.Text=texto
	self._preenchimento.Size=UDim2.fromScale(t,1)
	self._marcador.Position=UDim2.fromScale(t,.5)
end
function Controle:ObterInstancia() return self._raiz end
function Controle:Destruir()
	self:_Soltar()
	for _,c in self._conexoes do c:Disconnect() end
	self._raiz:Destroy()
end
return Controle
