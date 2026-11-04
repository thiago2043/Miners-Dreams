local fs = require("@lune/fs")
local r = require("@lune/roblox")
local premios = require("../../src/shared/RecompensasRenascimento")
local V, CF, C, E = r.Vector3, r.CFrame, r.Color3, r.Enum
local destino = "modelos/renascimento"
fs.writeDir(destino.."/assets")
local galeria = r.Instance.new("Model"); galeria.Name = "GaleriaRenascimento"
for i, def in premios do
	local categoria = if def.Tipo=="Soltador" then "mineradoras" elseif def.Tipo=="Vendedor" then "fornalhas" else "modificadores"
	local modelo = r.deserializeModel(fs.readFile("modelos/"..categoria.."/assets/"..def.Base..".rbxm"))[1]
	modelo.Name = def.Id
	modelo:SetAttribute("NomeExibicao", def.Nome)
	modelo:SetAttribute("Renascimento", true)
	modelo:SetAttribute("SomenteModelagem", false)
	if def.Codigo then modelo:SetAttribute("IdProposta",def.Codigo) end
	modelo:SetAttribute("PrecoProposto","0")
	if def.Multiplicador then modelo:SetAttribute("MultiplicadorProposto",def.Multiplicador) end
	local cor = C.fromRGB(table.unpack(def.Cor))
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency<.5 then
			if p.Material==E.Material.Neon then p.Color=cor
			elseif p.Material==E.Material.Metal or p.Material==E.Material.DiamondPlate then p.Color=p.Color:Lerp(cor,.18) end
		end
	end
	local hitbox = assert(modelo:FindFirstChild("HitboxConstrucao"))
	local w,h,d = hitbox.Size.X,hitbox.Size.Y,hitbox.Size.Z
	local detalhes = r.Instance.new("Folder"); detalhes.Name="EstruturaRenascimento"; detalhes.Parent=modelo
	local function bloco(nome,size,pos,luz,giro)
		local p=r.Instance.new("Part"); p.Name=nome; p.Size=size
		p.CFrame=hitbox.CFrame*CF.new(pos)*(giro or CF.identity)
		p.Color=if luz then cor else C.fromRGB(46,52,65)
		p.Material=if luz then E.Material.Neon else E.Material.DiamondPlate
		p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,true
		p.Parent=detalhes; return p
	end
	local function arco(nome,centro,raio,giro)
		for j=0,11 do
			local a=j*math.pi/6
			local cf=CF.new(centro)*(giro or CF.identity)*CF.Angles(0,0,a)*CF.new(raio,0,0)
			bloco(nome,V.new(.22,raio*.52,.22),cf.Position,true,cf.Rotation)
		end
	end
	local estilo=(i-1)%3+1
	if def.Tipo=="Soltador" then
		-- A estrutura traseira acompanha o corpo; bocal e broca conservam os encaixes aprovados.
		for _,s in {-1,1} do
			bloco("ModuloTraseiro",V.new(w*.19,h*.34,d*.32),V.new(s*w*.36,h*.08,-d*.22))
			for j=1,estilo+2 do
				bloco("AletaReator",V.new(w*.21,.18,d*.045),V.new(s*w*.36,h*.24,-d*.4+j*d*.08),true)
			end
		end
		if estilo==1 then
			arco("ArcoDorsal",V.new(0,h*.24,-d*.22),w*.24)
		elseif estilo==2 then
			for _,s in {-1,1} do bloco("TorrePulsar",V.new(w*.09,h*.55,d*.12),V.new(s*w*.27,h*.28,-d*.32),true) end
		else
			for j=1,3 do arco("CoroaEterna",V.new(0,h*.18,-d*.42+j*d*.12),w*.26) end
		end
	elseif def.Tipo=="Vendedor" then
		if estilo==1 then
			for _,s in {-1,1} do
				bloco("CamaraAurora",V.new(w*.17,h*.5,d*.23),V.new(s*w*.33,h*.1,d*.22))
				bloco("NucleoAurora",V.new(w*.11,h*.39,d*.18),V.new(s*w*.33,h*.12,d*.23),true)
			end
		elseif estilo==2 then
			arco("ColetorSupernova",V.new(0,h*.12,d*.15),w*.36)
			arco("OrbitaSupernova",V.new(0,h*.12,d*.15),w*.3,CF.Angles(0,math.pi/3,0))
		else
			for _,s in {-1,1} do
				bloco("PilarEterno",V.new(.55,h*.7,.7),V.new(s*w*.4,h*.1,d*.3))
				bloco("CanalEterno",V.new(.17,h*.6,.17),V.new(s*w*.4,h*.1,d*.26),true)
			end
			bloco("TravessaEterna",V.new(w*.83,.7,.7),V.new(0,h*.46,d*.3))
		end
	else
		-- As adicoes ficam nas laterais e acima do corredor de dois blocos.
		for _,s in {-1,1} do
			bloco("ApoioAmplificador",V.new(w*.17,h*.55,d*.7),V.new(s*w*.39,-h*.12,0))
			for j=1,estilo+1 do
				bloco("CristalAmplificador",V.new(.5,h*.3,.5),V.new(s*w*.39,h*.27,-d*.3+j*d*.17),true,CF.Angles(0,0,s*.25))
			end
		end
		if estilo==1 then arco("SeloSuperior",V.new(0,h*.25,0),w*.25)
		elseif estilo==2 then
			for _,s in {-1,1} do arco("PrismaCruzado",V.new(0,h*.2,0),w*.27,CF.Angles(0,s*math.pi/4,0)) end
		else
			for j=1,3 do bloco("PonteNexus",V.new(w*.74,.3,.3),V.new(0,h*.22+j*.45,0),true) end
		end
	end
	fs.writeFile(destino.."/assets/"..def.Id..".rbxm",r.serializeModel({modelo}))
	local deslocamento=CF.new((i-1)%3*54,0,math.floor((i-1)/3)*54)
	for _,p in modelo:GetDescendants() do if p:IsA("BasePart") then p.CFrame=deslocamento*p.CFrame end end
	modelo.Parent=galeria
end
fs.writeFile(destino.."/GaleriaRenascimento.rbxm",r.serializeModel({galeria}))
print("RENASCIMENTO_MODELOS_OK",#premios)
