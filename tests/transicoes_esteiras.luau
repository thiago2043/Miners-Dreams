local r=require('./suporte/modelos')
local V,CF,I=r.Vector3,r.CFrame,r.Instance
local mundo=I.new('Workspace')
local carregar=require('./suporte/carregador')({workspace=mundo,Vector3=V,CFrame=CF,Instance=I,Enum=r.Enum,typeof=r.typeof},
	{Players={GetPlayerByUserId=function() return nil end}})
local Sim=carregar('src/server/SimulacaoMinerios')
local Corpo=carregar('src/shared/CorpoRigido')
local modelos=require('./suporte/catalogo_modelos')()
local Maquina=carregar('src/server/Maquinas/Maquina')
local Catalogo=carregar('src/shared/CatalogoMaquinas')
local terreno=I.new('Model'); terreno.Parent=mundo
terreno:SetAttribute('DonoUserId',123); terreno:SetAttribute('TerrenoId',1)
local maquinas=I.new('Folder'); maquinas.Name='Maquinas'; maquinas.Parent=terreno
local sim=Sim.new()
local objetos={}
for i=0,11 do
	local m=modelos.Esteira2x2:Clone(); m:PivotTo(CF.new(0,0,i*6)*m:GetPivot()); m.Parent=maquinas
	m:SetAttribute('DonoUserId',123); m:SetAttribute('TerrenoId',1)
	local maq=Maquina.new(m,terreno,Catalogo.Esteira2x2,sim); maq:Atualizar(0); table.insert(objetos,maq)
	assert(sim._transportadores[m.Correia].Velocidade==V.new(0,0,6))
end
local obstaculos={}
for _,p in maquinas:GetDescendants() do
	if not p:IsA('BasePart') or not p.CanCollide then continue end
	local reg=sim._transportadores[p]
	table.insert(obstaculos,{Parte=p,CFrame=p.CFrame,Tamanho=p.Size,Velocidade=reg and reg.Velocidade or V.zero,
		PriorizarTopo=reg and reg.PriorizarTopo,Atrito=reg and reg.Atrito,Centralizacao=reg and reg.Centralizacao})
end
local falhas={}
for _,x in {0,2.4,-2.4} do
	local c=Corpo.new(CF.new(x,4,-1)*CF.Angles(.21,.4,.3),V.one*.75)
	local maxDesvio,menorY=0,math.huge
	for _=1,1440 do
		c:Avancar(1/120,V.new(0,-196.2,0),obstaculos)
		maxDesvio=math.max(maxDesvio,math.abs(c.CFrame.Position.X-x))
		menorY=math.min(menorY,c.CFrame.Position.Y)
		if c.CFrame.Position.Z>=64 then break end
	end
	if c.CFrame.Position.Z<60 or maxDesvio>.12 or menorY<1.2 then
		table.insert(falhas,string.format('inicio X=%.1f: fim=%s desvio=%.3f menorY=%.3f',x,tostring(c.CFrame.Position),maxDesvio,menorY))
	end
