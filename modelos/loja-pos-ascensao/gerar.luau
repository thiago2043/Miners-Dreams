local fs = require("@lune/fs")
local r = require("@lune/roblox")
local serde = require("@lune/serde")
local processo = require("@lune/process")
local montagem = require("../renascimento/novas/montagem")
local bloco = require("../../src/shared/Medidas").Bloco
local abreviar = require("../../src/shared/AbreviarInteiro")
local series = require("./series")
local formas = require("./formas")
local pasta = "modelos/loja-pos-ascensao"
local ordem = {
	{"Mineradoras", 1}, {"Fornalhas", 1}, {"Modificadores", 1}, {"Modificadores", 2}, {"Modificadores", 3},
	{"Mineradoras", 2}, {"Fornalhas", 2}, {"Modificadores", 4}, {"Modificadores", 5}, {"Modificadores", 6},
}
local grupoCodigo = {Mineradoras = "M", Fornalhas = "F", Modificadores = "X"}
local contagens = {Mineradoras = 0, Fornalhas = 0, Modificadores = 0}
local manifesto, geometria = {}, {}
local galeria = r.Instance.new("Model")
galeria.Name = "Galeria100LojaPosAscensao"
fs.writeDir(pasta .. "/assets")

local tabela = {
	"# Preços da loja pós-Ascensão",
	"",
	"Na proposta, as 100 peças ficam disponíveis após a primeira Ascensão concluída. Os preços abaixo são em dinheiro e estão em ordem crescente. As medidas seguem largura × comprimento × altura em blocos de 3 studs.",
	"",
	"| Código | Série | Máquina | Hitbox | Preço em expoente | Abreviação no jogo |",
	"| --- | --- | --- | --- | --- | --- |",
}

for n, serie in series do
	local grupo = r.Instance.new("Folder")
	grupo.Name, grupo.Parent = string.format("%02d · %s", n, serie.Nome), galeria
	local matiz, saturacao, brilho = r.Color3.fromHex(string.format("%06X", serie.Cor)):ToHSV()
	for i, slot in ordem do
		local categoria, indice = slot[1], slot[2]
		local def = serie[categoria][indice]
		contagens[categoria] += 1
		local sigla = grupoCodigo[categoria] .. string.format("%02d", contagens[categoria])
		local id, codigo = "LojaPosAsc" .. sigla, "LA" .. sigla
		local expoente = serie.Expoente + i - 1
		local preco = "1" .. string.rep("0", expoente)
		local luz = r.Color3.fromHSV((matiz + (i - 5.5)*.018) % 1, saturacao, brilho)
		local cor = tonumber(luz:ToHex(), 16)
		local projeto = {id, def[1], def[2], def[3], def[4], cor, def[5], def[6], def[7]}
		local m = montagem.Modelo.new(projeto, categoria)
		formas[categoria](m, projeto)
		local modelo = m.modelo
		modelo:SetAttribute("SomenteModelagem", true)
		modelo:SetAttribute("OrigemProposta", "Loja pós-Ascensão")
		modelo:SetAttribute("CodigoVisual", codigo)
		modelo:SetAttribute("AscensoesMinimas", 1)
		modelo:SetAttribute("PrecoProposto", preco)
		local arquivo = pasta .. "/assets/" .. id .. ".rbxm"
		fs.writeFile(arquivo, r.serializeModel({modelo}))
		local info = {
			id = id, nome = def[1], codigo = codigo, categoria = categoria, arquivo = arquivo,
			serie = n, blocos = {def[2], def[3], def[4]}, preco = preco, expoente = expoente, ascensoesMinimas = 1,
			etapas = modelo:GetAttribute("Etapas"), largura = modelo:GetAttribute("LarguraCorreiaBlocos"),
			nivel = if categoria == "Modificadores" then def[7] else nil,
		}
		table.insert(manifesto, info)
		table.insert(tabela, string.format("| %s | %s | %s | %s | $1e%d | $%s |",
			codigo, serie.Nome, def[1], table.concat(info.blocos, "×"), expoente, abreviar(preco)))
		if processo.args[1] then
			local desenho = table.clone(info)
			desenho.partes = montagem.Geometria(modelo)
			table.insert(geometria, desenho)
		end
		local deslocamento = r.Vector3.new((i - 1) % 5 * bloco * 16, 0, ((n - 1) * 3 + math.floor((i - 1)/5)) * bloco * 18)
		for _, p in modelo:GetDescendants() do
			if p:IsA("BasePart") then p.CFrame += deslocamento end
		end
		modelo.Parent = grupo
	end
end

assert(#manifesto == 100)
fs.writeFile(pasta .. "/" .. galeria.Name .. ".rbxm", r.serializeModel({galeria}))
fs.writeFile(pasta .. "/modelos.json", serde.encode("json", manifesto, true))
fs.writeFile(pasta .. "/Tabela_de_precos.md", table.concat(tabela, "\n") .. "\n")
if processo.args[1] then fs.writeFile(processo.args[1], serde.encode("json", geometria)) end
print(galeria.Name, #manifesto)
