local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo=I.new("Workspace")
local carregar=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,Color3=r.Color3,
	Enum=r.Enum,typeof=r.typeof,OverlapParams={new=function() return {} end}}, {Players={}})
local Previa=carregar("src/client/PreviaConstrucao")
local Personalizacao=carregar("src/shared/PersonalizacaoMaquina")
local Catalogo=carregar("src/shared/CatalogoMaquinas")
local Rotacao=carregar("src/shared/RotacaoConstrucao")
local modelos=require("./suporte/catalogo_modelos")()
local maquinas=I.new("Folder"); maquinas.Parent=mundo
local total,transportadoras=0,0
for id,def in Catalogo do
	local original=modelos:FindFirstChild(id)
	assert(original and not original:FindFirstChild("SetaTransporte"))
	local temEsteira=false
	for _,c in def.Componentes do if c.Tipo=="Transportador" and c.ExibirSeta~=false then temEsteira=true end end
	local previa=Previa.new(original,Personalizacao.new(),def,maquinas)
	local giros={CF.identity,CF.Angles(0,math.pi/2,0)}
	if Rotacao.PermiteInclinar(def) then
		table.insert(giros,CF.Angles(math.pi/4,0,0)); table.insert(giros,CF.Angles(-math.pi/4,0,0))
	end
	for _,giro in giros do
		local extensao,ocupado=previa:ObterVolume(giro):Calcular(giro)
		local corpo=previa:ObterModelo()
		for _,p in corpo:GetDescendants() do
			if not p:IsA("BasePart") or p:FindFirstAncestor("SetaTransporte") then continue end
			local fonte=original:FindFirstChild(p.Name,true)
			if not fonte or not fonte:IsA("BasePart") or p:GetAttribute("GuiaPosicionamento") or p:GetAttribute("EfeitoOperacao") then continue end
			assert(math.abs(p.Transparency-math.max(fonte.Transparency,.55))<.000001,id..": a previa deve manter a transparencia intencional.")
		end
		assert(previa:ObterTamanho()==corpo.HitboxConstrucao.Size,"Seta nao pode aumentar as medidas da previa.")
		local alvo={maquinaId=id,minimo=V.new(30,0,30),rotacao=giro,ocupado=ocupado,livre=true,
			caixaDestino=CF.new(30+ocupado.X/2,extensao.Y,30+ocupado.Z/2)*Rotacao.DecomporEsteira(giro,def),
			volumeDestino=CF.new(V.new(30,0,30)+ocupado/2)}
		previa:Animar(alvo,1)
		assert((corpo.HitboxConstrucao.CFrame.Position-alvo.volumeDestino.Position).Magnitude<.01,id..": seta alterou o encaixe da peca.")
		local setas=corpo:FindFirstChild("SetaTransporte")
		assert((setas~=nil)==temEsteira,id..": indicador deve existir somente na previa de uma transportadora.")
		if setas then
			local quantidade=0
			for _,c in def.Componentes do
				if c.Tipo~="Transportador" or c.ExibirSeta==false then continue end
				local p=corpo:FindFirstChild(c.Parte)
				local seta=assert(setas:FindFirstChild(c.Parte),id..": falta seta em "..c.Parte)
				local direcao=p.CFrame:VectorToWorldSpace(p:GetAttribute("DirecaoSuperficie") or p:GetAttribute("DirecaoTransporte") or V.zAxis)
				local topo=p.CFrame:PointToWorldSpace(V.new(0,p.Size.Y/2,0)); quantidade+=1
				local cima=p.CFrame.UpVector
				local distancia=seta.Haste.CFrame.Position-topo
				assert(math.abs(distancia:Dot(cima)-.1725)<.001 and (distancia-cima*distancia:Dot(cima)).Magnitude<.001,
					id..": seta deve ficar centrada logo acima de cada correia.")
				assert(#seta:GetChildren()==3 and seta.Haste.CFrame.LookVector:Dot(direcao.Unit)>.999,id..": direcao incorreta.")
				for _,p in seta:GetChildren() do
					assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery and p.Transparency==0)
					assert(p.Color==r.Color3.new(1,1,1) and not p.CastShadow)
				end
			end
			assert(#setas:GetChildren()==quantidade,"Deve haver uma seta por correia.")
		end
	end
	local visual=previa:ObterModelo()
	previa:Ocultar(); assert(visual.Parent==nil)
	previa:Destruir(); assert(visual.Parent==nil and not original:FindFirstChild("SetaTransporte"))
	total+=1; if temEsteira then transportadoras+=1 end
end
assert(total==91 and #maquinas:GetChildren()==0)
print("DIRECAO_COLOCACAO_OK",total,transportadoras,"modelos/transportadoras; seta por correia, giros, inclinacao, medidas e limpeza.")
