local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo=I.new("Workspace")
local carregar=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,
	Color3=r.Color3,Enum=r.Enum,typeof=r.typeof},{})
local Grade=carregar("src/client/GradeTerreno")
local Geo=carregar("src/shared/GeometriaColocacao")
local piso=I.new("Part"); piso.Size=V.new(48,1,48); piso.CFrame=CF.new(16,4,80); piso.Parent=mundo
local grade=Grade.new(piso)
local function plano(modelo,largura,altura,passo,destino)
	local pivo=modelo:GetPivot()
	assert((pivo.Position-destino.Position).Magnitude<.001 and pivo.UpVector:Dot(destino.UpVector)>.999
		and pivo.RightVector:Dot(destino.RightVector)>.999)
	assert(#modelo:GetChildren()==math.floor(largura/passo+.001)+math.floor(altura/passo+.001)+2)
	for _,linha in modelo:GetChildren() do
		assert(linha:IsA("Part") and linha.Color==r.Color3.fromRGB(110,110,110))
		assert(linha.Material==r.Enum.Material.Neon and linha.Reflectance==0)
		assert(linha.Anchored and not linha.CanCollide and not linha.CanTouch and not linha.CanQuery and not linha.CastShadow)
		assert(linha.Transparency==1 and linha.Traco.Transparency==(if grade._visibilidade[modelo] then 0 else 1))
		assert(linha.Traco.Texture=="rbxasset://textures/ui/InGameMenu/WhiteSquare.png" and linha.Traco.Color3==linha.Color)
		local cf=pivo:ToObjectSpace(linha.CFrame)
		local vertical=linha.Name:sub(1,8)=="Vertical"
		local indice=tonumber(linha.Name:match("_(%d+)$"))
		local limite=if vertical then largura else altura
		local a,b=math.max(0,indice*passo-1/8),math.min(limite,indice*passo+1/8)
		local verso=modelo.Name=="Frente" or modelo.Name=="Direita"
		local z=if verso then -.01 else .01
		assert(linha.Traco.Face==(if verso then r.Enum.NormalId.Back else r.Enum.NormalId.Front))
		local esperado=if vertical then V.new((a+b)/2,altura/2,z) else V.new(largura/2,(a+b)/2,z)
		local tamanho=if vertical then V.new(b-a,altura,.02) else V.new(largura,b-a,.02)
		assert((cf.Position-esperado).Magnitude<.002 and (linha.Size-tamanho).Magnitude<.001)
		assert(cf.Position.X-linha.Size.X/2>=-.001 and cf.Position.X+linha.Size.X/2<=largura+.001)
		assert(cf.Position.Y-linha.Size.Y/2>=-.001 and cf.Position.Y+linha.Size.Y/2<=altura+.001)
		assert(math.abs(cf.Position.Z+(if verso then linha.Size.Z/2 else -linha.Size.Z/2))<.001,"A pintura precisa estar no plano exato do piso/parede.")
	end
end
local function conferir()
	local origem,tamanho=Geo.Origem(piso),piso.Size
	local altura=Geo.AlturaDoTerreno(piso.Size)
	local textura=grade._pisoTextura
	assert(textura.Parent==piso and textura.Face==r.Enum.NormalId.Top and textura.Texture=="rbxasset://textures/grid2.png")
	assert(textura.StudsPerTileU==12 and textura.StudsPerTileV==12 and math.abs(textura.OffsetStudsU-tamanho.Z%3)<.001)
	assert(math.abs(textura.Transparency-(if grade._visivel then .384 else 1))<.000001)
	assert(piso.Material==(if grade._visivel then r.Enum.Material.Neon else grade._materialPiso))
	plano(grade._paredes.Frente,tamanho.X,altura,12,origem*CF.new(0,grade._inicio,0))
	plano(grade._paredes.Fundo,tamanho.X,altura,12,origem*CF.new(0,grade._inicio,tamanho.Z))
	plano(grade._paredes.Esquerda,tamanho.Z,altura,12,origem*CF.new(0,grade._inicio,0)*CF.Angles(0,-math.pi/2,0))
	plano(grade._paredes.Direita,tamanho.Z,altura,12,origem*CF.new(tamanho.X,grade._inicio,0)*CF.Angles(0,-math.pi/2,0))
	plano(grade._paredes.Teto,tamanho.X,tamanho.Z,12,origem*CF.new(0,altura,tamanho.Z)*CF.Angles(-math.pi/2,0,0))
	for _,obj in grade._pasta:GetDescendants() do assert(not obj:IsA("SurfaceGui")) end
	assert(piso.Quadriculado==textura)
end
conferir(); assert(not grade._visivel)
grade:DefinirVisivel(true); conferir()
local linha,parede=grade._linhas[1],grade._paredes.Frente:GetChildren()[1]
for _=1,1000 do grade:Atualizar(0) end
assert(grade._linhas[1]==linha)
grade:Atualizar(3000); conferir()
assert(grade._inicio==0 and grade._altura==48 and grade._paredes.Frente:GetChildren()[1]==parede)
for _,tamanho in {V.new(72,1,30),V.new(21,1,15),V.new(9,1,27)} do
	piso.Size=tamanho; grade:Atualizar(3000); conferir()
end
grade:DefinirVisivel(false); conferir()
piso.Size=V.new(48,1,48); grade:Atualizar(0); conferir()
local linhaOculta=grade._linhas[1]
grade:DefinirVisivel(true); conferir(); assert(grade._linhas[1]==linhaOculta)
piso.CFrame=CF.new(-75,13,16)*CF.Angles(0,math.pi/2,0)
grade:Atualizar(0); conferir(); assert(grade._inicio==0)
local camera=I.new("Camera"); mundo.CurrentCamera=camera
local origem=Geo.Origem(piso)
for _,caso in {{V.new(24,10,-3),"Frente"},{V.new(24,10,51),"Fundo"},
	{V.new(-3,10,24),"Esquerda"},{V.new(51,10,24),"Direita"}} do
	camera.CFrame=origem*CF.new(caso[1]); grade:Atualizar(0); conferir()
	assert(not grade._visibilidade[grade._paredes[caso[2]]],"Laterais vistas de fora nao devem cobrir a cena.")
end
camera.CFrame=origem*CF.new(24,60,24); grade:Atualizar(0); assert(not grade._visibilidade[grade._paredes.Teto])
camera.CFrame=origem*CF.new(24,10,24); grade:Atualizar(0); conferir()
for _,modelo in grade._paredes do assert(grade._visibilidade[modelo]) end
local pasta=grade._pasta
grade:Destruir(); grade:Destruir(); assert(pasta.Parent==nil and not piso:FindFirstChild("Quadriculado"))
assert(piso.Material==grade._materialPiso and piso.Reflectance==grade._reflexoPiso)
print("GRADE_TERRENO_SUPERFICIE_OK: textura no piso, encaixe, altura, tamanho, giro, visibilidade, reutilizacao, restauracao e limpeza.")
