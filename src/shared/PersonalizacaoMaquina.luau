-- Guarda diferencas serializaveis da peca; clona dados para que aplicar uma variante nao modifique o catalogo
-- original.
local HttpService = game:GetService("HttpService")

local PersonalizacaoMaquina = {}
PersonalizacaoMaquina.__index = PersonalizacaoMaquina

-- Copia recursivamente dados que podem ser codificados em JSON. Recusa tipos nao suportados, numeros nao
-- finitos e profundidade excessiva; assim a personalizacao nao guarda referencias mutaveis de quem a forneceu.
local function copiar(valor, profundidade)
	local tipo = type(valor)
	if tipo == "table" then
		-- A copia entra em cada subtabela. Limitar os niveis impede recursao infinita em ciclos e recusa
		-- configuracoes que nao cabem no formato esperado.
		assert((profundidade or 0) < 16, "Personalizacao profunda demais ou ciclica.")
		local resultado = {}
		for chave, item in valor do
			assert(type(chave) == "string" or (type(chave) == "number" and chave >= 1 and chave % 1 == 0), "Chave invalida.")
			resultado[chave] = copiar(item, (profundidade or 0) + 1)
		end
		return resultado
	end
	assert(tipo == "string" or tipo == "boolean" or (tipo == "number" and valor == valor and math.abs(valor) < math.huge),
		"Personalizacao deve conter apenas dados serializaveis.")
	return valor
end

-- Aplica as alteracoes sobre a tabela destino: mescla subtabelas e substitui valores simples por copias. E
-- usada em uma copia da definicao, para preservar o catalogo compartilhado.
local function combinar(destino, alteracoes)
	for chave, valor in alteracoes do
		-- Duas tabelas permitem alterar so um campo interno, por exemplo a velocidade de um componente. Um valor
		-- simples substitui o campo inteiro no destino.
		if type(valor) == "table" and type(destino[chave]) == "table" then
			combinar(destino[chave], valor)
		else
			destino[chave] = copiar(valor)
		end
	end
end

-- Gera o caminho de uma parte ate o Model, guardando nome e numero de ocorrencia em cada nivel. O indice
-- distingue irmaos com o mesmo nome e permite localizar a parte na proxima copia do modelo.
local function caminhoDaParte(parte, modelo)
	local caminho = {}
	while parte ~= modelo do
		local indice = 0
		for _, irma in parte.Parent:GetChildren() do
			if irma.Name == parte.Name then indice += 1 end
			if irma == parte then break end
		end
		-- Inserir no inicio inverte a subida: o caminho final vai da raiz ate a parte. O nome junto com a
		-- ocorrencia identifica inclusive partes irmas de nomes iguais.
		table.insert(caminho, 1, { Nome = parte.Name, Indice = indice })
		parte = parte.Parent
	end
	return caminho
end

-- Percorre no modelo o caminho de nomes e ocorrencias salvo por caminhoDaParte. Devolve a instancia
-- correspondente ou nil se algum segmento nao existir.
local function encontrar(modelo, caminho)
	local atual = modelo
	for _, segmento in caminho do
		local indice, encontrada = 0, nil
		for _, filha in atual:GetChildren() do
			if filha.Name == segmento.Nome then
				indice += 1
				if indice == segmento.Indice then encontrada = filha; break end
			end
		end
		if not encontrada then return nil end
		atual = encontrada
	end
	return atual
end

