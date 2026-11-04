local fs = require("@lune/fs")
local r = require("@lune/roblox")
local serde = require("@lune/serde")
local V = r.Vector3
local raiz = "modelos/esteiras"
local manifesto = serde.decode("json",fs.readFile(raiz .. "/geometria.json"))
local medidas = {
	Esteira2x2=V.new(6,3,6),Esteira1x1=V.new(3,3,3),
	Centralizadora2x2=V.new(6,3,6),Centralizadora1x1=V.new(3,3,3),Parede1x1=V.new(3,3,3),
}
local modelos={}
local function limites(p)
	local min,max = V.new(math.huge,math.huge,math.huge),V.new(-math.huge,-math.huge,-math.huge)
	for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
		local v = p.CFrame:PointToWorldSpace(p.Size*V.new(x,y,z)/2)
		min=V.new(math.min(min.X,v.X),math.min(min.Y,v.Y),math.min(min.Z,v.Z))
		max=V.new(math.max(max.X,v.X),math.max(max.Y,v.Y),math.max(max.Z,v.Z))
	end end end
	return min,max
end

local quantidade = 0
for _,def in manifesto do
	local modelo = r.deserializeModel(fs.readFile(raiz .. "/assets/" .. def.id .. ".rbxm"))[1]
	modelos[def.id]=modelo
	local esperado = assert(medidas[def.id],"Tipo inesperado: " .. def.id)
	medidas[def.id]=nil
	assert(modelo.Name==def.id and modelo:GetAttribute("SomenteModelagem")==false)
	assert(modelo.PrimaryPart.Name=="BaseModelo" and modelo:GetAttribute("GradeStuds")==3)
	local hitbox = modelo.HitboxConstrucao
	assert(hitbox.Size==esperado and hitbox.CFrame.Position==V.new(0,esperado.Y/2,0))
	assert(hitbox.Transparency==1 and not hitbox.CanCollide and not hitbox.CanQuery)
	local total = 0
	for _,p in modelo:GetDescendants() do
		assert(not p:IsA("LuaSourceContainer"),"A modelagem nao deve embutir scripts.")
		assert(p.Name~="SulcoCorreia" and p.Name~="SetaDirecao" and p.Name~="RoloConvergente"
			and p.Name~="EixoCentral" and p.Name~="SetaTransporte","Correia deve permanecer lisa e sem indicacao permanente.")
		if not p:IsA("BasePart") then continue end
		total+=1
		assert(p.Anchored and p.Size.X>0 and p.Size.Y>0 and p.Size.Z>0)
		for _,n in {p.CFrame:GetComponents()} do assert(n==n and math.abs(n)<math.huge) end
		local min,max = limites(p)
		assert(min.X>=-esperado.X/2-.001 and max.X<=esperado.X/2+.001
			and min.Z>=-esperado.Z/2-.001 and max.Z<=esperado.Z/2+.001
			and min.Y>=-.001 and max.Y<=esperado.Y+.001,"Peca fora da reserva: " .. def.id .. "/" .. p.Name)
		local direcao = p:GetAttribute("DirecaoTransporte")
		if direcao then
			assert(p.CanCollide and math.abs(direcao.Magnitude-1)<.001)
			if def.tipo=="reta" or def.tipo=="centralizadora" then
				assert(direcao.Y==0 and direcao.Z>0)
				assert(math.abs(max.Y-.9375)<.001 and min.Z==-esperado.Z/2 and max.Z==esperado.Z/2)
				if def.tipo=="centralizadora" then assert(direcao.X*p.CFrame.Position.X<0)
				else assert(direcao==V.zAxis and p.Size.X==esperado.X) end
			elseif math.abs(direcao.Y)>.01 then
				assert((direcao.Y<0)==def.descida,"Direcao vertical invertida.")
			end
		end
	end
	assert(total==#def.partes,"O manifesto deve descrever o RBXM relido.")
	if def.tipo=="centralizadora" then
		local a,b=modelo.CorreiaEsquerda,modelo.CorreiaDireita
		local linha=assert(modelo:FindFirstChild("LinhaCentral"))
		assert(not linha.CanCollide and not linha.CanTouch and not linha.CastShadow)
		assert(linha.CFrame.Position.X==0 and linha.Size.Z==esperado.Z)
		assert(math.abs(linha.CFrame.Position.Y-linha.Size.Y/2-.9375)<.001)
		local minA,maxA=limites(a)
		local minB,maxB=limites(b)
		assert(minA.X==-esperado.X/2 and maxA.X==0 and minB.X==0 and maxB.X==esperado.X/2)
	elseif def.tipo=="parede" then
		assert(modelo.NucleoParede.CanCollide and math.abs(modelo.TampaParede.CFrame.Position.Y+modelo.TampaParede.Size.Y/2-3)<.001)
	elseif def.tipo=="reta" then
		assert(modelo.Correia.Size.X==esperado.X and modelo.Correia.Size.Z==esperado.Z)
	else
		assert(math.abs(math.abs(modelo:GetAttribute("AlturaSaida")-modelo:GetAttribute("AlturaEntrada"))-4)<.001)
		assert(modelo:GetAttribute("AlturaEntrada")==if def.descida then 5.25 else 1.25)
	end
	quantidade+=1
	print("PASS:",def.id,total,"partes; reserva e passagem conferidas.")
end
assert(next(medidas)==nil,"Faltam modelos solicitados.")
local galeria = r.deserializeModel(fs.readFile(raiz .. "/GaleriaEsteiras.rbxm"))[1]
assert(#galeria:GetChildren()==quantidade)
print("ESTEIRAS_GEOMETRIA_OK",quantidade,"RBXM relidos; nao comprova transporte no Studio.")

local luau=require("@lune/luau")
local CF=r.CFrame
local Corpo=luau.load(fs.readFile("src/shared/CorpoRigido.luau"),{environment={Vector3=V,CFrame=CF}})()
local erros,percursos={},0
for _,def in manifesto do
	if def.tipo=="parede" then continue end
	local modelo=modelos[def.id]
	local entrada,saida=modelo:GetAttribute("PortaEntrada"),modelo:GetAttribute("PortaSaida")
	local dirEntrada=V.zAxis
	local dirSaida=dirEntrada
	local laterais=if def.tipo=="centralizadora" then {-1.1,0,1.1} else {0}
	for _,giro in {0,1} do for _,lateral in laterais do
		local ok,erro=pcall(function()
			local transformacao=CF.Angles(0,giro*math.pi/2,0)
			local obstaculos={}
			local function adicionar(m,cf)
				for _,p in m:GetDescendants() do
					if not p:IsA("BasePart") or not p.CanCollide then continue end
					assert(p.Shape==r.Enum.PartType.Block,"O solver exige colisoes de caixas.")
					local dir=p:GetAttribute("DirecaoTransporte")
					table.insert(obstaculos,{CFrame=transformacao*cf*p.CFrame,Tamanho=p.Size,
						Velocidade=if dir then transformacao:VectorToWorldSpace(cf:VectorToWorldSpace(dir))*6 else V.zero})
				end
			end
			adicionar(modelo,CF.identity)
			local grande=modelo:GetAttribute("LarguraUtil")==6
			local comum=if grande then modelos.Esteira2x2 else modelos.Esteira1x1
			local metade=if grande then 3 else 1.5
			adicionar(comum,CF.new(entrada-dirEntrada*metade-V.yAxis*.9375))
			adicionar(comum,CF.new(saida+dirSaida*metade-V.yAxis*.9375)*CF.Angles(0,math.atan2(dirSaida.X,dirSaida.Z),0))
			local pos=entrada-dirEntrada*.75+V.new(lateral*.75,.375,0)
			local corpo=Corpo.new(transformacao*CF.new(pos),V.one*.75)
			local passou=false
			for _=1,1800 do
				corpo:Avancar(1/240,V.new(0,-196.2,0),obstaculos)
				local p=transformacao:PointToObjectSpace(corpo.CFrame.Position)
				assert(p.Y>.525,"Minerio perdeu apoio: " .. tostring(p))
				local depois=(p-saida):Dot(dirSaida)
				if depois>1 then
					local desvio=(p-saida-dirSaida*depois)*V.new(1,0,1)
					assert(desvio.Magnitude<1.0875 and math.abs(p.Y-saida.Y-.375)<.4125,"Saida incorreta: " .. tostring(p))
					if def.tipo=="centralizadora" then assert(math.abs(p.X)<.22,"Nao centralizou: " .. tostring(p)) end
					passou=true; break
				end
			end
			assert(passou,"Minerio nao atravessou: " .. def.id .. " / " .. tostring(transformacao:PointToObjectSpace(corpo.CFrame.Position)))
		end)
		if ok then percursos+=1 else table.insert(erros,def.id .. " giro " .. giro .. ": " .. tostring(erro)) end
	end end
	print("PERCURSO:",def.id)
end
for _,erro in erros do warn(erro) end
assert(#erros==0,"Falharam " .. #erros .. " percursos.")
print("ESTEIRAS_TRAVESSIA_LOCAL_OK",percursos,"percursos com vetores declarados e solver do projeto, fora do Studio.")
