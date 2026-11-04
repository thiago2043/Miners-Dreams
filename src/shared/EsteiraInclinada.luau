local Rotacao = require(script.Parent.RotacaoConstrucao)
local bloco = require(script.Parent.Medidas).Bloco
local escala = bloco / 4
local EsteiraInclinada = {}

local function conter(parte, largura, comprimento, angulo, ancoraBaixa)
	local cf=parte.CFrame
	for _=1,2 do
		local fator=1
		for _,eixo in {"X","Z"} do
			local limite=(if eixo=="X" then largura else comprimento)/2
			local fixo=math.abs(cf.RightVector[eixo])*parte.Size.X/2+math.abs(cf.UpVector[eixo])*parte.Size.Y/2
			local raio=math.abs(cf.LookVector[eixo])*parte.Size.Z/2
			local maximo=math.max(0,limite-fixo-.001)
			if math.abs(cf.Position[eixo])>maximo then
				local pos=cf.Position
				local z=math.clamp(pos.Z,-maximo,maximo)
				pos=if eixo=="X" then Vector3.new(math.clamp(pos.X,-maximo,maximo),pos.Y,pos.Z)
					else Vector3.new(pos.X,pos.Y-math.sign(angulo)*(z-pos.Z),z)
				cf=CFrame.new(pos)*cf.Rotation
				parte.CFrame=cf
			end
			if raio>0 then fator=math.min(fator,math.max(.001,(limite-math.abs(cf.Position[eixo])-fixo)/raio)) end
		end
		if fator>=1 then break end
		local removido=parte.Size.Z*(1-fator)/2
		parte.Size=Vector3.new(parte.Size.X,parte.Size.Y,parte.Size.Z*fator)
		if ancoraBaixa then
			cf=cf*CFrame.new(0,0,ancoraBaixa*removido)
			parte.CFrame=cf
		end
	end
end