-- Confere que o dado tem tres elementos e o converte em Vector3. JSON armazena listas numericas, por isso a
-- conversao e necessaria antes de aplicar tamanho ou cor.
local function vetor(tabela)
	assert(type(tabela) == "table" and #tabela == 3, "Vetor invalido na personalizacao.")
	return Vector3.new(table.unpack(tabela))
end

-- Compara duas listas numericas e indica diferenca de tamanho ou de componente acima de 0.0001. Evita
-- registrar residuos numericos de transformacoes como personalizacoes reais.
local function diferentes(a, b)
	if #a ~= #b then return true end
	for i, valor in a do if math.abs(valor - b[i]) > 0.0001 then return true end end
	return false
end

-- Recebe uma tabela opcional de modificacoes e devolve um objeto com copia propria desses dados. Sem
-- argumento, representa a configuracao original da peca.
function PersonalizacaoMaquina.new(dados)
	assert(dados == nil or type(dados) == "table", "Personalizacao invalida.")
	return setmetatable({ _dados = copiar(dados or {}) }, PersonalizacaoMaquina)
end

-- Converte o texto JSON de uma personalizacao em objeto; nil significa uma personalizacao vazia. Formato
-- invalido gera erro para que o chamador possa recusar a operacao.
function PersonalizacaoMaquina.Decodificar(texto)
	if texto == nil then return PersonalizacaoMaquina.new() end
	assert(type(texto) == "string", "Personalizacao codificada invalida.")
	return PersonalizacaoMaquina.new(HttpService:JSONDecode(texto))
end

-- Le o atributo Personalizacao publicado no Model e devolve seu objeto de dados. Nao captura mudancas visuais
-- feitas depois da publicacao; isso e responsabilidade de Capturar.
function PersonalizacaoMaquina.DoModelo(modelo)
	return PersonalizacaoMaquina.Decodificar(modelo:GetAttribute("Personalizacao"))
end

-- Devolve uma copia profunda dos dados internos. O chamador pode preparar alteracoes nessa copia sem mudar o
-- objeto que esta sendo usado por outra peca.
function PersonalizacaoMaquina:ObterDados() return copiar(self._dados) end

-- Compara tipos, valores e chaves recursivamente, inclusive chaves presentes apenas de um lado. Usa tolerancia
-- numerica nas Partes ou quando solicitada; configuracoes e demais valores continuam com comparacao exata.
function PersonalizacaoMaquina.Iguais(a, b, tolerancia)
	if type(a) ~= type(b) then return false end
	if type(a) == "number" and tolerancia then return math.abs(a - b) <= tolerancia end
	if type(a) ~= "table" then return a == b end
	for chave, valor in a do
		-- Transformacoes das partes passam por floats do motor antes de voltar ao inventario.
		local erro = tolerancia or (chave == "Partes" and 0.0001 or nil)
		if not PersonalizacaoMaquina.Iguais(valor, b[chave], erro) then return false end
	end
	for chave in b do if a[chave] == nil then return false end end
	return true
end

-- Devolve o JSON dos dados internos para atributos e comunicacao. A criacao do objeto ja verificou se seus
-- dados usam tipos serializaveis.
function PersonalizacaoMaquina:Codificar()
	return HttpService:JSONEncode(self._dados)
end

-- Grava o JSON no atributo Personalizacao do Model, tornando a configuracao consultavel pelos consumidores
-- desse modelo. Nao aplica propriedades visuais por si so.
function PersonalizacaoMaquina:Publicar(modelo)
	modelo:SetAttribute("Personalizacao", self:Codificar())
end

-- Mescla as diferencas em uma copia: varias pecas podem compartilhar o catalogo sem compartilhar suas melhorias.
-- Devolve uma copia da entrada de catalogo com as mudancas de Configuracao sobrepostas. Os componentes recebem
-- essa definicao efetiva, enquanto a entrada original permanece compartilhavel.
function PersonalizacaoMaquina:ObterDefinicao(original)
	local definicao = copiar(original)
	if self._dados.Configuracao then combinar(definicao, self._dados.Configuracao) end
	return definicao
end

-- Localiza as partes indicadas, valida cada propriedade suportada e aplica cor, tamanho, transformacao
-- relativa e acabamento. Ao terminar, publica os dados no Model; um caminho ou valor invalido interrompe com
-- erro.
function PersonalizacaoMaquina:Aplicar(modelo)
	local pivo = modelo:GetPivot()
	for _, alteracao in self._dados.Partes or {} do
		local parte = assert(encontrar(modelo, alteracao.Caminho), "Parte personalizada nao encontrada.")
		assert(parte:IsA("BasePart"), "Personalizacao exige uma BasePart.")
		if alteracao.Cor then
			local cor = vetor(alteracao.Cor)
			assert(cor.X >= 0 and cor.X <= 1 and cor.Y >= 0 and cor.Y <= 1 and cor.Z >= 0 and cor.Z <= 1, "Cor invalida.")
			parte.Color = Color3.new(cor.X, cor.Y, cor.Z)
		end
		if alteracao.Tamanho then
			local tamanho = vetor(alteracao.Tamanho)
			assert(tamanho.X > 0 and tamanho.Y > 0 and tamanho.Z > 0, "Tamanho invalido.")
			parte.Size = tamanho
		end
		-- O CFrame salvo e relativo ao pivo, nao uma posicao mundial fixa. Multiplicar pelo pivo atual conserva a
		-- modificacao ao copiar a maquina para outro lugar.
		if alteracao.CFrame then
			assert(#alteracao.CFrame == 12, "CFrame de parte invalido.")
			parte.CFrame = pivo * CFrame.new(table.unpack(alteracao.CFrame))
		end
		if alteracao.Material then parte.Material = Enum.Material[alteracao.Material] end
		for _, propriedade in { "Transparency", "Reflectance" } do
			local valor = alteracao[propriedade]
			if valor ~= nil then
				assert(type(valor) == "number" and valor >= 0 and valor <= 1, "Propriedade visual invalida.")
				parte[propriedade] = valor
			end
		end
	end
	self:Publicar(modelo)
end

-- Salva somente diferencas do modelo original; os CFrames relativos permitem recolocar a peca em outro lugar.
-- Compara as partes atuais com o modelo original e cria uma nova personalizacao contendo somente as diferencas
-- visuais suportadas. Preserva a Configuracao ja existente e mede CFrames relativos aos pivos, permitindo
-- recolocar a copia em outro lugar.
function PersonalizacaoMaquina:Capturar(modelo, original)
	local dados = self:ObterDados()
	local partes = {}
	local pivo, pivoOriginal = modelo:GetPivot(), original:GetPivot()
	for _, parte in modelo:GetDescendants() do
		if not parte:IsA("BasePart") then continue end
		local caminho = caminhoDaParte(parte, modelo)
		local base = assert(encontrar(original, caminho), "Parte nao pertence ao modelo original.")
		local alteracao = { Caminho = caminho }
		local mudou = false
		if parte.Color ~= base.Color then
			alteracao.Cor = { parte.Color.R, parte.Color.G, parte.Color.B }; mudou = true
		end
		if (parte.Size - base.Size).Magnitude > 0.0001 then
			alteracao.Tamanho = { parte.Size.X, parte.Size.Y, parte.Size.Z }; mudou = true
		end
		-- Compara as duas partes no referencial de seus proprios modelos. Assim mover ou girar a maquina inteira
		-- nao e confundido com deslocar uma parte dentro dela.
		local cf = { pivo:ToObjectSpace(parte.CFrame):GetComponents() }
		local cfBase = { pivoOriginal:ToObjectSpace(base.CFrame):GetComponents() }
		if diferentes(cf, cfBase) then alteracao.CFrame = cf; mudou = true end
		if parte.Material ~= base.Material then alteracao.Material = parte.Material.Name; mudou = true end
		for _, propriedade in { "Transparency", "Reflectance" } do
			if math.abs(parte[propriedade] - base[propriedade]) > 0.0001 then
				alteracao[propriedade] = parte[propriedade]; mudou = true
			end
		end
		if mudou then table.insert(partes, alteracao) end
	end
	-- Somente partes com diferencas entram no registro. Sem diferencas, remove a lista Partes e cria outro
	-- objeto, preservando os dados do objeto que iniciou a captura.
	dados.Partes = #partes > 0 and partes or nil
	return PersonalizacaoMaquina.new(dados)
end

return PersonalizacaoMaquina
