local fs = require("@lune/fs")
local r = require("./suporte/modelos")
local serde = require("@lune/serde")
local definicoes = require("../modelos/ascensao/definicoes")
local bloco = require("../src/shared/Medidas").Bloco
local carregar = require("./suporte/carregador")({}, {})
local catalogo = carregar("src/shared/CatalogoMaquinas")
local pasta = "modelos/ascensao"
local manifesto = serde.decode("json", fs.readFile(pasta .. "/modelos.json"))
local receitas = serde.decode("json", fs.readFile(pasta .. "/receitas.json"))
local itensLoja = serde.decode("json", fs.readFile("modelos/loja-pos-ascensao/modelos.json"))
local loja = {}
for _, item in itensLoja do loja[item.id] = item end
local totais = {Mineradoras = 10, Fornalhas = 10, Modificadores = 30}
local tipos = {Soltador = "Mineradoras", Vendedor = "Fornalhas", Modificador = "Modificadores"}
local porId, porCodigo, transicoes, assinaturas, galerias = {}, {}, {}, {}, {}
local erro = .001
local function perto(a, b) return math.abs(a - b) < erro end
local function naGrade(v) return perto(v / bloco, math.round(v / bloco)) end

assert(#manifesto == 150 and #receitas == 100 and #itensLoja == 100)
for origem, nome in {Ascensao = "Galeria50Ascensao", Craft = "Galeria50CraftAscensao", Intermediarios = "Galeria50CraftIntermediariosAscensao"} do
	local grupos = if origem == "Intermediarios" then require("../modelos/ascensao/intermediarios") else definicoes[origem]
	local arquivo = pasta .. "/" .. nome .. ".rbxm"
	local galeria = r.deserializeModel(fs.readFile(arquivo))[1]
	assert(galeria.Name == nome and #fs.readDir(pasta .. "/assets/" .. origem) == 50, nome)
	galerias[origem] = galeria
	for categoria, lista in grupos do
		assert(#galeria[categoria]:GetChildren() == totais[categoria], categoria)
		assert(#lista == totais[categoria], categoria)
	end
end

for _, item in manifesto do
	local id, categoria = item.id, item.categoria
	local m = r.deserializeModel(fs.readFile(item.arquivo))[1]
	assert(m.Name == id and m.PrimaryPart and galerias[item.origem][categoria]:FindFirstChild(id), id)
	assert(not catalogo[id] and not porId[id] and not porCodigo[item.codigo], id)
	porId[id], porCodigo[item.codigo] = item, true
	assert(m:GetAttribute("CodigoVisual") == item.codigo and m:GetAttribute("GradeStuds") == bloco, id)
	if item.origem == "Ascensao" then
		assert(not transicoes[item.transicao] and m:GetAttribute("TransicaoAscensao") == item.transicao, id)
		transicoes[item.transicao] = true
	elseif item.origem == "Intermediarios" then
		assert(m:GetAttribute("AscensoesMinimas") == 1 and m:GetAttribute("SerieLoja") == item.serieLoja, id)
	end
	local w, d, h = item.blocos[1] * bloco, item.blocos[2] * bloco, item.blocos[3] * bloco
	local caixa = m.HitboxConstrucao
	assert(caixa.Size == r.Vector3.new(w, h, d) and perto(caixa.CFrame.Position.Y, h/2), id)
	assert(not caixa.CanCollide and not caixa.CanTouch and not caixa.CanQuery and caixa.Transparency == 1, id)
	local formas = {}
	for _, p in m:GetDescendants() do
		assert(not p:IsA("LuaSourceContainer"), id)
		if p:IsA("BasePart") and p.Transparency < 1 then
			assert(p.Anchored and p.Size.X > 0 and p.Size.Y > 0 and p.Size.Z > 0, id .. "/" .. p.Name)
			local _, y, _, _, _, _, a, b, c = p.CFrame:GetComponents()
			local meio = (math.abs(a) * p.Size.X + math.abs(b) * p.Size.Y + math.abs(c) * p.Size.Z)/2
			assert(y - meio >= -.05 and y + meio <= h + .15, id .. "/" .. p.Name)
			table.insert(formas, p.ClassName .. "/" .. tostring(p.Size) .. "/" .. tostring(p.CFrame))
		end
	end
	table.sort(formas)
	local assinatura = table.concat(formas, "|")
	assert(not assinaturas[assinatura], id .. " repete " .. (assinaturas[assinatura] or ""))
	assinaturas[assinatura] = id
	if categoria == "Mineradoras" then
		local origem = m.PrimaryPart.CFrame * m.PrimaryPart.SaidaMinerio.CFrame
		assert(perto(origem.X,0) and origem.Y > 1 and origem.Y < h, id)
		assert(origem.Z > d/2 and naGrade(origem.Z-d/2-bloco/2), id)
		assert(origem.Z+d/2 < 12*bloco, id .. " precisa alcançar a saída na plot inicial")
	else
		local fornalha = categoria == "Fornalhas"
		local leito = if fornalha then m.BandejaEntrada else m.Correia
		local pos = leito.CFrame.Position
		local topo = pos.Y + leito.Size.Y/2
		assert(leito.CanCollide and leito.Size.X == bloco * 2, id)
		assert(perto(topo, bloco * (1.25/4 + (item.nivel or 0))), id)
		assert(naGrade(pos.X - leito.Size.X/2 + w/2) and naGrade(pos.X + leito.Size.X/2 + w/2), id)
		assert(perto(pos.Z - leito.Size.Z/2, -d/2), id)
		if fornalha then
			assert(leito.Size.Z == 2*bloco and m.SensorEntrada.Size.Z == leito.Size.Z, id)
			assert(m.SensorEntrada.CFrame.Position.X == pos.X, id)
		else
			assert(leito.Size.Z == d and item.etapas == m:GetAttribute("Etapas"), id)
			local anterior = -d/2
			for i = 1, item.etapas do
				local faixa = m[string.format("FaixaUpgrade%02d", i)]
				local sensor = m[faixa:GetAttribute("Sensor")]
				assert(sensor.Size == faixa.Size and sensor.CFrame == faixa.CFrame and not sensor.CanCollide, id)
				local centro = faixa.CFrame.Position
				assert(perto(centro.Y-faixa.Size.Y/2, topo) and perto(centro.X, pos.X) and faixa.Size.X == leito.Size.X, id)
				assert(centro.Z - faixa.Size.Z/2 >= anterior and sensor:GetAttribute("EtapaUpgrade") == i, id)
				anterior = centro.Z + faixa.Size.Z/2
			end
			assert(anterior <= d/2, id)
		end
	end
end
for marco = 1, 50 do assert(transicoes[marco], marco) end

local novas, finais = {}, {}
local basesAnteriores = {[2] = 1, [4] = 1, [5] = 2, [7] = 1, [9] = 1, [10] = 3}
for _, receita in receitas do
	local modelo = porId[receita.id]
	assert(not novas[receita.id] and modelo.origem ~= "Ascensao" and receita.serieLoja == modelo.serieLoja, receita.id)
	assert(#receita.ingredientes >= 2 and #receita.ingredientes <= 8, receita.id)
	novas[receita.id] = receita
	if receita.final then
		assert(not finais[receita.categoria], receita.id)
		finais[receita.categoria] = receita.id
	end
	local compras, passos = 0, 0
	for _, id in receita.ingredientes do
		local entrada, peca = novas[id], loja[id]
		assert((entrada and entrada.categoria == receita.categoria) or (catalogo[id] and catalogo[id].Obtencao) or peca, receita.id .. "/" .. id)
		if peca then
			assert(peca.categoria == receita.categoria and peca.serie == receita.serieLoja, receita.id .. "/" .. id)
			compras += 1
		end
		if entrada and entrada.serieLoja then
			assert(entrada.serieLoja < (receita.serieLoja or math.huge), receita.id .. "/" .. id)
			passos += 1
		end
	end
	if receita.serieLoja then
		assert(compras == 2 and passos == (basesAnteriores[receita.serieLoja] or 0), receita.id)
	end
end
for categoria in totais do
	local vistos, pilha = {}, {}
	local function visitar(id)
		assert(not pilha[id], "Ciclo na receita de " .. id)
		pilha[id] = true
		vistos[id] = (vistos[id] or 0) + 1
		local lista = if novas[id] then novas[id].ingredientes else catalogo[id] and catalogo[id].Receita
		for _, ingrediente in lista or {} do visitar(ingrediente) end
		pilha[id] = nil
	end
	visitar(assert(finais[categoria]))
	for id, item in catalogo do
		if (item.Receita or item.Renascimento) and tipos[item.Componentes[#item.Componentes].Tipo] == categoria then
			assert(vistos[id], categoria .. " não abrange " .. id)
		end
	end
	for id, receita in novas do
		if receita.categoria == categoria then
			assert(vistos[id], id)
			if receita.serieLoja then assert(vistos[id] == 1, id .. " consumido mais de uma vez") end
		end
	end
	for id, item in loja do
		if item.categoria == categoria then assert(vistos[id] == 1, id .. " deve ser consumido uma vez") end
	end
end
print("MODELOS_ASCENSAO_OK: 150 modelos distintos, 100 receitas, 50 transições e três sínteses com as 100 peças da loja.")
