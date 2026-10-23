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

-- Monta indices de modelos, restauracoes, limites de pedidos e tokens de copia individual e em grupo. Para
-- cada tipo do catalogo, guarda o modelo original, seu volume e o deslocamento entre caixa e pivo.
function ServicoConstrucao.new()
	-- Os mapas separam modelos, plots restauradas, limites e vinculos Model-registro; os tokens guardam no
	-- servidor configuracoes individuais ou formacoes inteiras capturadas para copiar.
	local self = setmetatable({
		_modelos = {}, _carregados = {}, _limites = {}, _registrosPorMaquina = {}, _copias = {}, _copiasGrupo = {},
		_movimentosPendentes = {}, _sequenciaCopia = 0, _sequenciaMovimento = 0,
	}, ServicoConstrucao)
	-- Carrega recursos de ReplicatedStorage; nao depende de maquinas iniciais no Workspace. Mede uma vez os
	-- originais e conserva o deslocamento entre centro da caixa e pivo.
	local modelos = ReplicatedStorage:WaitForChild("ModelosMaquinas")
	for maquinaId in CatalogoMaquinas do
		local modelo = modelos:WaitForChild(maquinaId)
		local caixaOriginal, tamanho = Geometria.CaixaDeConstrucao(modelo)
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
function ServicoConstrucao:_PermitirPedido(jogador, custo)
	local agora = os.clock()
	local limite = self._limites[jogador] or { tempo = agora, tokens = 60 }
	custo = custo or 1

	-- Reposicao proporcional ao tempo permite varios cliques seguidos sem aceitar spam continuo. math.min
	-- impede acumular mais que a capacidade maxima durante uma espera longa.
	limite.tokens = math.min(60, limite.tokens + (agora - limite.tempo) * 30)
	limite.tempo = agora
	self._limites[jogador] = limite

	if type(custo) ~= "number" or custo < 1 or custo % 1 ~= 0 or limite.tokens < custo then return false end

	limite.tokens -= custo
	return true
end

-- Guarda no servidor um grupo pronto para colocar e devolve as transforms serializaveis para a previa do cliente.
function ServicoConstrucao:_RegistrarCopiaGrupo(jogador, pecas)
	self._sequenciaCopia += 1
	local token = self._sequenciaCopia
	self._copiasGrupo[jogador] = { Token = token, Pecas = pecas }
	local resposta = {}
	for indice, peca in pecas do
		resposta[indice] = {
			MaquinaId = peca.MaquinaId,
			Modificacoes = PersonalizacaoMaquina.new(peca.Modificacoes):ObterDados(),
			DeslocamentoInicial = peca.DeslocamentoInicial,
			RotacaoInicial = peca.RotacaoInicial,
		}
	end
	return { Token = token, Pecas = resposta }
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
		if outra == ignorar or (type(ignorar) == "table" and ignorar[outra]) or not outra:IsA("Model") then continue end

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
		local caixa, tamanho = Geometria.CaixaDeConstrucao(modelo)
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
function ServicoConstrucao:_CriarMaquina(jogador, terreno, maquinas, destino, registro, dadosModelo,
	minimoAlvo, rotacaoAlvo, totalRecebido)
	dadosModelo = dadosModelo or self._modelos[registro.MaquinaId]
	local maquina = dadosModelo.Modelo:Clone()

	maquina:SetAttribute("DonoUserId", jogador.UserId)
	maquina:SetAttribute("TerrenoId", terreno:GetAttribute("TerrenoId"))
	maquina:SetAttribute("PodeRecolher", true)
	local rotacao = rotacaoAlvo or CFrame.new(0, 0, 0, table.unpack(registro.Rotacao))
	local _, ocupado = dadosModelo.Volume:Calcular(rotacao)
	maquina:SetAttribute("VolumeMinimo", minimoAlvo or Vector3.new(table.unpack(registro.Posicao)))
	maquina:SetAttribute("VolumeOcupado", ocupado)
	maquina:SetAttribute("TamanhoConstrucao", dadosModelo.Volume:ObterTamanhoVisual())
	maquina:SetAttribute("RotacaoConstrucao", rotacao)
	if totalRecebido ~= nil then maquina:SetAttribute("TotalRecebido", totalRecebido) end
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

