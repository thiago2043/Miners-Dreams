-- Monta o HUD e duas instancias de PainelPecas; alteracoes dos atributos replicados atualizam os valores
-- mostrados.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local PainelPecas = require(script.Parent.PainelPecas)
local Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)

local InterfaceJogo = {}
InterfaceJogo.__index = InterfaceJogo

-- Cria o ScreenGui do jogador, o saldo, as instrucoes e duas instancias de PainelPecas que compartilham a
-- conexao da loja. Liga os atributos replicados e a navegacao as atualizacoes da interface.
function InterfaceJogo.new(jogador, construcao)
	local self = setmetatable({ _jogador = jogador, _construcao = construcao, _conexoes = {}, _paineis = {} }, InterfaceJogo)
	-- ScreenGui e o recipiente desenhado na tela. ResetOnSpawn=false conserva essa interface quando o
	-- personagem renasce, evitando perder os paineis pelo respawn.
	self._interface = Instance.new("ScreenGui")
	self._interface.Name, self._interface.ResetOnSpawn = "InterfaceJogo", false
	self._interface.Parent = jogador:WaitForChild("PlayerGui")
	self._textoDinheiro = self:_CriarTexto("Dinheiro", UDim2.new(0.5, 0, 0, 16), UDim2.fromOffset(260, 48), Vector2.new(0.5, 0))
	self._textoDinheiro.TextScaled = true
	local limite = Instance.new("UITextSizeConstraint")
	limite.MinTextSize, limite.MaxTextSize, limite.Parent = 12, 24, self._textoDinheiro
	self._textoModo = self:_CriarTexto("ModoAtual", UDim2.new(0.5, 0, 1, -12), UDim2.new(0.9, 0, 0, 64), Vector2.new(0.5, 1))
	self._textoModo.BackgroundTransparency = 0.15
	-- Os dois paineis compartilham o canal de pedidos, mas cada um conserva selecao e resposta proprias. A
	-- interface nao cria outra regra de compra.
	local rede = Networker.client.new("Loja", {})
	for _, aba in { "Inventario", "Loja" } do
		self._paineis[aba] = PainelPecas.new(self._interface, aba, jogador, construcao, rede)
	end
	-- Os atributos chegam replicados do servidor. Os sinais atualizam o HUD quando os dados mudam, dispensando
	-- uma consulta repetida a cada quadro.
	table.insert(self._conexoes, jogador:GetAttributeChangedSignal("Dinheiro"):Connect(function() self:AtualizarDinheiro() end))
	for id in Catalogo do
		for _, prefixo in { "Inventario_", "ConfiguracaoInventario_" } do
			table.insert(self._conexoes, jogador:GetAttributeChangedSignal(prefixo .. id):Connect(function() self:AtualizarInventario() end))
		end
	end
	table.insert(self._conexoes, construcao.Navegacao.Alterado:Connect(function() self:AtualizarInventario() end))
	-- Faz a primeira leitura agora, pois os atributos podem ter chegado antes de os ouvintes serem conectados.
	-- Depois disso, os eventos mantem a tela atualizada.
	self:AtualizarDinheiro()
	self:AtualizarInventario()
	return self
end

-- Recebe nome, posicao, tamanho e ponto de ancora e devolve um TextLabel no ScreenGui. Centraliza o estilo dos
-- textos gerais do HUD, sem criar regras de compra ou construcao.
function InterfaceJogo:_CriarTexto(nome, posicao, tamanho, ancora)
	local texto = Instance.new("TextLabel")
	texto.Name, texto.Position, texto.Size, texto.AnchorPoint = nome, posicao, tamanho, ancora
	texto.BackgroundColor3, texto.BorderSizePixel = Color3.fromRGB(25, 25, 25), 0
	texto.Font, texto.TextColor3, texto.TextSize = Enum.Font.SourceSansBold, Color3.fromRGB(255, 255, 255), 18
	texto.TextWrapped, texto.Parent = true, self._interface
	return texto
end

-- Le o atributo Dinheiro publicado no jogador e atualiza o texto do HUD. Diferencia carregamento, texto
-- decimal valido e dado indisponivel; nao calcula nem altera o saldo do servidor.
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

-- Solicita a cada painel que releia estoque e selecao, e depois atualiza as instrucoes. E chamada pelos
-- eventos de atributos e de navegacao, em vez de reconstruir a interface a cada quadro.
function InterfaceJogo:AtualizarInventario()
	if self._destruida then return end
	for _, painel in self._paineis do painel:Atualizar() end
	self:AtualizarEstado()
end

-- Troca as instrucoes do rodape conforme colocacao, rotacao, recolhimento ou copia. O estoque e o preco
-- mostrados sao informativos; a autorizacao da operacao continua no servidor.
function InterfaceJogo:AtualizarEstado()
	if self._destruida then return end
	local estado = self._construcao.Navegacao:Atual()
	if estado == "Reposicionamento" or (estado == "Rotacao" and self._construcao.Navegacao:Contem("Reposicionamento")) then
		local item = Catalogo[self._jogador:GetAttribute("MaquinaSelecionada")]
		self._textoModo.Text = "Mover: " .. (item and item.Nome or "Peça") .. " | Sem custo\n"
			.. (estado == "Rotacao" and "R + arraste: girar 90° | Q: sair da rotação"
				or "Clique: confirmar | R: girar | T: altura | Q: cancelar movimento | M: sair")
	elseif estado == "Movimentacao" then
		self._textoModo.Text = "Clique em uma peça do seu terreno para mover.\nM ou Q: sair | E: inventário | F: loja"
	elseif estado == "Colocacao" or estado == "Rotacao" then
		local id = self._jogador:GetAttribute("MaquinaSelecionada")
		local item = Catalogo[id]
		self._textoModo.Text = (item and item.Nome or "Peça") .. " | Estoque: " .. tostring(self._jogador:GetAttribute("Inventario_" .. tostring(id)) or "...")
			.. " | Compra se necessário: " .. (item and item.Preco or "...") .. "\n"
			.. (estado == "Rotacao" and "R + arraste: girar 90° | Q: sair da rotação"
				or "Clique: colocar | R: girar | T: altura | Q: cancelar colocação | E: inventário | F: loja | X: recolher")
	elseif estado == "Recolhimento" then
		self._textoModo.Text = "Clique em peças do seu terreno para recolher.\nX ou Q: sair | E: inventário | F: loja"
	elseif estado == "Copiando" then
		self._textoModo.Text = "Obtendo a configuração da peça...\nQ: cancelar a seleção da cópia"
	else
		self._textoModo.Text = "E: inventário | F: loja | M: mover | X: recolher | Botão do meio: copiar | Q: voltar"
	end
end

-- Desconecta os ouvintes da interface, encerra os dois paineis e remove o ScreenGui. A guarda _destruida
-- tambem protege callbacks de rede que retornem depois desse encerramento.
function InterfaceJogo:Destruir()
	if self._destruida then return end
	self._destruida = true
	for _, conexao in self._conexoes do conexao:Disconnect() end
	table.clear(self._conexoes)
	for _, painel in self._paineis do painel:Destruir() end
	self._interface:Destroy()
end

return InterfaceJogo
