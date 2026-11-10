local fs = require("@lune/fs")
local serde = require("@lune/serde")
local r = require("./suporte/modelos")
local I,V,CF = r.Instance,r.Vector3,r.CFrame
local carregar = require("./suporte/carregador")({Instance=I,Vector3=V,CFrame=CF,Color3=r.Color3,Enum=r.Enum,typeof=r.typeof},{Players={GetPlayerByUserId=function() return nil end}})
local premios = carregar("src/shared/RecompensasRenascimento")
local catalogo = carregar("src/shared/CatalogoMaquinas")
local Maquina = carregar("src/server/Maquinas/Maquina")
local Minerio = carregar("src/server/Minerio")
local Inteiro = carregar("src/shared/InteiroGrande")
local Ficha = carregar("src/client/FichaMaquina")
local projeto = serde.decode("json",fs.readFile("default.project.json"))
assert(#premios==60)
for _, p in premios do
	local def = catalogo[p.Id]
	assert(def.Renascimento and def.Preco=="0" and def.LoteRenascimento==p.Lote)
	local modelo = r.deserializeModel(fs.readFile(projeto.tree.ReplicatedStorage.ModelosMaquinas[p.Id]["$path"]))[1]
	assert(modelo.Name==p.Id and modelo:GetAttribute("GradeStuds")==3)
	assert(modelo.HitboxConstrucao.Size==V.new(table.unpack(p.Blocos))*3,p.Id)
	assert(modelo:GetAttribute("SomenteModelagem")==false)
	local terreno = I.new("Model"); terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1)
	for _,nome in {"Maquinas","Minerios"} do local f=I.new("Folder"); f.Name,f.Parent=nome,terreno end
	modelo.Parent=terreno.Maquinas; modelo:SetAttribute("DonoUserId",123); modelo:SetAttribute("TerrenoId",1)
	local emitidos = 0
	local sim = {RegistrarMinerio=function(_,minerio)
		emitidos+=1; assert(minerio:ObterValor()==p.Valor); minerio:Consumir()
	end}
	local maquina = Maquina.new(modelo,terreno,def,sim)
	local recebido = "0"
	function maquina:ObterDadosDono()
		return {RegistrarRecorde=function() end, AdicionarDinheiro=function(_,valor) recebido=valor; return true end}
	end
	if p.Tipo=="Soltador" then
		local saida = modelo:FindFirstChild("SaidaMinerio",true)
		saida.WorldCFrame=saida.Parent.CFrame*saida.CFrame
		maquina:Atualizar(0); assert(emitidos==1)
	else
		local minerio = Minerio.Criar({Valor="10",Tamanho={.75,.75,.75}},CF.identity,terreno)
		local componente = maquina._componentes[2]
		if p.Tipo=="Modificador" then
			assert(p.LimiteUsos>=4 and p.LimiteUsos<=8)
			assert(tonumber(p.Multiplicador)*(1+(p.LimiteUsos-1)*.5)<=1000)
			local sensores = {}
			for i=1,#p.Faixas do sensores[i]=modelo[if i==1 then "SensorEntrada" else string.format("SensorEtapa%02d",i)] end
			componente._sensores=sensores
			componente:Receber(minerio,sensores[1]); assert(minerio:ObterValor()=="10","Ativacao exige processamento.")
			assert(minerio:DefinirValor("100000"))
			for _,s in sensores do componente:Receber(minerio,s) end
			local esperado = Inteiro.multiplicar("100000",p.Multiplicador)
			assert(minerio:ObterValor()==esperado,p.Id)
			table.clear(componente._passagens)
			componente:Receber(minerio,sensores[1])
			assert(minerio:ObterValor()==esperado,"A mesma unidade fisica nao pode reaplicar.")
			for copia=2,p.LimiteUsos+1 do
				local clone=modelo:Clone(); clone.Parent=terreno.Maquinas
				local outra=Maquina.new(clone,terreno,def,sim)._componentes[2]
				outra._sensores={}
				for i=1,#p.Faixas do
					local s=clone[if i==1 then "SensorEntrada" else string.format("SensorEtapa%02d",i)]
					outra._sensores[i]=s
				end
				for _,s in outra._sensores do outra:Receber(minerio,s) end
				local usadas=math.min(copia,p.LimiteUsos)
				local fator=tostring(1+(usadas-1)*.5)
				assert(minerio:ObterValor()==Inteiro.multiplicarArredondado(esperado,fator),p.Id.." copias")
			end
			assert(Ficha.Descrever(def):find("Cópias",1,true))
		else
			componente:Receber(minerio)
			assert(recebido==Inteiro.multiplicar("10",p.Multiplicador) and not minerio:ObterParte().Parent)
		end
	end
	terreno:Destroy()
end
print("RECOMPENSAS_60_OK: assets reais, saidas, 46 conjuntos de faixas, copias fisicas, limites, fichas e vendas.")
