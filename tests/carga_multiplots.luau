-- Mede o codigo real com consultas espaciais simuladas; nao mede rede ou FPS do Roblox.
local r=require("./suporte/modelos")
local V,CF,I=r.Vector3,r.CFrame,r.Instance
local mundo=I.new("Workspace"); mundo.Gravity=196.2
local solidos,consultas,plots={},0,{}
r.implementMethod("Workspace","GetPartBoundsInBox",function(_,pose,tamanho,filtro)
	consultas+=1
	local encontrados={}
	for _,p in (if filtro.RespectCanCollide then solidos else filtro.FilterDescendantsInstances) do
		local d=pose.Position-p.CFrame.Position; local h=(tamanho+p.Size)/2
		if math.abs(d.X)<=h.X and math.abs(d.Y)<=h.Y and math.abs(d.Z)<=h.Z then table.insert(encontrados,p) end
	end
	return encontrados
end)
local carregar=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,Color3=r.Color3,
	Enum=r.Enum,OverlapParams={new=function() return {} end},typeof=r.typeof},
	{Players={GetPlayerByUserId=function() return nil end}})
local Sim=carregar("src/server/SimulacaoMinerios")
local Minerio=carregar("src/server/Minerio")
local sim=Sim.new()
local porPlot=tonumber(require("@lune/process").args[1]) or 128
assert(porPlot>=1 and porPlot%1==0 and porPlot<=5000)
for plot=1,8 do
	local terreno=I.new("Model"); terreno.Parent=mundo
	plots[plot]=terreno
	terreno:SetAttribute("DonoUserId",plot); terreno:SetAttribute("TerrenoId",plot)
	for _,nome in {"Maquinas","Minerios"} do local pasta=I.new("Folder"); pasta.Name,pasta.Parent=nome,terreno end
	for i=0,3 do
		local p=I.new("Part"); p.Size,p.CFrame,p.Parent=V.new(6,1,6),CF.new(plot*100,-.5,i*6),terreno.Maquinas
		table.insert(solidos,p); sim:RegistrarTransportador({EstaAtivo=function() return true end},p,V.new(0,0,6))
	end
	for i=1,porPlot do
		local m=Minerio.Criar({Valor="5",Tamanho={.75,.75,.75}},CF.new(plot*100+(i%5)*.15,.3751,(i%16)*.3),terreno)
		sim:RegistrarMinerio(m,nil,{})
		sim:ObterCorpo(m:ObterParte()).Velocidade=V.new(0,0,6)
	end
end
sim:Avancar(1/60)
local antes,passos=os.clock(),sim._passos
consultas=0
for i=1,8 do mundo:SetAttribute("TempoServidorTeste",i/30); sim:Avancar(1/30) end
local custo=os.clock()-antes
assert(#sim._minerios==8*porPlot and sim._passos-passos==32)
assert(consultas<=96,"Consultas nao devem repetir por subpasso ou por minerio.")
for _,registro in sim._minerios do
	assert(sim:ObterCorpo(registro.Parte).CFrame.Position.Z>0 and registro.Parte:GetAttribute("MovimentoMinerio"))
end
print(string.format("CARGA_MULTIPLOTS: 8 plots, %d minerios, 32 passos; %.1f ms CPU local; %d consultas espaciais.",8*porPlot,custo*1000,consultas))
local Vendedor=carregar("src/server/Componentes/VendedorMinerio")
local Inteiro=carregar("src/server/InteiroGrande")
local contas,vendedores={},{}
for i,terreno in plots do
	local modelo=I.new("Model"); modelo.Parent=terreno.Maquinas
	local sensor=I.new("Part"); sensor.Name,sensor.Size,sensor.CFrame,sensor.Parent="SensorEntrada",V.new(6,3,30),CF.new(i*100,1,9),modelo
	local conta={Saldo="0",Creditos=0}; contas[i]=conta
	function conta:AdicionarDinheiro(valor) self.Saldo=Inteiro.somar(self.Saldo,valor); self.Creditos+=1; return true end
	local maquina={ObterModelo=function() return modelo end,ObterTerreno=function() return terreno end,
		ObterSimulacao=function() return sim end,EstaNoTerreno=function() return true end,
		ObterDadosDono=function() return conta end,ObterNivelUpgrade=function() return 0 end}
	local vendedor=Vendedor.new(maquina,{Sensor="SensorEntrada",Multiplicador="2"})
	vendedor:Atualizar(0); table.insert(vendedores,vendedor)
end
sim:Avancar(1/120); sim:Avancar(1/120)
for _,conta in contas do
	assert(conta.Creditos==porPlot and conta.Saldo==tostring(porPlot*10),"Cada dono deve receber seu lote completo exatamente uma vez.")
end
for _,v in vendedores do v:Destruir() end
print("PAGAMENTOS_MULTIPLOTS_OK: "..8*porPlot.." vendas, oito donos, valores integrais e sem credito duplicado.")
sim:Destruir(); mundo:Destroy()
