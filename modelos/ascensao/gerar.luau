local fs = require("@lune/fs")
local r = require("@lune/roblox")
local serde = require("@lune/serde")
local processo = require("@lune/process")
local montagem = require("../renascimento/novas/montagem")
local bloco = require("../../src/shared/Medidas").Bloco
local formas = require("./formas")
local definicoes = require("./definicoes")
local intermediarios = require("./intermediarios")
local pasta = "modelos/ascensao"
local categorias = {"Mineradoras", "Fornalhas", "Modificadores"}
local siglas = {Mineradoras = "M", Fornalhas = "F", Modificadores = "X"}
local totais = {Mineradoras = 10, Fornalhas = 10, Modificadores = 30}
local geometria, ids, transicoes = {}, {}, {}
local manifesto = {}

for _, origem in {"Ascensao", "Craft", "Intermediarios"} do
	local craft, intermediario = origem ~= "Ascensao", origem == "Intermediarios"
	local grupos = if intermediario then intermediarios else definicoes[origem]
	fs.writeDir(pasta .. "/assets/" .. origem)
	local galeria = r.Instance.new("Model")
	galeria.Name = "Galeria50" .. (if intermediario then "CraftIntermediariosAscensao" elseif craft then "CraftAscensao" else "Ascensao")
	local linha = 0
	for _, categoria in categorias do
		local grupo = r.Instance.new("Folder")
		grupo.Name, grupo.Parent = categoria, galeria
		local defs = grupos[categoria]
		assert(#defs == totais[categoria], categoria)
		for i, def in defs do
			local id = def[1]
			assert(id:match("^[A-Za-z][A-Za-z0-9]*$") and not ids[id], id)
			ids[id] = true
			local m = montagem.Modelo.new(def, categoria)
			formas[categoria](m, def, craft)
			local modelo = m.modelo
			local codigo = (if intermediario then "CI" elseif craft then "CA" else "A") .. siglas[categoria] .. string.format("%02d", i)
			local serieLoja
			if intermediario then
				formas.JuntasIntermediario(m, categoria)
				serieLoja = if categoria == "Modificadores" then math.ceil(i/3) else i
				modelo:SetAttribute("AscensoesMinimas", 1)
				modelo:SetAttribute("SerieLoja", serieLoja)
			end
			local transicao
			if not craft then
				transicao = if categoria == "Mineradoras" then (i - 1) * 5 + 1
					elseif categoria == "Fornalhas" then (i - 1) * 5 + 3
					else math.floor((i - 1) / 3) * 5 + ({2, 4, 5})[(i - 1) % 3 + 1]
				assert(not transicoes[transicao], id)
				transicoes[transicao] = id
				modelo:SetAttribute("TransicaoAscensao", transicao)
			end
			modelo:SetAttribute("SomenteModelagem", true)
			modelo:SetAttribute("OrigemProposta", if intermediario then "Craft intermediário de Ascensão" elseif craft then "Craft de Ascensão" else "Ascensão")
			modelo:SetAttribute("CodigoVisual", codigo)
			local arquivo = pasta .. "/assets/" .. origem .. "/" .. id .. ".rbxm"
			fs.writeFile(arquivo, r.serializeModel({modelo}))
			local info = {
				id = id, nome = def[2], codigo = codigo, categoria = categoria, origem = origem,
				blocos = {def[3], def[4], def[5]}, arquivo = arquivo, transicao = transicao, serieLoja = serieLoja,
				etapas = modelo:GetAttribute("Etapas"), largura = modelo:GetAttribute("LarguraCorreiaBlocos"),
				nivel = if categoria == "Modificadores" then def[9] else nil,
			}
			table.insert(manifesto, info)
			if processo.args[1] then
				local desenho = table.clone(info)
				desenho.partes = montagem.Geometria(modelo)
				table.insert(geometria, desenho)
			end
			local deslocamento = r.Vector3.new((i - 1) % 5 * bloco * 14, 0, (linha + math.floor((i - 1) / 5)) * bloco * 17)
			for _, p in modelo:GetDescendants() do
				if p:IsA("BasePart") then p.CFrame += deslocamento end
			end
			modelo.Parent = grupo
		end
		linha += math.ceil(#defs / 5) + 1
	end
	fs.writeFile(pasta .. "/" .. galeria.Name .. ".rbxm", r.serializeModel({galeria}))
	print(galeria.Name, 50)
end

for n = 1, 50 do assert(transicoes[n], "Falta transição " .. n) end
fs.writeFile(pasta .. "/modelos.json", serde.encode("json", manifesto, true))
if processo.args[1] then fs.writeFile(processo.args[1], serde.encode("json", geometria)) end
