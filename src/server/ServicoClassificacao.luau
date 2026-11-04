local Regras = require(game:GetService("ReplicatedStorage").Shared.Classificacao)
local Servico = {}
Servico.__index = Servico

local function geracoes(a,b)
	local novo=table.clone(a or {})
	for id,n in b or {} do novo[id]=math.max(n,novo[id] or 0) end
	return novo
end
local function filtrar(lista,versoes)
	local resultado={}
	for _,r in lista or {} do
		if (r.Geracao or 0)>=(versoes[tostring(r.UserId)] or 0) then table.insert(resultado,r) end
	end
	return resultado
end
local function ler(valor)
	-- A geracao permanece mesmo fora do top 50 para caches antigos nao restaurarem recordes zerados.
	if valor and valor.Lista then return valor.Lista,valor.Geracoes or {} end
	return valor or {},{}
end

function Servico.new(armazenamento)
	return setmetatable({ _store = armazenamento, _pendentes = {}, _tabelas = {}, _disponivel = false, _geracoes={},_geracoesPendentes={} }, Servico)
end

function Servico:Registrar(jogador, recordes,geracao)
	geracao=geracao or 0
	for _, categoria in Regras.Categorias do
		local id = categoria.Id
		local versoes=self._geracoes[id] or {}
		if geracao>0 then
			local pendentes=self._geracoesPendentes[id] or {}
			pendentes[tostring(jogador.UserId)]=math.max(geracao,pendentes[tostring(jogador.UserId)] or 0)
			self._geracoesPendentes[id]=pendentes
			versoes=geracoes(versoes,pendentes); self._geracoes[id]=versoes
			self._pendentes[id]=filtrar(self._pendentes[id],versoes)
			self._tabelas[id]=filtrar(self._tabelas[id],versoes)
		end
		local valor = Regras.Normalizar(recordes[id])
		if not valor or valor == "0" then continue end
		local lista = self._pendentes[id] or {}
		local novo = filtrar({ { UserId = jogador.UserId, Nome = jogador.Name, Valor = valor,Geracao=geracao } },versoes)
		self._pendentes[id] = Regras.Mesclar(lista, novo)
		self._tabelas[id] = Regras.Mesclar(self._tabelas[id], novo)
	end
end

-- shortcut: quatro chaves globais com top 50 exato; particionar se muitos servidores disputarem essas chaves.
-- O DataStore comum conserva inteiros decimais maiores que o limite numerico do OrderedDataStore.
function Servico:Atualizar()
	if self._atualizando then return false end
	self._atualizando = true
	local completo = true
	for _, categoria in Regras.Categorias do
		local id = categoria.Id
		local enviados = self._pendentes[id]
		local versoesEnviadas=self._geracoesPendentes[id]
		self._pendentes[id] = nil
		self._geracoesPendentes[id]=nil
		local ok, lista = pcall(function()
			if enviados or versoesEnviadas then
				return self._store:UpdateAsync(id, function(anterior)
					local registros,versoes=ler(anterior)
					versoes=geracoes(versoes,versoesEnviadas)
					return {Lista=Regras.Mesclar(filtrar(registros,versoes),filtrar(enviados,versoes)),Geracoes=versoes}
				end)
			end
			return self._store:GetAsync(id) or {}
		end)
		if ok then
			local registros,versoes=ler(lista)
			self._geracoes[id]=geracoes(versoes,self._geracoesPendentes[id])
			self._tabelas[id] = Regras.Mesclar(filtrar(registros,self._geracoes[id]),filtrar(self._pendentes[id],self._geracoes[id]))
		else
			completo = false
			if enviados then self._pendentes[id] = Regras.Mesclar(enviados, self._pendentes[id]) end
			if versoesEnviadas then self._geracoesPendentes[id]=geracoes(versoesEnviadas,self._geracoesPendentes[id]) end
			warn("Classificação indisponível (" .. id .. "): " .. tostring(lista))
		end
	end
	self._disponivel = completo
	self._atualizando = false
	return completo
end

function Servico:Consultar()
	return { Tabelas = self._tabelas, Disponivel = self._disponivel }
end

return Servico
