local fs=require("@lune/fs")
local serde=require("@lune/serde")
local r=require("@lune/roblox")
local V=r.Vector3
local reducoes=require("../src/shared/ReducoesAlturaHitbox")
local Corpo=require("@lune/luau").load(fs.readFile("src/shared/CorpoRigido.luau"),{environment={Vector3=V,CFrame=r.CFrame}})()
local raiz="modelos/fornalhas"
local manifesto=serde.decode("json",fs.readFile(raiz.."/geometria.json"))
assert(#manifesto==9)
local precos={"100","3000","1000000","500000000","250000000000","25000000000000","1000000000000000","100000000000000000","10000000000000000000"}
local multiplicadores={"1","1.5","3","5","8","12","20","35","60"}
for i,def in manifesto do
	local modelo=r.deserializeModel(fs.readFile(raiz.."/assets/"..def.id..".rbxm"))[1]
	assert(modelo.Name==def.id and modelo.PrimaryPart.Name=="BaseModelo")
	assert(modelo:GetAttribute("SomenteModelagem")==false and modelo:GetAttribute("GradeStuds")==3)
	assert(def.codigo=="F"..i and def.preco==precos[i] and def.multiplicador==multiplicadores[i])
	local tamanho=V.new(def.blocos[1],def.blocos[3],def.blocos[2])*3
	local caixa=modelo.HitboxConstrucao
	if def.id=="FornalhaBasica" then assert(tamanho==V.new(6,3,6) and def.entrada[1]==2 and def.entrada[2]==2) end
	assert(caixa.Size==tamanho and caixa.CFrame.Position==V.new(0,tamanho.Y/2,0))
	assert(not caixa.CanCollide and not caixa.CanQuery and caixa.Transparency==1)
	local bandeja,sensor=modelo.BandejaEntrada,modelo.SensorEntrada
	assert(bandeja.CanCollide and bandeja.Material==r.Enum.Material.Neon)
	assert(bandeja.Size.X==def.entrada[1]*3 and bandeja.Size.Z==def.entrada[2]*3)
	assert(math.abs(bandeja.CFrame.Position.Y+bandeja.Size.Y/2-.9375)<.001)
	assert(math.abs(bandeja.CFrame.Position.Z-bandeja.Size.Z/2+tamanho.Z/2)<.001)
	assert(bandeja:GetAttribute("DirecaoTransporte")==V.zAxis)
	assert(not sensor.CanCollide and sensor.CanQuery and sensor.Transparency==1)
	assert(sensor.Size.X==bandeja.Size.X and sensor.Size.Z==bandeja.Size.Z)
	assert(math.abs(sensor.CFrame.Position.Y-sensor.Size.Y/2-.9375)<.001)
	local quantidade=0
	for _,p in modelo:GetDescendants() do
		assert(not p:IsA("LuaSourceContainer"),"Asset nao deve conter scripts.")
		if not p:IsA("BasePart") then continue end
		quantidade+=1
		assert(p.Anchored and p.Size.X>0 and p.Size.Y>0 and p.Size.Z>0)
		if p.CanCollide then assert(p:IsA("Part") and p.Shape==r.Enum.PartType.Block,"Colisao futura exige caixas.") end
		for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
			local ponto=p.CFrame:PointToWorldSpace(p.Size*V.new(x,y,z)/2)
			assert(math.abs(ponto.X)<=tamanho.X/2+.001 and math.abs(ponto.Z)<=tamanho.Z/2+.001
				and ponto.Y>=-.001 and ponto.Y<=tamanho.Y+(reducoes[def.id] or 0)*3+.001,"Fora da reserva: "..def.codigo.." / "..p.Name.." / "..tostring(ponto))
		end end end
		-- Um cubo de minerio deve alcancar a borda frontal sem encontrar uma parede na entrada.
		if p.CanCollide and p~=bandeja then
			for _,x in {-bandeja.Size.X/2+.375,0,bandeja.Size.X/2-.375} do
				local frente=r.CFrame.new(x,1.3125,-tamanho.Z/2+.375)
				assert(not Corpo.Intersecao(frente,V.one*.75,p.CFrame,p.Size),"Entrada obstruida: "..def.codigo.." / "..p.Name)
			end
		end
	end
	print("PASS:",def.codigo,quantidade,"partes; reserva, entrada e sensor relidos do RBXM.")
end
local galeria=r.deserializeModel(fs.readFile(raiz.."/GaleriaFornalhas.rbxm"))[1]
assert(#galeria:GetChildren()==9)
print("FORNALHAS_GEOMETRIA_OK",#manifesto,"assets editaveis; nao comprova funcionamento integrado.")