-- A geometria fica no referencial ortogonal; a matriz salva conserva o giro solicitado de 45 graus.
function EsteiraInclinada.Aplicar(modelo, definicao, rotacao)
	local _,angulo=Rotacao.DecomporEsteira(rotacao,definicao)
	if angulo==0 then return end
	local hitbox=modelo:FindFirstChild("HitboxConstrucao")
	local caixa,tamanho
	if hitbox then caixa,tamanho=hitbox.CFrame,hitbox.Size else caixa,tamanho=modelo:GetBoundingBox() end
	local blocos=definicao.Blocos or {math.ceil(tamanho.X/bloco),math.ceil(tamanho.Y/bloco),math.ceil(tamanho.Z/bloco)}
	local largura,comprimento,altura=blocos[1]*bloco,blocos[3]*bloco,(blocos[2]+blocos[3])*bloco
	local correia=assert(modelo:FindFirstChild(definicao.Componentes[1].Parte),"Esteira sem correia.")
	local centro=caixa:PointToObjectSpace(correia.CFrame.Position)
	local topo=centro.Y+correia.Size.Y/2+tamanho.Y/2
	local referencia=caixa*CFrame.new(0,topo-tamanho.Y/2,centro.Z)
	local fator=comprimento*math.sqrt(2)/correia.Size.Z
	local inclinacao=CFrame.Angles(angulo,0,0)
	local pivoOriginal=modelo:GetPivot()
	modelo:SetAttribute("TamanhoConstrucao",tamanho)
	local originais={}
	local superficies={}
	for _,p in modelo:GetDescendants() do
		if not p:IsA("BasePart") then continue end
		originais[p]={CFrame=pivoOriginal:ToObjectSpace(p.CFrame),Size=p.Size}
		if p==hitbox then continue end
		local cf=referencia:ToObjectSpace(p.CFrame)
		local direcao=p:GetAttribute("DirecaoTransporte") or Vector3.zAxis
		local sx=(cf.RightVector*Vector3.new(1,1,fator)).Magnitude
		local sy=(cf.UpVector*Vector3.new(1,1,fator)).Magnitude
		local sz=(cf.LookVector*Vector3.new(1,1,fator)).Magnitude
		p.Size*=Vector3.new(sx,sy,sz)
		p.CFrame=CFrame.new(0,topo+comprimento/2,0)*inclinacao
			*CFrame.new(cf.X,cf.Y,cf.Z*fator)*cf.Rotation
		p:SetAttribute("DirecaoSuperficie",p.CFrame:VectorToObjectSpace(
			inclinacao:VectorToWorldSpace(Vector3.new(direcao.X,direcao.Y,direcao.Z*fator))).Unit)
		conter(p,largura,comprimento,angulo,if p==correia or p:GetAttribute("DirecaoTransporte") then math.sign(angulo) else nil)
		if p==correia or p:GetAttribute("DirecaoTransporte") then table.insert(superficies,p) end
	end
	if not hitbox then
		hitbox=Instance.new("Part")
		hitbox.Name="HitboxConstrucao"
		hitbox:SetAttribute("GeometriaEsteiraGerada",true)
		hitbox.Parent=modelo
	end
	hitbox.Size,hitbox.CFrame=Vector3.new(largura,altura,comprimento),CFrame.new(0,altura/2,0)
	hitbox.Transparency,hitbox.Anchored,hitbox.CanCollide,hitbox.CanTouch,hitbox.CanQuery=1,true,false,false,false
	for i,p in superficies do
		local pos=p.CFrame.Position
		for _,s in {-1,1} do
			local y=topo+(if (s>0)==(angulo<0) then comprimento else 0)
			local porta=Instance.new("Part")
			porta.Name="EncaixeEsteira" .. i .. (if s<0 then "Entrada" else "Saida")
			porta.Size=Vector3.new(p.Size.X,.12*escala,.18*escala)
			porta.CFrame=CFrame.new(pos.X,y-.06*escala,s*(comprimento/2-.09*escala))
			porta.Color,porta.Material=p.Color,p.Material
			porta.Transparency,porta.Reflectance=p.Transparency,p.Reflectance
			porta.Anchored,porta.CanCollide,porta.CanTouch=true,true,false
			porta:SetAttribute("GeometriaEsteiraGerada",true)
			porta:SetAttribute("ParteTransporteOrigem",p.Name)
			porta:SetAttribute("DirecaoSuperficie",p:GetAttribute("DirecaoTransporte") or Vector3.zAxis)
			porta.Parent=modelo
			if (s>0)==(angulo<0) then
				local a=p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,s*p.Size.Z/2))
				local b=Vector3.new(pos.X,y,s*(comprimento/2-.09*escala))
				local frente=(b-a).Unit
				local direita=Vector3.xAxis*math.sign(frente.Z)
				local cima=frente:Cross(direita)
				local transicao=Instance.new("Part")
				transicao.Name="RevestimentoEncaixe" .. i
				transicao.Size=Vector3.new(p.Size.X,.04*escala,(b-a).Magnitude)
				transicao.CFrame=CFrame.fromMatrix((a+b)/2-cima*.02*escala,direita,cima,frente)
				transicao.Color,transicao.Material=p.Color,p.Material
				transicao.Transparency,transicao.Reflectance=p.Transparency,p.Reflectance
				transicao.Anchored,transicao.CanCollide,transicao.CanTouch=true,false,false
				transicao:SetAttribute("GeometriaEsteiraGerada",true)
				transicao.Parent=modelo
			end
		end
	end
	local pivo=modelo:GetPivot()
	for p,original in originais do
		p:SetAttribute("CFramePlanoEsteira",original.CFrame)
		p:SetAttribute("TamanhoPlanoEsteira",original.Size)
		p:SetAttribute("CFrameAdaptadoEsteira",pivo:ToObjectSpace(p.CFrame))
		p:SetAttribute("TamanhoAdaptadoEsteira",p.Size)
	end
	modelo:SetAttribute("InclinacaoEsteira",angulo)
end

function EsteiraInclinada.GeometriaPlana(parte,pivo)
	local cf=pivo:ToObjectSpace(parte.CFrame)
	local tamanho=parte.Size
	local original=parte:GetAttribute("CFramePlanoEsteira")
	if original then
		local adaptado=parte:GetAttribute("CFrameAdaptadoEsteira")
		cf=original*adaptado:ToObjectSpace(cf)
		local plano,adaptado=parte:GetAttribute("TamanhoPlanoEsteira"),parte:GetAttribute("TamanhoAdaptadoEsteira")
		tamanho=Vector3.new(plano.X*tamanho.X/adaptado.X,plano.Y*tamanho.Y/adaptado.Y,plano.Z*tamanho.Z/adaptado.Z)
	end
	return cf,tamanho
end

return EsteiraInclinada
