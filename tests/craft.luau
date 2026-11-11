local serde = require("@lune/serde")
local ui = require("./suporte/interface")
local r = require("./suporte/modelos")
local mundo, modelos = r.Instance.new("Workspace"), r.Instance.new("Folder")
local replicado = {ModelosMaquinas=modelos}
function replicado:WaitForChild(nome) return assert(self[nome]) end
local Players = {PlayerRemoving = ui.Sinal()}
local canal
local tempo = 0
local ultimoSorteio
local mathTeste = table.clone(math)
mathTeste.random = function(minimo, maximo)
	ultimoSorteio = maximo
	return minimo
end
local carregar, no = require("./suporte/carregador")({
	workspace=mundo, Instance=r.Instance, Vector3=r.Vector3, CFrame=r.CFrame,
	Color3=r.Color3, Enum=r.Enum, typeof=r.typeof,
	os = {clock = function() return tempo end}, math = mathTeste,
}, {Players=Players, ReplicatedStorage=replicado}, {
	["Packages/Networker"] = {server = {new = function(nome, objeto, permitidos)
		if nome == "Craft" then
			assert(#permitidos == 1 and permitidos[1] == objeto.Fabricar)
			canal = objeto
		end
	end}},
})
replicado.Shared, replicado.Packages = no("src/shared"), no("Packages")
local Template = carregar("src/server/Data/Template")
local Reinicio = carregar("src/server/Data/ReinicioProgresso")
local Premios = carregar("src/server/Data/PremiosRenascimento")
local Regra = carregar("src/shared/RegraRecompensas")
local Catalogo = carregar("src/shared/CatalogoMaquinas")
local Expansao = carregar("src/shared/ExpansaoMaquinas")
local Inteiro = carregar("src/shared/InteiroGrande")
local Manager = carregar("src/server/Data/DataManager")
carregar("src/server/Craft.server")
assert(canal)

local atributos = {TerrenoId=1}
local jogador = {Parent=Players, Name="Craft", UserId=123}
function jogador:GetAttribute(k) return atributos[k] end
function jogador:SetAttribute(k,v) atributos[k] = v end
local ativo = true
local reinicio = Reinicio.new(Template, {"RecompensasReencarnacao"})
local perfil = {Data=reinicio:Preparar({}), IsActive=function() return ativo end}
local dados = Manager.RegistrarPerfil(jogador, perfil)
perfil.Data.Reencarnacoes = 50
perfil.Data.Dinheiro = "1"..string.rep("0", 170)
for id, def in Catalogo do
	if def.Renascimento then
		perfil.Data.Inventory[id] = 1
		perfil.Data.RecompensasReencarnacao[id] = {Quantidade=1}
	end
end
dados:Sincronizar()
local inicial = perfil.Data.Dinheiro
for id, item in Catalogo do
	if item.Obtencao or dados:ObterQuantidade(id) > 0 then continue end
	assert(dados:ComprarMaquina(id),id)
	inicial = Inteiro.subtrair(inicial,item.Preco)
end
assert(dados:ObterSaldo()==inicial)

local function foto(id)
	local lista = {}
	for i, ingrediente in Catalogo[id].Receita do
		lista[i] = {Quantidade=dados:ObterQuantidade(ingrediente),
			Configuracao=atributos["ConfiguracaoInventario_"..ingrediente]}
	end
	return lista
end
local function fabricar(id, estoque, ciclo)
	tempo += 1
	return canal:Fabricar(jogador,id,ciclo or 50,estoque or foto(id))
end

local primeiro = "EscavadoraEstratos"
assert(not dados:ComprarMaquina(primeiro) and not dados:VenderMaquina(primeiro,"{}"))
assert(not dados:RegistrarColocacao({MaquinaId=primeiro, Modificacoes={}}))
assert(not fabricar(primeiro,nil,49))
assert(not canal:Fabricar(jogador,"MineradoraBasica",50,{}))
local faltante = Catalogo[primeiro].Receita[#Catalogo[primeiro].Receita]
dados:_DefinirQuantidade(faltante,0)
local antes = serde.encode("json",perfil.Data)
assert(not fabricar(primeiro) and serde.encode("json",perfil.Data)==antes)
dados:_DefinirQuantidade(faltante,1)
local obsoleto = foto(primeiro)
local id = Catalogo[primeiro].Receita[1]
perfil.Data.InventarioPersonalizado[id] = {{Dados={Nivel=7}}}
dados:_DefinirQuantidade(id,2)
antes = serde.encode("json",perfil.Data)
assert(not fabricar(primeiro,obsoleto) and serde.encode("json",perfil.Data)==antes)

local fabricadas = 0
for _, item in Expansao do
	if not item.Receita then continue end
	local estoque = foto(item.Id)
	local sucesso, mensagem = fabricar(item.Id,estoque)
	assert(sucesso,item.Id..": "..mensagem)
	assert(dados:ObterQuantidade(item.Id)==1)
	assert(not fabricar(item.Id,estoque),"Pedido repetido consumiu o estoque de novo.")
	fabricadas += 1
end
assert(fabricadas==50 and dados:ObterSaldo()==inicial)
assert(perfil.Data.Inventory[id]==1 and perfil.Data.InventarioPersonalizado[id][1].Dados.Nivel==7)
for id, def in Catalogo do
	if def.Renascimento then
		assert(dados:ObterQuantidade(id)==0 and perfil.Data.RecompensasReencarnacao[id].Quantidade==0,id)
	end
end
local finais = {EscavadoraConvergencia=true,FornalhaConvergencia=true,ModificadorConvergencia=true}
for _, item in Expansao do
	if item.Receita then assert(dados:ObterQuantidade(item.Id)==(finais[item.Id] and 1 or 0),item.Id) end
end

require("./suporte/catalogo_modelos")(modelos)
local terrenos = r.Instance.new("Folder")
terrenos.Name, terrenos.Parent = "Terrenos", mundo
local terreno = r.Instance.new("Model")
terreno.Parent = terrenos
terreno:SetAttribute("DonoUserId", jogador.UserId)
terreno:SetAttribute("TerrenoId", 1)
local piso = r.Instance.new("Part")
piso.Name, piso.Size, piso.Parent = "Piso", r.Vector3.new(36,1,36), terreno
for _, nome in {"Maquinas", "Minerios"} do
	local pasta = r.Instance.new("Folder")
	pasta.Name, pasta.Parent = nome, terreno
end
local construcao = carregar("src/server/ServicoConstrucao").new()
tempo += 1
assert(construcao:Colocar(jogador, "EscavadoraConvergencia", r.Vector3.zero, r.CFrame.identity))
local modelo = terreno.Maquinas:FindFirstChild("EscavadoraConvergencia")
tempo += 1
local ok, mensagem, resumo = construcao:CriarBlueprint(jogador, "Craft", {modelo})
assert(ok,mensagem)
assert(resumo.Custo=="0" and resumo.Craft==1 and resumo.Renascimento==0)
tempo += 1
assert(construcao:Recolher(jogador, modelo) and dados:ObterQuantidade("EscavadoraConvergencia")==1)
tempo += 1
assert(construcao:Colocar(jogador, "EscavadoraConvergencia", r.Vector3.zero, r.CFrame.identity))
local colocada = dados:ObterConstrucoes()[1]
assert(not dados:VenderConstrucoes({colocada}))
colocada.Modificacoes = {Dados={Nivel=3}}
local novo = reinicio:Preparar(perfil.Data)
Premios.Aplicar(novo, perfil.Data, 2)
assert(ultimoSorteio==60,"Consumir recompensa retirou seu tipo do sorteio.")
perfil.Data.Dinheiro = "1"..string.rep("0",171)
assert(dados:Reencarnar(50))
for id in finais do assert(dados:ObterQuantidade(id)==1,id) end
assert(perfil.Data.InventarioPersonalizado.EscavadoraConvergencia[1].Dados.Nivel==3)
local entregas = {}
for _, premio in Regra.Garantidas(51) do entregas[premio.Id] = (entregas[premio.Id] or 0) + 1 end
for id, def in Catalogo do
	if def.Renascimento then assert(dados:ObterQuantidade(id)==(entregas[id] or 0),id) end
end
local migracao = carregar("src/server/Data/MigracaoCatalogo")
local salvo = migracao.Preparar(serde.decode("json",serde.encode("json",perfil.Data)))
for id in finais do assert(salvo.Inventory[id]==1,id) end
assert(salvo.RecompensasReencarnacao.MineradoraAurora.Quantidade==0)
assert(salvo.InventarioPersonalizado.EscavadoraConvergencia[1].Dados.Nivel==3)
ativo = false
assert(not fabricar(primeiro,nil,51))
print("CRAFT_50_OK: rede, compra, 50 receitas, estoque atômico, colocação, blueprint, permanência e sorteio.")
