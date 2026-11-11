local fs = require("@lune/fs")
local r = require("./suporte/modelos")
local serde = require("@lune/serde")
local defs = require("../modelos/expansao/definicoes")
local grade = require("../src/shared/Medidas").Bloco
local carregar = require("./suporte/carregador")({Instance=r.Instance, Vector3=r.Vector3, CFrame=r.CFrame,
	Color3=r.Color3, Enum=r.Enum, typeof=r.typeof}, {})
local catalogo = carregar("src/shared/CatalogoMaquinas")
local Inteiro = carregar("src/shared/InteiroGrande")
local Maquina = carregar("src/server/Maquinas/Maquina")
local Minerio = carregar("src/server/Minerio")
local pasta = "modelos/expansao"
local receitas = serde.decode("json",fs.readFile(pasta.."/receitas.json"))
local projeto = serde.decode("json",fs.readFile("default.project.json"))
local tipos = {Soltador="Mineradoras",Vendedor="Fornalhas",Modificador="Modificadores"}
local quantidades = {Mineradoras=10,Fornalhas=10,Modificadores=30}
local categorias, assinaturas, porId = {}, {}, {}
local total, maiorPrecoAntigo = 0, "0"

local function igual(a,b) return math.abs(a-b)<.0001 end
local function naGrade(v) return igual(v/grade,math.round(v/grade)) end

