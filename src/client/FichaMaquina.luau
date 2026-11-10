-- Traduz a definicao de componentes em estatisticas legiveis, sem alterar o catalogo ou as propriedades da
-- peca.
local AbreviarInteiro = require(game:GetService("ReplicatedStorage").Shared.AbreviarInteiro)
local Efeitos=require(game:GetService("ReplicatedStorage").Shared.EfeitosUpgrades)
local Upgrades=require(game:GetService("ReplicatedStorage").Shared.Upgrades)
local Inteiro=require(game:GetService("ReplicatedStorage").Shared.InteiroGrande)
local bloco=require(game:GetService("ReplicatedStorage").Shared.Medidas).Bloco
local FichaMaquina = {}

-- Abrevia inteiros e usa virgula em decimais; o resultado nao volta para os calculos.
local function numero(valor)
	if type(valor) == "number" and valor >= 0 and valor < 2 ^ 53 and valor % 1 == 0 then return AbreviarInteiro(valor) end
	if type(valor) == "string" and valor:match("^%d+$") then return AbreviarInteiro(valor) end
	if type(valor)=="number" then return ((string.format("%.6f",valor):gsub("0+$",""):gsub("%.$","")):gsub("%.",",")) end
	return (tostring(valor):gsub("%.", ","))
end

-- Monta a expressao de multiplicador e bonus mostrada na ficha, omitindo um bonus igual a zero.
local function efeito(configuracao)
	local bonus=configuracao.Bonus and configuracao.Bonus~="0"
	local multiplicador=configuracao.Multiplicador or "1"
	local texto = bonus and multiplicador=="1" and "" or "×" .. numero(multiplicador)
	if bonus then texto ..= (texto=="" and "+" or " + ") .. numero(configuracao.Bonus) end
	return texto
end

-- Recebe uma definicao de peca ja resolvida e devolve um texto com uma linha por estatistica relevante. A
-- lista de Componentes decide quais campos sao exibidos; um tipo desconhecido e indicado no texto.
function FichaMaquina.Descrever(definicao,jogador)
	local linhas = {}
	if definicao.Blocos then
		local b=definicao.Blocos
		table.insert(linhas,"Tamanho (L×C×A): "..numero(b[1]).." × "..numero(b[3]).." × "..numero(b[2]).." blocos")
	end
	local transportes,vendedor={},false
	for _,c in definicao.Componentes or {} do if c.Tipo=="Vendedor" then vendedor=true end end
	if definicao.Renascimento then table.insert(linhas, "Renascimento • Permanente") end
	-- A ficha percorre capacidades, nao nomes de modelos. Cada ramo traduz os parametros desse comportamento em
	-- texto, incluindo unidades, para servir tambem a outras pecas com o mesmo Tipo.
	for _, componente in definicao.Componentes or {} do
		if componente.Tipo == "Soltador" then
			local minerio = componente.Minerio
			table.insert(linhas, "Minério: $" .. AbreviarInteiro(Efeitos.Extracao(minerio.Valor,Efeitos.Nivel(jogador,"Extracao"))))
			table.insert(linhas, "Intervalo de geração: " .. numero(componente.Intervalo) .. " s")
			table.insert(linhas, "Tamanho do minério: " .. table.concat({ numero(minerio.Tamanho[1]),
				numero(minerio.Tamanho[2]), numero(minerio.Tamanho[3]) }, " × ") .. " studs")
		elseif componente.Tipo == "Transportador" then
			local selecionado=jogador and jogador:GetAttribute("VelocidadeMotores") or 0
			local nivel=Upgrades.Valido(selecionado) and math.min(selecionado,Efeitos.Nivel(jogador,"Motores")) or 0
			local texto="Transporte: " .. numero(Efeitos.Velocidade(componente.Velocidade,nivel)/bloco) .. " blocos/s"
			if not vendedor and not transportes[texto] then table.insert(linhas,texto); transportes[texto]=true end
		elseif componente.Tipo == "Modificador" then
			table.insert(linhas, "Modificação: " .. efeito(componente))
			if componente.Renascimento then
				table.insert(linhas, "Cópias: +50% por unidade adicional")
				table.insert(linhas, "Entrada inicial: minério processado ×10K")
			end
			local limites = {}
			if componente.LimiteUsos then table.insert(limites, numero(componente.LimiteUsos)) end
			local minimo,maximo=Efeitos.Limites(componente,Efeitos.Nivel(jogador,"Calibracao"))
			minimo=minimo or "0"
			if maximo then
				maximo = "$" .. AbreviarInteiro(maximo, true)
				table.insert(limites, minimo:match("^0+$") and maximo or ("$" .. AbreviarInteiro(minimo, true) .. "~" .. maximo))
			elseif not minimo:match("^0+$") then
				table.insert(limites, "≥$" .. AbreviarInteiro(minimo, true))
			end
			table.insert(linhas, "Limite: " .. (#limites > 0 and table.concat(limites, " e ") or "inf"))
		elseif componente.Tipo == "Vendedor" then
			local nivel=Efeitos.Nivel(jogador,"Fundicao")
			local venda=efeito(componente)
			if nivel>0 then
				local fator=Upgrades.Fator(nivel)
				local base=venda
				venda=efeito({Multiplicador=Inteiro.multiplicarDecimal(componente.Multiplicador or "1",fator),Bonus=Inteiro.multiplicarDecimal(componente.Bonus or "0",fator)})
				-- A venda original arredonda antes do bonus de fundicao; fundir decimais nao e exato por unidade.
				if (componente.Multiplicador or "1"):find("%.") then venda="≈"..venda.."\nCálculo: ("..base..") → ×"..numero(fator) end
			end
			table.insert(linhas, "Venda: " .. venda)
		end
	end
	-- Junta as estatisticas com quebra de linha para o TextLabel. Essa formatacao e somente de exibicao: nao
	-- modifica numeros nem componentes da maquina.
	return table.concat(linhas, "\n")
end

return FichaMaquina
