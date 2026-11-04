local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo=I.new("Workspace")
local carregar=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,Color3=r.Color3,
	Enum=r.Enum,typeof=r.typeof,OverlapParams={new=function() return {} end}}, {})
local Previa=carregar("src/client/PreviaConstrucao")
local Personalizacao=carregar("src/shared/PersonalizacaoMaquina")
r.implementMethod("Workspace","GetPartBoundsInBox",function(_,pose,tamanho,consulta)
	local encontrados={}
	for _, pasta in consulta.FilterDescendantsInstances do
		for _, parte in pasta:GetChildren() do
			if not parte:IsA("BasePart") or not parte.CanQuery then continue end
			local d=parte.CFrame.Position-pose.Position
			local metade=(parte.Size+tamanho)/2
			if math.abs(d.X)<metade.X and math.abs(d.Y)<metade.Y and math.abs(d.Z)<metade.Z then table.insert(encontrados,parte) end
		end
	end
	return encontrados
end)
local maquinas=I.new("Folder"); maquinas.Parent=mundo
for i=1,100 do
	local m=I.new("Model"); m.Name="Vizinho"..i; m.Parent=maquinas
	m:SetAttribute("VolumeMinimo",V.new((i-1)%10*3,0,math.floor((i-1)/10)*3))
	m:SetAttribute("VolumeOcupado",V.one*3)
end
local original=I.new("Model")
local corpo=I.new("Part"); corpo.Name="HitboxConstrucao"; corpo.Size=V.one*3; corpo.Parent=original
local definicao={Blocos={1,1,1},Componentes={}}
local criadas,atualizadas=0,0
local criarCaixa,atualizarCaixa=Previa._CriarCaixa,Previa._AtualizarCaixa
function Previa:_CriarCaixa(nome,...)
	if nome~="VolumePrevia" then criadas+=1 end
	return criarCaixa(self,nome,...)
end
function Previa:_AtualizarCaixa(caixa,...)
	if caixa.Name~="VolumePrevia" then atualizadas+=1 end
	return atualizarCaixa(self,caixa,...)
end
local previas={}
for i=1,60 do previas[i]=Previa.new(original,Personalizacao.new(),definicao,maquinas,nil,previas[1]) end
local pasta=previas[1]:ObterPastaVolumes()
previas[1]:AtualizarVolumes(CF.identity,0)
assert(criadas==100 and atualizadas==100 and #pasta:GetChildren()==160)
atualizadas=0
for _=1,5 do previas[1]:AtualizarVolumes(CF.identity,.2) end
assert(criadas==100 and atualizadas==500,"O grupo deve criar 100 caixas e fazer 500 atualizacoes, nao 6.000/30.000.")
for _,p in previas do
	assert(p:ObterPastaVolumes()==pasta and not p:VolumeLivre(CF.identity,V.zero,V.one*3))
	assert(p:VolumeLivre(CF.identity,V.new(0,30,0),V.one*3))
end
local vizinho=maquinas:GetChildren()[1]
vizinho:SetAttribute("VolumeMinimo",V.new(0,30,0))
previas[2]:ForcarAtualizacao(); previas[1]:AtualizarVolumes(CF.identity,0)
assert(previas[3]:VolumeLivre(CF.identity,V.zero,V.one*3) and not previas[3]:VolumeLivre(CF.identity,V.new(0,30,0),V.one*3))
vizinho:Destroy(); previas[1]:AtualizarVolumes(CF.identity,.2)
assert(previas[3]:VolumeLivre(CF.identity,V.new(0,30,0),V.one*3))
local independente=Previa.new(original,Personalizacao.new(),definicao,maquinas)
assert(independente:ObterPastaVolumes()~=pasta)
independente:Destruir()
local volumes=previas[1]._volumes
previas[1]:Destruir(); previas[1]:Destruir()
assert(volumes.Usuarios==59 and pasta.Parent==mundo)
previas[2]:AtualizarVolumes(CF.identity,.2)
for i=60,2,-1 do previas[i]:Destruir() end
assert(volumes.Usuarios==0 and pasta.Parent==nil and next(volumes.Caixas)==nil)
print("PASS: 60 previas/100 vizinhos: 100 caixas e 500 atualizacoes em cinco revisoes; consulta, movimento, remocao e destruicao em qualquer ordem.")

previas={}; criadas=0
for i=1,1000 do previas[i]=Previa.new(original,Personalizacao.new(),definicao,maquinas,nil,previas[1]) end
previas[1]:AtualizarVolumes(CF.identity,0)
assert(criadas==99 and #previas[1]:ObterPastaVolumes():GetChildren()==1099)
for i,p in previas do assert(p._volumes==previas[1]._volumes and p:ObterCaixa().CanQuery==false); if i>1 then p:Destruir() end end
previas[1]:Destruir(); maquinas:Destroy(); original:Destroy()
print("PASS: 1.000 previas compartilham uma pasta e um filtro, mantendo um volume proprio por peca.")
