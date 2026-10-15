local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local DataManager = require(ServerScriptService.Data.DataManager)

local ServicoConstrucao = {}
ServicoConstrucao.__index = ServicoConstrucao

function ServicoConstrucao.new()
	local self = setmetatable({
		_modelos = {}, _carregados = {}, _limites = {}, _registrosPorMaquina = {},
	}, ServicoConstrucao)
	for maquinaId in CatalogoMaquinas do
		local modelo = workspace:WaitForChild(maquinaId)
		local caixaOriginal, tamanho = modelo:GetBoundingBox()
		self._modelos[maquinaId] = {
			Modelo = modelo, Volume = VolumeConstrucao.new(tamanho, CatalogoMaquinas[maquinaId].Blocos),
			CaixaParaPivo = caixaOriginal:ToObjectSpace(modelo:GetPivot()),
		}
	end
	return self
end

function ServicoConstrucao:_PermitirPedido(jogador)
	local agora = os.clock()
	local limite = self._limites[jogador] or { tempo = agora, tokens = 60 }

	limite.tokens = math.min(60, limite.tokens + (agora - limite.tempo) * 30)
	limite.tempo = agora
	self._limites[jogador] = limite

	if limite.tokens < 1 then return false end

	limite.tokens -= 1
	return true
end

local function finito(v)
	return type(v) == "number" and v == v and math.abs(v) < math.huge
end

local function validarRotacao(rotacao)
	if typeof(rotacao) ~= "CFrame" then
		return nil
	end

	local c = { rotacao:GetComponents() }

	for i, v in c do
		if not finito(v) then
			return nil
		end

		if i <= 3 then
			if math.abs(v) > 0.0001 then return nil end
		else
			if math.abs(v - math.round(v)) > 0.0001 then return nil end
			c[i] = math.round(v)
		end
	end

	local direita = Vector3.new(c[4], c[7], c[10])
	local cima = Vector3.new(c[5], c[8], c[11])
	local tras = Vector3.new(c[6], c[9], c[12])

	if direita:Dot(direita) ~= 1
		or cima:Dot(cima) ~= 1
		or direita:Dot(cima) ~= 0
		or direita:Cross(cima) ~= tras
	then
		return nil
	end

	return CFrame.fromMatrix(Vector3.zero, direita, cima, tras)
end

local function contexto(jogador)
	local dados = DataManager.ObterDados(jogador)

	if jogador.Parent ~= Players or not dados then
		return nil
	end

	local pasta = workspace:FindFirstChild("Terrenos")
	if not pasta then return nil end

	for _, terreno in pasta:GetChildren() do
		if terreno:GetAttribute("DonoUserId") ~= jogador.UserId
			or terreno:GetAttribute("TerrenoId") ~= jogador:GetAttribute("TerrenoId")
		then
			continue
		end

		local piso = terreno:FindFirstChild("Piso")
		local maquinas = terreno:FindFirstChild("Maquinas")

		if piso and piso:IsA("BasePart") and maquinas then
			return dados, terreno, piso, maquinas
		end
	end
end

local function destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo)
	if typeof(minimo) ~= "Vector3" then return nil end

	for _, v in { minimo.X, minimo.Y, minimo.Z } do
		if not finito(v) or v % Geometria.Passo ~= 0 then
			return nil
		end
	end

	local extensao, ocupado = dadosModelo.Volume:Calcular(rotacao)
	local maximo = minimo + ocupado

	if minimo.X < 0 or minimo.Y < 0 or minimo.Z < 0
		or maximo.X > piso.Size.X or maximo.Z > piso.Size.Z
	then
		return nil
	end

	local origem = Geometria.Origem(piso)
	local erro = Geometria.Tolerancia

	for _, outra in maquinas:GetChildren() do
		if not outra:IsA("Model") then continue end

		local a, b = Geometria.VolumeDoModelo(outra, origem)

		if a and minimo.X < b.X - erro and maximo.X > a.X + erro
			and minimo.Y < b.Y - erro and maximo.Y > a.Y + erro
			and minimo.Z < b.Z - erro and maximo.Z > a.Z + erro
		then
			return nil
		end
	end

	local caixaDestino = origem * CFrame.new(
		minimo + Vector3.new(ocupado.X / 2, extensao.Y, ocupado.Z / 2)
	) * rotacao

	for _, v in { caixaDestino:GetComponents() } do
		if not finito(v) then return nil end
	end

	return caixaDestino * dadosModelo.CaixaParaPivo
end

function ServicoConstrucao:_CriarMaquina(jogador, terreno, maquinas, destino, registro)
	local maquina = self._modelos[registro.MaquinaId].Modelo:Clone()

	maquina:SetAttribute("DonoUserId", jogador.UserId)
	maquina:SetAttribute("TerrenoId", terreno:GetAttribute("TerrenoId"))
	maquina:SetAttribute("PodeRecolher", true)
	local rotacao = CFrame.new(0, 0, 0, table.unpack(registro.Rotacao))
	local _, ocupado = self._modelos[registro.MaquinaId].Volume:Calcular(rotacao)
	maquina:SetAttribute("VolumeMinimo", Vector3.new(table.unpack(registro.Posicao)))
	maquina:SetAttribute("VolumeOcupado", ocupado)
	maquina:SetAttribute("TamanhoConstrucao", self._modelos[registro.MaquinaId].Volume:ObterTamanhoVisual())

	self._registrosPorMaquina[maquina] = {
		registro = registro,
		jogador = jogador,
	}

	for _, parte in maquina:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.Anchored = true
		end
	end

	maquina:PivotTo(destino)
	maquina.Parent = maquinas

	return maquina
