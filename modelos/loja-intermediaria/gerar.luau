local fs = require("@lune/fs")
local r = require("@lune/roblox")
local serde = require("@lune/serde")
local processo = require("@lune/process")
local montagem = require("../renascimento/novas/montagem")
local abreviar = require("../../src/shared/AbreviarInteiro")
local bloco = require("../../src/shared/Medidas").Bloco
local formas = require("./formas")
local series = require("./series")
local precificar = require("./precos")
local pasta = "modelos/loja-intermediaria"
local categorias = {M = "Mineradoras", F = "Fornalhas", X = "Modificadores"}
local contagens = {M = 0, F = 0, X = 0}
local galeria = r.Instance.new("Model")
galeria.Name = "Galeria80LojaIntermediaria"
local precos = precificar.Distribuir()
local manifesto, geometria = {}, {}
fs.writeDir(pasta .. "/assets")

local tabela = {
	"# 80 máquinas intermediárias da loja",
	"",
	"Preços propostos para a loja anterior à primeira Ascensão. Cada modelo ocupa uma posição entre dois preços do plano atual. As medidas são largura × comprimento × altura em blocos de 3 studs.",
	"",
	"| Código | Máquina | Hitbox | Preço | Abreviação | Entre estes dois preços |",
	"| --- | --- | --- | --- | --- | --- |",
}

local linha = 0
for n, serie in series do
	local grupo = r.Instance.new("Folder")
	grupo.Name, grupo.Parent = string.format("%02d · %s", n, serie.Nome), galeria
	assert(#precos[n] == #serie.Pecas, serie.Nome)
	for i, def in serie.Pecas do
		local tipo = def[1]
		local categoria = categorias[tipo]
		contagens[tipo] += 1
		local sigla = tipo .. string.format("%02d", contagens[tipo])
		local id, codigo = "LojaIntermediaria" .. sigla, "LI" .. sigla
		local projeto = {id, table.unpack(def, 2)}
		local m = montagem.Modelo.new(projeto, categoria)
		formas[categoria](m, projeto)
		local modelo = m.modelo
		local p = precos[n][i]
		modelo:SetAttribute("SomenteModelagem", true)
		modelo:SetAttribute("OrigemProposta", "Loja anterior à Ascensão")
		modelo:SetAttribute("CodigoVisual", codigo)
		modelo:SetAttribute("PrecoProposto", p.preco)
		local arquivo = pasta .. "/assets/" .. id .. ".rbxm"
		fs.writeFile(arquivo, r.serializeModel({modelo}))
		local info = {
			id = id, nome = def[2], codigo = codigo, categoria = categoria, arquivo = arquivo,
			serie = n, blocos = {def[3], def[4], def[5]}, preco = p.preco, expoente = #p.preco - 1,
			ancoraAnterior = p.anterior, ancoraSeguinte = p.seguinte,
			etapas = modelo:GetAttribute("Etapas"), largura = modelo:GetAttribute("LarguraCorreiaBlocos"),
			nivel = if tipo == "X" then def[9] else nil,
		}
		table.insert(manifesto, info)
		table.insert(tabela, string.format("| %s | %s | %s | $%s | $%s | %s → %s |",
			codigo, def[2], table.concat(info.blocos,"×"), precificar.Notacao(p.preco), abreviar(p.preco), p.anterior, p.seguinte))
		if processo.args[1] then
			local desenho = table.clone(info)
			desenho.partes = montagem.Geometria(modelo)
			table.insert(geometria, desenho)
		end
		local deslocamento = r.Vector3.new((i - 1) % 5 * bloco * 15, 0, (linha + math.floor((i - 1)/5)) * bloco * 17)
		for _, peca in modelo:GetDescendants() do
			if peca:IsA("BasePart") then peca.CFrame += deslocamento end
		end
		modelo.Parent = grupo
	end
	linha += math.ceil(#serie.Pecas/5) + 1
end

assert(contagens.M == 16 and contagens.F == 16 and contagens.X == 48 and #manifesto == 80)
fs.writeFile(pasta .. "/" .. galeria.Name .. ".rbxm", r.serializeModel({galeria}))
fs.writeFile(pasta .. "/modelos.json", serde.encode("json", manifesto, true))
fs.writeFile(pasta .. "/Tabela_de_precos.md", table.concat(tabela,"\n") .. "\n")
if processo.args[1] then fs.writeFile(processo.args[1], serde.encode("json", geometria)) end
print(galeria.Name, #manifesto)