end
for _,maq in objetos do maq:Destruir() end
assert(#falhas==0,table.concat(falhas,'\n'))
print('TRANSICOES_ESTEIRAS_OK: queda e 12 esteiras comuns reais, inclusive perto das laterais, sem centralizar ou perder apoio.')

maquinas:ClearAllChildren(); table.clear(objetos); table.clear(obstaculos)
for _,p in {{0,0,0},{0,6,math.pi/2},{6,6,math.pi/2},{12,6,math.pi/2}} do
	local m=modelos.Esteira2x2:Clone(); m:PivotTo(CF.new(p[1],0,p[2])*CF.Angles(0,p[3],0)*m:GetPivot()); m.Parent=maquinas
	m:SetAttribute('DonoUserId',123); m:SetAttribute('TerrenoId',1)
	local maq=Maquina.new(m,terreno,Catalogo.Esteira2x2,sim); maq:Atualizar(0); table.insert(objetos,maq)
end
for _,p in maquinas:GetDescendants() do
	if not p:IsA('BasePart') or not p.CanCollide then continue end
	local reg=sim._transportadores[p]
	table.insert(obstaculos,{Parte=p,CFrame=p.CFrame,Tamanho=p.Size,Velocidade=reg and reg.Velocidade or V.zero,
		PriorizarTopo=reg and reg.PriorizarTopo,Atrito=reg and reg.Atrito})
end
for _,x in {0,2.4,-2.4} do
	local c=Corpo.new(CF.new(x,4,-1)*CF.Angles(.21,.4,.3),V.one*.75)
	for _=1,1000 do
		c:Avancar(1/120,V.new(0,-196.2,0),obstaculos)
		assert(c.CFrame.Position.Y>1.2,'Perdeu o apoio na curva comum: '..tostring(c.CFrame.Position))
		if c.CFrame.Position.X>=10 then break end
	end
	assert(c.CFrame.Position.X>=10,'Travou na mudanca de direcao.')
end
for _,maq in objetos do maq:Destruir() end
print('CURVA_COMUM_OK: entrada perpendicular pelos dois lados e pelo centro, sem centralizadora.')

maquinas:ClearAllChildren(); table.clear(objetos); table.clear(obstaculos)
for _,p in {{'Esteira2x2',0},{'Esteira2x2',6},{'RefinadorMolecular',13.5},{'CamaraMagnetica',21},{'FornalhaBasica',27}} do
	local m=modelos[p[1]]:Clone(); m:PivotTo(CF.new(0,0,p[2])*m:GetPivot()); m.Parent=maquinas
	m:SetAttribute('DonoUserId',123); m:SetAttribute('TerrenoId',1)
	local maq=Maquina.new(m,terreno,Catalogo[p[1]],sim); maq:Atualizar(0); table.insert(objetos,maq)
end
for _,p in maquinas:GetDescendants() do
	if not p:IsA('BasePart') or not p.CanCollide then continue end
	local reg=sim._transportadores[p]
	table.insert(obstaculos,{Parte=p,CFrame=p.CFrame,Tamanho=p.Size,Velocidade=reg and reg.Velocidade or V.zero,
		PriorizarTopo=reg and reg.PriorizarTopo,Atrito=reg and reg.Atrito})
end
for _,giro in {0,math.pi/2} do
	local transformacao=CF.Angles(0,giro,0)
	local solidos={}
	for _,o in obstaculos do
		local q=table.clone(o); q.CFrame=transformacao*o.CFrame; q.Velocidade=transformacao:VectorToWorldSpace(o.Velocidade)
		table.insert(solidos,q)
	end
	for _,x in {-2.4,0,2.4} do
		local c=Corpo.new(transformacao*CF.new(x,4,-1)*CF.Angles(.21,.4,.3),V.one*.75)
		for _=1,800 do
			c:Avancar(1/120,V.new(0,-196.2,0),solidos)
			assert(c.CFrame.Position.Y>1.2,'Perdeu apoio na borda da maquina.')
			if transformacao:PointToObjectSpace(c.CFrame.Position).Z>=25.5 then break end
		end
		assert(transformacao:PointToObjectSpace(c.CFrame.Position).Z>=25.5,'Travou na entrada/saida de modificador ou fornalha.')
	end
end
for _,maq in objetos do maq:Destruir() end
print('MAQUINAS_BORDAS_OK: duas esteiras, dois modificadores e bandeja real da fornalha, seis percursos perto das laterais e em dois giros.')

maquinas:ClearAllChildren(); table.clear(objetos); table.clear(obstaculos)
for i=0,11 do
	local m=modelos.Esteira1x1:Clone(); m:PivotTo(CF.new(0,0,i*3)*m:GetPivot()); m.Parent=maquinas
	m:SetAttribute('DonoUserId',123); m:SetAttribute('TerrenoId',1)
	local maq=Maquina.new(m,terreno,Catalogo.Esteira1x1,sim); maq:Atualizar(0); table.insert(objetos,maq)
end
for _,p in maquinas:GetDescendants() do
	if not p:IsA('BasePart') or not p.CanCollide then continue end
	local reg=sim._transportadores[p]
	table.insert(obstaculos,{Parte=p,CFrame=p.CFrame,Tamanho=p.Size,Velocidade=reg and reg.Velocidade or V.zero,
		PriorizarTopo=reg and reg.PriorizarTopo,Atrito=reg and reg.Atrito})
end
for _,x in {-.9,0,.9} do
	local c=Corpo.new(CF.new(x,4,-.5)*CF.Angles(.21,.4,.3),V.one*.75)
	for _=1,900 do
		c:Avancar(1/120,V.new(0,-196.2,0),obstaculos)
		assert(c.CFrame.Position.Y>1.2,'Caiu da esteira comum 1x1.')
		if c.CFrame.Position.Z>=31 then break end
	end
	assert(c.CFrame.Position.Z>=31,'Travou na emenda de esteiras 1x1.')
end
for _,maq in objetos do maq:Destruir() end
print('ESTEIRA_1X1_OK: queda inclinada e doze emendas, pelas laterais e pelo centro, sem centralizacao.')
