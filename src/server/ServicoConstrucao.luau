-- Autoridade da construcao: confere terreno, grade e ocupacao antes de coordenar o registro salvo e o modelo
-- colocado.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RotacaoConstrucao = require(ReplicatedStorage.Shared.RotacaoConstrucao)
local PersonalizacaoMaquina = require(ReplicatedStorage.Shared.PersonalizacaoMaquina)
local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local DataManager = require(ServerScriptService.Data.DataManager)
local Maquina = require(script.Parent.Maquinas.Maquina)

local ServicoConstrucao = {}
ServicoConstrucao.__index = ServicoConstrucao

-- Monta os indices de modelos, restauracoes, limites de pedidos e capturas de copia. Para cada tipo do
-- catalogo, guarda o modelo original, seu volume e o deslocamento entre caixa e pivo.
function ServicoConstrucao.new()
	-- Os mapas separam referencia de modelo, plot ja restaurada, limite de pedidos e vinculo Model-registro. A
	-- copia por jogador guarda dados capturados no servidor e um token de identificacao.
	local self = setmetatable({
		_modelos = {}, _carregados = {}, _limites = {}, _registrosPorMaquina = {}, _copias = {}, _sequenciaCopia = 0,
	}, ServicoConstrucao)
	-- Carrega recursos de ReplicatedStorage; nao depende de maquinas iniciais no Workspace. Mede uma vez os
	-- originais e conserva o deslocamento entre centro da caixa e pivo.
	local modelos = ReplicatedStorage:WaitForChild("ModelosMaquinas")
	for maquinaId in CatalogoMaquinas do
		local modelo = modelos:WaitForChild(maquinaId)
		local caixaOriginal, tamanho = modelo:GetBoundingBox()
		self._modelos[maquinaId] = {
			Modelo = modelo, Volume = VolumeConstrucao.new(tamanho, CatalogoMaquinas[maquinaId].Blocos),
			CaixaParaPivo = caixaOriginal:ToObjectSpace(modelo:GetPivot()),
		}
	end
	return self
end

-- O saldo de pedidos permite rajadas de cliques e se recupera com o tempo, limitando spam continuo.
-- Mantem por jogador um saldo maximo de 60 pedidos, recuperado a 30 por segundo. Cada pedido aceito consome
-- um; devolve false quando a rajada esgotou esse saldo.
function ServicoConstrucao:_PermitirPedido(jogador)
	local agora = os.clock()
	local limite = self._limites[jogador] or { tempo = agora, tokens = 60 }

	-- Reposicao proporcional ao tempo permite varios cliques seguidos sem aceitar spam continuo. math.min
	-- impede acumular mais que a capacidade maxima durante uma espera longa.
	limite.tokens = math.min(60, limite.tokens + (agora - limite.tempo) * 30)
	limite.tempo = agora
	self._limites[jogador] = limite

	if limite.tokens < 1 then return false end

	limite.tokens -= 1
	return true
end

-- Devolve true para um number que nao e NaN nem infinito. E usada antes de aceitar coordenadas e componentes
-- de uma transformacao recebida ou restaurada.
local function finito(v)
	return type(v) == "number" and v == v and math.abs(v) < math.huge
end

-- Confere sessao ativa, presenca do jogador no servidor e propriedade da plot. Devolve dados, terreno, piso e
-- pasta de maquinas quando esse conjunto existe; caso contrario encerra sem resultado.
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

-- Toda posicao recebida e validada novamente: a previa do cliente nao e uma autorizacao de construcao.
-- Recebe canto local, orientacao e volume do modelo, e confere grade, bordas e sobreposicao. ignorar permite
-- testar uma personalizacao no lugar da propria maquina. Devolve o CFrame do pivo no mundo ou nil se o destino
-- nao for permitido.
local function destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo, ignorar)
	if typeof(minimo) ~= "Vector3" then return nil end

	-- O canto recebido deve estar em multiplos exatos do passo da grade e nao pode conter NaN ou infinito. A
	-- verificacao do servidor independe do que a previa mostrou.
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

	-- Duas caixas se sobrepoem somente quando seus intervalos se cruzam em X, Y e Z. A tolerancia permite
	-- contato entre faces; ignorar e usado ao substituir a propria maquina.
	for _, outra in maquinas:GetChildren() do
		if outra == ignorar or not outra:IsA("Model") then continue end

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

