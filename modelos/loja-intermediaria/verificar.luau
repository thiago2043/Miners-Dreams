local fs = require("@lune/fs")
local r = require("../../tests/suporte/modelos")
local serde = require("@lune/serde")
local I = require("../../src/shared/InteiroGrande")
local bloco = require("../../src/shared/Medidas").Bloco
local series = require("./series")
local cotas, ancoras = require("./precos").Distribuir()
local pasta = "modelos/loja-intermediaria"
local itens = serde.decode("json", fs.readFile(pasta .. "/modelos.json"))
local galeria = r.deserializeModel(fs.readFile(pasta .. "/Galeria80LojaIntermediaria.rbxm"))[1]
local contagem = {Mineradoras = 0, Fornalhas = 0, Modificadores = 0}
local grupos, indices, ids, codigos, nomes, formas, precos = {}, {}, {}, {}, {}, {}, {}

local function perto(a, b) return math.abs(a - b) < .001 end
local function naGrade(v) return perto(v/bloco, math.round(v/bloco)) end

assert(#itens == 80 and #fs.readDir(pasta .. "/assets") == 80 and #galeria:GetChildren() == 6)
for _, grupo in galeria:GetChildren() do
	local g = tonumber(grupo.Name:sub(1, 2))
	assert(g and not grupos[g] and #grupo:GetChildren() == #series[g].Pecas, grupo.Name)
	grupos[g] = grupo
end
for _, ancora in ancoras do table.insert(precos, ancora.preco) end
for _, item in itens do
	local id = item.id
	local m = r.deserializeModel(fs.readFile(item.arquivo))[1]
	local copia = grupos[item.serie]:FindFirstChild(id)
	assert(copia and m.Name == id and not ids[id] and not codigos[item.codigo] and not nomes[item.nome], id)
	ids[id], codigos[item.codigo], nomes[item.nome] = true, true, true
	contagem[item.categoria] += 1
	local indice = (indices[item.serie] or 0) + 1
	indices[item.serie] = indice
	assert(cotas[item.serie][indice].preco == item.preco, id)
	table.insert(precos, item.preco)
	for _, modelo in {m, copia} do
		assert(modelo.PrimaryPart and modelo:GetAttribute("SomenteModelagem") == true, id)
		assert(modelo:GetAttribute("GradeStuds") == bloco and modelo:GetAttribute("PrecoProposto") == item.preco, id)
		assert(modelo:GetAttribute("CodigoVisual") == item.codigo and modelo:GetAttribute("NomeExibicao") == item.nome, id)
	end
	local w, d, h = item.blocos[1]*bloco, item.blocos[2]*bloco, item.blocos[3]*bloco
	local caixa = m.HitboxConstrucao
	assert(caixa.Size == r.Vector3.new(w,h,d) and perto(caixa.CFrame.Position.Y, h/2), id)
	assert(not caixa.CanCollide and not caixa.CanQuery and caixa.Transparency == 1, id)
	local partes = {}
	for _, p in m:GetDescendants() do
		assert(not p:IsA("LuaSourceContainer"), id)
		if p:IsA("BasePart") and p.Transparency < 1 then
			local _, y, _, _, _, _, a, b, c = p.CFrame:GetComponents()
			local raio = (math.abs(a)*p.Size.X + math.abs(b)*p.Size.Y + math.abs(c)*p.Size.Z)/2
			assert(p.Anchored and y - raio >= -.05 and y + raio <= h + .15, id .. "/" .. p.Name)
			local forma = if p.ClassName == "Part" then tostring(p.Shape) else p.ClassName
			table.insert(partes, forma .. "/" .. tostring(p.Size) .. "/" .. tostring(p.CFrame))
		end
	end
	table.sort(partes)
	local assinatura = table.concat(partes, "|")
	assert(not formas[assinatura], id .. " repete " .. (formas[assinatura] or ""))
	formas[assinatura] = id
	if item.categoria == "Mineradoras" then
		local origem = m.PrimaryPart.CFrame * m.PrimaryPart.SaidaMinerio.CFrame
		assert(perto(origem.X,0) and origem.Y > 1 and origem.Y < h, id)
		assert(origem.Z > d/2 and naGrade(origem.Z-d/2-bloco/2) and origem.Z+d/2 < bloco*12, id)
		local perfil = series[item.serie].Pecas[indice][7]
		if perfil == "helicoidal" or perfil == "palhetas" then
			local flange, mancal, chassi = m.FlangeDaBroca, m.MancalDaBroca, m.ChassiDeTransmissao
			local y = h*.53
			local raiz = r.Vector3.new(0,y,d*(if perfil == "helicoidal" then .20 else .13))
			local ponta = r.Vector3.new(0,y-(if perfil == "helicoidal" then .42 else .25),origem.Z)
			local localRaiz = flange.CFrame:PointToObjectSpace(raiz)
			assert(flange.Shape == r.Enum.PartType.Cylinder and flange.Transparency == 0 and not flange.CanCollide, id)
			assert(perto(flange.CFrame.XVector:Dot((ponta-raiz).Unit), 1) and localRaiz.Magnitude < flange.Size.X/2, id)
			assert(flange.Size.Y/2 >= math.min(w*.19,h*.18)*1.25+.11, id .. " com a traseira da broca exposta")
			local apoio = mancal.CFrame.Position - mancal.CFrame.YVector*mancal.Size.Y*.46
			local dentro = chassi.CFrame:PointToObjectSpace(apoio)
			assert(math.abs(dentro.X) < chassi.Size.X/2 and math.abs(dentro.Y) < chassi.Size.Y/2 and math.abs(dentro.Z) < chassi.Size.Z/2, id)
		end
	else
		local fornalha = item.categoria == "Fornalhas"
		local leito = if fornalha then m.BandejaEntrada else m.Correia
		local pos = leito.CFrame.Position
		local topo = pos.Y + leito.Size.Y/2
		assert(leito.CanCollide and leito.Size.X == bloco*2 and perto(topo, bloco*(1.25/4 + (item.nivel or 0))), id)
		assert(naGrade(pos.X - bloco + w/2) and perto(pos.Z-leito.Size.Z/2, -d/2), id)
		if fornalha then
			local sensor = m.SensorEntrada
			assert(leito.Size.Z == bloco*2 and sensor.Size.Z == bloco*2 and sensor.Size.X == bloco*2, id)
			assert(sensor.CFrame.Position.X == pos.X and sensor.CFrame.Position.Z == pos.Z, id)
			assert(perto(sensor.CFrame.Position.Y-sensor.Size.Y/2, topo) and sensor.CanTouch and not sensor.CanCollide, id)
		else
			assert(leito.Size.Z == d and item.etapas == m:GetAttribute("Etapas"), id)
			local fim = -d/2
			for etapa = 1, item.etapas do
				local faixa = m[string.format("FaixaUpgrade%02d", etapa)]
				local sensor = m[faixa:GetAttribute("Sensor")]
				local centro = faixa.CFrame.Position
				assert(sensor.Size == faixa.Size and sensor.CFrame == faixa.CFrame and sensor.CanTouch and not sensor.CanCollide, id)
				assert(perto(centro.Y-faixa.Size.Y/2, topo) and perto(centro.X, pos.X) and faixa.Size.X == leito.Size.X, id)
				assert(centro.Z-faixa.Size.Z/2 >= fim and sensor:GetAttribute("EtapaUpgrade") == etapa, id)
				fim = centro.Z + faixa.Size.Z/2
			end
			assert(fim <= d/2, id)
		end
	end
end
table.sort(precos, I.menor)
for i = 1, #precos - 1 do assert(not I.menor(precos[i] .. "000", precos[i+1]), "Lacuna de preço") end
assert(contagem.Mineradoras == 16 and contagem.Fornalhas == 16 and contagem.Modificadores == 48)
print("MODELOS_LOJA_INTERMEDIARIA_OK: 80 modelos, hitboxes, sensores e teto de preço.")
