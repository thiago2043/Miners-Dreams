local fs = require("@lune/fs")
local r = require("@lune/roblox")
local serde = require("@lune/serde")
local grade = require("../../../src/shared/Medidas").Bloco
local definicoes = require("./definicoes")
local premios = {}
for _, premio in require("../../../src/shared/RecompensasRenascimento") do premios[premio.Id] = premio end
local V = r.Vector3
local montagem = require("./montagem")
local destino = "modelos/renascimento/novas"
local ids, cores, total, exportados = {}, {}, 0, {}
local galeria = r.Instance.new("Model")
galeria.Name = "Galeria51Renascimento"
fs.writeDir(destino.."/assets")
for _, grupo in {
	{"Mineradoras", montagem.Mineradora, 4, 4, 0},
	{"Fornalhas", montagem.Fornalha, 4, 4, 58},
	{"Modificadores", montagem.Modificador, 43, 8, 104},
} do
	local categoria, montar, quantidade, colunas, inicio = table.unpack(grupo)
	local pasta = r.Instance.new("Folder")
	pasta.Name, pasta.Parent = categoria, galeria
	assert(#definicoes[categoria] == quantidade)
	for i, def in definicoes[categoria] do
		assert(def[1]:match("^[A-Za-z]+$") and not ids[def[1]] and not cores[def[6]], def[1])
		ids[def[1]], cores[def[6]] = true, true
		local m = montagem.Modelo.new(def,categoria)
		montar(m,def)
		local modelo = m.modelo
		modelo:SetAttribute("Renascimento", true)
		modelo:SetAttribute("SomenteModelagem", false)
		modelo:SetAttribute("PrecoProposto", "0")
		if premios[def[1]].Multiplicador then modelo:SetAttribute("MultiplicadorProposto", premios[def[1]].Multiplicador) end
		modelo:SetAttribute("CodigoVisual", (if categoria=="Mineradoras" then "MR" elseif categoria=="Fornalhas" then "FR" else "XR")..string.format("%02d",i))
		fs.writeFile(destino.."/assets/"..def[1]..".rbxm",r.serializeModel({modelo}))
		table.insert(exportados,{id=def[1],nome=def[2],categoria=categoria,blocos={def[3],def[4],def[5]},
			codigo=modelo:GetAttribute("CodigoVisual"),etapas=modelo:GetAttribute("Etapas"),largura=def[8] or 2,
			nivel=def[9] or 0,partes=montagem.Geometria(modelo)})
		local deslocamento = V.new((i-1)%colunas*34,0,inicio+math.floor((i-1)/colunas)*24)
		for _, p in modelo:GetDescendants() do if p:IsA("BasePart") then p.CFrame += deslocamento end end
		modelo.Parent = pasta
		total += 1
	end
end
assert(total==51)
fs.writeFile(destino.."/Galeria51Renascimento.rbxm",r.serializeModel({galeria}))
fs.writeFile(destino.."/geometria.json",serde.encode("json",exportados))
print("RENASCIMENTO_MODELOS_OK", total)