-- Recebe um tipo e suas diferencas. Reutiliza a referencia base quando nao ha alteracoes; caso contrario, cria
-- uma copia temporaria, aplica a configuracao e valida seus componentes e dimensoes.
function ServicoConstrucao:_PrepararModelo(maquinaId, modificacoes)
	local base = assert(self._modelos[maquinaId], "Maquina invalida.")
	local personalizacao = PersonalizacaoMaquina.new(modificacoes)
	if next(personalizacao:ObterDados()) == nil then return base end
	-- Uma configuracao diferente precisa de uma copia temporaria para ser aplicada e medida. Construir Maquina
	-- valida seus componentes; Destruir encerra esse objeto de validacao.
	local modelo = base.Modelo:Clone()
	local sucesso, resultado = pcall(function()
		personalizacao:Aplicar(modelo)
		local caixa, tamanho = modelo:GetBoundingBox()
		local definicao = personalizacao:ObterDefinicao(CatalogoMaquinas[maquinaId])
		local validacao = Maquina.new(modelo, nil, definicao)
		validacao:Destruir()
		return {
			Modelo = modelo, Volume = VolumeConstrucao.new(tamanho, definicao.Blocos),
			CaixaParaPivo = caixa:ToObjectSpace(modelo:GetPivot()), Temporario = true,
		}
	end)
	-- Se a preparacao falhar, destroi a copia antes de propagar o erro. A referencia original continua
	-- disponivel para outras colocacoes.
	if not sucesso then modelo:Destroy(); error(resultado, 0) end
	return resultado
end

-- Destroi apenas modelos preparados que estao marcados como temporarios. A referencia original do catalogo
-- deve continuar disponivel para as proximas construcoes.
local function liberarModelo(dadosModelo)
	if dadosModelo.Temporario then dadosModelo.Modelo:Destroy() end
end

-- Clona o modelo preparado, publica dono, ocupacao e personalizacao, liga esse Model ao registro salvo e
-- aplica o pivo de destino. Devolve o modelo colocado; os componentes serao encontrados pela Fabrica.
function ServicoConstrucao:_CriarMaquina(jogador, terreno, maquinas, destino, registro, dadosModelo)
	dadosModelo = dadosModelo or self._modelos[registro.MaquinaId]
	local maquina = dadosModelo.Modelo:Clone()

	maquina:SetAttribute("DonoUserId", jogador.UserId)
	maquina:SetAttribute("TerrenoId", terreno:GetAttribute("TerrenoId"))
	maquina:SetAttribute("PodeRecolher", true)
	local rotacao = CFrame.new(0, 0, 0, table.unpack(registro.Rotacao))
	local _, ocupado = dadosModelo.Volume:Calcular(rotacao)
	maquina:SetAttribute("VolumeMinimo", Vector3.new(table.unpack(registro.Posicao)))
	maquina:SetAttribute("VolumeOcupado", ocupado)
	maquina:SetAttribute("TamanhoConstrucao", dadosModelo.Volume:ObterTamanhoVisual())
	maquina:SetAttribute("RotacaoConstrucao", rotacao)
	PersonalizacaoMaquina.new(registro.Modificacoes):Publicar(maquina)

	-- O vinculo conserva a identidade do registro dentro do perfil. Recolhimento e sincronizacao localizam essa
	-- mesma unidade, sem procurar somente pelo nome do modelo.
	self._registrosPorMaquina[maquina] = {
		registro = registro,
		jogador = jogador,
	}

	for _, parte in maquina:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.Anchored = true
		end
	end

	-- So publica o clone na pasta Maquinas depois de configurar atributos, ancoragem e pose. A Fabrica encontra
	-- esse modelo na proxima atualizacao e monta seus comportamentos.
	maquina:PivotTo(destino)
	maquina.Parent = maquinas

	return maquina