for id, def in catalogo do
	if def.CodigoVisual then continue end
	if not def.Obtencao and Inteiro.menor(maiorPrecoAntigo, def.Preco) then maiorPrecoAntigo = def.Preco end
	local ultimo = def.Componentes[#def.Componentes]
	if ultimo then categorias[id] = tipos[ultimo.Tipo] end
end

local function testarComponente(modelo, def, id)
	local terreno = r.Instance.new("Model")
	terreno:SetAttribute("DonoUserId", 1)
	terreno:SetAttribute("TerrenoId", 1)
	for _, nome in {"Maquinas", "Minerios"} do
		local pasta = r.Instance.new("Folder")
		pasta.Name, pasta.Parent = nome, terreno
	end
	modelo.Parent = terreno.Maquinas
	modelo:SetAttribute("DonoUserId", 1)
	modelo:SetAttribute("TerrenoId", 1)
	local config = def.Componentes[#def.Componentes]
	local emitidos, saldo = 0, "0"
	local simulacao = {RegistrarMinerio = function(_, minerio)
		emitidos += 1
		assert(minerio:ObterValor() == config.Minerio.Valor, id)
		minerio:Consumir()
	end}
	local maquina = Maquina.new(modelo, terreno, def, simulacao)
	function maquina:ObterDadosDono()
		return {RegistrarRecorde=function() end, AdicionarDinheiro=function(_,valor) saldo=valor; return true end}
	end
	if config.Tipo == "Soltador" then
		local saida = modelo.PrimaryPart.SaidaMinerio
		saida.WorldCFrame = saida.Parent.CFrame * saida.CFrame
		maquina:Atualizar(0)
		maquina:Atualizar(config.Intervalo * .99)
		assert(emitidos == 1, id)
		maquina:Atualizar(config.Intervalo)
		assert(emitidos == 2, id)
	else
		local minerio = Minerio.Criar({Valor="10",Tamanho={.75,.75,.75}},r.CFrame.identity,terreno)
		local componente = maquina._componentes[2]
		if config.Tipo == "Vendedor" then
			componente:Receber(minerio)
			assert(saldo == Inteiro.multiplicar("10",config.Multiplicador) and not minerio:ObterParte().Parent, id)
		else
			local fatores = config.MultiplicadoresFaixas
			local total = "1"
			componente._sensores = {}
			for i, fator in fatores do
				componente._sensores[i] = modelo[if i==1 then "SensorEntrada" else string.format("SensorEtapa%02d",i)]
				total = Inteiro.multiplicarDecimal(total, fator)
			end
			assert(total == config.Multiplicador, id)
			local valor = "10"
			for uso = 1, config.LimiteUsos + 1 do
				table.clear(componente._passagens)
				for i, sensor in componente._sensores do
					componente:Receber(minerio, sensor)
					if uso <= config.LimiteUsos then
						valor = Inteiro.somar(Inteiro.multiplicarArredondado(valor, fatores[i]), config.Bonus)
					end
					assert(minerio:ObterValor() == valor, id)
				end
			end
			if config.ValorMaximo then
				assert(minerio:DefinirValor(config.ValorMaximo))
				table.clear(componente._passagens)
				assert(not componente:PrecisaReceber(minerio, componente._sensores[1]), id)
			end
		end
	end
	terreno:Destroy()
end

for origem, grupos in defs do
	local galeria = r.deserializeModel(fs.readFile(pasta.."/Galeria50"..origem..".rbxm"))[1]
	assert(#fs.readDir(pasta.."/assets/"..origem)==50,origem)
	for categoria, lista in grupos do
		local grupo = assert(galeria:FindFirstChild(categoria))
		assert(#grupo:GetChildren()==#lista and #lista==quantidades[categoria],categoria)
		for _, def in lista do
			local id, w, d, h = def[1],def[3]*grade,def[4]*grade,def[5]*grade
			local arquivo = pasta.."/assets/"..origem.."/"..id..".rbxm"
			local item = assert(catalogo[id],id)
			assert(not categorias[id] and projeto.tree.ReplicatedStorage.ModelosMaquinas[id]["$path"]==arquivo,id)
			assert(tipos[item.Componentes[#item.Componentes].Tipo]==categoria,id)
			if origem=="Loja" then
				assert(not item.Obtencao and Inteiro.menor(maiorPrecoAntigo,item.Preco),id)
			else
				assert(item.Obtencao=="Craft" and item.Receita and item.Preco=="0",id)
			end
			categorias[id] = categoria
			local m = r.deserializeModel(fs.readFile(arquivo))[1]
			assert(m.Name==id and grupo:FindFirstChild(id) and m.PrimaryPart,id)
			assert(m:GetAttribute("SomenteModelagem")==false and m:GetAttribute("OrigemProposta")==origem,id)
			assert(m:GetAttribute("GradeStuds")==grade and m.HitboxConstrucao.Size==r.Vector3.new(w,h,d),id)
			assert(igual(m.HitboxConstrucao.CFrame.Position.Y,h/2) and not m.HitboxConstrucao.CanCollide,id)
			local topo, partes = 0,{}
			for _, p in m:GetDescendants() do
				if not p:IsA("BasePart") or p.Transparency==1 then continue end
				local _,y,_,_,_,_,a,b,c = p.CFrame:GetComponents()
				local meio = (math.abs(a)*p.Size.X+math.abs(b)*p.Size.Y+math.abs(c)*p.Size.Z)/2
				topo = math.max(topo,y+meio)
				table.insert(partes,p.ClassName.."/"..tostring(p.Size).."/"..tostring(p.CFrame))
			end
			assert(topo>=h-grade-.16 and topo<=h+.18,id.." altura "..topo.." / "..h)
			table.sort(partes)
			local assinatura = table.concat(partes,"|")
			assert(not assinaturas[assinatura],id.." repete "..(assinaturas[assinatura] or ""))
			assinaturas[assinatura] = id
			if categoria=="Mineradoras" then
				local marca = m.IndicadorSaida
				local pos = marca.CFrame.Position
				local saida = (m.PrimaryPart.CFrame*m.PrimaryPart.SaidaMinerio.CFrame).Position
				assert(igual(pos.X,0) and igual(saida.X,0) and igual(saida.Z,pos.Z),id)
				assert(saida.Y<pos.Y and marca.Transparency>.5 and not marca.CanCollide,id)
				assert(igual((pos.Z-d/2)/grade,def[8]) and naGrade(pos.Z-d/2-grade/2),id)
				if def[9] then
					local base = m:GetAttribute("BaseBroca")
					assert(igual(base.Z,d/2) and pos.Y<base.Y and m:FindFirstChild("LaminaDaBroca"),id)
				end
			else
				local forno = categoria=="Fornalhas"
				local correia = if forno then m.BandejaEntrada else m.Correia
				local largura = if forno then 2 else def[8]
				local nivel = if forno then 0 else def[9]
				local pos = correia.CFrame.Position
				local superficie = pos.Y+correia.Size.Y/2
				local x = pos.X+w/2
				assert(correia.CanCollide and correia.Size.X==largura*grade,id)
				assert(naGrade(x-correia.Size.X/2) and naGrade(x+correia.Size.X/2),id)
				assert(igual(superficie,1.25*grade/4+nivel*grade),id)
				assert(igual(pos.Z-correia.Size.Z/2,-d/2),id)
				if forno then
					assert(correia.Size.Z==grade*2 and m.SensorEntrada.Size.Z==grade*2,id)
					assert(m.SensorEntrada.CFrame.Position.X==pos.X,id)
				else
					assert(correia.Size.Z==d and m:GetAttribute("Etapas")==#def[7],id)
					local limite = -d/2
					for i in def[7] do
						local faixa = m[string.format("FaixaUpgrade%02d",i)]
						local sensor = m[faixa:GetAttribute("Sensor")]
						local centro = faixa.CFrame.Position
						assert(sensor.Size==faixa.Size and sensor.CFrame==faixa.CFrame,id)
						assert(faixa.Size.X==correia.Size.X and igual(centro.X,pos.X),id)
						assert(igual(centro.Y-faixa.Size.Y/2,superficie) and centro.Z-faixa.Size.Z/2>=limite,id)
						assert(sensor:GetAttribute("EtapaUpgrade")==i and not sensor.CanCollide,id)
						limite = centro.Z+faixa.Size.Z/2
					end
					assert(limite<=d/2,id)
				end
			end
			testarComponente(m,item,id)
			total += 1
		end
	end
end
assert(total==100 and #receitas==50)
for _, receita in receitas do
	assert(not porId[receita.id] and categorias[receita.id],receita.id)
	assert(#receita.ingredientes>=2 and #receita.ingredientes<=8,receita.id)
	assert(serde.encode("json",catalogo[receita.id].Receita)==serde.encode("json",receita.ingredientes),receita.id)
	porId[receita.id] = receita.ingredientes
end

for categoria, lista in defs.Craft do
	local final = lista[#lista][1]
	local visitados, bases, crafts = {},0,0
	local function visitar(id)
		assert(categorias[id]==categoria and not visitados[id],final.." / "..id)
		visitados[id] = true
		if porId[id] then
			crafts += 1
			for _, ingrediente in porId[id] do visitar(ingrediente) end
		else
			bases += 1
		end
	end
	visitar(final)
	for id, tipo in categorias do
		if tipo==categoria then assert(visitados[id],final.." falta "..id) end
	end
	for _, def in lista do assert(porId[def[1]],def[1]) end
	assert(crafts==#lista,categoria)
	print(final,bases.." peças da loja/renascimento",(crafts-1).." crafts intermediários")
end
print("100_MODELOS_OK: assets distintos, galerias, hitboxes, saídas, bandejas, correias, sensores e receitas completas.")
