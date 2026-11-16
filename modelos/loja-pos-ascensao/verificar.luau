local fs = require("@lune/fs")
local r = require("../../tests/suporte/modelos")
local serde = require("@lune/serde")
local bloco = require("../../src/shared/Medidas").Bloco
local carregar = require("../../tests/suporte/carregador")({}, {})
local catalogo = carregar("src/shared/CatalogoMaquinas")
local inteiro = carregar("src/shared/InteiroGrande")
local pasta = "modelos/loja-pos-ascensao"
local itens = serde.decode("json", fs.readFile(pasta .. "/modelos.json"))
local galeria = r.deserializeModel(fs.readFile(pasta .. "/Galeria100LojaPosAscensao.rbxm"))[1]
local grupos, contagens = {}, {Mineradoras = 0, Fornalhas = 0, Modificadores = 0}
local assinaturas, ids, codigos = {}, {}, {}
local precoAtual = "0"

local function perto(a, b) return math.abs(a - b) < .001 end
local function naGrade(v) return perto(v / bloco, math.round(v / bloco)) end

for _, item in catalogo do
	if not item.Obtencao and inteiro.menor(precoAtual, item.Preco) then precoAtual = item.Preco end
end
assert(precoAtual == "1" .. string.rep("0", 147), "Maior preço da loja atual mudou")
assert(#itens == 100 and #fs.readDir(pasta .. "/assets") == 100)
assert(#galeria:GetChildren() == 10)
for _, grupo in galeria:GetChildren() do
	local numero = tonumber(string.sub(grupo.Name, 1, 2))
	assert(numero and not grupos[numero] and #grupo:GetChildren() == 10, grupo.Name)
	grupos[numero] = grupo
end

local anterior = precoAtual
for i, item in itens do
	local id = item.id
	local modelo = r.deserializeModel(fs.readFile(item.arquivo))[1]
	local copia = grupos[item.serie]:FindFirstChild(id)
	assert(modelo.Name == id and copia and item.serie == math.ceil(i/10), id)
	assert(not ids[id] and not codigos[item.codigo] and not catalogo[id], id)
	ids[id], codigos[item.codigo] = true, true
	contagens[item.categoria] += 1
	assert(item.preco == "1" .. string.rep("0", item.expoente) and inteiro.menor(anterior, item.preco), id)
	anterior = item.preco
	for _, m in {modelo, copia} do
		assert(m.PrimaryPart and m:GetAttribute("AscensoesMinimas") == 1 and item.ascensoesMinimas == 1, id)
		assert(m:GetAttribute("PrecoProposto") == item.preco and m:GetAttribute("SomenteModelagem"), id)
		assert(m:GetAttribute("GradeStuds") == bloco and m:GetAttribute("CodigoVisual") == item.codigo, id)
	end
	local w, d, h = item.blocos[1]*bloco, item.blocos[2]*bloco, item.blocos[3]*bloco
	local caixa = modelo.HitboxConstrucao
	assert(caixa.Size == r.Vector3.new(w, h, d) and perto(caixa.CFrame.Position.Y, h/2), id)
	assert(not caixa.CanCollide and not caixa.CanTouch and not caixa.CanQuery and caixa.Transparency == 1, id)
	local formas = {}
	for _, parte in modelo:GetDescendants() do
		assert(not parte:IsA("LuaSourceContainer"), id)
		if parte:IsA("BasePart") and parte.Transparency < 1 then
			local _, y, _, _, _, _, a, b, c = parte.CFrame:GetComponents()
			local raio = (math.abs(a)*parte.Size.X + math.abs(b)*parte.Size.Y + math.abs(c)*parte.Size.Z)/2
			assert(parte.Anchored and y - raio >= -.05 and y + raio <= h + .15, id .. "/" .. parte.Name)
			local forma = if parte.ClassName == "Part" then tostring(parte.Shape) else parte.ClassName
			table.insert(formas, forma .. "/" .. tostring(parte.Size) .. "/" .. tostring(parte.CFrame))
		end
	end
	table.sort(formas)
	local assinatura = table.concat(formas, "|")
	assert(not assinaturas[assinatura], id .. " repete " .. (assinaturas[assinatura] or ""))
	assinaturas[assinatura] = id
	if item.categoria == "Mineradoras" then
		local origem = modelo.PrimaryPart.CFrame * modelo.PrimaryPart.SaidaMinerio.CFrame
		assert(perto(origem.X, 0) and origem.Y > 1 and origem.Y < h, id)
		assert(origem.Z > d/2 and naGrade(origem.Z-d/2-bloco/2) and origem.Z+d/2 < 12*bloco, id)
	else
		local fornalha = item.categoria == "Fornalhas"
		local leito = if fornalha then modelo.BandejaEntrada else modelo.Correia
		local pos = leito.CFrame.Position
		local topo = pos.Y + leito.Size.Y/2
		assert(leito.CanCollide and leito.Size.X == bloco*2 and perto(topo, bloco*(1.25/4 + (item.nivel or 0))), id)
		assert(naGrade(pos.X - leito.Size.X/2 + w/2) and perto(pos.Z - leito.Size.Z/2, -d/2), id)
		if fornalha then
			local sensor = modelo.SensorEntrada
			assert(leito.Size.Z == bloco*2 and sensor.Size.Z == bloco*2 and sensor.Size.X == bloco*2, id)
			assert(sensor.CFrame.Position.X == pos.X and sensor.CFrame.Position.Z == pos.Z and perto(sensor.CFrame.Position.Y-sensor.Size.Y/2, topo), id)
		else
			assert(leito.Size.Z == d and item.etapas == modelo:GetAttribute("Etapas"), id)
			local fim = -d/2
			for etapa = 1, item.etapas do
				local faixa = modelo[string.format("FaixaUpgrade%02d", etapa)]
				local sensor = modelo[faixa:GetAttribute("Sensor")]
				assert(sensor.Size == faixa.Size and sensor.CFrame == faixa.CFrame and not sensor.CanCollide, id)
				assert(perto(faixa.CFrame.Position.Y-faixa.Size.Y/2, topo) and perto(faixa.CFrame.Position.X, pos.X) and faixa.Size.X == leito.Size.X, id)
				assert(faixa.CFrame.Position.Z-faixa.Size.Z/2 >= fim and sensor:GetAttribute("EtapaUpgrade") == etapa, id)
				fim = faixa.CFrame.Position.Z + faixa.Size.Z/2
			end
			assert(fim <= d/2, id)
		end
	end
end
assert(contagens.Mineradoras == 20 and contagens.Fornalhas == 20 and contagens.Modificadores == 60)
assert(itens[1].expoente == 155 and itens[100].expoente == 399)
print("MODELOS_LOJA_POS_ASCENSAO_OK: 100 geometrias distintas, galerias, hitboxes, conexoes e precos.")