end

-- Reconstroi os modelos a partir dos registros do perfil, preservando registros que nao puderem ser colocados.
-- Reconstroi os registros do perfil uma vez para o mesmo contexto de dados e plot. Valida cada registro antes
-- de criar seu modelo; uma entrada que nao possa ser restaurada fica preservada no perfil para recuperacao.
function ServicoConstrucao:Restaurar(jogador)
	local dados, terreno, piso, maquinas = contexto(jogador)

	if not dados then return false end
	-- Restaurar pode ser chamado por caminhos diferentes. Este cache evita duplicar construcoes quando o mesmo
	-- objeto de dados ja foi carregado nesta plot.
	if self._carregados[terreno] == dados then return true end

	local registros = dados:ObterConstrucoes()

	if type(registros) ~= "table" then
		warn("MaquinasColocadas indisponivel para " .. jogador.Name)
		return false
	end

	for indice, registro in registros do
		local destino
		local dadosModelo

		-- Um registro salvo precisa ter um tipo conhecido, tres coordenadas e nove componentes de rotacao finitos.
		-- Um registro invalido fica no perfil e gera aviso, em vez de ser descartado.
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

				local rotacao = RotacaoConstrucao.Validar(
					CFrame.new(0, 0, 0, table.unpack(registro.Rotacao))
				)

				if rotacao then
					local preparou, preparado = pcall(self._PrepararModelo, self, registro.MaquinaId, registro.Modificacoes)
					if preparou then
						dadosModelo = preparado
						destino = destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo)
					end
				end
			end
		end

		if destino then
			self:_CriarMaquina(jogador, terreno, maquinas, destino, registro, dadosModelo)
		else
			warn("Nao foi possivel restaurar a maquina " .. tostring(indice)
				.. " de " .. jogador.Name .. "; o registro foi preservado.")
		end
		if dadosModelo then liberarModelo(dadosModelo) end
	end

	self._carregados[terreno] = dados
	return true
end

-- Valida o pedido e escolhe a configuracao a partir do token de copia, do padrao da loja ou do estoque do
-- servidor. Se o destino for livre, registra o consumo/compra e cria o modelo; devolve sucesso e mensagem.
function ServicoConstrucao:Colocar(jogador, maquinaId, minimo, rotacao, tokenCopia, usarPadrao)
	if not self:_PermitirPedido(jogador) then
		return false, "Muitos pedidos de construcao. Aguarde um instante."
	end

	local dadosModelo = type(maquinaId) == "string" and self._modelos[maquinaId]
	if not dadosModelo then
		return false, "Maquina invalida."
	end

	rotacao = RotacaoConstrucao.ValidarNaGrade(rotacao)

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
	if usarPadrao ~= nil and type(usarPadrao) ~= "boolean" then return false, "Origem da colocacao invalida." end
	if usarPadrao and tokenCopia ~= nil then return false, "Origem da colocacao invalida." end
	local modificacoes
	-- O cliente envia so o token da captura, nao as estatisticas que deseja receber. Sem token, a loja escolhe
	-- o padrao e o inventario escolhe a configuracao publicada pelo servidor.
	if tokenCopia ~= nil then
		local copia = self._copias[jogador]
		if not copia or copia.Token ~= tokenCopia or copia.MaquinaId ~= maquinaId then
			return false, "A copia selecionada nao esta mais disponivel."
		end
		modificacoes = copia.Modificacoes
	elseif usarPadrao then
		modificacoes = {}
	else
		modificacoes = dados:ObterModificacoesInventario(maquinaId)
	end
	local preparou, preparado = pcall(self._PrepararModelo, self, maquinaId, modificacoes)
	if not preparou then return false, "Configuracao da peca invalida." end
	dadosModelo = preparado

	local destino = destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo)

	if not destino then
		liberarModelo(dadosModelo)
		return false, "Essa posicao esta ocupada ou fora da grade do seu terreno."
	end

	-- O perfil usa dados serializaveis: posicao como tres numeros e rotacao como os nove componentes da matriz.
	-- Os tres primeiros componentes do CFrame sao sua translacao e ficam de fora.
	local componentes = { rotacao:GetComponents() }

	local registro = {
		MaquinaId = maquinaId,
		Posicao = { minimo.X, minimo.Y, minimo.Z },
		Rotacao = { table.unpack(componentes, 4, 12) },
	}
	if modificacoes and next(modificacoes) then
		registro.Modificacoes = PersonalizacaoMaquina.new(modificacoes):ObterDados()
	end

	-- O destino ja passou pelas validacoes. DadosJogador consome estoque ou compra e registra a unidade;
	-- somente o sucesso autoriza criar o modelo definitivo.
	local sucesso, mensagem = dados:RegistrarColocacao(registro)
	if not sucesso then liberarModelo(dadosModelo); return false, mensagem end
	self:_CriarMaquina(jogador, terreno, maquinas, destino, registro, dadosModelo)
	liberarModelo(dadosModelo)
	return true, mensagem