-- Captura uma peca ou grupo sem retirar as originais. O token guarda no servidor as configuracoes; os centros
-- e orientacoes relativos a ancora permitem que o cliente mova a formacao como uma unica previa.
function ServicoConstrucao:CopiarGrupo(jogador, maquinasSelecionadas)
	if type(maquinasSelecionadas) ~= "table" then return false, "Selecao de copia invalida." end
	local quantidade = 0
	for indice in maquinasSelecionadas do
		if type(indice) ~= "number" or indice % 1 ~= 0 or indice < 1 or indice > 60 then
			return false, "Selecao de copia invalida."
		end
		quantidade += 1
	end
	if quantidade < 1 or quantidade > 60 then return false, "Quantidade de pecas invalida." end
	for indice = 1, quantidade do
		if maquinasSelecionadas[indice] == nil then return false, "Selecao de copia invalida." end
	end
	if not self:_PermitirPedido(jogador, quantidade) then
		return false, "Muitas pecas para copiar agora. Aguarde um instante."
	end
	if not self:Restaurar(jogador) then return false, "Seus dados ou seu terreno ainda nao estao disponiveis." end

	local pecas, vistos = {}, {}
	local dadosGrupo, terrenoGrupo, pisoGrupo, maquinasGrupo
	local origem
	for _, maquina in maquinasSelecionadas do
		if typeof(maquina) ~= "Instance" or not maquina:IsA("Model") or vistos[maquina] then
			return false, "Selecao de copia invalida."
		end
		vistos[maquina] = true
		local dados, terreno, piso, maquinas = self:_ObterMaquina(jogador, maquina)
		local vinculo = self._registrosPorMaquina[maquina]
		local registro = vinculo and vinculo.registro
		if not dados or not registro or vinculo.jogador ~= jogador or registro.MaquinaId ~= maquina.Name
			or not table.find(dados:ObterConstrucoes(), registro)
		then return false, "Uma das pecas nao esta disponivel para copiar." end
		if dadosGrupo and (dados ~= dadosGrupo or terreno ~= terrenoGrupo or piso ~= pisoGrupo or maquinas ~= maquinasGrupo) then
			return false, "As pecas precisam pertencer a mesma plot."
		end
		dadosGrupo, terrenoGrupo, pisoGrupo, maquinasGrupo = dados, terreno, piso, maquinas
		origem = origem or Geometria.Origem(piso)

		local capturaValida, resultado = pcall(function()
			local personalizacao = PersonalizacaoMaquina.DoModelo(maquina)
				:Capturar(maquina, self._modelos[registro.MaquinaId].Modelo):ObterDados()
			local preparado = self:_PrepararModelo(registro.MaquinaId, personalizacao)
			liberarModelo(preparado)
			return personalizacao
		end)
		if not capturaValida then return false, "Nao foi possivel preservar a configuracao de uma peca." end

		local rotacao = maquina:GetAttribute("RotacaoConstrucao")
		if not rotacao then
			rotacao = origem:ToObjectSpace(maquina:GetPivot() * self._modelos[registro.MaquinaId].CaixaParaPivo:Inverse()).Rotation
		end
		rotacao = RotacaoConstrucao.ValidarNaGrade(rotacao)
		if not rotacao then return false, "Rotacao de uma peca invalida." end

		local minimo, ocupado = maquina:GetAttribute("VolumeMinimo"), maquina:GetAttribute("VolumeOcupado")
		if typeof(minimo) ~= "Vector3" or typeof(ocupado) ~= "Vector3" then
			local maximo
			minimo, maximo = Geometria.VolumeDoModelo(maquina, origem)
			ocupado = maximo and (maximo - minimo)
		end
		if typeof(minimo) ~= "Vector3" or typeof(ocupado) ~= "Vector3" then
			return false, "Volume de uma peca invalido."
		end
		registro.Modificacoes = next(resultado) and resultado or nil
		table.insert(pecas, {
			MaquinaId = registro.MaquinaId, Modificacoes = resultado,
			CentroInicial = minimo + ocupado / 2, RotacaoInicial = rotacao,
		})
	end

	local centroAncora = pecas[1].CentroInicial
	for _, peca in pecas do
		peca.DeslocamentoInicial = peca.CentroInicial - centroAncora
		peca.CentroInicial = nil
	end
	return true, "Peca copiada para colocacao.", self:_RegistrarCopiaGrupo(jogador, pecas)
end

