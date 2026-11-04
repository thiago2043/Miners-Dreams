local Tutorial=require(game:GetService("ReplicatedStorage").Shared.Tutorial)
local Janela=require(script.Parent.PainelProgressao)
local Botao=require(script.Parent.Botao)
local Painel={}; Painel.__index=Painel

function Painel.new(pai,jogador,navegacao)
	local janela=Janela.new(pai,navegacao,"Tutorial","Tutorial",nil,nil,460,jogador)
	janela.Conteudo.AutomaticCanvasSize=Enum.AutomaticSize.Y
	janela.Conteudo.Selectable=true
	local corpo=Instance.new("Frame")
	corpo.Name,corpo.Size,corpo.AutomaticSize="Capitulos",UDim2.new(1,-8,0,0),Enum.AutomaticSize.Y
	corpo.BackgroundTransparency,corpo.Parent=1,janela.Conteudo
	local self=setmetatable({_janela=janela,_grupo=janela._grupo,_jogador=jogador,_corpo=corpo,
		_botoes={},_conexoes={},_nivel="Todos",_busca=""},Painel)
	self:_Desenhar()
	return self
end

function Painel:_Limpar()
	for _,c in self._conexoes do c:Disconnect() end
	table.clear(self._conexoes)
	for _,b in self._botoes do b:Destruir() end
	table.clear(self._botoes)
	for _,c in self._corpo:GetChildren() do c:Destroy() end
	self._ordem=0
end
function Painel:_Inserir(objeto)
	self._ordem+=1
	objeto.LayoutOrder,objeto.Parent=self._ordem,self._corpo
	return objeto
end
function Painel:_Texto(nome,texto,tamanho,negrito)
	local t=self._janela:Texto(self._corpo,nome,Tutorial.Formatar(texto,self._jogador),UDim2.new(),UDim2.new(1,0,0,0),tamanho or 17,negrito)
	t.AutomaticSize,t.TextYAlignment=Enum.AutomaticSize.Y,Enum.TextYAlignment.Top
	self:_Inserir(t)
	return t
end
function Painel:_Botao(pai,nome,texto,callback)
	local b=Botao.new(pai,nome,callback)
	local o=b:ObterInstancia()
	o.Text,o.Size=texto,UDim2.new(1,0,0,48)
	o.Font,o.TextSize,o.TextWrapped=Enum.Font.SourceSansBold,17,true
	o.TextColor3,o.BackgroundColor3,o.BorderSizePixel=Color3.fromRGB(238,244,247),Color3.fromRGB(33,43,48),0
	local canto=Instance.new("UICorner"); canto.CornerRadius,canto.Parent=UDim.new(0,7),o
	b:DefinirDisponivel(true)
	table.insert(self._botoes,b)
	return b
end
function Painel:_Faixa(nome)
	local f=Instance.new("Frame")
	f.Name,f.Size,f.BackgroundTransparency=nome,UDim2.new(1,0,0,48),1
	return self:_Inserir(f)
end
function Painel:_Filtrar()
	local total=0
	for i,b in self._capitulos do
		local mostrar=Tutorial.Corresponde(Tutorial.Licoes[i],self._busca,self._nivel)
		b:ObterInstancia().Visible=mostrar
		if mostrar then total+=1 end
	end
	self._resultado.Text=total==0 and "Nenhum capítulo encontrado. Tente outro termo ou nível."
		or tostring(total).." de "..#Tutorial.Licoes.." capítulos • escolha um tema ou siga a sequência"
	for nivel,b in self._filtros do
		b:ObterInstancia().BackgroundColor3=nivel==self._nivel and Color3.fromRGB(40,91,76) or Color3.fromRGB(33,43,48)
	end
	self._janela.Conteudo.CanvasPosition=Vector2.zero
end
function Painel:_Indice()
	self._atual=nil
	self:_Desenhar()
end
function Painel:_Abrir(indice)
	if not Tutorial.Licoes[indice] then return end
	self._atual=indice
	self:_Desenhar()