end

-- Confere se o argumento e um Model de tipo conhecido, dentro da pasta e com os atributos do jogador. Devolve
-- o contexto do dono quando autorizado, ou nil se a maquina nao puder ser usada.
function ServicoConstrucao:_ObterMaquina(jogador, maquina)
	if typeof(maquina) ~= "Instance" or not maquina:IsA("Model") then return nil end
	local dados, terreno, piso, maquinas = contexto(jogador)
	if not dados or maquina.Parent ~= maquinas
		or maquina:GetAttribute("DonoUserId") ~= jogador.UserId
		or maquina:GetAttribute("TerrenoId") ~= terreno:GetAttribute("TerrenoId")
		or not self._modelos[maquina.Name]
	then return nil end
	return dados, terreno, piso, maquinas
end

-- O servidor captura a origem e entrega um token; o cliente nao escolhe os valores de uma melhoria copiada.
-- Captura as diferencas da origem e sua orientacao, guarda uma selecao de copia por jogador e gera um token
-- novo. Devolve sucesso, mensagem e os dados para a previa; a origem permanece colocada.
function ServicoConstrucao:Copiar(jogador, maquina)
	if not self:_PermitirPedido(jogador) then return false, "Muitos pedidos de construcao." end
	local dados, terreno, piso = self:_ObterMaquina(jogador, maquina)
	if not dados then return false, "Selecione uma peca do seu terreno." end
	local base = self._modelos[maquina.Name]
	local sucesso, personalizacao = pcall(function()
		return PersonalizacaoMaquina.DoModelo(maquina):Capturar(maquina, base.Modelo)
	end)
	if not sucesso then return false, "Nao foi possivel capturar a configuracao da peca." end
	local vinculo = self._registrosPorMaquina[maquina]
	if vinculo then
		local modificacoes = personalizacao:ObterDados()
		vinculo.registro.Modificacoes = next(modificacoes) and modificacoes or nil
	end
	local rotacao = maquina:GetAttribute("RotacaoConstrucao")
	if not rotacao then
		rotacao = Geometria.Origem(piso):ToObjectSpace(maquina:GetPivot() * base.CaixaParaPivo:Inverse()).Rotation
	end
	rotacao = RotacaoConstrucao.Validar(rotacao)
	if not rotacao then return false, "Rotacao da peca invalida." end
	rotacao = RotacaoConstrucao.EncaixarNaGrade(rotacao)
	-- Cada captura recebe outro numero para invalidar selecoes de copia anteriores. Os dados completos ficam no
	-- servidor e uma copia deles e enviada para a exibicao da previa.
	self._sequenciaCopia += 1
	local copia = {
		Token = self._sequenciaCopia, MaquinaId = maquina.Name,
		Modificacoes = personalizacao:ObterDados(), Rotacao = rotacao,
	}
	self._copias[jogador] = copia
	return true, "Peca copiada para colocacao.", {
		Token = copia.Token, MaquinaId = copia.MaquinaId, Rotacao = copia.Rotacao,
		Modificacoes = personalizacao:ObterDados(),
	}
