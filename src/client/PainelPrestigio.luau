local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RegraReencarnacao = require(ReplicatedStorage.Shared.RegraReencarnacao)
local RegraRecompensas = require(ReplicatedStorage.Shared.RegraRecompensas)
local Config=require(ReplicatedStorage.Shared.Configuracoes)
local AbreviarInteiro = require(ReplicatedStorage.Shared.AbreviarInteiro)
local BarraProgressao = require(script.Parent.BarraProgressao)
local Botao = require(script.Parent.Botao)
local AnimacaoInterface = require(script.Parent.AnimacaoInterface)
local GerenciadorJanelas = require(script.Parent.GerenciadorJanelas)

local PainelPrestigio = {}
PainelPrestigio.__index = PainelPrestigio
local laranja, coral = Color3.fromRGB(255, 182, 90), Color3.fromRGB(255, 107, 91)

local function acabamento(objeto, raio)
	local canto = Instance.new("UICorner")
	canto.CornerRadius, canto.Parent = UDim.new(0, raio), objeto
end

local function marco(expoente)
	if expoente <= 38 then return AbreviarInteiro("1" .. string.rep("0", expoente)) end
	return "1e" .. string.format("%.0f", expoente)
end

-- A ficha possui apresentacao e botoes. Navegacao controla P/Q, regra calcula a estimativa e rede
-- apenas solicita a operacao; nenhum clique altera dinheiro ou vidas diretamente no cliente.
function PainelPrestigio.new(pai, jogador, navegacao, rede)
	local self = setmetatable({ _jogador = jogador, _navegacao = navegacao, _rede = rede,
		_regra = RegraReencarnacao.new(), _botoes = {}, _estado = nil }, PainelPrestigio)
	self._grupo = Instance.new("Frame")
	self._grupo.Name, self._grupo.AnchorPoint = "Prestigio", Vector2.new(0.5, 0.5)
	self._grupo.Position, self._grupo.Size = UDim2.fromScale(0.5, 0.5), UDim2.new(1, -32, 0, 260)
	self._grupo.BackgroundColor3, self._grupo.BorderSizePixel = Color3.fromRGB(22, 23, 29), 0
	self._grupo.ZIndex = 2
	self._grupo.Active, self._grupo.Visible, self._grupo.Parent = true, false, pai
	acabamento(self._grupo, 12)
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize, limite.Parent = Vector2.new(620, 260), self._grupo
	local borda = Instance.new("UIStroke")
	borda.Color, borda.Thickness, borda.Transparency, borda.Parent = laranja, 1.5, 0.2, self._grupo
	self._titulo = self:_Texto("Titulo", "Prestígio [P]", UDim2.fromOffset(18, 10), UDim2.new(1, -74, 0, 30), 22, laranja)
	self._fechar = self:_Botao("Fechar", UDim2.new(1, -42, 0, 12), UDim2.fromOffset(28, 28), function()
		navegacao:Fechar("Prestigio")
	end)
	local fechar = self._fechar:ObterInstancia()
	fechar.Text, fechar.TextSize, fechar.BackgroundColor3 = "×", 25, coral
	acabamento(fechar, 14)
	self._vida = self:_Texto("Vida", "", UDim2.fromOffset(18, 52), UDim2.new(0.5, -18, 0, 24), 21)
	self._ciclos = self:_Texto("Ciclos", "", UDim2.new(0.5, 0, 0, 52), UDim2.new(0.5, -18, 0, 24), 14)
	self._ciclos.TextXAlignment = Enum.TextXAlignment.Right
	self._requisito = self:_Texto("Requisito", "", UDim2.fromOffset(18, 82), UDim2.new(1, -36, 0, 22), 18, laranja)
	self._saldo = self:_Texto("Saldo", "", UDim2.fromOffset(18, 108), UDim2.new(1, -36, 0, 20), 16)
	self._saltos = self:_Texto("Saltos", "", UDim2.fromOffset(18, 134), UDim2.new(1, -36, 0, 24), 18, Color3.fromRGB(88, 244, 166))
	self._barra = BarraProgressao.new(self._grupo, laranja, coral)
	self._barra:ObterInstancia().Position, self._barra:ObterInstancia().Size = UDim2.fromOffset(18, 169), UDim2.new(1, -36, 0, 16)
	self._mensagem = self:_Texto("Resposta", "", UDim2.fromOffset(18, 195), UDim2.new(1, -36, 0, 20), 14, laranja)
	self._reencarnar = self:_Botao("Reencarnar", UDim2.new(0, 18, 1, -44), UDim2.new(1, -36, 0, 32), function()
		self:Reencarnar()
	end)
self._reencarnar:DefinirDisponivel(false)
GerenciadorJanelas.Registrar("Janela_Prestigio", self._grupo, {
Jogador = jogador,
AlturaBarra = 44,
RecuoDireitoBarra = 48,
MinLargura = 280,
MinAltura = 240,
LarguraPadrao = 560,
AlturaPadrao = 260,
})
self:Atualizar()
return self
end

