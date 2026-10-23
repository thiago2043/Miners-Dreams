local ProgressaoLogaritmica = {}
ProgressaoLogaritmica.__index = ProgressaoLogaritmica

-- Retira zeros a esquerda sem converter o inteiro completo para number.
local function normalizar(valor)
	if type(valor) ~= "string" or not valor:match("^[0-9]+$") then return nil end
	local semZeros = valor:gsub("^0+", "")
	return semZeros ~= "" and semZeros or "0"
end

local function menor(a, b)
	return #a < #b or (#a == #b and a < b)
end

-- So a animacao da barra usa uma aproximacao: as primeiras 15 casas fornecem a mantissa.
-- Comparacoes de marcos usam as strings completas, inclusive um valor uma unidade abaixo do limite.
local function logaritmo(valor)
	if valor == "0" then return 0 end
	local inicio = valor:sub(1, 15)
	return #valor - #inicio + math.log10(tonumber(inicio))
end

-- Cada objeto define uma escala N, N*10, N*100...; nao conhece vidas, recompensas ou dados de jogadores.
function ProgressaoLogaritmica.new(marcoInicial)
	local inicial = normalizar(marcoInicial)
	assert(inicial and inicial ~= "0", "O marco inicial precisa ser um inteiro decimal positivo.")
	return setmetatable({ _inicial = inicial }, ProgressaoLogaritmica)
end

-- Acrescentar zeros e a multiplicacao exata por uma potencia de dez. O chamador escolhe o marco;
-- esta operacao nao recebe pedidos de rede nem cobra dinheiro.
function ProgressaoLogaritmica:ObterMarco(zerosExtras)
	assert(type(zerosExtras) == "number" and zerosExtras >= 0 and zerosExtras < math.huge
		and zerosExtras % 1 == 0, "A quantidade de zeros precisa ser um inteiro nao negativo.")
	return self._inicial .. string.rep("0", zerosExtras)
end

-- Mede o caminho ate um marco deslocado sem construir strings gigantes apenas por causa do indice.
-- A regra de jogo ainda compara os marcos exatamente; este resultado serve somente para a barra.
function ProgressaoLogaritmica:FracaoAteMarco(valor, zerosExtras)
	valor = normalizar(valor)
	if not valor then return nil end
	assert(type(zerosExtras) == "number" and zerosExtras >= 0 and zerosExtras < math.huge
		and zerosExtras % 1 == 0, "Indice de marco invalido.")
	local destino = logaritmo(self._inicial) + zerosExtras
	if valor == "0" then return 0 end
	return destino == 0 and 1 or math.clamp(logaritmo(valor) / destino, 0, 1)
end

-- Identifica os marcos completos por comprimento e ordem decimal. Ex.: com N*10000, ha cinco
-- marcos atingidos (N ate N*10000); a regra que usa a escala decide quantas vidas isso representa.
function ProgressaoLogaritmica:Avaliar(valor)
	valor = normalizar(valor)
	if not valor then return nil, "O valor precisa ser um inteiro decimal nao negativo." end
	local atingidos, atual, proximo, fracao = 0, "0", self._inicial, 0
	if not menor(valor, self._inicial) then
		local zeros = #valor - #self._inicial
		if menor(valor, self:ObterMarco(zeros)) then zeros -= 1 end
		atingidos, atual, proximo = zeros + 1, self:ObterMarco(zeros), self:ObterMarco(zeros + 1)
		-- Entre dois marcos consecutivos ha uma unidade de log10, independentemente da magnitude.
		fracao = logaritmo(valor) - logaritmo(atual)
	elseif valor ~= "0" and self._inicial ~= "1" then
		-- Antes de N, a escala comeca em 1; zero recebe explicitamente progresso zero, pois log(0) nao existe.
		fracao = logaritmo(valor) / logaritmo(self._inicial)
	end
	return {
		MarcosAtingidos = atingidos, MarcoAtual = atual, ProximoMarco = proximo,
		Fracao = math.clamp(fracao, 0, 1),
	}
end

return ProgressaoLogaritmica
