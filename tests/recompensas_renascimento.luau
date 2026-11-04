local fs=require("@lune/fs")
local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local carregar=require("./suporte/carregador")({Instance=I,Vector3=V,CFrame=CF,Color3=r.Color3,Enum=r.Enum,typeof=r.typeof},{Players={}})
local premios=carregar("src/shared/RecompensasRenascimento")
local catalogo=carregar("src/shared/CatalogoMaquinas")
local Maquina=carregar("src/server/Maquinas/Maquina")
local Minerio=carregar("src/server/Minerio")
local melhores={Soltador=0,Vendedor=0,Modificador=0}
for _,def in catalogo do if not def.Renascimento then
	for _,c in def.Componentes do
		if c.Tipo=="Soltador" then melhores.Soltador=math.max(melhores.Soltador,tonumber(c.Minerio.Valor)/c.Intervalo)
		elseif c.Tipo=="Vendedor" then melhores.Vendedor=math.max(melhores.Vendedor,tonumber(c.Multiplicador))
		elseif c.Tipo=="Modificador" then melhores.Modificador=math.max(melhores.Modificador,tonumber(c.Multiplicador)^c.Etapas) end
	end
end end
assert(#premios==9)
for _,p in premios do
	local def=catalogo[p.Id]
	assert(def.Renascimento and def.Preco=="0")
	local modelo=r.deserializeModel(fs.readFile("modelos/renascimento/assets/"..p.Id..".rbxm"))[1]
	local caixa=modelo.HitboxConstrucao
	assert(modelo.Name==p.Id and modelo:GetAttribute("GradeStuds")==3)
	assert(caixa.Size==V.new(table.unpack(p.Blocos))*3 and #modelo.EstruturaRenascimento:GetChildren()>0,p.Id)
	local terreno=I.new("Model"); terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1)
	for _,nome in {"Maquinas","Minerios"} do local f=I.new("Folder"); f.Name,f.Parent=nome,terreno end
	modelo.Parent=terreno.Maquinas; modelo:SetAttribute("DonoUserId",123); modelo:SetAttribute("TerrenoId",1)
	local emitidos=0
	local sim={RegistrarMinerio=function(_,minerio) emitidos+=1; assert(minerio:ObterValor()==p.Valor); minerio:Consumir() end}
	local maquina=Maquina.new(modelo,terreno,def,sim)
	local recebido="0"
	function maquina:ObterDadosDono() return {RegistrarRecorde=function() end, AdicionarDinheiro=function(_,valor) recebido=valor; return true end} end
	if p.Tipo=="Soltador" then
		assert(tonumber(p.Valor)/p.Intervalo>melhores.Soltador)
		local saida=modelo:FindFirstChild("SaidaMinerio",true); saida.WorldCFrame=saida.Parent.CFrame*saida.CFrame
		maquina:Atualizar(0); assert(emitidos==1)
	else
		assert(tonumber(p.Multiplicador)>melhores[p.Tipo])
		local minerio=Minerio.Criar({Valor="10",Tamanho={.75,.75,.75}},CF.identity,terreno)
		local componente=maquina._componentes[2]
		if p.Tipo=="Modificador" then
			componente._sensores={modelo.SensorEntrada}
			componente:Receber(minerio,modelo.SensorEntrada)
			assert(minerio:ObterValor()==tostring(10*tonumber(p.Multiplicador)))
			componente:Receber(minerio,modelo.SensorEntrada)
			assert(minerio:ObterValor()==tostring(10*tonumber(p.Multiplicador)))
		else
			componente:Receber(minerio)
			assert(recebido==tostring(10*tonumber(p.Multiplicador)) and not minerio:ObterParte().Parent)
		end
	end
	terreno:Destroy()
end
print("RECOMPENSAS_RENASCIMENTO_OK: nove modelos, grade, saidas, sensores, geracao, modificacao e venda superiores aos itens de loja.")