end

-- API de servidor que prepara uma configuracao nova e verifica se ela cabe na mesma posicao, desconsiderando o
-- modelo antigo na colisao. Cria o modelo substituto, preserva TotalRecebido e remove a versao anterior
-- somente no fluxo aceito.
function ServicoConstrucao:Personalizar(jogador, maquina, modificacoes)
	local dados, terreno, piso, maquinas = self:_ObterMaquina(jogador, maquina)
	local vinculo = self._registrosPorMaquina[maquina]
	if not dados or not vinculo or vinculo.jogador ~= jogador then
		return false, "Peca indisponivel para personalizacao."
	end
	local registro = vinculo.registro
	local preparou, dadosModelo = pcall(self._PrepararModelo, self, registro.MaquinaId, modificacoes)
	if not preparou then return false, "Personalizacao invalida." end
	local minimo = Vector3.new(table.unpack(registro.Posicao))
	local rotacao = CFrame.new(0, 0, 0, table.unpack(registro.Rotacao))
	-- A personalizacao pode aumentar o visual ou a reserva, por isso testa novamente o espaco. Ignorar a
	-- maquina antiga evita considera-la uma colisao contra sua substituta.
	local destino = destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo, maquina)
	if not destino then liberarModelo(dadosModelo); return false, "A peca modificada nao cabe nessa posicao." end
	registro.Modificacoes = PersonalizacaoMaquina.new(modificacoes):ObterDados()
	local nova = self:_CriarMaquina(jogador, terreno, maquinas, destino, registro, dadosModelo)
	local total = maquina:GetAttribute("TotalRecebido")
	if total then nova:SetAttribute("TotalRecebido", total) end
	self._registrosPorMaquina[maquina] = nil
	maquina:Destroy()
	liberarModelo(dadosModelo)
	return true, "Peca personalizada.", nova
end

-- Recebe uma peca colocada, o novo canto e o giro. Valida o contexto e o destino antes de mover o mesmo Model
-- e atualizar seu registro. Nao compra, vende ou devolve estoque, preservando tambem o estado dos componentes.
function ServicoConstrucao:Mover(jogador, maquina, minimo, rotacao)
	if not self:_PermitirPedido(jogador) then return false, "Muitos pedidos de construcao. Aguarde um instante." end
	rotacao = RotacaoConstrucao.ValidarNaGrade(rotacao)
	if not rotacao then return false, "Rotacao invalida." end
	local dados, _, piso, maquinas = self:_ObterMaquina(jogador, maquina)
	local vinculo = self._registrosPorMaquina[maquina]
	if not dados or not vinculo or vinculo.jogador ~= jogador or vinculo.registro.MaquinaId ~= maquina.Name then
		return false, "Essa peca nao esta disponivel para mover."
	end
	local registro = vinculo.registro
	local registros = dados:ObterConstrucoes()
	if type(registros) ~= "table" or not table.find(registros, registro) then
		return false, "O registro desta peca nao esta mais disponivel."
	end

	-- Captura as diferencas da unidade real no servidor. O pedido do cliente nao pode alterar melhorias ao mover.
	local capturou, personalizacao = pcall(function()
		return PersonalizacaoMaquina.DoModelo(maquina):Capturar(maquina, self._modelos[registro.MaquinaId].Modelo)
	end)
	if not capturou then return false, "Nao foi possivel preservar a configuracao da peca." end
	local modificacoes = personalizacao:ObterDados()
	local preparou, preparado = pcall(self._PrepararModelo, self, registro.MaquinaId, modificacoes)
	if not preparou then return false, "Configuracao da peca invalida." end
	-- A reserva antiga pertence a esta mesma unidade; so os outros modelos podem bloquear seu destino.
	local destino = destinoLivre(piso, maquinas, minimo, rotacao, preparado, maquina)
	local _, ocupado = preparado.Volume:Calcular(rotacao)
	local tamanho = preparado.Volume:ObterTamanhoVisual()
	liberarModelo(preparado)
	if not destino then return false, "Essa posicao esta ocupada ou fora da grade do seu terreno." end

	-- Nao ha espera entre a mudanca no mundo e no perfil. Reutilizar o Model conserva atributos, filhos e os
	-- objetos de comportamento que a Fabrica ja acompanha, como o historico de aplicacoes de um modificador.
	local componentes = { rotacao:GetComponents() }
	maquina:PivotTo(destino)
	maquina:SetAttribute("VolumeMinimo", minimo)
	maquina:SetAttribute("VolumeOcupado", ocupado)
	maquina:SetAttribute("TamanhoConstrucao", tamanho)
	maquina:SetAttribute("RotacaoConstrucao", rotacao)
	personalizacao:Publicar(maquina)
	registro.Posicao = { minimo.X, minimo.Y, minimo.Z }
	registro.Rotacao = { table.unpack(componentes, 4, 12) }
	registro.Modificacoes = next(modificacoes) and modificacoes or nil
	return true, "Peca movida."