function PainelPrestigio:_Texto(nome, texto, posicao, tamanho, fonte, cor)
	local label = Instance.new("TextLabel")
	label.Name, label.Text, label.Position, label.Size = nome, texto, posicao, tamanho
	label.BackgroundTransparency, label.Font = 1, Enum.Font.SourceSansBold
	label.TextColor3, label.TextSize, label.TextWrapped = cor or Color3.fromRGB(239, 240, 245), fonte, true
	label.TextXAlignment, label.Parent = Enum.TextXAlignment.Left, self._grupo
	return label
end

-- Botao e o dono da conexao; todos os botoes sao encerrados ao destruir esta ficha.
function PainelPrestigio:_Botao(nome, posicao, tamanho, callback)
	local botao = Botao.new(self._grupo, nome, callback)
	local b = botao:ObterInstancia()
	b.Name, b.Text, b.Position, b.Size = nome, nome, posicao, tamanho
	b.BorderSizePixel, b.Font, b.TextSize, b.TextWrapped = 0, Enum.Font.SourceSansBold, 18, true
	b.BackgroundColor3, b.TextColor3, b.Selectable = laranja, Color3.fromRGB(22, 23, 29), true
	acabamento(b, 8)
	botao:DefinirDisponivel(true)
	table.insert(self._botoes, botao)
	return botao
end

-- Dados replicados atualizam apenas a estimativa. Marcos completos e progresso parcial possuem
-- textos separados: uma barra zerada no novo marco nao esconde as vidas que ja podem ser obtidas.
function PainelPrestigio:Atualizar()
  if self._destruido then return end
  self._titulo.Text="Prestígio ["..Config.Tecla(self._jogador,"P").."]"
  AnimacaoInterface.DefinirVisivel(self._grupo, self._navegacao:Contem("Prestigio"), "Centro")
	local saldo = self._jogador:GetAttribute("Dinheiro")
	local estado = self._regra:Calcular(saldo, self._jogador:GetAttribute("Reencarnacoes"), self._jogador:GetAttribute("Vidas"))
	self._estado = estado
	local disponivel = estado ~= nil and estado.VidasDisponiveis > 0 and not self._enviando
	self._reencarnar:DefinirDisponivel(disponivel)
	local b = self._reencarnar:ObterInstancia()
	b.BackgroundColor3 = disponivel and laranja or Color3.fromRGB(61, 58, 62)
	b.TextColor3 = disponivel and Color3.fromRGB(22, 23, 29) or Color3.fromRGB(192, 189, 196)
	b.Text = self._enviando and "Reencarnando..." or "Reencarnar"
	if not estado then
		self._vida.Text, self._ciclos.Text, self._requisito.Text = "Vida: carregando...", "", "Progressão indisponível."
		self._saldo.Text, self._saltos.Text = "", ""
		self._barra:Atualizar(0)
		return
	end
	self._vida.Text, self._ciclos.Text = "Vida " .. AbreviarInteiro(estado.Vidas), "Reencarnações: " .. AbreviarInteiro(estado.Reencarnacoes)
	self._requisito.Text = "Requisito: $" .. marco(estado.ExpoenteRequisito)
	self._saldo.Text = "Saldo disponível: $" .. AbreviarInteiro(saldo)
	self._saltos.Text = estado.VidasDisponiveis > 0
		and ("+" .. AbreviarInteiro(estado.VidasDisponiveis) .. " vida(s) · " .. AbreviarInteiro(estado.VidasPuladas) .. " pulada(s) · destino: vida " .. AbreviarInteiro(estado.VidaDestino))
		or ""
	self._barra:Atualizar(estado.Fracao)

	if disponivel then
		local garantidas = #RegraRecompensas.Garantidas(estado.Reencarnacoes + 1)
		b.Text = "Reencarnar · " .. (garantidas + estado.VidasPuladas) .. " peça(s) · +" .. AbreviarInteiro(estado.VidasDisponiveis) .. " vida(s)"
	end
end

-- Um clique envia apenas o ciclo esperado. O guarda evita pedidos simultaneos; fechar com Q durante
-- a resposta continua permitido. Uma ficha destruida ignora o retorno sem acessar seus elementos.
function PainelPrestigio:Reencarnar(confirmada)
	if self._destruido or self._enviando or not self._grupo.Visible then return end
	self:Atualizar()
	if not self._estado or self._estado.VidasDisponiveis == 0 then return end
	if not confirmada and self.Confirmacao then return self.Confirmacao:Pedir("Renascimento",1,function() self:Reencarnar(true) end) end
	local indice = self._estado.Reencarnacoes
	self._enviando = true
	self:Atualizar()
	local comunicou, sucesso, mensagem = pcall(function() return self._rede:fetch("Reencarnar", indice) end)
	if self._destruido then return end
	self._enviando = false
	self._mensagem.Text = comunicou and type(sucesso) == "boolean" and type(mensagem) == "string"
		and mensagem or "Não foi possível concluir a reencarnação. Confira seus dados antes de tentar novamente."
	self:Atualizar()
end

function PainelPrestigio:Destruir()
	if self._destruido then return end
	self._destruido = true
	for _, botao in self._botoes do botao:Destruir() end
	self._barra:Destruir()
	self._grupo:Destroy()
end

return PainelPrestigio
