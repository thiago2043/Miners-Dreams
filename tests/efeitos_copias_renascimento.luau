local r = require("./suporte/modelos")
local carregar = require("./suporte/carregador")({Instance=r.Instance, Vector3=r.Vector3,
	CFrame=r.CFrame, Color3=r.Color3, Enum=r.Enum, typeof=r.typeof}, {})
local Catalogo = carregar("src/shared/CatalogoMaquinas")
local Minerio = carregar("src/server/Minerio")
local Modificador = carregar("src/server/Componentes/ModificadorMinerio")
local Vendedor = carregar("src/server/Componentes/VendedorMinerio")
local Inteiro = carregar("src/shared/InteiroGrande")
local terreno = r.Instance.new("Model")
terreno:SetAttribute("DonoUserId", 1); terreno:SetAttribute("TerrenoId", 1)
local pasta = r.Instance.new("Folder"); pasta.Name, pasta.Parent = "Minerios", terreno
local recebido = "0"
local function componente(id, unidade)
	local config = Catalogo[id].Componentes[2]
	local modelo = r.Instance.new("Model"); modelo.Parent = terreno
	modelo:SetAttribute("IdUnidade", unidade)
	local maquina = {
		ObterModelo=function() return modelo end, ObterTerreno=function() return terreno end,
		EstaNoTerreno=function() return true end, ObterNivelUpgrade=function() return 0 end,
		ObterDadosDono=function() return {AdicionarDinheiro=function(_, valor) recebido=valor; return true end} end,
	}
	local objeto = (if config.Tipo=="Vendedor" then Vendedor else Modificador).new(maquina, config)
	objeto._sensores = {}
	for i=1,config.Etapas or 1 do
		local sensor = r.Instance.new("Part"); sensor.Parent = modelo
		table.insert(objeto._sensores, sensor)
	end
	return objeto
end
local function atravessar(objeto, minerio)
	for _, sensor in objeto._sensores do objeto:Receber(minerio, sensor) end
end
local minerio = Minerio.Criar({Valor="1", Tamanho={.75,.75,.75}}, r.CFrame.identity, terreno)
local selo = componente("SeloAurora", "selo-1")
minerio:DefinirValor("9999"); atravessar(selo, minerio)
assert(minerio:ObterValor()=="9999", "A ativacao nao pode ocorrer antes de x10K.")
minerio:DefinirValor("10000"); atravessar(selo, minerio)
assert(minerio:ObterValor()=="200000")
atravessar(componente("SeloAurora", "selo-2"), minerio)
assert(minerio:ObterValor()=="300000")
atravessar(componente("SeloAurora", "selo-2"), minerio)
assert(minerio:ObterValor()=="300000", "Reconstruir ou mover a mesma unidade nao reaplica.")
local loja = componente("CamaraFissao", "loja-1")
atravessar(loja, minerio)
assert(minerio:ObterValor()=="300015", "O bonus de copias nao pode se multiplicar novamente.")
atravessar(componente("PrismaPulsar", "prisma-1"), minerio)
assert(minerio:ObterValor()=="7200360")
atravessar(componente("PrismaPulsar", "prisma-2"), minerio)
assert(minerio:ObterValor()=="9600480", "Bonus de tipos diferentes devem se somar.")
local venda = componente("FornalhaAurora", "venda-1")
atravessar(venda, minerio)
assert(recebido=="960048000" and not minerio:ObterParte().Parent)

local gigante = Minerio.Criar({Valor="1", Tamanho={.75,.75,.75}}, r.CFrame.identity, terreno)
gigante:DefinirValor("1"..string.rep("0", 309))
atravessar(componente("CisalhaHelio", "cisalha-1"), gigante)
local principal = Inteiro.multiplicar("1"..string.rep("0", 309), "84")
assert(gigante:ObterValor()==principal)
local copia = componente("CisalhaHelio", "cisalha-2")
local pontos = {16,33,50}
for i,sensor in copia._sensores do
	copia:Receber(gigante,sensor)
	assert(gigante:ObterValor()==Inteiro.multiplicarArredondado(principal,tostring(1+pontos[i]/100)))
end
atravessar(componente("FornalhaCatedral", "venda-2"), gigante)
assert(recebido==Inteiro.multiplicar(gigante:ObterValor(),"1"..string.rep("0",31)))
print("COPIAS_COMBINADAS_OK: ativacao, unidade estavel, loja, soma entre tipos, faixas, venda e valores acima de e308.")
