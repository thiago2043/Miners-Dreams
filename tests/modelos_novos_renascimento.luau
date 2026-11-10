local fs = require("@lune/fs")
local r = require("@lune/roblox")
local grade = require("../src/shared/Medidas").Bloco
local defs = require("../modelos/renascimento/novas/definicoes")
local pasta = "modelos/renascimento/novas"
local galeria = r.deserializeModel(fs.readFile(pasta.."/Galeria51Renascimento.rbxm"))[1]
local total, estreitas = 0, 0

local function igual(a, b)
	return math.abs(a-b)<.0001
end

local function naGrade(borda)
	return igual(borda/grade, math.round(borda/grade))
end

for categoria, lista in defs do
	local grupo = assert(galeria:FindFirstChild(categoria))
	assert(#grupo:GetChildren()==#lista)
	for _, def in lista do
		local id, w, d, h = def[1], def[3]*grade, def[4]*grade, def[5]*grade
		local modelo = r.deserializeModel(fs.readFile(pasta.."/assets/"..id..".rbxm"))[1]
		local hitbox = modelo.HitboxConstrucao
		assert(modelo.Name==id and grupo:FindFirstChild(id) and modelo.PrimaryPart, id)
		assert(modelo:GetAttribute("SomenteModelagem")==false and modelo:GetAttribute("Renascimento"),id)
		assert(modelo:GetAttribute("GradeStuds")==grade and hitbox.Size==r.Vector3.new(w,h,d),id)
		assert(hitbox.CFrame.Position.Y==h/2 and hitbox.Transparency==1 and not hitbox.CanCollide,id)
		local topoVisivel = 0
		for _, p in modelo:GetDescendants() do
			if not p:IsA("BasePart") or p.Transparency>=1 then continue end
			local _,y,_,_,_,_,rx,ry,rz = p.CFrame:GetComponents()
			local meiaAltura = (math.abs(rx)*p.Size.X+math.abs(ry)*p.Size.Y+math.abs(rz)*p.Size.Z)/2
			topoVisivel = math.max(topoVisivel,y+meiaAltura)
		end
		assert(topoVisivel>=h-grade-.05 and topoVisivel<=h+.12,id)
		if categoria=="Mineradoras" then
			local ponta, base = modelo:GetAttribute("PontaBroca"), modelo:GetAttribute("BaseBroca")
			local indicador, saida = modelo.IndicadorSaida, modelo.PrimaryPart.SaidaMinerio
			local origem = (modelo.PrimaryPart.CFrame * saida.CFrame).Position
			assert(indicador.CFrame.Position==ponta and indicador.Transparency>.5 and not indicador.CanCollide,id)
			assert(igual(origem.X,0) and igual(origem.Z,ponta.Z) and origem.Y<ponta.Y,id)
			assert(igual(base.Z,d/2) and igual((ponta.Z-d/2)/grade,def[8]),id)
			assert(naGrade(ponta.Z-d/2-grade/2) and ponta.Y<base.Y,id)
		else
			local forno = categoria=="Fornalhas"
			local correia = if forno then modelo.BandejaEntrada else modelo.Correia
			local largura, nivel = if forno then 2 else def[8] or 2, if forno then 0 else def[9] or 0
			local centro = correia.CFrame.Position
			local x, z = centro.X+w/2, centro.Z+d/2
			assert(correia.CanCollide and correia.Size.X==largura*grade,id)
			assert(naGrade(x-correia.Size.X/2) and naGrade(x+correia.Size.X/2),id)
			assert(naGrade(z-correia.Size.Z/2) and naGrade(z+correia.Size.Z/2),id)
			assert(igual(z-correia.Size.Z/2,0),id)
			local topo = centro.Y+correia.Size.Y/2
			assert(igual(topo,1.25*grade/4+nivel*grade),id)
			if forno then
				assert(correia.Size.Z==grade*2 and modelo.SensorEntrada.Size.Z==grade*2,id)
				assert(modelo.SensorEntrada.CFrame.Position.X==centro.X,id)
			else
				if largura==1 then estreitas += 1 end
				assert(correia.Size.Z==d and modelo:GetAttribute("Etapas")==#def[7],id)
				local anterior = -d/2
				for i = 1, #def[7] do
					local faixa = modelo[string.format("FaixaUpgrade%02d",i)]
					local sensor = modelo[faixa:GetAttribute("Sensor")]
					assert(sensor.Size==faixa.Size and sensor.CFrame==faixa.CFrame,id)
					local p = faixa.CFrame.Position
					assert(faixa.Size.X==correia.Size.X and p.X==centro.X,id)
					assert(igual(p.Y-faixa.Size.Y/2,topo),id)
					assert(p.Z-faixa.Size.Z/2>=anterior,id)
					assert(sensor:GetAttribute("EtapaUpgrade")==i and not sensor.CanCollide,id)
					anterior = p.Z+faixa.Size.Z/2
				end
			end
		end
		total += 1
	end
end
assert(#defs.Mineradoras==4 and #defs.Fornalhas==4 and #defs.Modificadores==43)
assert(total==51 and #fs.readDir(pasta.."/assets")==total and estreitas==4)
print("51_MODELOS_OK: modelos e galeria, grade, 4 saídas de broca, 4 bandejas, 43 correias e etapas em ordem.")
