local Elevador = require(game:GetService("ReplicatedStorage").Shared.ElevadorVertical)
local Janela = require(script.Parent.PainelProgressao)
local Painel = {}
Painel.__index = Painel

local nomesFaces = {["+Z"] = "Frente (+Z)", ["+X"] = "Direita (+X)", ["-Z"] = "Trás (−Z)", ["-X"] = "Esquerda (−X)"}

function Painel.new(pai, jogador, construcao)
	local nav = construcao.Navegacao
	local janela = Janela.new(pai, nav, "Elevador", "Configurar elevador", nil, nil, 348, jogador)
	local self = setmetatable({_janela = janela, _grupo = janela:ObterInstancia(), _nav = nav, _construcao = construcao}, Painel)
	local area = janela:ObterConteudo()
	area.CanvasSize = UDim2.fromOffset(0, 257)
	local function ajustar(passo)
		if self._enviando or not self._config then return end
		self._config.Altura = math.clamp(self._config.Altura + passo, Elevador.AlturaMinima, Elevador.AlturaMaxima)
		self:_AtualizarCampos()
	end
	self._menos = janela:Botao(area, "−", UDim2.fromOffset(0, 0), UDim2.fromOffset(44, 42), function() ajustar(-1) end)
	self._mais = janela:Botao(area, "+", UDim2.new(1, -50, 0, 0), UDim2.fromOffset(44, 42), function() ajustar(1) end)
	self._altura = janela:Texto(area, "Altura", "", UDim2.fromOffset(49, 0), UDim2.new(1, -104, 0, 42), 17, true)
	self._altura.TextXAlignment = Enum.TextXAlignment.Center
	self._faces = {}
	for i, campo in {"Entrada", "Saida"} do
		local botao = janela:Botao(area, campo, UDim2.new((i - 1) / 2, 0, 0, 50), UDim2.new(.5, -6, 0, 52), function()
			if self._enviando or not self._config then return end
			local atual = table.find(Elevador.Faces, self._config[campo])
			self._config[campo] = Elevador.Faces[atual % #Elevador.Faces + 1]
			self:_AtualizarCampos()
		end)
		botao:ObterInstancia().TextColor3 = if i == 1 then Color3.fromRGB(255, 189, 93) else janela.Cor
		self._faces[campo] = botao
	end
	self._sentido = janela:Botao(area, "Sentido", UDim2.fromOffset(0, 110), UDim2.new(1, -6, 0, 42), function()
		if self._enviando or not self._config then return end
		self._config.Sentido = if self._config.Sentido == "subir" then "descer" else "subir"
		self:_AtualizarCampos()
	end)
	self._aplicar = janela:Botao(area, "Aplicar", UDim2.fromOffset(0, 160), UDim2.new(1, -6, 0, 44), function() self:_Aplicar() end)
	local aplicar = self._aplicar:ObterInstancia()
	aplicar.BackgroundColor3, aplicar.TextColor3 = janela.Cor, Color3.fromRGB(22, 23, 29)
	self._resposta = janela:Texto(area, "Mensagem", "", UDim2.fromOffset(0, 211), UDim2.new(1, -6, 0, 44), 15)
	self._resposta.TextColor3 = Color3.fromRGB(255, 181, 145)
	return self
end

function Painel:_AtualizarCampos()
	local c = self._config
	self._altura.Text = "Altura · " .. c.Altura .. " blocos"
	self._faces.Entrada:ObterInstancia().Text = "Entrada\n" .. nomesFaces[c.Entrada]
	self._faces.Saida:ObterInstancia().Text = "Saída\n" .. nomesFaces[c.Saida]
	self._sentido:ObterInstancia().Text = if c.Sentido == "subir" then "Sentido · Subir ↑" else "Sentido · Descer ↓"
	self._menos:DefinirDisponivel(not self._enviando and c.Altura > Elevador.AlturaMinima)
	self._mais:DefinirDisponivel(not self._enviando and c.Altura < Elevador.AlturaMaxima)
	self._aplicar:DefinirDisponivel(not self._enviando)
end

function Painel:Abrir(maquina)
	local config = maquina and Elevador.Ler(maquina)
	if not config or self._enviando then return end
	self._maquina, self._config, self._resposta.Text = maquina, config, ""
	self:_AtualizarCampos()
	self._nav:Fechar("MenuPeca")
	if not self._nav:Focar("Elevador") then self._nav:Abrir("Elevador") end
end

function Painel:_Aplicar()
	if self._enviando or not self._maquina then return end
	self._enviando, self._resposta.Text = true, ""
	self:_AtualizarCampos()
	local c = self._config
	local ok, mensagem = self._construcao:ConfigurarElevador(self._maquina, c.Altura, c.Entrada, c.Saida, c.Sentido)
	if self._destruido then return end
	self._enviando = false
	self:_AtualizarCampos()
	if ok then self._nav:Fechar("Elevador") else self._resposta.Text = mensagem or "Elevador indisponível." end
end

function Painel:Atualizar() self._janela:Atualizar() end

function Painel:Destruir()
	self._destruido = true
	self._janela:Destruir()
end

return Painel
