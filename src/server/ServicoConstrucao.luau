--[[
Módulo: ServicoConstrucao (LPOO - Serviço de Domínio do Servidor)
Responsabilidade:
Gerencia todas as operações de construção na plot do jogador (colocação individual e em lote,
movimentação, rotação, recolhimento, venda direta, colagem, blueprints e restauração de sessão).
]]

-- Autoridade da construcao: confere terreno, grade e ocupacao antes de coordenar o registro salvo e o modelo
-- colocado.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RotacaoConstrucao = require(ReplicatedStorage.Shared.RotacaoConstrucao)
local PersonalizacaoMaquina = require(ReplicatedStorage.Shared.PersonalizacaoMaquina)
local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local EsteiraInclinada = require(ReplicatedStorage.Shared.EsteiraInclinada)
local ElevadorVertical = require(ReplicatedStorage.Shared.ElevadorVertical)
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local Limites = require(ReplicatedStorage.Shared.LimitesConstrucao)
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))
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
    _historicoCopias = {}, _historicoDesfazer = {}, _historicoRefazer = {}, _temposPrevia = {},
    _movimentosPendentes = {}, _sequenciaCopia = 0, _sequenciaMovimento = 0,
  }, ServicoConstrucao)
	-- Carrega recursos de ReplicatedStorage; nao depende de maquinas iniciais no Workspace. Mede uma vez os
	-- originais e conserva o deslocamento entre centro da caixa e pivo.
	local modelos = ReplicatedStorage:WaitForChild("ModelosMaquinas")
	for maquinaId in CatalogoMaquinas do
		local modelo = modelos:WaitForChild(maquinaId)
		local caixaOriginal, tamanho = Geometria.CaixaDeConstrucao(modelo)
		self._modelos[maquinaId] = {
			Modelo = modelo, Volume = VolumeConstrucao.new(tamanho, CatalogoMaquinas[maquinaId].Blocos, CatalogoMaquinas[maquinaId]),
			CaixaParaPivo = caixaOriginal:ToObjectSpace(modelo:GetPivot()),
		}
	end
	return self
end

-- O saldo de pedidos permite rajadas de cliques e se recupera com o tempo, limitando spam continuo.
-- Lotes maiores mantem o custo da maior rajada anterior, sem aumentar o orcamento de cliques individuais.
function ServicoConstrucao:_PermitirPedido(jogador, custo)
	local agora = os.clock()
	local limite = self._limites[jogador] or { tempo = agora, tokens = 60 }
	custo = custo or 1

	-- Reposicao proporcional ao tempo permite varios cliques seguidos sem aceitar spam continuo. math.min
	-- impede acumular mais que a capacidade maxima durante uma espera longa.
	limite.tokens = math.min(60, limite.tokens + (agora - limite.tempo) * 30)
	limite.tempo = agora
	self._limites[jogador] = limite

	if type(custo) ~= "number" or custo < 1 or custo % 1 ~= 0 or custo > Limites.PecasPorGrupo then return false end
	custo = math.min(custo, 60)
	if limite.tokens < custo then return false end

	limite.tokens -= custo
	return true
end

-- Guarda no servidor um grupo pronto para colocar e devolve as transforms serializaveis para a previa do cliente.
function ServicoConstrucao:_ObterCopiaGrupoPorToken(jogador, token)
  local atual = self._copiasGrupo[jogador]
  if atual and atual.Token == token then return atual end
  for _, item in self._historicoCopias[jogador] or {} do
    if item.Token == token then return item end
  end
  return nil
end

--- Método auxiliar privado (ServicoConstrucao:_RegistrarAcaoHistorico) encapsulado na classe.
function ServicoConstrucao:_RegistrarAcaoHistorico(jogador, acao)
  if self._executandoHistorico then return end
  local pilha = self._historicoDesfazer[jogador] or {}
  table.insert(pilha, acao)
  while #pilha > 50 do table.remove(pilha, 1) end
  self._historicoDesfazer[jogador] = pilha
  self._historicoRefazer[jogador] = nil
end

--- Método auxiliar privado (ServicoConstrucao:_RegistrarCopiaGrupo) encapsulado na classe.
function ServicoConstrucao:_RegistrarCopiaGrupo(jogador, pecas)
  self._sequenciaCopia += 1
  local token = self._sequenciaCopia
  local entrada = { Token = token, Pecas = pecas }
  self._copiasGrupo[jogador] = entrada
  local historico = self._historicoCopias[jogador] or {}
  table.insert(historico, 1, entrada)
  while #historico > 15 do table.remove(historico) end
  self._historicoCopias[jogador] = historico
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
	if typeof(minimo) ~= "Vector3" then return nil, "Posicao invalida." end

	-- O canto recebido deve estar em multiplos exatos do passo da grade e nao pode conter NaN ou infinito. A
	-- verificacao do servidor independe do que a previa mostrou.
	for _, v in { minimo.X, minimo.Y, minimo.Z } do
		if not finito(v) or v % Geometria.Passo ~= 0 then
			return nil, "Posicao invalida."
		end
	end

	local extensao, ocupado = dadosModelo.Volume:Calcular(rotacao)
	local maximo = minimo + ocupado

	if not Geometria.DentroDoTerreno(minimo, ocupado, piso.Size) then
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
	) * RotacaoConstrucao.DecomporEsteira(rotacao,dadosModelo.Definicao)

	for _, v in { caixaDestino:GetComponents() } do
		if not finito(v) then return nil end
	end

	return caixaDestino * dadosModelo.CaixaParaPivo
end

