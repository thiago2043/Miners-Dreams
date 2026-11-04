local Janela=require(script.Parent.PainelProgressao)
local PainelBlueprints={}
PainelBlueprints.__index=PainelBlueprints

function PainelBlueprints.new(pai,construcao,jogador)
	local janela=Janela.new(pai,construcao.Navegacao,"Blueprints","Blueprints","B",nil,520,jogador)
	local self=setmetatable({_construcao=construcao,_janela=janela,_grupo=janela._grupo,_botoes=janela._botoes,
		_listaBlueprints={},_jaVisivel=false},PainelBlueprints)
	local area=janela.Conteudo
	janela:Texto(area,"Novo","Novo blueprint",UDim2.fromOffset(0,0),UDim2.new(1,-8,0,24),18,true)
	self._nome=Instance.new("TextBox")
	local nome=self._nome
	nome.Name,nome.Position,nome.Size="NomeBlueprint",UDim2.fromOffset(0,30),UDim2.new(1,-8,0,38)
	nome.BackgroundColor3,nome.BorderSizePixel,nome.ClearTextOnFocus=Color3.fromRGB(31,33,40),0,false
	nome.Font,nome.TextColor3,nome.PlaceholderColor3=Enum.Font.SourceSans,Color3.fromRGB(240,243,250),Color3.fromRGB(163,172,189)
	nome.TextSize,nome.TextXAlignment,nome.TextWrapped=17,Enum.TextXAlignment.Left,true
	nome.PlaceholderText,nome.Text,nome.Parent="Nome do conjunto (opcional)","",area
	local canto=Instance.new("UICorner"); canto.CornerRadius,canto.Parent=UDim.new(0,7),nome
	local padding=Instance.new("UIPadding"); padding.PaddingLeft,padding.PaddingRight,padding.Parent=UDim.new(0,10),UDim.new(0,10),nome
	self._botaoCriar=janela:Botao(area,"Criar",UDim2.fromOffset(0,78),UDim2.new(1,-8,0,36),function()
		local iniciou,mensagem=construcao:IniciarCriacaoBlueprint(nome.Text)
		if not iniciou then self:_MostrarMensagem(mensagem) end
	end)
	local criar=self._botaoCriar:ObterInstancia()
	criar.Text,criar.BackgroundColor3,criar.TextColor3="Selecionar peças na plot",janela.Cor,Color3.fromRGB(17,29,35)
	self._status=janela:Texto(area,"Status","Selecione a área e confirme para salvar o conjunto.",UDim2.fromOffset(0,120),UDim2.new(1,-8,0,36),14)
	janela:Texto(area,"Salvos","Conjuntos salvos",UDim2.fromOffset(0,168),UDim2.new(.65,0,0,24),18,true)
	self._quantidade=janela:Texto(area,"Quantidade","",UDim2.new(.65,0,0,168),UDim2.new(.35,-8,0,24),14)
	self._quantidade.TextXAlignment=Enum.TextXAlignment.Right
	self._lista=Instance.new("Frame")
	self._lista.Name,self._lista.Position,self._lista.Size="ListaBlueprints",UDim2.fromOffset(0,202),UDim2.new(1,-8,0,92)
	self._lista.BackgroundTransparency,self._lista.Parent=1,area
	self._vazio=janela:Texto(self._lista,"Vazio","Nenhum blueprint salvo.\nCrie um conjunto com as peças da sua plot.",UDim2.fromOffset(14,8),UDim2.new(1,-28,0,72),17)
	self._vazio.TextXAlignment=Enum.TextXAlignment.Center
	return self
end

function PainelBlueprints:_MostrarMensagem(mensagem)
	self._status.Text=type(mensagem)=="string" and mensagem or "Não foi possível concluir a operação."
end

function PainelBlueprints:_LimparLista()
	for _,botao in self._listaBlueprints do
		botao:Destruir()
		local indice=table.find(self._botoes,botao)
		if indice then table.remove(self._botoes,indice) end
	end
	table.clear(self._listaBlueprints)
end

function PainelBlueprints:_CarregarLista()
	self:_LimparLista()
	local sucesso,mensagem,blueprints=self._construcao:ListarBlueprints()
	if self._destruido then return end
	if not sucesso then
		self._vazio.Visible,self._vazio.Text=true,mensagem
		self._quantidade.Text="Indisponível"
	else
		self._quantidade.Text=#blueprints.." salvo(s)"
		self._vazio.Visible,self._vazio.Text=#blueprints==0,"Nenhum blueprint salvo.\nCrie um conjunto com as peças da sua plot."
		for indice,blueprint in blueprints do
			local id=blueprint.Id
			local botao=self._janela:Botao(self._lista,"Blueprint_"..id,UDim2.fromOffset(0,(indice-1)*76),UDim2.new(1,0,0,66),function()
				local iniciou,erro=self._construcao:ColocarBlueprint(id)
				if not iniciou then self:_MostrarMensagem(erro) end
			end)
			local b=botao:ObterInstancia(); b.Text=""
			local nome=self._janela:Texto(b,"Nome",blueprint.Nome,UDim2.fromOffset(12,7),UDim2.new(1,-112,0,24),18,true)
			nome.TextWrapped,nome.TextTruncate=false,Enum.TextTruncate.AtEnd
			self._janela:Texto(b,"Pecas",tostring(blueprint.Quantidade).." peças",UDim2.fromOffset(12,34),UDim2.new(1,-112,0,21),14)
			local acao=self._janela:Texto(b,"Acao","Colocar →",UDim2.new(1,-100,0,0),UDim2.fromOffset(88,66),16,true)
			acao.TextColor3=self._janela.Cor
			table.insert(self._listaBlueprints,botao)
		end
	end
	local altura=math.max(92,#self._listaBlueprints*76)
	self._lista.Size=UDim2.new(1,-8,0,altura)
	self._janela.Conteudo.CanvasSize=UDim2.fromOffset(0,202+altura)
end

function PainelBlueprints:Atualizar()
	if self._destruido then return end
	self._janela:Atualizar()
	local visivel=self._grupo.Visible
	if visivel then
		local resultado=self._construcao:ObterResultadoBlueprint()
		if resultado then
			self:_MostrarMensagem(resultado.Mensagem)
			if resultado.Sucesso then self._nome.Text="" end
		end
		if not self._jaVisivel or resultado then self:_CarregarLista() end
	end
	self._jaVisivel=visivel
end

function PainelBlueprints:Destruir()
	if self._destruido then return end
	self._destruido=true
	self:_LimparLista()
	self._janela:Destruir()
end

return PainelBlueprints