end
function Painel:_Desenhar()
	if self._destruido then return end
	self:_Limpar()
	local layout=Instance.new("UIListLayout")
	layout.SortOrder,layout.Padding,layout.Parent=Enum.SortOrder.LayoutOrder,UDim.new(0,12),self._corpo
	if not self._atual then
		self:_Texto("Introducao","Escolha um tema ou pesquise uma dúvida.",17)
		local busca=Instance.new("TextBox")
		busca.Name,busca.Text,busca.PlaceholderText="Pesquisar",self._busca,"Pesquisar: modificadores, área, renascimento…"
		busca.Size,busca.ClearTextOnFocus,busca.TextXAlignment=UDim2.new(1,0,0,44),false,Enum.TextXAlignment.Left
		busca.Selectable=true
		busca.TextColor3,busca.PlaceholderColor3,busca.BackgroundColor3=Color3.new(1,1,1),Color3.fromRGB(163,180,185),Color3.fromRGB(30,34,40)
		busca.Font,busca.TextSize,busca.BorderSizePixel=Enum.Font.SourceSans,17,0
		local padding=Instance.new("UIPadding"); padding.PaddingLeft,padding.Parent=UDim.new(0,10),busca
		self:_Inserir(busca)
		self._pesquisa=busca
		local faixa=self:_Faixa("Niveis")
		self._filtros={}
		for i,nivel in {"Todos",table.unpack(Tutorial.Niveis)} do
			local b=self:_Botao(faixa,nivel,nivel,function() self._nivel=nivel; self:_Filtrar() end)
			local o=b:ObterInstancia(); o.Position,o.Size=UDim2.fromScale((i-1)/4,0),UDim2.new(.25,-6,1,0)
			o.TextSize=15
			self._filtros[nivel]=b
		end
		self._resultado=self:_Texto("Resultado","",15)
		self._capitulos={}
		for i,licao in Tutorial.Licoes do
			local b=self:_Botao(self._corpo,licao.Id,string.format("%02d • %s\n%s",i,licao.Titulo,licao.Nivel),function() self:_Abrir(i) end)
			local o=b:ObterInstancia(); o.Size,o.AutomaticSize=UDim2.new(1,0,0,56),Enum.AutomaticSize.Y
			o.TextSize=15
			o.TextXAlignment=Enum.TextXAlignment.Left
			local padding=Instance.new("UIPadding")
			padding.PaddingLeft,padding.PaddingRight=UDim.new(0,12),UDim.new(0,12)
			padding.PaddingTop,padding.PaddingBottom,padding.Parent=UDim.new(0,10),UDim.new(0,10),o
			self:_Inserir(o); self._capitulos[i]=b
		end
		table.insert(self._conexoes,busca:GetPropertyChangedSignal("Text"):Connect(function()
			self._busca=busca.Text; self:_Filtrar()
		end))
		self:_Filtrar()
	else
		local licao=Tutorial.Licoes[self._atual]
		self:_Inserir(self:_Botao(self._corpo,"Indice","← Todos os capítulos",function() self:_Indice() end):ObterInstancia())
		self:_Texto("Contador",string.format("Capítulo %d de %d • %s",self._atual,#Tutorial.Licoes,licao.Nivel),15)
		local titulo=self:_Texto("Tema",licao.Titulo,23,true); titulo.TextColor3=self._janela.Cor
		
		for i,s in licao.Secoes do
			self:_Texto("Secao"..i,s[1],19,true)
			self:_Texto("Explicacao"..i,s[2],17)
		end
		local faixa=self:_Faixa("Sequencia")
		for i,item in {{"Anterior","← Anterior",-1},{"Proximo","Próximo →",1}} do
			local destino=self._atual+item[3]
			local b=self:_Botao(faixa,item[1],item[2],function() self:_Abrir(destino) end)
			local o=b:ObterInstancia(); o.Position,o.Size=UDim2.fromScale((i-1)/2,0),UDim2.new(.5,-6,1,0)
			local disponivel=Tutorial.Licoes[destino]~=nil
			b:DefinirDisponivel(disponivel); o.Selectable=disponivel
			o.TextColor3=disponivel and Color3.fromRGB(238,244,247) or Color3.fromRGB(132,146,150)
		end
	end
	self._janela.Conteudo.CanvasPosition=Vector2.zero
end
function Painel:Atualizar()
	if self._destruido then return end
	self._janela:Atualizar()
	if self._grupo.Visible and not self._visivel and self._atual then self:_Desenhar() end
	self._visivel=self._grupo.Visible
end
function Painel:Destruir()
	if self._destruido then return end
	self._destruido=true; self:_Limpar(); self._janela:Destruir()
end
return Painel