-- Recebe um tipo e suas diferencas. Reutiliza a referencia base quando nao ha alteracoes; caso contrario, cria
-- uma copia temporaria, aplica a configuracao e valida seus componentes e dimensoes.
function ServicoConstrucao:_PrepararModelo(maquinaId, modificacoes, rotacao, encaixeGrade)
	local base = assert(self._modelos[maquinaId], "Maquina invalida.")
	local personalizacao = PersonalizacaoMaquina.new(modificacoes)
	rotacao = rotacao or CFrame.identity
	local _,angulo = RotacaoConstrucao.DecomporEsteira(rotacao,CatalogoMaquinas[maquinaId])
	if next(personalizacao:ObterDados()) == nil and angulo==0 then return base end
	-- Uma configuracao diferente precisa de uma copia temporaria para ser aplicada e medida. Construir Maquina
	-- valida seus componentes; Destruir encerra esse objeto de validacao.
	local modelo = base.Modelo:Clone()
	local sucesso, resultado = pcall(function()
		personalizacao:Aplicar(modelo)
		local caixa, tamanho = Geometria.CaixaDeConstrucao(modelo)
		local definicao = personalizacao:ObterDefinicao(CatalogoMaquinas[maquinaId])
		if encaixeGrade~=false then EsteiraInclinada.Aplicar(modelo,definicao,rotacao)
		else modelo:SetAttribute("OrientacaoEsteiraLegada",true) end
		caixa = Geometria.CaixaDeConstrucao(modelo)
		local validacao = Maquina.new(modelo, nil, definicao)
		validacao:Destruir()
		return {
			Modelo = modelo, Volume = VolumeConstrucao.new(tamanho, definicao.Blocos, if encaixeGrade~=false then definicao else nil),
			Definicao = if encaixeGrade~=false then definicao else nil,
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
	registro.Id=registro.Id or game:GetService("HttpService"):GenerateGUID(false)

	maquina:SetAttribute("DonoUserId", jogador.UserId)
	maquina:SetAttribute("TerrenoId", terreno:GetAttribute("TerrenoId"))
	maquina:SetAttribute("PodeRecolher", true)
	maquina:SetAttribute("IdUnidade", registro.Id)
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
	require(script.Parent.ExpansaoPlot).Aplicar(terreno,dados:ObterUpgrade("Expansao"))
	-- Restaurar pode ser chamado por caminhos diferentes. Este cache evita duplicar construcoes quando o mesmo
	-- objeto de dados ja foi carregado nesta plot.
	if self._carregados[terreno] == dados then return true end

	local registros = dados:ObterConstrucoes()

	if type(registros) ~= "table" then
		warn("MaquinasColocadas indisponivel para " .. jogador.Name)
		return false
	end

	for indice, registro in table.clone(registros) do
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
					local preparou, preparado = pcall(self._PrepararModelo, self, registro.MaquinaId, registro.Modificacoes, rotacao,registro.InclinacaoGrade==true)
					if preparou then
						dadosModelo = preparado
						destino = destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo)
					end
				end
			end
		end

		if destino then
			self:_CriarMaquina(jogador, terreno, maquinas, destino, registro, dadosModelo)
		elseif dados:RegistrarRecolhimento(registro) then
			warn("A maquina " .. tostring(indice) .. " de " .. jogador.Name .. " nao foi restaurada e voltou ao inventario.")
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

	rotacao = RotacaoConstrucao.ValidarNaGrade(rotacao,CatalogoMaquinas[maquinaId])

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
	local preparou, preparado = pcall(self._PrepararModelo, self, maquinaId, modificacoes, rotacao)
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
		InclinacaoGrade = if dadosModelo.Modelo:GetAttribute("InclinacaoEsteira") then true else nil,
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
  self:_RegistrarAcaoHistorico(jogador, {
    Tipo = "Colocacao",
    Pecas = { {
      Id = registro.Id, MaquinaId = registro.MaquinaId,
      Posicao = table.clone(registro.Posicao), Rotacao = table.clone(registro.Rotacao),
      InclinacaoGrade = registro.InclinacaoGrade,
      Modificacoes = registro.Modificacoes and PersonalizacaoMaquina.new(registro.Modificacoes):ObterDados() or nil,
    } },
  })
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
	rotacao = RotacaoConstrucao.EncaixarNaGrade(rotacao,CatalogoMaquinas[maquina.Name])
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
		if type(indice) ~= "number" or indice % 1 ~= 0 or indice < 1 or indice > Limites.PecasPorGrupo then
			return false, "Selecao de copia invalida."
		end
		quantidade += 1
	end
	if quantidade < 1 or quantidade > Limites.PecasPorGrupo then return false, "Quantidade de pecas invalida." end
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
		rotacao = RotacaoConstrucao.ValidarNaGrade(rotacao,CatalogoMaquinas[registro.MaquinaId])
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

--- Método auxiliar privado (ServicoConstrucao:_ValidarNomeBlueprint) encapsulado na classe.
function ServicoConstrucao:_ValidarNomeBlueprint(nome, idPadrao)
  if nome ~= nil and type(nome) ~= "string" then return nil, "Nome de blueprint invalido." end
  nome = string.gsub(string.gsub(nome or "", "^%s+", ""), "%s+$", "")
  local caracteres = utf8.len(nome)
  if not caracteres or caracteres > 40 or nome:find("[%c]") then
    return nil, "Use um nome de ate 40 caracteres."
  end
  if nome == "" then nome = "Blueprint " .. tostring(idPadrao) end
  return nome
end

--- Método auxiliar privado (ServicoConstrucao:_ResumoBlueprint) encapsulado na classe.
function ServicoConstrucao:_ResumoBlueprint(blueprint)
  if type(blueprint) ~= "table" or type(blueprint.Id) ~= "string" or type(blueprint.Nome) ~= "string"
    or type(blueprint.Pecas) ~= "table" or #blueprint.Pecas < 1 or #blueprint.Pecas > Limites.PecasPorGrupo
  then return nil end
  local pecas = {}
  local custoTotal, renascimento, craft = "0", 0, 0
  local minX, minY, minZ = math.huge, math.huge, math.huge
  local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
  for indice, item in blueprint.Pecas do
    if type(item) ~= "table" then return nil end
    local defModelo = self._modelos[item.MaquinaId]
    local cat = CatalogoMaquinas[item.MaquinaId]
    local deslocamento, matriz = item.DeslocamentoInicial, item.RotacaoInicial
    if not defModelo or not cat or type(item.Modificacoes) ~= "table"
      or type(deslocamento) ~= "table" or #deslocamento ~= 3
      or type(matriz) ~= "table" or #matriz ~= 9
    then return nil end
    for _, n in deslocamento do if not finito(n) then return nil end end
    for _, n in matriz do if not finito(n) then return nil end end
    local rotacao = RotacaoConstrucao.ValidarNaGrade(CFrame.new(0, 0, 0, table.unpack(matriz)), cat)
    if not rotacao then return nil end
    local okMod, modificacoes = pcall(function()
      return PersonalizacaoMaquina.new(item.Modificacoes):ObterDados()
    end)
    if not okMod then return nil end
    local posRel = Vector3.new(table.unpack(deslocamento))
    local _, ocupado = defModelo.Volume:Calcular(rotacao)
    local pMin, pMax = posRel - ocupado * 0.5, posRel + ocupado * 0.5
    minX, minY, minZ = math.min(minX, pMin.X), math.min(minY, pMin.Y), math.min(minZ, pMin.Z)
    maxX, maxY, maxZ = math.max(maxX, pMax.X), math.max(maxY, pMax.Y), math.max(maxZ, pMax.Z)
    if cat.Renascimento then
      renascimento += 1
    elseif cat.Receita then
      craft += 1
    elseif InteiroGrande.eValido(cat.Preco) then
      custoTotal = InteiroGrande.somar(custoTotal, cat.Preco)
    end
    pecas[indice] = {
      MaquinaId = item.MaquinaId, Modificacoes = modificacoes,
      DeslocamentoInicial = posRel, RotacaoInicial = rotacao,
    }
  end
  local passo = Geometria.Passo
  local blocos = {
    math.max(1, math.round((maxX - minX) / passo)),
    math.max(1, math.round((maxY - minY) / passo)),
    math.max(1, math.round((maxZ - minZ) / passo)),
  }
  return {
    Id = blueprint.Id, Nome = blueprint.Nome, Quantidade = #pecas,
    Custo = custoTotal, Renascimento = renascimento, Craft = craft, Blocos = blocos, Pecas = pecas,
  }
end

--- Método auxiliar privado (ServicoConstrucao:_CapturarPecasParaBlueprint) encapsulado na classe.
function ServicoConstrucao:_CapturarPecasParaBlueprint(jogador, maquinasSelecionadas)
  local historicoAntes = self._historicoCopias[jogador] and table.clone(self._historicoCopias[jogador]) or nil
  local anteriorGrupo = self._copiasGrupo[jogador]
  local sucesso, mensagem = self:CopiarGrupo(jogador, maquinasSelecionadas)
  if not sucesso then return nil, mensagem end
  local captura = self._copiasGrupo[jogador]
  self._copiasGrupo[jogador] = anteriorGrupo
  self._historicoCopias[jogador] = historicoAntes
  if not captura or #captura.Pecas ~= #maquinasSelecionadas then
    return nil, "Nao foi possivel capturar as pecas do blueprint."
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
  return pecas
end

--- Método público LPOO (ServicoConstrucao:ListarBlueprints).
function ServicoConstrucao:ListarBlueprints(jogador)
  if not self:_PermitirPedido(jogador) then return false, "Aguarde um instante antes de atualizar os blueprints." end
  local dados = DataManager.ObterDados(jogador)
  local blueprints = dados and dados:ObterBlueprints()
  if not blueprints then return false, "Seus dados ainda nao estao disponiveis." end
  local resposta = {}
  for _, blueprint in blueprints do
    local resumo = self:_ResumoBlueprint(blueprint)
    if not resumo then return false, "Os dados de um blueprint estao invalidos." end
    table.insert(resposta, resumo)
  end
  return true, "Blueprints carregados.", resposta
end

--- Método público LPOO (ServicoConstrucao:CriarBlueprint).
function ServicoConstrucao:CriarBlueprint(jogador, nome, maquinasSelecionadas)
  local dados = DataManager.ObterDados(jogador)
  local existentes = dados and dados:ObterBlueprints()
  if not existentes then return false, "Seus dados ainda nao estao disponiveis." end
  local usados = {}
  for _, b in existentes do
    if type(b) == "table" and type(b.Id) == "string" then usados[b.Id] = true end
  end
  local numeroId = #existentes + 1
  while usados[tostring(numeroId)] do numeroId += 1 end
  local identificador = tostring(numeroId)
  local nomeValido, erroNome = self:_ValidarNomeBlueprint(nome, identificador)
  if not nomeValido then return false, erroNome end

  local pecas, erroCaptura = self:_CapturarPecasParaBlueprint(jogador, maquinasSelecionadas)
  if not pecas then return false, erroCaptura end
  local blueprint = { Id = identificador, Nome = nomeValido, Pecas = pecas }
  local adicionado, resultado = dados:AdicionarBlueprint(blueprint)
  if not adicionado then return false, resultado end
  return true, "Blueprint salvo.", self:_ResumoBlueprint(blueprint)
end

--- Método público LPOO (ServicoConstrucao:SubstituirBlueprint).
function ServicoConstrucao:SubstituirBlueprint(jogador, identificador, nome, maquinasSelecionadas)
  if type(identificador) ~= "string" then return false, "Blueprint invalido." end
  local dados = DataManager.ObterDados(jogador)
  local existentes = dados and dados:ObterBlueprints()
  if not existentes then return false, "Seus dados ainda nao estao disponiveis." end
  local atual
  for _, b in existentes do
    if type(b) == "table" and b.Id == identificador then atual = b; break end
  end
  if not atual then return false, "Esse blueprint nao esta disponivel." end
  local nomeFinal = atual.Nome
  if type(nome) == "string" and string.gsub(nome, "%s+", "") ~= "" then
    local validado, erroNome = self:_ValidarNomeBlueprint(nome, identificador)
    if not validado then return false, erroNome end
    nomeFinal = validado
  end
  local pecas, erroCaptura = self:_CapturarPecasParaBlueprint(jogador, maquinasSelecionadas)
  if not pecas then return false, erroCaptura end
  local ok, msg, atualizado = dados:AtualizarBlueprint(identificador, nomeFinal, pecas)
  if not ok then return false, msg end
  return true, "Blueprint substituido com sucesso.", self:_ResumoBlueprint(atualizado)
end

--- Método público LPOO (ServicoConstrucao:RenomearBlueprint).
function ServicoConstrucao:RenomearBlueprint(jogador, identificador, novoNome)
  if not self:_PermitirPedido(jogador) then return false, "Aguarde um instante." end
  if type(identificador) ~= "string" then return false, "Blueprint invalido." end
  local nomeValido, erroNome = self:_ValidarNomeBlueprint(novoNome, identificador)
  if not nomeValido then return false, erroNome end
  local dados = DataManager.ObterDados(jogador)
  if not dados then return false, "Seus dados ainda nao estao disponiveis." end
  local ok, msg, atualizado = dados:AtualizarBlueprint(identificador, nomeValido, nil)
  if not ok then return false, msg end
  return true, "Blueprint renomeado.", self:_ResumoBlueprint(atualizado)
end

--- Método público LPOO (ServicoConstrucao:EditarBlueprint).
function ServicoConstrucao:EditarBlueprint(jogador, identificador, novoNome, indicesMantidos)
  if not self:_PermitirPedido(jogador) then return false, "Aguarde um instante." end
  if type(identificador) ~= "string" then return false, "Blueprint invalido." end
  local dados = DataManager.ObterDados(jogador)
  local existentes = dados and dados:ObterBlueprints()
  if not existentes then return false, "Seus dados ainda nao estao disponiveis." end
  local atual
  for _, b in existentes do
    if type(b) == "table" and b.Id == identificador then atual = b; break end
  end
  if not atual or type(atual.Pecas) ~= "table" then return false, "Esse blueprint nao esta disponivel." end
  local nomeValido, erroNome = self:_ValidarNomeBlueprint(novoNome ~= nil and novoNome or atual.Nome, identificador)
  if not nomeValido then return false, erroNome end

  local novasPecas
  if indicesMantidos ~= nil then
    if type(indicesMantidos) ~= "table" or #indicesMantidos < 1 or #indicesMantidos > #atual.Pecas then
      return false, "O blueprint precisa manter pelo menos uma peca."
    end
    novasPecas = {}
    local vistos = {}
    for i = 1, #indicesMantidos do
      local idx = indicesMantidos[i]
      if type(idx) ~= "number" or idx % 1 ~= 0 or idx < 1 or idx > #atual.Pecas or vistos[idx] then
        return false, "Selecao de pecas do blueprint invalida."
      end
      vistos[idx] = true
      local orig = atual.Pecas[idx]
      table.insert(novasPecas, {
        MaquinaId = orig.MaquinaId,
        Modificacoes = PersonalizacaoMaquina.new(orig.Modificacoes):ObterDados(),
        DeslocamentoInicial = table.clone(orig.DeslocamentoInicial),
        RotacaoInicial = table.clone(orig.RotacaoInicial),
      })
    end
    local ancora = table.clone(novasPecas[1].DeslocamentoInicial)
    for _, p in novasPecas do
      p.DeslocamentoInicial = {
        p.DeslocamentoInicial[1] - ancora[1],
        p.DeslocamentoInicial[2] - ancora[2],
        p.DeslocamentoInicial[3] - ancora[3],
      }
    end
  end
  local ok, msg, atualizado = dados:AtualizarBlueprint(identificador, nomeValido, novasPecas)
  if not ok then return false, msg end
  return true, "Blueprint atualizado.", self:_ResumoBlueprint(atualizado)
end

--- Método público LPOO (ServicoConstrucao:DeletarBlueprint).
function ServicoConstrucao:DeletarBlueprint(jogador, identificador)
  if not self:_PermitirPedido(jogador) then return false, "Aguarde um instante." end
  if type(identificador) ~= "string" then return false, "Blueprint invalido." end
  local dados = DataManager.ObterDados(jogador)
  if not dados then return false, "Seus dados ainda nao estao disponiveis." end
  return dados:RemoverBlueprint(identificador)
end

--- Método público LPOO (ServicoConstrucao:MoverBlueprint).
function ServicoConstrucao:MoverBlueprint(jogador, identificador, deslocamento)
  if not self:_PermitirPedido(jogador) then return false, "Aguarde um instante." end
  if type(identificador) ~= "string" then return false, "Blueprint invalido." end
  local dados = DataManager.ObterDados(jogador)
  if not dados then return false, "Seus dados ainda nao estao disponiveis." end
  return dados:MoverBlueprint(identificador, deslocamento)
end

-- Recria um token de grupo a partir do blueprint persistido; a confirmacao usa a colocacao parcial das copias.
function ServicoConstrucao:PrepararBlueprint(jogador, identificador)
	if type(identificador) ~= "string" then return false, "Blueprint invalido." end
	local dados = DataManager.ObterDados(jogador)
	local blueprints = dados and dados:ObterBlueprints()
	if not blueprints then return false, "Seus dados ainda nao estao disponiveis." end
	local blueprint
	for _, item in blueprints do
		if type(item) == "table" and item.Id == identificador then blueprint = item; break end
	end
	if not blueprint or type(blueprint.Pecas) ~= "table" or #blueprint.Pecas < 1 or #blueprint.Pecas > Limites.PecasPorGrupo then
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
		local rotacao = RotacaoConstrucao.ValidarNaGrade(CFrame.new(0, 0, 0, table.unpack(matriz)),CatalogoMaquinas[item.MaquinaId])
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

-- Confirma as copias disponiveis; obstaculos e saldo insuficiente nao bloqueiam as demais.
function ServicoConstrucao:ColocarGrupoCopia(jogador, token, pedidos)
  local copia = type(token) == "number" and self:_ObterCopiaGrupoPorToken(jogador, token)
  if not copia then
    return false, "A copia selecionada nao esta mais disponivel."
  end
  return self:_ColocarCaptura(jogador, copia, pedidos)
end

-- A linha repete uma configuracao escolhida pelo servidor, sem substituir tokens de grupos ou aceitar melhorias do cliente.
function ServicoConstrucao:ColocarMultiplos(jogador, maquinaId, pedidos, tokenCopia, usarPadrao)
	if type(maquinaId) ~= "string" or not self._modelos[maquinaId] then return false, "Maquina invalida." end
	if type(pedidos) ~= "table" then return false, "Destinos invalidos." end
	local quantidade = 0
	for indice in pedidos do
		if type(indice) ~= "number" or indice % 1 ~= 0 or indice < 1 or indice > Limites.PecasPorGrupo then
			return false, "Destinos invalidos."
		end
		quantidade += 1
	end
	if quantidade < 1 or quantidade ~= #pedidos then return false, "Quantidade de pecas invalida." end
	if usarPadrao ~= nil and type(usarPadrao) ~= "boolean" then return false, "Origem da colocacao invalida." end
	if usarPadrao and tokenCopia ~= nil then return false, "Origem da colocacao invalida." end
	if not self:Restaurar(jogador) then return false, "Seus dados ou seu terreno ainda nao estao disponiveis." end
	local dados = contexto(jogador)
	if not dados or dados:ObterQuantidade(maquinaId) == nil then return false, "Quantidade invalida no inventario." end
	local modificacoes
	if tokenCopia ~= nil then
local copia = self._copias[jogador]
    if not copia or copia.Token ~= tokenCopia then
      local grupo = type(tokenCopia) == "number" and self:_ObterCopiaGrupoPorToken(jogador, tokenCopia)
      copia = if grupo and #grupo.Pecas == 1 then grupo.Pecas[1] else nil
    end
		if not copia or copia.MaquinaId ~= maquinaId then
			return false, "A copia selecionada nao esta mais disponivel."
		end
		modificacoes = copia.Modificacoes
	else
		modificacoes = if usarPadrao then {} else dados:ObterModificacoesInventario(maquinaId)
	end
	local pecas = {}
	for indice = 1, quantidade do pecas[indice] = {MaquinaId=maquinaId, Modificacoes=modificacoes} end
	return self:_ColocarCaptura(jogador, {Pecas=pecas}, pedidos)
end

-- Copias e linhas compartilham a validacao, a colocacao parcial e a recuperacao de falhas internas.
function ServicoConstrucao:_ColocarCaptura(jogador, copia, pedidos)
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
		local peca = copia.Pecas[indice]
		local rotacao = RotacaoConstrucao.ValidarNaGrade(pedido.Rotacao,CatalogoMaquinas[peca.MaquinaId])
		if not rotacao then
			for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
			return false, "Rotacao invalida."
		end
		local preparou, dadosModelo = pcall(self._PrepararModelo, self, peca.MaquinaId, peca.Modificacoes, rotacao)
		if not preparou then
			for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
			return false, "Configuracao de uma peca invalida."
		end
		local destino, erroDestino = destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo)
		local _, ocupado = dadosModelo.Volume:Calcular(rotacao)
		if not destino then
			liberarModelo(dadosModelo)
			if erroDestino then
				for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
				return false, erroDestino
			end
			continue
		end
		local maximo = minimo + ocupado
		local sobrepoe = false
		for _, anterior in alvos do
			local a, b = anterior.Minimo, anterior.Minimo + anterior.Ocupado
			local erro = Geometria.Tolerancia
			if minimo.X < b.X - erro and maximo.X > a.X + erro
				and minimo.Y < b.Y - erro and maximo.Y > a.Y + erro
				and minimo.Z < b.Z - erro and maximo.Z > a.Z + erro
			then
				sobrepoe = true
				break
			end
		end
		if sobrepoe then liberarModelo(dadosModelo); continue end
		local componentes = { rotacao:GetComponents() }
		local registro = {
			MaquinaId = peca.MaquinaId,
			Posicao = { minimo.X, minimo.Y, minimo.Z },
			Rotacao = { table.unpack(componentes, 4, 12) },
			InclinacaoGrade = if dadosModelo.Modelo:GetAttribute("InclinacaoEsteira") then true else nil,
		}
		if next(peca.Modificacoes) then
			registro.Modificacoes = PersonalizacaoMaquina.new(peca.Modificacoes):ObterDados()
		end
		table.insert(alvos, {
			Peca = peca, Minimo = minimo, Rotacao = rotacao, Ocupado = ocupado,
			Destino = destino, DadosModelo = dadosModelo, Registro = registro,
		})
	end
	if #alvos == 0 then return false, "Nenhuma posicao esta livre no terreno." end

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
	local sucesso, mensagem, registrosAceitos = dados:RegistrarColocacoes(registros)
	if not sucesso then
		for _, maquina in criadas do self._registrosPorMaquina[maquina] = nil; maquina:Destroy() end
		for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
		return false, mensagem
	end
	local aceitos, colocadas = {}, {}
	for _, registro in registrosAceitos do aceitos[registro] = true end
	for indice, maquina in criadas do
		if aceitos[alvos[indice].Registro] then table.insert(colocadas, maquina)
		else self._registrosPorMaquina[maquina] = nil; maquina:Destroy() end
	end