-- Lista nomes e tamanhos sem enviar ao cliente os dados usados para reconstruir as pecas.
function ServicoConstrucao:ListarBlueprints(jogador)
	if not self:_PermitirPedido(jogador) then return false, "Aguarde um instante antes de atualizar os blueprints." end
	local dados = DataManager.ObterDados(jogador)
	local blueprints = dados and dados:ObterBlueprints()
	if not blueprints then return false, "Seus dados ainda nao estao disponiveis." end
	local resposta = {}
	for _, blueprint in blueprints do
		if type(blueprint) ~= "table" or type(blueprint.Id) ~= "string" or type(blueprint.Nome) ~= "string"
			or type(blueprint.Pecas) ~= "table" or #blueprint.Pecas < 1 or #blueprint.Pecas > 60
		then return false, "Os dados de um blueprint estao invalidos." end
		table.insert(resposta, { Id = blueprint.Id, Nome = blueprint.Nome, Quantidade = #blueprint.Pecas })
	end
	return true, "Blueprints carregados.", resposta
end

-- Captura um grupo validado pela rotina de copia e salva sua configuracao em relacao a primeira peca selecionada.
function ServicoConstrucao:CriarBlueprint(jogador, nome, maquinasSelecionadas)
	if nome ~= nil and type(nome) ~= "string" then return false, "Nome de blueprint invalido." end
	nome = nome or ""
	nome = string.gsub(string.gsub(nome, "^%s+", ""), "%s+$", "")
	local caracteres = utf8.len(nome)
	if not caracteres or caracteres > 40 or nome:find("[%c]") then
		return false, "Use um nome de ate 40 caracteres."
	end
	local dados = DataManager.ObterDados(jogador)
	local existentes = dados and dados:ObterBlueprints()
	if not existentes then return false, "Seus dados ainda nao estao disponiveis." end
	local identificador = tostring(#existentes + 1)
	if nome == "" then nome = "Blueprint " .. identificador end

	local sucesso, mensagem = self:CopiarGrupo(jogador, maquinasSelecionadas)
	if not sucesso then return false, mensagem end
	local captura = self._copiasGrupo[jogador]
	if not captura or #captura.Pecas ~= #maquinasSelecionadas then
		self._copiasGrupo[jogador] = nil
		return false, "Nao foi possivel capturar as pecas do blueprint."
	end
	local pecas = {}
	for indice, peca in captura.Pecas do
		local deslocamento = peca.DeslocamentoInicial
		local componentes = { peca.RotacaoInicial:GetComponents() }
		pecas[indice] = {
			MaquinaId = peca.MaquinaId,
			Modificacoes = PersonalizacaoMaquina.new(peca.Modificacoes):ObterDados(),
			DeslocamentoInicial = { deslocamento.X, deslocamento.Y, deslocamento.Z },
			RotacaoInicial = { table.unpack(componentes, 4, 12) },
		}
	end
	self._copiasGrupo[jogador] = nil
	local blueprint = { Id = identificador, Nome = nome, Pecas = pecas }
	local adicionado, resultado = dados:AdicionarBlueprint(blueprint)
	if not adicionado then return false, resultado end
	return true, "Blueprint salvo.", { Id = blueprint.Id, Nome = blueprint.Nome, Quantidade = #pecas }
end

-- Recria um token de grupo a partir do blueprint persistido; a confirmacao segue o fluxo de compra atomica existente.
function ServicoConstrucao:PrepararBlueprint(jogador, identificador)
	if type(identificador) ~= "string" then return false, "Blueprint invalido." end
	local dados = DataManager.ObterDados(jogador)
	local blueprints = dados and dados:ObterBlueprints()
	if not blueprints then return false, "Seus dados ainda nao estao disponiveis." end
	local blueprint
	for _, item in blueprints do
		if type(item) == "table" and item.Id == identificador then blueprint = item; break end
	end
	if not blueprint or type(blueprint.Pecas) ~= "table" or #blueprint.Pecas < 1 or #blueprint.Pecas > 60 then
		return false, "Esse blueprint nao esta disponivel."
	end
	if not self:_PermitirPedido(jogador, #blueprint.Pecas) then
		return false, "Muitas pecas para preparar agora. Aguarde um instante."
	end
	if not self:Restaurar(jogador) then return false, "Seus dados ou seu terreno ainda nao estao disponiveis." end
	local pecas = {}
	for indice, item in blueprint.Pecas do
		if type(item) ~= "table" then return false, "Os dados de uma peca do blueprint estao invalidos." end
		local definicao = self._modelos[item.MaquinaId]
		local deslocamento, matriz = item.DeslocamentoInicial, item.RotacaoInicial
		if not definicao or type(item.Modificacoes) ~= "table" or type(deslocamento) ~= "table"
			or #deslocamento ~= 3 or type(matriz) ~= "table" or #matriz ~= 9
		then return false, "Os dados de uma peca do blueprint estao invalidos." end
		for _, numero in deslocamento do if not finito(numero) then return false, "Deslocamento de blueprint invalido." end end
		for _, numero in matriz do if not finito(numero) then return false, "Rotacao de blueprint invalida." end end
		local rotacao = RotacaoConstrucao.ValidarNaGrade(CFrame.new(0, 0, 0, table.unpack(matriz)))
		if not rotacao then return false, "Rotacao de blueprint invalida." end
		local capturaValida, modificacoes = pcall(function()
			return PersonalizacaoMaquina.new(item.Modificacoes):ObterDados()
		end)
		if not capturaValida then return false, "Configuracao de blueprint invalida." end
		local preparou, modelo = pcall(self._PrepararModelo, self, item.MaquinaId, modificacoes)
		if not preparou then return false, "Configuracao de blueprint invalida." end
		liberarModelo(modelo)
		pecas[indice] = {
			MaquinaId = item.MaquinaId, Modificacoes = modificacoes,
			DeslocamentoInicial = Vector3.new(table.unpack(deslocamento)), RotacaoInicial = rotacao,
		}
	end
	local resposta = self:_RegistrarCopiaGrupo(jogador, pecas)
	resposta.BlueprintNome = blueprint.Nome
	return true, "Blueprint pronto para colocar.", resposta
end

-- Valida todos os destinos, cria todas as replicas e so entao consome o inventario em lote. Uma falha em
-- geometria, clonagem ou saldo descarta as novas instancias sem remover as fontes nem deixar colocacao parcial.
function ServicoConstrucao:ColocarGrupoCopia(jogador, token, pedidos)
	local copia = self._copiasGrupo[jogador]
	if not copia or type(token) ~= "number" or copia.Token ~= token then
		return false, "A copia selecionada nao esta mais disponivel."
	end
	if type(pedidos) ~= "table" then
		return false, "Destinos da copia invalidos."
	end
	local quantidade = 0
	for indice in pedidos do
		if type(indice) ~= "number" or indice % 1 ~= 0 or indice < 1 or indice > #copia.Pecas then
			return false, "Destinos da copia invalidos."
		end
		quantidade += 1
	end
	if quantidade ~= #copia.Pecas or #pedidos ~= #copia.Pecas then
		return false, "Destinos da copia invalidos."
	end
	for indice = 1, quantidade do
		if pedidos[indice] == nil then return false, "Destinos da copia invalidos." end
	end
	if not self:_PermitirPedido(jogador, quantidade) then
		return false, "Muitas pecas para colocar agora. Aguarde um instante."
	end
	if not self:Restaurar(jogador) then return false, "Seus dados ou seu terreno ainda nao estao disponiveis." end
	local dados, terreno, piso, maquinas = contexto(jogador)
	if not dados then return false, "Terreno indisponivel." end

	local alvos = {}
	for indice, pedido in pedidos do
		if type(pedido) ~= "table" then
			for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
			return false, "Destino da copia invalido."
		end
		local minimo = pedido.Minimo
		local rotacao = RotacaoConstrucao.ValidarNaGrade(pedido.Rotacao)
		if not rotacao then
			for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
			return false, "Rotacao invalida."
		end
		local peca = copia.Pecas[indice]
		local preparou, dadosModelo = pcall(self._PrepararModelo, self, peca.MaquinaId, peca.Modificacoes)
		if not preparou then
			for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
			return false, "Configuracao de uma peca invalida."
		end
		local destino = destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo)
		local _, ocupado = dadosModelo.Volume:Calcular(rotacao)
		if not destino then
			liberarModelo(dadosModelo)
			for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
			return false, "Essa posicao esta ocupada ou fora da grade do terreno."
		end
		local maximo = minimo + ocupado
		for _, anterior in alvos do
			local a, b = anterior.Minimo, anterior.Minimo + anterior.Ocupado
			local erro = Geometria.Tolerancia
			if minimo.X < b.X - erro and maximo.X > a.X + erro
				and minimo.Y < b.Y - erro and maximo.Y > a.Y + erro
				and minimo.Z < b.Z - erro and maximo.Z > a.Z + erro
			then
				liberarModelo(dadosModelo)
				for _, item in alvos do liberarModelo(item.DadosModelo) end
				return false, "As copias nao podem se sobrepor."
			end
		end
		local componentes = { rotacao:GetComponents() }
		local registro = {
			MaquinaId = peca.MaquinaId,
			Posicao = { minimo.X, minimo.Y, minimo.Z },
			Rotacao = { table.unpack(componentes, 4, 12) },
		}
		if next(peca.Modificacoes) then
			registro.Modificacoes = PersonalizacaoMaquina.new(peca.Modificacoes):ObterDados()
		end
		table.insert(alvos, {
			Peca = peca, Minimo = minimo, Rotacao = rotacao, Ocupado = ocupado,
			Destino = destino, DadosModelo = dadosModelo, Registro = registro,
		})
	end

	local criadas = {}
	local criacaoValida = pcall(function()
		for _, alvo in alvos do
			table.insert(criadas, self:_CriarMaquina(
				jogador, terreno, maquinas, alvo.Destino, alvo.Registro, alvo.DadosModelo,
				alvo.Minimo, alvo.Rotacao
			))
		end
	end)
	if not criacaoValida then
		for _, maquina in criadas do self._registrosPorMaquina[maquina] = nil; maquina:Destroy() end
		for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
		return false, "Nao foi possivel criar todas as copias."
	end

	local registros = {}
	for _, alvo in alvos do table.insert(registros, alvo.Registro) end
	local sucesso, mensagem = dados:RegistrarColocacoes(registros)
	if not sucesso then
		for _, maquina in criadas do self._registrosPorMaquina[maquina] = nil; maquina:Destroy() end
		for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
		return false, mensagem
	end
	for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
	return true, mensagem, criadas
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

-- Valida e captura o grupo antes de destruir suas instancias. O perfil conserva os registros na origem ate a
-- confirmacao, assim uma sessao interrompida ainda pode restaurar as pecas no ponto anterior.
function ServicoConstrucao:IniciarMovimento(jogador, maquinasSelecionadas)
	if type(maquinasSelecionadas) ~= "table" or #maquinasSelecionadas < 1 or #maquinasSelecionadas > 60 then
		return false, "Selecao de movimento invalida."
	end
	if self._movimentosPendentes[jogador] then return false, "Ja existe um movimento em andamento." end
	if not self:_PermitirPedido(jogador, #maquinasSelecionadas) then
		return false, "Muitas pecas para mover agora. Aguarde um instante."
	end
	if not self:Restaurar(jogador) then return false, "Seus dados ou seu terreno ainda nao estao disponiveis." end

	local pecas, vistos = {}, {}
	local dadosGrupo, terrenoGrupo, pisoGrupo, maquinasGrupo
	for _, maquina in maquinasSelecionadas do
		if typeof(maquina) ~= "Instance" or not maquina:IsA("Model") or vistos[maquina] then
			return false, "Selecao de movimento invalida."
		end
		vistos[maquina] = true
		local dados, terreno, piso, maquinas = self:_ObterMaquina(jogador, maquina)
		local vinculo = self._registrosPorMaquina[maquina]
		local registro = vinculo and vinculo.registro
		if not dados or not registro or vinculo.jogador ~= jogador or registro.MaquinaId ~= maquina.Name
			or not table.find(dados:ObterConstrucoes(), registro)
		then return false, "Uma das pecas nao esta disponivel para mover." end
		if dadosGrupo and (dados ~= dadosGrupo or terreno ~= terrenoGrupo or piso ~= pisoGrupo or maquinas ~= maquinasGrupo) then
			return false, "As pecas precisam pertencer a mesma plot."
		end
		dadosGrupo, terrenoGrupo, pisoGrupo, maquinasGrupo = dados, terreno, piso, maquinas

		local capturaValida, personalizacao = pcall(function()
			local capturada = PersonalizacaoMaquina.DoModelo(maquina):Capturar(maquina, self._modelos[registro.MaquinaId].Modelo)
			local modificacoes = capturada:ObterDados()
			local preparado = self:_PrepararModelo(registro.MaquinaId, modificacoes)
			liberarModelo(preparado)
			return modificacoes
		end)
		if not capturaValida then return false, "Nao foi possivel preservar a configuracao de uma peca." end
		table.insert(pecas, {
			Maquina = maquina, Registro = registro, MaquinaId = registro.MaquinaId,
			Modificacoes = personalizacao, TotalRecebido = maquina:GetAttribute("TotalRecebido"),
		})
	end

	self._sequenciaMovimento += 1
	local token = self._sequenciaMovimento
	for _, peca in pecas do
		peca.Registro.Modificacoes = next(peca.Modificacoes) and peca.Modificacoes or nil
		self._registrosPorMaquina[peca.Maquina] = nil
	end
	self._movimentosPendentes[jogador] = {
		Token = token, Dados = dadosGrupo, Terreno = terrenoGrupo, Piso = pisoGrupo,
		Maquinas = maquinasGrupo, Pecas = pecas,
	}
	for _, peca in pecas do peca.Maquina:Destroy() end
	return true, "Peca removida para movimentacao.", token
end

-- Confirma um movimento pendente. Todos os destinos e modelos substitutos sao preparados antes de publicar
-- novas instancias, e os registros so mudam depois que o lote inteiro foi criado.
function ServicoConstrucao:_ConcluirMovimento(jogador, token, movimentos, grupo)
	local pendente = self._movimentosPendentes[jogador]
	if not pendente or pendente.Token ~= token then return false, "Movimento nao esta mais disponivel." end
	if type(movimentos) ~= "table" or #movimentos ~= #pendente.Pecas
		or (grupo and #movimentos < 2) or (not grupo and #movimentos ~= 1)
	then return false, "Destinos do movimento invalidos." end
	local dados, terreno, piso, maquinas = contexto(jogador)
	if dados ~= pendente.Dados or terreno ~= pendente.Terreno or piso ~= pendente.Piso or maquinas ~= pendente.Maquinas then
		return false, "Terreno indisponivel para concluir o movimento."
	end

	local alvos = {}
	local origem = Geometria.Origem(piso)
	for indice, movimento in movimentos do
		if type(movimento) ~= "table" then return false, "Destino do movimento invalido." end
		local rotacao = RotacaoConstrucao.ValidarNaGrade(movimento.Rotacao)
		if not rotacao then return false, "Rotacao invalida." end
		local peca = pendente.Pecas[indice]
		local preparou, dadosModelo = pcall(self._PrepararModelo, self, peca.MaquinaId, peca.Modificacoes)
		if not preparou then
			for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
			return false, "Configuracao de uma peca invalida."
		end
		local alvo = {
			Peca = peca, Minimo = movimento.Minimo, Rotacao = rotacao, DadosModelo = dadosModelo,
		}
		local destino = destinoLivre(piso, maquinas, alvo.Minimo, rotacao, dadosModelo)
		local _, ocupado = dadosModelo.Volume:Calcular(rotacao)
		alvo.Destino, alvo.Ocupado = destino, ocupado
		if not destino then
			liberarModelo(dadosModelo)
			for _, anterior in alvos do liberarModelo(anterior.DadosModelo) end
			return false, "Essa posicao esta ocupada ou fora da grade do terreno."
		end

		local maximo = alvo.Minimo + ocupado
		for _, anterior in alvos do
			local anteriorMaximo = anterior.Minimo + anterior.Ocupado
			local erro = Geometria.Tolerancia
			if alvo.Minimo.X < anteriorMaximo.X - erro and maximo.X > anterior.Minimo.X + erro
				and alvo.Minimo.Y < anteriorMaximo.Y - erro and maximo.Y > anterior.Minimo.Y + erro
				and alvo.Minimo.Z < anteriorMaximo.Z - erro and maximo.Z > anterior.Minimo.Z + erro
			then
				liberarModelo(dadosModelo)
				for _, item in alvos do liberarModelo(item.DadosModelo) end
				return false, "As pecas do grupo nao podem se sobrepor."
			end
		end
		table.insert(alvos, alvo)
	end

	local criadas = {}
	local criacaoValida = pcall(function()
		for _, alvo in alvos do
			table.insert(criadas, self:_CriarMaquina(
				jogador, terreno, maquinas, alvo.Destino, alvo.Peca.Registro, alvo.DadosModelo,
				alvo.Minimo, alvo.Rotacao, alvo.Peca.TotalRecebido
			))
		end
	end)
	if not criacaoValida then
		for _, maquina in criadas do
			self._registrosPorMaquina[maquina] = nil
			maquina:Destroy()
		end
		for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
		return false, "Nao foi possivel recriar todas as pecas do movimento."
	end

	for _, alvo in alvos do
		local componentes = { alvo.Rotacao:GetComponents() }
		local registro = alvo.Peca.Registro
		registro.Posicao = { alvo.Minimo.X, alvo.Minimo.Y, alvo.Minimo.Z }
		registro.Rotacao = { table.unpack(componentes, 4, 12) }
		registro.Modificacoes = next(alvo.Peca.Modificacoes) and alvo.Peca.Modificacoes or nil
		liberarModelo(alvo.DadosModelo)
	end
	self._movimentosPendentes[jogador] = nil
	return true, "Pecas movidas.", criadas
end

function ServicoConstrucao:Mover(jogador, token, minimo, rotacao)
	return self:_ConcluirMovimento(jogador, token, { { Minimo = minimo, Rotacao = rotacao } }, false)
end

function ServicoConstrucao:MoverGrupo(jogador, token, movimentos)
	return self:_ConcluirMovimento(jogador, token, movimentos, true)
end

-- Cancelar o arraste encerra o token e devolve as configuracoes capturadas ao inventario. As instancias antigas
-- ja foram destruidas ao iniciar; as entradas do perfil so sao removidas se a devolucao inteira for aceita.
function ServicoConstrucao:CancelarMovimento(jogador, token)
	local pendente = self._movimentosPendentes[jogador]
	if not pendente or pendente.Token ~= token then return false, "Movimento nao esta mais disponivel." end
	local devolucoes = {}
	for _, peca in pendente.Pecas do
		table.insert(devolucoes, { Registro = peca.Registro, Modificacoes = peca.Modificacoes })
	end
	local sucesso, mensagem
	if #devolucoes == 1 then
		local registro = devolucoes[1].Registro
		sucesso, mensagem = pendente.Dados:RegistrarRecolhimento(registro)
	else
		sucesso, mensagem = pendente.Dados:RegistrarRecolhimentos(devolucoes)
	end
	if not sucesso then return false, mensagem end
	self._movimentosPendentes[jogador] = nil
	return true, mensagem or "Pecas devolvidas ao inventario."
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
	if type(maquina) == "table" then return self:RecolherGrupo(jogador, maquina) end
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

-- Valida e devolve o grupo inteiro antes de destruir seus modelos; uma falha preserva todas as pecas no terreno.
function ServicoConstrucao:RecolherGrupo(jogador, maquinasSelecionadas)
	if type(maquinasSelecionadas) ~= "table" then return false, "Maquinas invalidas." end
	local quantidade = 0
	for indice in maquinasSelecionadas do
		if type(indice) ~= "number" or indice % 1 ~= 0 or indice < 1 or indice > 60 then
			return false, "Maquinas invalidas."
		end
		quantidade += 1
	end
	if quantidade < 2 or quantidade > 60 then return false, "Quantidade de maquinas invalida." end
	for indice = 1, quantidade do
		if maquinasSelecionadas[indice] == nil then return false, "Maquinas invalidas." end
	end
	if not self:_PermitirPedido(jogador, quantidade) then
		return false, "Muitos pedidos de construcao. Aguarde um instante."
	end
	if not self:Restaurar(jogador) then
		return false, "Seus dados ou seu terreno ainda nao estao disponiveis."
	end

	local dados, terreno, _, pastaMaquinas = contexto(jogador)
	if not dados then return false, "Terreno indisponivel." end
	local devolucoes, vistos = {}, {}
	for _, maquina in maquinasSelecionadas do
		if typeof(maquina) ~= "Instance" or not maquina:IsA("Model") or vistos[maquina] then
			return false, "Maquina invalida ou repetida."
		end
		vistos[maquina] = true
		if maquina.Parent ~= pastaMaquinas
			or maquina:GetAttribute("DonoUserId") ~= jogador.UserId
			or maquina:GetAttribute("TerrenoId") ~= terreno:GetAttribute("TerrenoId")
		then
			return false, "Uma das maquinas nao pertence ao seu terreno."
		end

		local vinculo = self._registrosPorMaquina[maquina]
		local registro = vinculo and vinculo.registro
		if not registro or vinculo.jogador ~= jogador or not self._modelos[registro.MaquinaId] then
			return false, "Uma das maquinas nao pode ser recolhida."
		end

		local capturou, modificacoes = pcall(function()
			return PersonalizacaoMaquina.DoModelo(maquina)
				:Capturar(maquina, self._modelos[registro.MaquinaId].Modelo):ObterDados()
		end)
		if not capturou then return false, "Nao foi possivel preservar a personalizacao das pecas." end
		table.insert(devolucoes, { Registro = registro, Modificacoes = modificacoes })
	end

	local sucesso, mensagem = dados:RegistrarRecolhimentos(devolucoes)
	if not sucesso then return false, mensagem end
	for _, maquina in maquinasSelecionadas do
		self._registrosPorMaquina[maquina] = nil
		maquina:Destroy()
	end
	return true, mensagem or "Pecas devolvidas ao inventario."
end

-- Vende uma ou varias pecas da plot como lote. O servidor resolve cada registro e o preco no catalogo; so apaga
-- os modelos depois de o perfil remover todos os registros e creditar o total com sucesso.
function ServicoConstrucao:VenderMaquinasColocadas(jogador, maquinasSelecionadas)
	if type(maquinasSelecionadas) ~= "table" then return false, "Selecao de venda invalida." end
	local quantidade = 0
	for indice in maquinasSelecionadas do
		if type(indice) ~= "number" or indice % 1 ~= 0 or indice < 1 or indice > 60 then
			return false, "Selecao de venda invalida."
		end
		quantidade += 1
	end
	if quantidade < 1 or quantidade > 60 then return false, "Quantidade de pecas invalida." end
	for indice = 1, quantidade do
		if maquinasSelecionadas[indice] == nil then return false, "Selecao de venda invalida." end
	end
	if not self:_PermitirPedido(jogador, quantidade) then
		return false, "Muitas pecas para vender agora. Aguarde um instante."
	end
	if not self:Restaurar(jogador) then
		return false, "Seus dados ou seu terreno ainda nao estao disponiveis."
	end

	local dados, terreno, _, pastaMaquinas = contexto(jogador)
	if not dados then return false, "Terreno indisponivel." end
	local registros, vistos = {}, {}
	for _, maquina in maquinasSelecionadas do
		if typeof(maquina) ~= "Instance" or not maquina:IsA("Model") or vistos[maquina] then
			return false, "Maquina invalida ou repetida."
		end
		vistos[maquina] = true
		if maquina.Parent ~= pastaMaquinas
			or maquina:GetAttribute("DonoUserId") ~= jogador.UserId
			or maquina:GetAttribute("TerrenoId") ~= terreno:GetAttribute("TerrenoId")
		then
			return false, "Uma das maquinas nao pertence ao seu terreno."
		end

		local vinculo = self._registrosPorMaquina[maquina]
		local registro = vinculo and vinculo.registro
		if not registro or vinculo.jogador ~= jogador or not self._modelos[registro.MaquinaId]
			or not table.find(dados:ObterConstrucoes(), registro)
		then
			return false, "Uma das maquinas nao pode ser vendida."
		end
		table.insert(registros, registro)
	end

	local sucesso, mensagem = dados:VenderConstrucoes(registros)
	if not sucesso then return false, mensagem end
	for _, maquina in maquinasSelecionadas do
		self._registrosPorMaquina[maquina] = nil
		maquina:Destroy()
	end
	return true, mensagem
end

-- Sincroniza as alteracoes visuais antes de descartar tokens, limites e vinculos locais do jogador. A limpeza
-- do terreno e o encerramento do ProfileStore sao realizados por seus respectivos sistemas.
function ServicoConstrucao:LimparJogador(jogador)
	self:Sincronizar(jogador)
	self._copias[jogador] = nil
	self._copiasGrupo[jogador] = nil
	self._limites[jogador] = nil
	self._movimentosPendentes[jogador] = nil
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

-- Coordenacao interna para mecanicas que reiniciam a plot. O callback prepara/valida os dados antes
-- de apagar o mundo. Nenhuma destas etapas deve ceder a execucao: pedidos antigos nao podem intercalar-se.
function ServicoConstrucao:ReiniciarProgresso(jogador, alterarDados)
	local dados, terreno, _, maquinas = contexto(jogador)
	local minerios = terreno and terreno:FindFirstChild("Minerios")
	if not dados or not minerios then return false, "Seus dados ou seu terreno ainda nao estao disponiveis." end
	local sucesso, mensagem, resultado = alterarDados(dados)
	if not sucesso then return false, mensagem end
	-- Tokens antigos nao podem recriar pecas, devolver variantes ou aplicar melhorias depois do reinicio.
	self._copias[jogador], self._copiasGrupo[jogador], self._movimentosPendentes[jogador] = nil, nil, nil
	for maquina, vinculo in self._registrosPorMaquina do
		if vinculo.jogador == jogador then self._registrosPorMaquina[maquina] = nil end
	end
	maquinas:ClearAllChildren()
	minerios:ClearAllChildren()
	self._carregados[terreno] = dados
	dados:Sincronizar()
	return true, mensagem, resultado
end

return ServicoConstrucao
