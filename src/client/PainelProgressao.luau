local Botao = require(script.Parent.Botao)
local Icones = require(script.Parent.IconesAbas)
local AnimacaoInterface = require(script.Parent.AnimacaoInterface)
local PainelProgressao = {}
PainelProgressao.__index = PainelProgressao
local cores = {Blueprints=Color3.fromRGB(49,211,240), Upgrades=Color3.fromRGB(176,137,255), Configuracoes=Color3.fromRGB(255,214,78), Classificacao=Color3.fromRGB(255,190,86),Administracao=Color3.fromRGB(112,198,255),Tutorial=Color3.fromRGB(101,228,196)}

local function arredondar(objeto, raio)
	local canto=Instance.new("UICorner")
	canto.CornerRadius,canto.Parent=UDim.new(0,raio),objeto
end

function PainelProgressao.new(pai, navegacao, nome, titulo, tecla, mensagem, altura,jogador)
	local self=setmetatable({_navegacao=navegacao,_nome=nome,_botoes={},Cor=cores[nome],_tecla=tecla,_jogador=jogador},PainelProgressao)
	local g=Instance.new("Frame")
	g.Name,g.AnchorPoint=nome,Vector2.new(.5,.5)
	g.Position,g.Size=UDim2.fromScale(.5,.5),UDim2.new(1,-32,1,-48)
g.BackgroundColor3,g.BorderSizePixel=Color3.fromRGB(22,23,29),0
  g.ZIndex=15
  g.Active,g.Visible,g.Parent=true,false,pai
	arredondar(g,12)
	self._grupo=g
	local limite=Instance.new("UISizeConstraint")
	limite.MaxSize,limite.Parent=Vector2.new(540,altura or 340),g
	local borda=Instance.new("UIStroke")
	borda.Color,borda.Transparency,borda.Parent=self.Cor,.55,g
	local icone=Instance.new("Frame")
	icone.Name,icone.Position,icone.Size="IconeAba",UDim2.fromOffset(12,7),UDim2.fromOffset(56,56)
	icone.BackgroundTransparency,icone.ZIndex,icone.Parent=1,1,g
	Icones.Criar(icone,nome)
	local escala=Instance.new("UIScale")
	escala.Scale,escala.Parent=.8,icone
	self._titulo=self:Texto(g,"Titulo",titulo,UDim2.fromOffset(66,10),UDim2.new(1,-120,0,28),23,true)
	self._titulo.TextColor3=self.Cor
	self._titulo.TextScaled=true
	local fonteTitulo=Instance.new("UITextSizeConstraint")
	fonteTitulo.MinTextSize,fonteTitulo.MaxTextSize,fonteTitulo.Parent=14,23,self._titulo
	self._fechar=self:Botao(g,"Fechar",UDim2.new(1,-44,0,16),UDim2.fromOffset(28,28),function() navegacao:Fechar(nome) end)
	local fechar=self._fechar:ObterInstancia()
	fechar.Text,fechar.TextSize,fechar.BackgroundColor3,fechar.TextColor3="×",26,self.Cor,Color3.fromRGB(22,23,29)
	arredondar(fechar,14)
	self.Conteudo=Instance.new("ScrollingFrame")
	self.Conteudo.Name,self.Conteudo.Position,self.Conteudo.Size="Conteudo",UDim2.fromOffset(16,56),UDim2.new(1,-32,1,-72)
	self.Conteudo.BackgroundTransparency,self.Conteudo.BorderSizePixel=1,0
	self.Conteudo.CanvasSize,self.Conteudo.ScrollBarThickness=UDim2.new(),4
	self.Conteudo.ScrollingDirection,self.Conteudo.Active,self.Conteudo.Parent=Enum.ScrollingDirection.Y,true,g
	self.Conteudo.ScrollBarImageColor3=self.Cor
	if mensagem then
		local estado=Instance.new("Frame")
		estado.Name,estado.Position,estado.Size="EstadoVazio",UDim2.fromOffset(0,8),UDim2.new(1,-8,0,176)
		estado.BackgroundColor3,estado.BorderSizePixel,estado.Parent=Color3.fromRGB(29,31,39),0,self.Conteudo
		arredondar(estado,10)
		self._mensagem=self:Texto(estado,"Vazio",mensagem,UDim2.fromOffset(20,24),UDim2.new(1,-40,0,56),21,true)
		self._mensagem.TextXAlignment=Enum.TextXAlignment.Center
		self.Conteudo.CanvasSize=UDim2.fromOffset(0,192)
	end
	return self
end

function PainelProgressao:Texto(pai,nome,conteudo,posicao,tamanho,fonte,negrito)
	local label=Instance.new("TextLabel")
	label.Name,label.Text,label.Position,label.Size=nome,conteudo,posicao,tamanho
	label.BackgroundTransparency,label.BorderSizePixel=1,0
	label.Font=negrito and Enum.Font.SourceSansBold or Enum.Font.SourceSans
	label.TextColor3,label.TextSize,label.TextWrapped=Color3.fromRGB(225,229,239),fonte,true
	label.TextXAlignment,label.Parent=Enum.TextXAlignment.Left,pai
	return label
end

function PainelProgressao:Botao(pai,nome,posicao,tamanho,callback)
	local botao=Botao.new(pai,nome,callback)
	local b=botao:ObterInstancia()
	b.Position,b.Size,b.Text=posicao,tamanho,nome
	b.BackgroundColor3,b.BorderSizePixel=Color3.fromRGB(34,37,46),0
	b.Font,b.TextColor3,b.TextSize=Enum.Font.SourceSansBold,Color3.fromRGB(240,243,250),17
	b.TextWrapped,b.Selectable=true,true
	arredondar(b,7)
	botao:DefinirDisponivel(true)
	table.insert(self._botoes,botao)
	return botao
end

function PainelProgressao:Atualizar()
  if not self._destruido then
    AnimacaoInterface.DefinirVisivel(self._grupo, self._navegacao:Contem(self._nome), "Centro")
  end
end

function PainelProgressao:Destruir()
	if self._destruido then return end
	self._destruido=true
	for _,botao in self._botoes do botao:Destruir() end
	table.clear(self._botoes)
	self._grupo:Destroy()
end

return PainelProgressao
