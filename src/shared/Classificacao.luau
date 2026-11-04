local Classificacao = {}
Classificacao.Categorias = {
	{ Id = "Vidas", Nome = "Vidas", Monetario = false },
	{ Id = "DinheiroPorSegundo", Nome = "Dinheiro/s", Monetario = true },
	{ Id = "Minerio", Nome = "Minério", Monetario = true },
	{ Id = "Dinheiro", Nome = "Dinheiro", Monetario = true },
}
Classificacao.Limite = 50

function Classificacao.Normalizar(valor)
	if type(valor) ~= "string" or not valor:match("^[0-9]+$") then return nil end
	if valor:sub(1, 1) ~= "0" then return valor end
	local normalizado = valor:gsub("^0+", "")
	return normalizado ~= "" and normalizado or "0"
end

function Classificacao.Maior(a, b)
	return #a > #b or (#a == #b and a > b)
end

function Classificacao.Mesclar(anterior, novos)
	local porJogador = {}
	for _, lista in { anterior or {}, novos or {} } do
		for _, registro in lista do
			local valor = Classificacao.Normalizar(registro.Valor)
			if not valor or valor == "0" then continue end
			local salvo = porJogador[registro.UserId]
			local geracao=registro.Geracao or 0
			if not salvo or geracao>(salvo.Geracao or 0) or (geracao==(salvo.Geracao or 0) and Classificacao.Maior(valor, salvo.Valor)) then
				porJogador[registro.UserId] = { UserId = registro.UserId, Nome = registro.Nome, Valor = valor, Geracao=geracao }
			end
		end
	end
	local lista = {}
	for _, registro in porJogador do table.insert(lista, registro) end
	table.sort(lista, function(a, b)
		return if a.Valor == b.Valor then a.UserId < b.UserId else Classificacao.Maior(a.Valor, b.Valor)
	end)
	while #lista > Classificacao.Limite do table.remove(lista) end
	return lista
end

return Classificacao
