local fs = require("@lune/fs")
local r = require("@lune/roblox")
local serde = require("@lune/serde")
local processo = require("@lune/process")
local montagem = require("../renascimento/novas/montagem")
local formas = require("./formas")
local definicoes = require("./definicoes")
local destino = "modelos/expansao"
local categorias = {"Mineradoras","Fornalhas","Modificadores"}
local siglas = {Mineradoras="M",Fornalhas="F",Modificadores="X"}
local exportar = processo.args[1]
local geometria = {}
local ids = {}

for _, origem in {"Loja","Craft"} do
	fs.writeDir(destino.."/assets/"..origem)
	local galeria = r.Instance.new("Model")
	galeria.Name = "Galeria50"..origem
	local total, linha = 0,0
	for _, categoria in categorias do
		local lista = definicoes[origem][categoria]
		local pasta = r.Instance.new("Folder")
		pasta.Name, pasta.Parent = categoria,galeria
		for i, def in lista do
			assert(def[1]:match("^[A-Za-z]+$") and not ids[def[1]],def[1])
			ids[def[1]] = true
			local m = montagem.Modelo.new(def,categoria)
			formas[categoria](m,def)
			local modelo = m.modelo
			local codigo = (if origem=="Loja" then "L" else "C")..siglas[categoria]..string.format("%02d",i)
			modelo:SetAttribute("SomenteModelagem",false)
			modelo:SetAttribute("OrigemProposta",origem)
			modelo:SetAttribute("CodigoVisual",codigo)
			local arquivo = destino.."/assets/"..origem.."/"..def[1]..".rbxm"
			fs.writeFile(arquivo,r.serializeModel({modelo}))
			if exportar then
				table.insert(geometria,{
					id=def[1],nome=def[2],categoria=categoria,origem=origem,codigo=codigo,
					blocos={def[3],def[4],def[5]},etapas=modelo:GetAttribute("Etapas"),
					largura=modelo:GetAttribute("LarguraCorreiaBlocos"),nivel=if categoria=="Modificadores" then def[9] else 0,
					partes=montagem.Geometria(modelo),
				})
			end
			local deslocamento = r.Vector3.new((i-1)%5*66,0,(linha+math.floor((i-1)/5))*51)
			for _, p in modelo:GetDescendants() do
				if p:IsA("BasePart") then p.CFrame += deslocamento end
			end
			modelo.Parent = pasta
			total += 1
		end
		linha += math.ceil(#lista/5)+1
	end
	assert(total==50,origem)
	fs.writeFile(destino.."/"..galeria.Name..".rbxm",r.serializeModel({galeria}))
	print(galeria.Name,total)
end

if exportar then fs.writeFile(exportar,serde.encode("json",geometria)) end
