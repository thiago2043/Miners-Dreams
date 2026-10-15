local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local Botao = require(script.Parent.Botao)

local InterfaceJogo = {}
InterfaceJogo.__index = InterfaceJogo

function InterfaceJogo.new(jogador)
	local self = setmetatable({ _jogador = jogador, _conexoes = {}, _destruida = false }, InterfaceJogo)
	local playerGui = jogador:WaitForChild("PlayerGui")
	self._interface = Instance.new("ScreenGui")
	self._interface.Name = "InterfaceJogo"
	self._interface.ResetOnSpawn = false

	self._textoDinheiro = Instance.new("TextLabel")
	self._textoDinheiro.Name = "Dinheiro"
	self._textoDinheiro.AnchorPoint = Vector2.new(0.5, 0)
	self._textoDinheiro.Position = UDim2.new(0.5, 0, 0, 16)
	self._textoDinheiro.Size = UDim2.new(0, 260, 0, 48)
	self._textoDinheiro.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	self._textoDinheiro.BorderSizePixel = 0
	self._textoDinheiro.Font = Enum.Font.SourceSansBold
	self._textoDinheiro.TextColor3 = Color3.fromRGB(255, 255, 255)
	self._textoDinheiro.TextScaled = true
	self._textoDinheiro.Parent = self._interface

	local limiteTexto = Instance.new("UITextSizeConstraint")
	limiteTexto.MinTextSize = 12
	limiteTexto.MaxTextSize = 24
	limiteTexto.Parent = self._textoDinheiro

	table.insert(self._conexoes, self._jogador:GetAttributeChangedSignal("Dinheiro"):Connect(function()
		self:AtualizarDinheiro()
	end))
	self:AtualizarDinheiro()

	self._interface.Parent = playerGui

	self._redeLoja = Networker.client.new("Loja", {})

	self._painelLoja = Instance.new("Frame")
	self._painelLoja.Name = "Loja"
	self._painelLoja.AnchorPoint = Vector2.new(1, 0.5)
	self._painelLoja.Position = UDim2.new(1, -16, 0.5, 0)
	self._painelLoja.Size = UDim2.new(0, 280, 0, 160)
	self._painelLoja.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	self._painelLoja.BorderSizePixel = 0
	self._painelLoja.Parent = self._interface

	self._textoQuantidade = self:_CriarTextoLoja("Quantidade", 10, 32)
	self._textoResposta = self:_CriarTextoLoja("Resposta", 102, 48)
	self._textoResposta.Text = ""

	self._botaoCompra = Botao.new(self._painelLoja, "Comprar", function()
		self:ComprarSelecionada()
	end)
	self._botaoComprar = self._botaoCompra:ObterInstancia()
	self._botaoComprar.Name = "Comprar"
	self._botaoComprar.Position = UDim2.new(0, 12, 0, 50)
	self._botaoComprar.Size = UDim2.new(1, -24, 0, 44)
	self._botaoComprar.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	self._botaoComprar.BorderSizePixel = 0
	self._botaoComprar.Font = Enum.Font.SourceSansBold
	self._botaoComprar.TextColor3 = Color3.fromRGB(255, 255, 255)
	self._botaoComprar.TextSize = 18
	self._botaoComprar.TextWrapped = true
	self._botaoComprar.Parent = self._painelLoja

	self._comprando = false

	for maquinaId in CatalogoMaquinas do
		table.insert(self._conexoes, self._jogador:GetAttributeChangedSignal("Inventario_" .. maquinaId):Connect(function()
			self:AtualizarInventario()
		end))
	end
	table.insert(self._conexoes, self._jogador:GetAttributeChangedSignal("MaquinaSelecionada"):Connect(function()
		self._textoResposta.Text = ""
		self:AtualizarInventario()
	end))

	self:AtualizarInventario()
	return self
end

function InterfaceJogo:AtualizarDinheiro()
	local dinheiro = self._jogador:GetAttribute("Dinheiro")

	if dinheiro == nil then
		self._textoDinheiro.Text = "Dinheiro: carregando..."
	elseif type(dinheiro) ~= "string" or not dinheiro:match("^[0-9]+$") then
		self._textoDinheiro.Text = "Dinheiro: indisponível"
	else
		self._textoDinheiro.Text = "Dinheiro: " .. dinheiro
	end
end

function InterfaceJogo:_MaquinaAtual()
	local maquinaId = self._jogador:GetAttribute("MaquinaSelecionada") or "MineradoraBasica"
	return maquinaId, CatalogoMaquinas[maquinaId]
end

function InterfaceJogo:AtualizarInventario()
	local maquinaId, item = self:_MaquinaAtual()
	if not item then
		self._textoQuantidade.Text = "Selecao indisponivel"
		self._botaoComprar.Text = "Selecione uma maquina"
		self._botaoCompra:DefinirDisponivel(false)
		return
	end

	local quantidade = self._jogador:GetAttribute("Inventario_" .. maquinaId)
	local pronto = type(quantidade) == "number"
		and quantidade >= 0
		and quantidade % 1 == 0

	if quantidade == nil then
		self._textoQuantidade.Text = "Inventario: carregando..."
	elseif not pronto then
		self._textoQuantidade.Text = "Inventario indisponivel"
	else
		self._textoQuantidade.Text = "No inventario: " .. quantidade
	end

	self._botaoCompra:DefinirDisponivel(pronto and not self._comprando)
	self._botaoComprar.Text = self._comprando
		and "Comprando..."
		or "Comprar " .. item.Nome .. ": " .. item.Preco
end

function InterfaceJogo:ComprarSelecionada()
	if self._destruida or self._comprando or not self._botaoComprar.Active then
		return
	end

	local maquinaId, item = self:_MaquinaAtual()
	if not item then return end

	self._comprando = true
	self._textoResposta.Text = ""
	self:AtualizarInventario()

	local comunicou, sucesso, mensagem = pcall(function()
		return self._redeLoja:fetch("Comprar", maquinaId)
	end)

	if self._destruida then return end
	self._comprando = false

	if not comunicou then
		self._textoResposta.Text = "Nao foi possivel confirmar a compra."
	elseif type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
		self._textoResposta.Text = "Resposta invalida da loja."
	else
		self._textoResposta.Text = mensagem
	end

	self:AtualizarInventario()
end

function InterfaceJogo:_CriarTextoLoja(nome, y, altura)
	local texto = Instance.new("TextLabel")
	texto.Name = nome
	texto.Position = UDim2.new(0, 12, 0, y)
	texto.Size = UDim2.new(1, -24, 0, altura)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.SourceSansBold
	texto.TextColor3 = Color3.fromRGB(255, 255, 255)
	texto.TextSize = 18
	texto.TextWrapped = true
	texto.Parent = self._painelLoja
	return texto
end
function InterfaceJogo:Destruir()
	if self._destruida then return end
	self._destruida = true
	for _, conexao in self._conexoes do conexao:Disconnect() end
	table.clear(self._conexoes)
	self._botaoCompra:Destruir()
	self._interface:Destroy()
end

return InterfaceJogo