end

-- Atualiza os registros com o estado das pecas antes do salvamento, incluindo diferencas visuais e de configuracao.
-- Percorre os modelos vinculados ao jogador e captura suas diferencas atuais nos registros do perfil. Uma
-- captura invalida gera aviso e nao substitui as diferencas por dados vazios.
function ServicoConstrucao:Sincronizar(jogador)
	for maquina, vinculo in self._registrosPorMaquina do
		if vinculo.jogador ~= jogador or not maquina.Parent
			or maquina:GetAttribute("DonoUserId") ~= jogador.UserId
		then continue end
		local sucesso, personalizacao = pcall(function()
			return PersonalizacaoMaquina.DoModelo(maquina):Capturar(maquina, self._modelos[vinculo.registro.MaquinaId].Modelo)
		end)
		if sucesso then
			local modificacoes = personalizacao:ObterDados()
			vinculo.registro.Modificacoes = next(modificacoes) and modificacoes or nil
		else
			warn("Personalizacao nao sincronizada em " .. maquina:GetFullName())
		end
	end
end

-- A retirada precisa pertencer ao jogador e devolver exatamente a mesma unidade ao seu inventario.
-- Confere limite de pedidos, dono e vinculo com um registro salvo. Captura a personalizacao e tenta devolve-la
-- ao inventario; so depois do sucesso remove o vinculo e destroi o modelo do terreno.
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

	local capturou, personalizacao = pcall(function()
		return PersonalizacaoMaquina.DoModelo(maquina):Capturar(maquina, self._modelos[registro.MaquinaId].Modelo)
	end)
	if not capturou then return false, "Nao foi possivel preservar a personalizacao da peca." end
	local modificacoes = personalizacao:ObterDados()
	registro.Modificacoes = next(modificacoes) and modificacoes or nil
	-- A devolucao ao inventario precisa terminar antes de remover o Model. Se os dados recusarem, retorna sem
	-- apagar a maquina do terreno.
	local sucesso, mensagem = dados:RegistrarRecolhimento(registro)
	if not sucesso then return false, mensagem end
	self._registrosPorMaquina[maquina] = nil
	maquina:Destroy()
	return true, mensagem
end

-- Sincroniza as alteracoes visuais antes de descartar tokens, limites e vinculos locais do jogador. A limpeza
-- do terreno e o encerramento do ProfileStore sao realizados por seus respectivos sistemas.
function ServicoConstrucao:LimparJogador(jogador)
	self:Sincronizar(jogador)
	self._copias[jogador] = nil
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
