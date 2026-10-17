-- Traduz a definicao de componentes em estatisticas legiveis, sem alterar o catalogo ou as propriedades da
-- peca.
local FichaMaquina = {}

-- Converte o valor em texto e troca ponto decimal por virgula para apresentacao. O resultado nao volta para os
-- calculos.
local function numero(valor)
	return (tostring(valor):gsub("%.", ","))
end

-- Monta a expressao de multiplicador e bonus mostrada na ficha, omitindo um bonus igual a zero.
local function efeito(configuracao)
	local texto = "valor ×" .. (configuracao.Multiplicador or "1")
	if configuracao.Bonus and configuracao.Bonus ~= "0" then texto ..= " + " .. configuracao.Bonus end
	return texto
end

-- Recebe uma definicao de peca ja resolvida e devolve um texto com uma linha por estatistica relevante. A
-- lista de Componentes decide quais campos sao exibidos; um tipo desconhecido e indicado no texto.
function FichaMaquina.Descrever(definicao)
	local linhas = {}
	-- A ficha percorre capacidades, nao nomes de modelos. Cada ramo traduz os parametros desse comportamento em
	-- texto, incluindo unidades, para servir tambem a outras pecas com o mesmo Tipo.
	for _, componente in definicao.Componentes or {} do
		if componente.Tipo == "Soltador" then
			local minerio = componente.Minerio
			table.insert(linhas, "Valor por minério: " .. minerio.Valor)
			table.insert(linhas, "Intervalo de geração: " .. numero(componente.Intervalo) .. " s")
			table.insert(linhas, "Tamanho do minério: " .. table.concat({ numero(minerio.Tamanho[1]),
				numero(minerio.Tamanho[2]), numero(minerio.Tamanho[3]) }, " × ") .. " studs")
			table.insert(linhas, "Duração do minério: " .. numero(componente.TempoVida) .. " s")
		elseif componente.Tipo == "Transportador" then
			table.insert(linhas, "Transporte: " .. numero(componente.Velocidade) .. " studs/s")
		elseif componente.Tipo == "Modificador" then
			table.insert(linhas, "Modificação: " .. efeito(componente))
			table.insert(linhas, "Aplica uma vez por minério nesta peça.")
		elseif componente.Tipo == "Vendedor" then
			table.insert(linhas, "Venda: " .. efeito(componente))
			table.insert(linhas, "Consome o minério ao vender.")
		else
			table.insert(linhas, "Comportamento: " .. componente.Tipo .. " (sem ficha disponível)")
		end
	end
	if #linhas == 0 then table.insert(linhas, "Esta peça não possui comportamentos de minério.") end
	-- Junta as estatisticas com quebra de linha para o TextLabel. Essa formatacao e somente de exibicao: nao
	-- modifica numeros nem componentes da maquina.
	return table.concat(linhas, "\n")
end

return FichaMaquina