for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
  local pecasHistorico = {}
  for _, registro in registrosAceitos do
    table.insert(pecasHistorico, {
      Id = registro.Id, MaquinaId = registro.MaquinaId,
      Posicao = table.clone(registro.Posicao), Rotacao = table.clone(registro.Rotacao),
      InclinacaoGrade = registro.InclinacaoGrade,
      Modificacoes = registro.Modificacoes and PersonalizacaoMaquina.new(registro.Modificacoes):ObterDados() or nil,
    })
  end
  self:_RegistrarAcaoHistorico(jogador, { Tipo = "Colocacao", Pecas = pecasHistorico })
  return true, string.format("%d de %d pecas colocadas.", #colocadas, quantidade), colocadas
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
	local rotacao = CFrame.new(0, 0, 0, table.unpack(registro.Rotacao))
	local preparou, dadosModelo = pcall(self._PrepararModelo, self, registro.MaquinaId, modificacoes, rotacao,registro.InclinacaoGrade==true)
	if not preparou then return false, "Personalizacao invalida." end
	local minimo = Vector3.new(table.unpack(registro.Posicao))
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

function ServicoConstrucao:ConfigurarElevador(jogador, maquina, altura, entrada, saida, sentido)
	if not self:_PermitirPedido(jogador) then return false, "Muitos pedidos de construção." end
	if not self:_ObterMaquina(jogador, maquina) or maquina.Name ~= "ElevadorVertical" then
		return false, "Elevador indisponível."
	end
	local config = ElevadorVertical.Validar(altura, entrada, saida, sentido)
	if not config then return false, "Configuração de elevador inválida." end
	local mods = PersonalizacaoMaquina.DoModelo(maquina):ObterDados()
	if PersonalizacaoMaquina.Iguais(config, ElevadorVertical.Ler(maquina)) then return true end
	mods.Elevador = config
	return self:Personalizar(jogador, maquina, mods)
end

-- Valida e captura o grupo antes de destruir suas instancias. O perfil conserva os registros na origem ate a
-- confirmacao, assim uma sessao interrompida ainda pode restaurar as pecas no ponto anterior.
function ServicoConstrucao:IniciarMovimento(jogador, maquinasSelecionadas)
	if type(maquinasSelecionadas) ~= "table" then
		return false, "Selecao de movimento invalida."
	end
	local quantidade = 0
	for indice in maquinasSelecionadas do
		if type(indice) ~= "number" or indice % 1 ~= 0 or indice < 1 or indice > Limites.PecasPorGrupo then
			return false, "Selecao de movimento invalida."
		end
		quantidade += 1
	end
	if quantidade < 1 or quantidade > Limites.PecasPorGrupo then return false, "Quantidade de pecas invalida." end
	for indice = 1, quantidade do
		if maquinasSelecionadas[indice] == nil then return false, "Selecao de movimento invalida." end
	end
	if self._movimentosPendentes[jogador] then return false, "Ja existe um movimento em andamento." end
	if not self:_PermitirPedido(jogador, quantidade) then
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

-- Move as pecas livres do grupo e devolve as bloqueadas ao inventario, preservando suas personalizacoes.
function ServicoConstrucao:_ConcluirMovimento(jogador, token, movimentos, grupo)
	local pendente = self._movimentosPendentes[jogador]
	if not pendente or pendente.Token ~= token then return false, "Movimento nao esta mais disponivel." end
	if type(movimentos) ~= "table" or #movimentos ~= #pendente.Pecas
		or (grupo and #movimentos < 2) or (not grupo and #movimentos ~= 1)
	then return false, "Destinos do movimento invalidos." end
	local quantidade = 0
	for indice in movimentos do
		if type(indice) ~= "number" or indice%1 ~= 0 or indice < 1 or indice > #pendente.Pecas then
			return false, "Destinos do movimento invalidos."
		end
		quantidade += 1
	end
	if quantidade ~= #pendente.Pecas then return false, "Destinos do movimento invalidos." end
	local dados, terreno, piso, maquinas = contexto(jogador)
	if dados ~= pendente.Dados or terreno ~= pendente.Terreno or piso ~= pendente.Piso or maquinas ~= pendente.Maquinas then
		return false, "Terreno indisponivel para concluir o movimento."
	end

	local alvos, devolucoes = {}, {}
	for indice, movimento in movimentos do
		if type(movimento) ~= "table" then
			for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
			return false, "Destino do movimento invalido."
		end
		local peca = pendente.Pecas[indice]
		local rotacao = RotacaoConstrucao.ValidarNaGrade(movimento.Rotacao,CatalogoMaquinas[peca.MaquinaId])
		if not rotacao then
			for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
			return false, "Rotacao invalida."
		end
		local preparou, dadosModelo = pcall(self._PrepararModelo, self, peca.MaquinaId, peca.Modificacoes, rotacao)
		if not preparou then
			for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
			return false, "Configuracao de uma peca invalida."
		end
		local alvo = {
			Peca = peca, Minimo = movimento.Minimo, Rotacao = rotacao, DadosModelo = dadosModelo,
		}
		local destino, erroDestino = destinoLivre(piso, maquinas, alvo.Minimo, rotacao, dadosModelo)
		local _, ocupado = dadosModelo.Volume:Calcular(rotacao)
		alvo.Destino, alvo.Ocupado = destino, ocupado
		if not destino then
			liberarModelo(dadosModelo)
			if not grupo or erroDestino then
				for _, anterior in alvos do liberarModelo(anterior.DadosModelo) end
				return false, erroDestino or "Essa posicao esta ocupada ou fora da grade do terreno."
			end
			table.insert(devolucoes, {Registro=peca.Registro, Modificacoes=peca.Modificacoes})
			continue
		end

		local maximo = alvo.Minimo + ocupado
		local sobrepoe = false
		for _, anterior in alvos do
			local anteriorMaximo = anterior.Minimo + anterior.Ocupado
			local erro = Geometria.Tolerancia
			if alvo.Minimo.X < anteriorMaximo.X - erro and maximo.X > anterior.Minimo.X + erro
				and alvo.Minimo.Y < anteriorMaximo.Y - erro and maximo.Y > anterior.Minimo.Y + erro
				and alvo.Minimo.Z < anteriorMaximo.Z - erro and maximo.Z > anterior.Minimo.Z + erro
			then
				sobrepoe = true
				break
			end
		end
		if sobrepoe then
			liberarModelo(dadosModelo)
			table.insert(devolucoes, {Registro=peca.Registro, Modificacoes=peca.Modificacoes})
			continue
		end
		table.insert(alvos, alvo)
	end
	if #alvos == 0 then return false, "Nenhuma posicao esta livre no terreno." end

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

	if #devolucoes > 0 then
		local sucesso, mensagem
		if #devolucoes == 1 then sucesso, mensagem = dados:RegistrarRecolhimento(devolucoes[1].Registro)
		else sucesso, mensagem = dados:RegistrarRecolhimentos(devolucoes) end
		if not sucesso then
			for _, maquina in criadas do self._registrosPorMaquina[maquina] = nil; maquina:Destroy() end
			for _, alvo in alvos do liberarModelo(alvo.DadosModelo) end
			return false, mensagem
		end
	end
local pecasHistorico = {}
  for _, alvo in alvos do
    local componentes = { alvo.Rotacao:GetComponents() }
    local registro = alvo.Peca.Registro
    local inclinacao = if alvo.DadosModelo.Modelo:GetAttribute("InclinacaoEsteira") then true else nil
    table.insert(pecasHistorico, {
      Id = registro.Id, MaquinaId = alvo.Peca.MaquinaId,
      Modificacoes = next(alvo.Peca.Modificacoes) and PersonalizacaoMaquina.new(alvo.Peca.Modificacoes):ObterDados() or nil,
      TotalRecebido = alvo.Peca.TotalRecebido,
      Antes = { Posicao = table.clone(registro.Posicao), Rotacao = table.clone(registro.Rotacao), InclinacaoGrade = registro.InclinacaoGrade },
      Depois = { Posicao = { alvo.Minimo.X, alvo.Minimo.Y, alvo.Minimo.Z }, Rotacao = { table.unpack(componentes, 4, 12) }, InclinacaoGrade = inclinacao },
    })
    registro.Posicao = { alvo.Minimo.X, alvo.Minimo.Y, alvo.Minimo.Z }
    registro.Rotacao = { table.unpack(componentes, 4, 12) }
    registro.InclinacaoGrade = inclinacao
    registro.Modificacoes = next(alvo.Peca.Modificacoes) and alvo.Peca.Modificacoes or nil
    liberarModelo(alvo.DadosModelo)
  end
  for _, peca in pendente.Pecas do
    local movida = false
    for _, alvo in alvos do if alvo.Peca == peca then movida = true; break end end
    if not movida then
      local reg = peca.Registro
      table.insert(pecasHistorico, {
        Id = reg.Id, MaquinaId = peca.MaquinaId,
        Modificacoes = next(peca.Modificacoes) and PersonalizacaoMaquina.new(peca.Modificacoes):ObterDados() or nil,
        TotalRecebido = peca.TotalRecebido,
        Antes = { Posicao = table.clone(reg.Posicao), Rotacao = table.clone(reg.Rotacao), InclinacaoGrade = reg.InclinacaoGrade },
        Depois = { Devolvida = true },
      })
    end
  end
  self:_RegistrarAcaoHistorico(jogador, { Tipo = "Movimento", Pecas = pecasHistorico })
  self._movimentosPendentes[jogador] = nil
  return true, string.format("%d pecas movidas; %d devolvidas ao inventario.", #criadas, #devolucoes), criadas
end

--- Método público LPOO (ServicoConstrucao:Mover).
function ServicoConstrucao:Mover(jogador, token, minimo, rotacao)
	return self:_ConcluirMovimento(jogador, token, { { Minimo = minimo, Rotacao = rotacao } }, false)
end

--- Método público LPOO (ServicoConstrucao:MoverGrupo).
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
local totalRecebido = maquina:GetAttribute("TotalRecebido")
  local sucesso, mensagem = dados:RegistrarRecolhimento(registro)
  if not sucesso then return false, mensagem end
  self:_RegistrarAcaoHistorico(jogador, {
    Tipo = "Recolhimento",
    Pecas = { {
      Id = registro.Id, MaquinaId = registro.MaquinaId,
      Posicao = table.clone(registro.Posicao), Rotacao = table.clone(registro.Rotacao),
      InclinacaoGrade = registro.InclinacaoGrade,
      Modificacoes = next(modificacoes) and PersonalizacaoMaquina.new(modificacoes):ObterDados() or nil,
      TotalRecebido = totalRecebido,
    } },
  })
  self._registrosPorMaquina[maquina] = nil
  maquina:Destroy()
  return true, mensagem
end

-- Valida e devolve o grupo inteiro antes de destruir seus modelos; uma falha preserva todas as pecas no terreno.
function ServicoConstrucao:RecolherGrupo(jogador, maquinasSelecionadas, plotInteira)
	if type(maquinasSelecionadas) ~= "table" then return false, "Maquinas invalidas." end
	local maximo=plotInteira and math.huge or Limites.PecasPorGrupo
	local quantidade = 0
	for indice in maquinasSelecionadas do
		if type(indice) ~= "number" or indice % 1 ~= 0 or indice < 1 or indice > maximo then
			return false, "Maquinas invalidas."
		end
		quantidade += 1
	end
	if quantidade < 2 or quantidade > maximo then return false, "Quantidade de maquinas invalida." end
	for indice = 1, quantidade do
		if maquinasSelecionadas[indice] == nil then return false, "Maquinas invalidas." end
	end
	if not self:_PermitirPedido(jogador, math.min(quantidade,Limites.PecasPorGrupo)) then
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

local pecasHistorico = {}
  for i, devolucao in devolucoes do
    local reg = devolucao.Registro
    local maq = maquinasSelecionadas[i]
    table.insert(pecasHistorico, {
      Id = reg.Id, MaquinaId = reg.MaquinaId,
      Posicao = table.clone(reg.Posicao), Rotacao = table.clone(reg.Rotacao),
      InclinacaoGrade = reg.InclinacaoGrade,
      Modificacoes = next(devolucao.Modificacoes) and PersonalizacaoMaquina.new(devolucao.Modificacoes):ObterDados() or nil,
      TotalRecebido = maq and maq:GetAttribute("TotalRecebido") or nil,
    })
  end
  local sucesso, mensagem = dados:RegistrarRecolhimentos(devolucoes, plotInteira)
  if not sucesso then return false, mensagem end
  self:_RegistrarAcaoHistorico(jogador, { Tipo = "Recolhimento", Pecas = pecasHistorico })
  for _, maquina in maquinasSelecionadas do
    self._registrosPorMaquina[maquina] = nil
    maquina:Destroy()
  end
  return true, mensagem or "Pecas devolvidas ao inventario."
end

--- Método público LPOO (ServicoConstrucao:RecolherTudo).
function ServicoConstrucao:RecolherTudo(jogador)
	if self._movimentosPendentes[jogador] then return false,"Conclua ou cancele a movimentação antes de limpar a plot." end
	if not self:Restaurar(jogador) then return false,"Sua plot ainda não está disponível." end
	local dados,_,_,pasta=contexto(jogador)
	if not dados then return false,"Plot indisponível." end
	local lista={}
	for _,modelo in pasta:GetChildren() do
		local vinculo=self._registrosPorMaquina[modelo]
		if vinculo and vinculo.jogador==jogador then table.insert(lista,modelo) end
	end
	if #lista==0 then return false,"A plot já está vazia." end
	if #lista==1 then return self:Recolher(jogador,lista[1]) end
	return self:RecolherGrupo(jogador,lista,true)
end

-- Vende uma ou varias pecas da plot como lote. O servidor resolve cada registro e o preco no catalogo; so apaga
-- os modelos depois de o perfil remover todos os registros e creditar o total com sucesso.
function ServicoConstrucao:VenderMaquinasColocadas(jogador, maquinasSelecionadas)
	if type(maquinasSelecionadas) ~= "table" then return false, "Selecao de venda invalida." end
	local quantidade = 0
	for indice in maquinasSelecionadas do
		if type(indice) ~= "number" or indice % 1 ~= 0 or indice < 1 or indice > Limites.PecasPorGrupo then
			return false, "Selecao de venda invalida."
		end
		quantidade += 1
	end
	if quantidade < 1 or quantidade > Limites.PecasPorGrupo then return false, "Quantidade de pecas invalida." end
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

local pecasHistorico = {}
  for i, reg in registros do
    local maq = maquinasSelecionadas[i]
    local okCap, modCap = pcall(function()
      return PersonalizacaoMaquina.DoModelo(maq):Capturar(maq, self._modelos[reg.MaquinaId].Modelo):ObterDados()
    end)
    local mods = (okCap and modCap) or reg.Modificacoes
    table.insert(pecasHistorico, {
      Id = reg.Id, MaquinaId = reg.MaquinaId,
      Posicao = table.clone(reg.Posicao), Rotacao = table.clone(reg.Rotacao),
      InclinacaoGrade = reg.InclinacaoGrade,
      Modificacoes = mods and next(mods) and PersonalizacaoMaquina.new(mods):ObterDados() or nil,
      TotalRecebido = maq:GetAttribute("TotalRecebido"),
    })
  end
  local sucesso, mensagem = dados:VenderConstrucoes(registros)
  if not sucesso then return false, mensagem end
  self:_RegistrarAcaoHistorico(jogador, { Tipo = "Venda", Pecas = pecasHistorico })
  for _, maquina in maquinasSelecionadas do
    self._registrosPorMaquina[maquina] = nil
    maquina:Destroy()
  end
  return true, mensagem
end

-- Sincroniza as alteracoes visuais antes de descartar tokens, limites e vinculos locais do jogador. A limpeza
-- do terreno e o encerramento do ProfileStore sao realizados por seus respectivos sistemas.
function ServicoConstrucao:AtualizarPrevia(jogador, previa)
  local _, terreno = contexto(jogador)
  if not terreno then return false end
  if previa == nil then
    terreno:SetAttribute("PreviaConstrucao", nil)
    return true
  end
  local agora = os.clock()
  if self._temposPrevia[jogador] and agora - self._temposPrevia[jogador] < 0.04 then
    return false
  end
  self._temposPrevia[jogador] = agora
  if type(previa) ~= "table" or #previa < 1 or #previa > 60 then return false end
  local limpo = {}
  for i = 1, #previa do
    local item = previa[i]
    if type(item) ~= "table" or type(item[1]) ~= "string" or not CatalogoMaquinas[item[1]] then return false end
    for j = 2, 13 do if not finito(item[j]) then return false end end
    local rot = RotacaoConstrucao.ValidarNaGrade(CFrame.new(0, 0, 0, table.unpack(item, 5, 13)), CatalogoMaquinas[item[1]])
    if not rot then return false end
    local c = { rot:GetComponents() }
    limpo[i] = { item[1], item[2], item[3], item[4], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12], item[14] == 1 and 1 or 0 }
    if item[1] == "ElevadorVertical" and item[15] ~= nil then
      local v = item[15]
      if type(v) ~= "table" or not ElevadorVertical.Validar(v[1], v[2], v[3], v[4]) then return false end
      limpo[i][15] = {v[1], v[2], v[3], v[4]}
    end
  end
  terreno:SetAttribute("PreviaConstrucao", game:GetService("HttpService"):JSONEncode(limpo))
  return true
end

--- Método público LPOO (ServicoConstrucao:LimparJogador).
function ServicoConstrucao:LimparJogador(jogador)
  self:Sincronizar(jogador)
  self._copias[jogador] = nil
  self._copiasGrupo[jogador] = nil
  self._historicoCopias[jogador] = nil
  self._historicoDesfazer[jogador] = nil
  self._historicoRefazer[jogador] = nil
  self._temposPrevia[jogador] = nil
  self._limites[jogador] = nil
  self._movimentosPendentes[jogador] = nil
  local pasta = workspace:FindFirstChild("Terrenos")
  if pasta then
    for _, terreno in pasta:GetChildren() do
      if terreno:GetAttribute("DonoUserId") == jogador.UserId then
        terreno:SetAttribute("PreviaConstrucao", nil)
      end
    end
  end
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
	self:Sincronizar(jogador)
	local sucesso, mensagem, resultado = alterarDados(dados)
	if not sucesso then return false, mensagem end
	-- Tokens antigos nao podem recriar pecas, devolver variantes ou aplicar melhorias depois do reinicio.
	self._copias[jogador], self._copiasGrupo[jogador], self._movimentosPendentes[jogador] = nil, nil, nil
self._historicoCopias[jogador], self._historicoDesfazer[jogador], self._historicoRefazer[jogador] = nil, nil, nil
	for maquina, vinculo in self._registrosPorMaquina do
		if vinculo.jogador == jogador then self._registrosPorMaquina[maquina] = nil end
	end
	maquinas:ClearAllChildren()
	minerios:ClearAllChildren()
	self._carregados[terreno] = dados
	require(script.Parent.ExpansaoPlot).Aplicar(terreno,dados:ObterUpgrade("Expansao"),true)
	dados:Sincronizar()
	return true, mensagem, resultado
end

-- Chamado somente pelo administrador no servidor; conserva as mesmas validacoes de grade e ocupacao.
function ServicoConstrucao:Administrar(jogador,pedido)
	if self._movimentosPendentes[jogador] then return false,"Aguarde o jogador terminar a movimentação." end
	if not self:Restaurar(jogador) then return false,"Plot indisponível." end
	local dados,terreno,piso,maquinas=contexto(jogador)
	if not dados then return false,"Plot indisponível." end
	self:Sincronizar(jogador)
	local registros=dados:ObterDadosPerfil().MaquinasColocadas
	local indice,anterior,modeloAnterior
	if pedido.Tipo~="Adicionar" then
		for i,r in registros do if r.Id==pedido.PecaId then indice,anterior=i,r; break end end
		if not anterior then return false,"A peça mudou ou não existe mais." end
		if #game:GetService("HttpService"):JSONEncode(anterior)>32000 then return false,"A personalização é grande demais para registrar essa edição com segurança." end
		for _,eixo in {1,2,3} do
			if anterior.Posicao[eixo]~=pedido.PosicaoAnterior[eixo] then return false,"A posição mudou. Atualize o painel." end
		end
		for modelo,vinculo in self._registrosPorMaquina do
			if vinculo.registro==anterior and vinculo.jogador==jogador then modeloAnterior=modelo; break end
		end
		if not modeloAnterior then return false,"Modelo indisponível; nenhuma alteração aplicada." end
	end
	if pedido.Tipo=="Remover" or pedido.Tipo=="Recolher" then
		if pedido.Tipo=="Recolher" then
			local ok,msg=dados:RegistrarRecolhimento(anterior)
			if not ok then return false,msg end
		else table.remove(registros,indice) end
		self._registrosPorMaquina[modeloAnterior]=nil; modeloAnterior:Destroy()
		self._copias[jogador],self._copiasGrupo[jogador]=nil,nil
		return true,"Peça "..(pedido.Tipo=="Recolher" and "recolhida." or "removida."),anterior,nil
	end
	local id=anterior and anterior.MaquinaId or pedido.MaquinaId
	local g=pedido.Giro
	local rotacao=RotacaoConstrucao.ValidarNaGrade(CFrame.Angles(math.rad(g[1]),math.rad(g[2]),math.rad(g[3])),CatalogoMaquinas[id])
	if not rotacao then return false,"Rotação não permitida para essa peça." end
	local ok,preparado=pcall(self._PrepararModelo,self,id,anterior and anterior.Modificacoes,rotacao)
	if not ok then return false,"Modelo inválido." end
	local p=pedido.Posicao
	local minimo=Vector3.new(p[1],p[2],p[3])*Geometria.Passo
	local destino=destinoLivre(piso,maquinas,minimo,rotacao,preparado,modeloAnterior)
	if not destino then liberarModelo(preparado); return false,"Posição ocupada, fora da grade ou dos limites." end
	local componentes={rotacao:GetComponents()}
	local novo={Id=anterior and anterior.Id,MaquinaId=id,Posicao={minimo.X,minimo.Y,minimo.Z},
		Rotacao={table.unpack(componentes,4,12)},InclinacaoGrade=preparado.Modelo:GetAttribute("InclinacaoEsteira") and true or nil,
		Modificacoes=anterior and anterior.Modificacoes}
	local criou,modelo=pcall(self._CriarMaquina,self,jogador,terreno,maquinas,destino,novo,preparado,nil,nil,
		modeloAnterior and modeloAnterior:GetAttribute("TotalRecebido"))
	liberarModelo(preparado)
	if not criou then return false,"Não foi possível criar a peça; o registro anterior foi preservado." end
	if anterior then
		registros[indice]=novo; self._registrosPorMaquina[modeloAnterior]=nil; modeloAnterior:Destroy()
	else table.insert(registros,novo) end
	self._copias[jogador],self._copiasGrupo[jogador]=nil,nil
	return true,"Peça "..(anterior and "reposicionada." or "adicionada sem custo."),anterior,novo
end

--- Método público LPOO (ServicoConstrucao:RedimensionarAdministrativo).
function ServicoConstrucao:RedimensionarAdministrativo(jogador,nivel)
	if self._movimentosPendentes[jogador] then return false,"Aguarde o jogador terminar a movimentação." end
	local dados,terreno,piso=contexto(jogador)
	if not dados then return false,"Plot indisponível." end
	local lado=require(ReplicatedStorage.Shared.Upgrades).TamanhosPlot[nivel+1]*Geometria.Passo
	local tamanho=Vector3.new(lado,piso.Size.Y,lado)
	local devolucoes,modelos={},{}
	self:Sincronizar(jogador)
	for modelo,vinculo in self._registrosPorMaquina do
		if vinculo.jogador~=jogador then continue end
		local r=vinculo.registro
		local minimo=modelo:GetAttribute("VolumeMinimo")
		local ocupado=modelo:GetAttribute("VolumeOcupado")
		if not Geometria.DentroDoTerreno(minimo,ocupado,tamanho) then
			table.insert(devolucoes,{Registro=r,Modificacoes=r.Modificacoes or {}})
			table.insert(modelos,modelo)
		end
	end
	if #devolucoes>0 then
		local ok,msg
		if #devolucoes==1 then ok,msg=dados:RegistrarRecolhimento(devolucoes[1].Registro)
		else ok,msg=dados:RegistrarRecolhimentos(devolucoes) end
		if not ok then return false,msg end
	end
	require(script.Parent.ExpansaoPlot).Aplicar(terreno,nivel,true)
	for _,modelo in modelos do self._registrosPorMaquina[modelo]=nil; modelo:Destroy() end
	self._copias[jogador],self._copiasGrupo[jogador]=nil,nil
	local devolvidas={}
	for _,d in devolucoes do
		local r=d.Registro
		table.insert(devolvidas,{Id=r.Id,MaquinaId=r.MaquinaId,Posicao=table.clone(r.Posicao),Rotacao=table.clone(r.Rotacao)})
	end
	return true,"Plot redimensionada; peças que não couberam voltaram ao inventário.",devolvidas
end

--- Método público LPOO (ServicoConstrucao:Desfazer).
function ServicoConstrucao:Desfazer(jogador)
  if self._movimentosPendentes[jogador] then return false, "Conclua ou cancele a movimentacao atual." end
  if not self:_PermitirPedido(jogador, 1) then return false, "Aguarde um instante." end
  local pilha = self._historicoDesfazer[jogador]
  local acao = pilha and pilha[#pilha]
  if not acao then return false, "Nada para desfazer." end
  self._executandoHistorico = true
  local ok, sucesso, msg = pcall(self._ExecutarAcaoHistorico, self, jogador, acao, true)
  self._executandoHistorico = false
  if not ok or not sucesso then return false, ok and msg or "Nao foi possivel desfazer a acao." end
  table.remove(pilha)
  local refazer = self._historicoRefazer[jogador] or {}
  table.insert(refazer, acao)
  self._historicoRefazer[jogador] = refazer
  return true, msg
end

--- Método público LPOO (ServicoConstrucao:Refazer).
function ServicoConstrucao:Refazer(jogador)
  if self._movimentosPendentes[jogador] then return false, "Conclua ou cancele a movimentacao atual." end
  if not self:_PermitirPedido(jogador, 1) then return false, "Aguarde um instante." end
  local pilha = self._historicoRefazer[jogador]
  local acao = pilha and pilha[#pilha]
  if not acao then return false, "Nada para refazer." end
  self._executandoHistorico = true
  local ok, sucesso, msg = pcall(self._ExecutarAcaoHistorico, self, jogador, acao, false)
  self._executandoHistorico = false
  if not ok or not sucesso then return false, ok and msg or "Nao foi possivel refazer a acao." end
  table.remove(pilha)
  local desfazer = self._historicoDesfazer[jogador] or {}
  table.insert(desfazer, acao)
  self._historicoDesfazer[jogador] = desfazer
  return true, msg
end

--- Método auxiliar privado (ServicoConstrucao:_LocalizarPorId) encapsulado na classe.
function ServicoConstrucao:_LocalizarPorId(jogador, id)
for modelo, vinculo in self._registrosPorMaquina do
if vinculo.jogador == jogador and vinculo.registro.Id == id and modelo.Parent then
return modelo, vinculo.registro
end
end
return nil, nil
end

--- Método auxiliar privado (ServicoConstrucao:_ExecutarAcaoHistorico) encapsulado na classe.
function ServicoConstrucao:_ExecutarAcaoHistorico(jogador, acao, desfazer)
if not self:Restaurar(jogador) then return false, "Terreno indisponivel." end
local dados, terreno, piso, maquinas = contexto(jogador)
if not dados then return false, "Terreno indisponivel." end
self:Sincronizar(jogador)

local recolher = (acao.Tipo == "Colocacao" and desfazer) or (acao.Tipo == "Recolhimento" and not desfazer)
local colocar = (acao.Tipo == "Colocacao" and not desfazer) or (acao.Tipo == "Recolhimento" and desfazer)

if recolher then
local modelos, devolucoes = {}, {}
for _, peca in acao.Pecas do
local modelo, registro = self:_LocalizarPorId(jogador, peca.Id)
if not modelo or not registro then return false, "As pecas dessa acao ja foram alteradas." end
local okCap, mods = pcall(function()
return PersonalizacaoMaquina.DoModelo(modelo):Capturar(modelo, self._modelos[registro.MaquinaId].Modelo):ObterDados()
end)
if not okCap then return false, "Nao foi possivel preservar a personalizacao." end
peca.Modificacoes = next(mods) and mods or nil
peca.TotalRecebido = modelo:GetAttribute("TotalRecebido")
table.insert(modelos, modelo)
table.insert(devolucoes, { Registro = registro, Modificacoes = mods })
end
if #devolucoes == 1 then
devolucoes[1].Registro.Modificacoes = next(devolucoes[1].Modificacoes) and devolucoes[1].Modificacoes or nil
local ok, msg = dados:RegistrarRecolhimento(devolucoes[1].Registro)
if not ok then return false, msg end
else
      local ok, msg = dados:RegistrarRecolhimentos(devolucoes, #devolucoes == #dados:ObterDadosPerfil().MaquinasColocadas)
      if not ok then return false, msg end
    end
for _, modelo in modelos do
self._registrosPorMaquina[modelo] = nil
modelo:Destroy()
end
return true, string.format("Acao %s: %d peca(s) recolhida(s).", desfazer and "desfeita" or "refeita", #modelos)
elseif colocar then
local alvos = {}
for _, peca in acao.Pecas do
local minimo = Vector3.new(table.unpack(peca.Posicao))
local rotacao = RotacaoConstrucao.ValidarNaGrade(CFrame.new(0, 0, 0, table.unpack(peca.Rotacao)), CatalogoMaquinas[peca.MaquinaId])
if not rotacao then
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, "Rotacao invalida no historico."
end
local okPrep, dadosModelo = pcall(self._PrepararModelo, self, peca.MaquinaId, peca.Modificacoes, rotacao, peca.InclinacaoGrade ~= false)
if not okPrep then
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, "Configuracao invalida no historico."
end
local destino = destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo)
local _, ocupado = dadosModelo.Volume:Calcular(rotacao)
if not destino then
liberarModelo(dadosModelo)
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, "Posicao ocupada na plot para restaurar as pecas."
end
local registro = {
Id = peca.Id, MaquinaId = peca.MaquinaId,
Posicao = table.clone(peca.Posicao), Rotacao = table.clone(peca.Rotacao),
InclinacaoGrade = if dadosModelo.Modelo:GetAttribute("InclinacaoEsteira") then true else nil,
Modificacoes = peca.Modificacoes and next(peca.Modificacoes) and PersonalizacaoMaquina.new(peca.Modificacoes):ObterDados() or nil,
}
table.insert(alvos, { Peca = peca, Minimo = minimo, Rotacao = rotacao, Ocupado = ocupado, Destino = destino, DadosModelo = dadosModelo, Registro = registro })
end
local d = dados:ObterDadosPerfil()
local backup = {
Dinheiro = d.Dinheiro, Inventory = table.clone(d.Inventory),
MaquinasColocadas = table.clone(d.MaquinasColocadas),
InventarioPersonalizado = table.clone(d.InventarioPersonalizado or {}),
}
for _, alvo in alvos do
local ok, msg = dados:RegistrarColocacao(alvo.Registro, true)
if not ok then
d.Dinheiro, d.Inventory, d.MaquinasColocadas, d.InventarioPersonalizado = backup.Dinheiro, backup.Inventory, backup.MaquinasColocadas, backup.InventarioPersonalizado
dados:Sincronizar()
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, msg
end
end
dados:PublicarResumoPlot()
for _, alvo in alvos do
self:_CriarMaquina(jogador, terreno, maquinas, alvo.Destino, alvo.Registro, alvo.DadosModelo, alvo.Minimo, alvo.Rotacao, alvo.Peca.TotalRecebido)
liberarModelo(alvo.DadosModelo)
end
return true, string.format("Acao %s: %d peca(s) colocada(s).", desfazer and "desfeita" or "refeita", #alvos)
elseif acao.Tipo == "Movimento" then
local ignorar, modelosAntigos = {}, {}
for _, peca in acao.Pecas do
local origem = if desfazer then peca.Depois else peca.Antes
if not origem.Devolvida then
local modelo, registro = self:_LocalizarPorId(jogador, peca.Id)
if not modelo or not registro then return false, "As pecas movidas ja foram alteradas." end
ignorar[modelo] = true
modelosAntigos[peca] = { Modelo = modelo, Registro = registro }
end
end
local alvos, paraInventario, doInventario = {}, {}, {}
for _, peca in acao.Pecas do
local origem = if desfazer then peca.Depois else peca.Antes
local destino = if desfazer then peca.Antes else peca.Depois
if destino.Devolvida then
local atual = modelosAntigos[peca]
if atual then table.insert(paraInventario, { Peca = peca, Modelo = atual.Modelo, Registro = atual.Registro }) end
else
local minimo = Vector3.new(table.unpack(destino.Posicao))
local rotacao = RotacaoConstrucao.ValidarNaGrade(CFrame.new(0, 0, 0, table.unpack(destino.Rotacao)), CatalogoMaquinas[peca.MaquinaId])
local okPrep, dadosModelo = pcall(self._PrepararModelo, self, peca.MaquinaId, peca.Modificacoes, rotacao, destino.InclinacaoGrade ~= false)
if not rotacao or not okPrep then
if okPrep then liberarModelo(dadosModelo) end
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, "Configuracao invalida ao restaurar movimento."
end
local cframeDestino = destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo, ignorar)
if not cframeDestino then
liberarModelo(dadosModelo)
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, "Posicao ocupada para restaurar o movimento."
end
local alvo = { Peca = peca, Minimo = minimo, Rotacao = rotacao, Destino = cframeDestino, DadosModelo = dadosModelo, Estado = destino }
table.insert(alvos, alvo)
if origem.Devolvida then table.insert(doInventario, alvo) end
end
end
local d = dados:ObterDadosPerfil()
local backup = {
Dinheiro = d.Dinheiro, Inventory = table.clone(d.Inventory),
MaquinasColocadas = table.clone(d.MaquinasColocadas),
InventarioPersonalizado = table.clone(d.InventarioPersonalizado or {}),
}
for _, item in paraInventario do
item.Registro.Modificacoes = item.Peca.Modificacoes and next(item.Peca.Modificacoes) and PersonalizacaoMaquina.new(item.Peca.Modificacoes):ObterDados() or nil
local ok, msg = dados:RegistrarRecolhimento(item.Registro)
if not ok then
d.Dinheiro, d.Inventory, d.MaquinasColocadas, d.InventarioPersonalizado = backup.Dinheiro, backup.Inventory, backup.MaquinasColocadas, backup.InventarioPersonalizado
dados:Sincronizar()
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, msg
end
end
for _, alvo in doInventario do
local registro = {
Id = alvo.Peca.Id, MaquinaId = alvo.Peca.MaquinaId,
Posicao = table.clone(alvo.Estado.Posicao), Rotacao = table.clone(alvo.Estado.Rotacao),
InclinacaoGrade = if alvo.DadosModelo.Modelo:GetAttribute("InclinacaoEsteira") then true else nil,
Modificacoes = alvo.Peca.Modificacoes and next(alvo.Peca.Modificacoes) and PersonalizacaoMaquina.new(alvo.Peca.Modificacoes):ObterDados() or nil,
}
local ok, msg = dados:RegistrarColocacao(registro, true)
if not ok then
d.Dinheiro, d.Inventory, d.MaquinasColocadas, d.InventarioPersonalizado = backup.Dinheiro, backup.Inventory, backup.MaquinasColocadas, backup.InventarioPersonalizado
dados:Sincronizar()
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, msg
end
alvo.Registro = registro
end
for _, item in paraInventario do
self._registrosPorMaquina[item.Modelo] = nil
item.Modelo:Destroy()
end
for _, alvo in alvos do
local antigo = modelosAntigos[alvo.Peca]
local registro = alvo.Registro or (antigo and antigo.Registro)
registro.Posicao = table.clone(alvo.Estado.Posicao)
registro.Rotacao = table.clone(alvo.Estado.Rotacao)
registro.InclinacaoGrade = if alvo.DadosModelo.Modelo:GetAttribute("InclinacaoEsteira") then true else nil
registro.Modificacoes = alvo.Peca.Modificacoes and next(alvo.Peca.Modificacoes) and PersonalizacaoMaquina.new(alvo.Peca.Modificacoes):ObterDados() or nil
if antigo then
self._registrosPorMaquina[antigo.Modelo] = nil
antigo.Modelo:Destroy()
end
self:_CriarMaquina(jogador, terreno, maquinas, alvo.Destino, registro, alvo.DadosModelo, alvo.Minimo, alvo.Rotacao, alvo.Peca.TotalRecebido)
liberarModelo(alvo.DadosModelo)
end
dados:PublicarResumoPlot()
return true, string.format("Movimento %s.", desfazer and "desfeito" or "refeito")
elseif acao.Tipo == "Venda" then
if desfazer then
local total = "0"
local alvos = {}
for _, peca in acao.Pecas do
local item = CatalogoMaquinas[peca.MaquinaId]
if not item or not InteiroGrande.eValido(item.Preco) then
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, "Peca invalida para restaurar venda."
end
total = InteiroGrande.somar(total, item.Preco)
local minimo = Vector3.new(table.unpack(peca.Posicao))
local rotacao = RotacaoConstrucao.ValidarNaGrade(CFrame.new(0, 0, 0, table.unpack(peca.Rotacao)), item)
local okPrep, dadosModelo = pcall(self._PrepararModelo, self, peca.MaquinaId, peca.Modificacoes, rotacao, peca.InclinacaoGrade ~= false)
if not rotacao or not okPrep then
if okPrep then liberarModelo(dadosModelo) end
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, "Configuracao invalida ao desfazer venda."
end
local destino = destinoLivre(piso, maquinas, minimo, rotacao, dadosModelo)
if not destino then
liberarModelo(dadosModelo)
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, "Posicao ocupada para desfazer a venda."
end
local registro = {
Id = peca.Id, MaquinaId = peca.MaquinaId,
Posicao = table.clone(peca.Posicao), Rotacao = table.clone(peca.Rotacao),
InclinacaoGrade = if dadosModelo.Modelo:GetAttribute("InclinacaoEsteira") then true else nil,
Modificacoes = peca.Modificacoes and next(peca.Modificacoes) and PersonalizacaoMaquina.new(peca.Modificacoes):ObterDados() or nil,
}
table.insert(alvos, { Peca = peca, Minimo = minimo, Rotacao = rotacao, Destino = destino, DadosModelo = dadosModelo, Registro = registro })
end
local novoSaldo = InteiroGrande.subtrair(dados:ObterSaldo(), total)
if not novoSaldo then
for _, a in alvos do liberarModelo(a.DadosModelo) end
return false, "Dinheiro insuficiente para desfazer a venda."
end
dados:_DefinirSaldo(novoSaldo)
for _, alvo in alvos do
table.insert(dados:ObterDadosPerfil().MaquinasColocadas, alvo.Registro)
self:_CriarMaquina(jogador, terreno, maquinas, alvo.Destino, alvo.Registro, alvo.DadosModelo, alvo.Minimo, alvo.Rotacao, alvo.Peca.TotalRecebido)
liberarModelo(alvo.DadosModelo)
end
dados:PublicarResumoPlot()
return true, "Venda desfeita."
else
local modelos, registros = {}, {}
for _, peca in acao.Pecas do
local modelo, registro = self:_LocalizarPorId(jogador, peca.Id)
if not modelo or not registro then return false, "As pecas para vender ja foram alteradas." end
table.insert(modelos, modelo)
table.insert(registros, registro)
end
local ok, msg = dados:VenderConstrucoes(registros)
if not ok then return false, msg end
for _, modelo in modelos do
self._registrosPorMaquina[modelo] = nil
modelo:Destroy()
end
return true, msg
end
end
return false, "Tipo de acao desconhecido."
end

return ServicoConstrucao
