local bloco = require(game:GetService("ReplicatedStorage").Shared.Medidas).Bloco
local Migracao = {}

local function copiar(valor)
	if type(valor) ~= "table" then return valor end
	local novo = {}
	for k, v in valor do novo[k] = copiar(v) end
	return novo
end

local function vetor(valor, escala, quantidade)
	assert(type(valor) == "table" and #valor == quantidade, "Medida salva invalida.")
	for i = 1, quantidade do
		local n = valor[i]
		assert(type(n) == "number" and n == n and math.abs(n) < math.huge, "Medida salva nao finita.")
		if i <= 3 then valor[i] = n * escala end
	end
end

local function personalizacao(dados, escala)
	if dados == nil then return end
	assert(type(dados) == "table", "Personalizacao salva invalida.")
	if dados.Partes ~= nil then
		assert(type(dados.Partes) == "table", "Partes salvas invalidas.")
		for _, p in dados.Partes do
			assert(type(p) == "table", "Parte salva invalida.")
			if p.Tamanho then vetor(p.Tamanho, escala, 3) end
			if p.CFrame then vetor(p.CFrame, escala, 12) end
		end
	end
	if dados.Configuracao and dados.Configuracao.Componentes then
		assert(type(dados.Configuracao.Componentes) == "table", "Componentes salvos invalidos.")
		for _, c in dados.Configuracao.Componentes do
			if c.Minerio and c.Minerio.Tamanho then vetor(c.Minerio.Tamanho, escala, 3) end
		end
	end
end

-- Converte uma copia antes de Reconcile e conserva os dados espaciais antigos para recuperacao.
function Migracao.Preparar(dados)
	assert(type(dados) == "table", "Perfil invalido.")
	if dados.TamanhoBloco == bloco then return dados end
	assert(dados.TamanhoBloco == nil or dados.TamanhoBloco == 4, "Escala salva desconhecida.")
	assert(dados.BackupGrade4 == nil, "Backup de grade ja existente; perfil preservado.")
	local novo, escala = copiar(dados), bloco / 4
	novo.BackupGrade4 = { TamanhoBloco = 4, MaquinasColocadas = copiar(dados.MaquinasColocadas),
		Blueprints = copiar(dados.Blueprints), InventarioPersonalizado = copiar(dados.InventarioPersonalizado) }
	for _, p in novo.MaquinasColocadas or {} do
		vetor(p.Posicao, escala, 3)
		personalizacao(p.Modificacoes, escala)
	end
	for _, b in novo.Blueprints or {} do
		for _, p in b.Pecas do
			vetor(p.DeslocamentoInicial, escala, 3)
			personalizacao(p.Modificacoes, escala)
		end
	end
	for _, variantes in novo.InventarioPersonalizado or {} do
		for _, p in variantes do personalizacao(p, escala) end
	end
	novo.TamanhoBloco = bloco
	return novo
end

return Migracao