end

function ServicoConstrucao:Restaurar(jogador)
	local dados, terreno, piso, maquinas = contexto(jogador)

	if not dados then return false end
	if self._carregados[terreno] == dados then return true end

	local registros = dados:ObterConstrucoes()

	if type(registros) ~= "table" then
		warn("MaquinasColocadas indisponivel para " .. jogador.Name)
		return false
	end

	for indice, registro in registros do
		local destino

		if type(registro) == "table"
			and type(registro.MaquinaId) == "string" and self._modelos[registro.MaquinaId]
			and type(registro.Posicao) == "table" and #registro.Posicao == 3
			and type(registro.Rotacao) == "table" and #registro.Rotacao == 9
		then
			local numerosValidos = true

			for _, v in registro.Posicao do
				if not finito(v) then numerosValidos = false end
			end

			for _, v in registro.Rotacao do
				if not finito(v) then numerosValidos = false end
			end

			if numerosValidos then
				local minimo = Vector3.new(table.unpack(registro.Posicao))

				local rotacao = validarRotacao(
					CFrame.new(0, 0, 0, table.unpack(registro.Rotacao))
				)

				if rotacao then
					destino = destinoLivre(piso, maquinas, minimo, rotacao, self._modelos[registro.MaquinaId])
				end
			end
		end

		if destino then
			self:_CriarMaquina(jogador, terreno, maquinas, destino, registro)
		else
			warn("Nao foi possivel restaurar a maquina " .. tostring(indice)
				.. " de " .. jogador.Name .. "; o registro foi preservado.")
		end
	end

	self._carregados[terreno] = dados
	return true
end

function ServicoConstrucao:Colocar(jogador, maquinaId, minimo, rotacao)
	if not self:_PermitirPedido(jogador) then
		return false, "Muitos pedidos de construcao. Aguarde um instante."
	end

	local dadosModelo = type(maquinaId) == "string" and self._modelos[maquinaId]
	if not dadosModelo then
		return false, "Maquina invalida."
	end

	rotacao = validarRotacao(rotacao)

	if not rotacao then
		return false, "Rotacao invalida."
	end

	if not self:Restaurar(jogador) then
		return false, "Seus dados ou seu terreno ainda nao estao disponiveis."
	end

	local dados, terreno, piso, maquinas = contexto(jogador)
	if not dados then return false, "Terreno indisponivel." end

	if dados:ObterQuantidade(maquinaId) == nil then
		return false, "Quantidade invalida no inventario."
	end

	local destino = destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo)

	if not destino then
		return false, "Essa posicao esta ocupada ou fora da grade do seu terreno."
	end

	local componentes = { rotacao:GetComponents() }

	local registro = {
		MaquinaId = maquinaId,
		Posicao = { minimo.X, minimo.Y, minimo.Z },
		Rotacao = { table.unpack(componentes, 4, 12) },
	}

	local sucesso, mensagem = dados:RegistrarColocacao(registro)
	if not sucesso then return false, mensagem end
	self:_CriarMaquina(jogador, terreno, maquinas, destino, registro)
	return true, mensagem
end

function ServicoConstrucao:Recolher(jogador, maquina)
	if not self:_PermitirPedido(jogador) then
		return false, "Muitos pedidos de construcao. Aguarde um instante."
	end

	if typeof(maquina) ~= "Instance" or not maquina:IsA("Model") then
		return false, "Maquina invalida."
	end

	if not self:Restaurar(jogador) then
		return false, "Seus dados ou seu terreno ainda nao estao disponiveis."
	end

	local dados, terreno, piso, maquinas = contexto(jogador)
	if not dados then return false, "Terreno indisponivel." end

	if maquina.Parent ~= maquinas
		or maquina:GetAttribute("DonoUserId") ~= jogador.UserId
		or maquina:GetAttribute("TerrenoId") ~= terreno:GetAttribute("TerrenoId")
	then
		return false, "Essa maquina nao pertence ao seu terreno."
	end

	local vinculo = self._registrosPorMaquina[maquina]
	local registro = vinculo and vinculo.registro

	if not registro or vinculo.jogador ~= jogador
		or not self._modelos[registro.MaquinaId]
	then
		return false, "Essa maquina nao pode ser recolhida."
	end

	local sucesso, mensagem = dados:RegistrarRecolhimento(registro)
	if not sucesso then return false, mensagem end
	self._registrosPorMaquina[maquina] = nil
	maquina:Destroy()
	return true, mensagem
end

function ServicoConstrucao:LimparJogador(jogador)
	self._limites[jogador] = nil
	for maquina, vinculo in self._registrosPorMaquina do
		if vinculo.jogador == jogador then
			self._registrosPorMaquina[maquina] = nil
		end
	end
	for terreno in self._carregados do
		if terreno:GetAttribute("DonoUserId") == jogador.UserId then
			self._carregados[terreno] = nil
		end
	end
end

return ServicoConstrucao
