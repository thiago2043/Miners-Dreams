local fs=require("@lune/fs")
local serde=require("@lune/serde")
local r=require("@lune/roblox")
local ajustes=require("../src/shared/AjustesHitbox")
local reducoes=require("../src/shared/ReducoesAlturaHitbox")
local M={}
function M.Aplicar(modelo)
	local a=ajustes[modelo.Name]; local h=modelo:FindFirstChild("HitboxConstrucao")
	if not h then return false end
	local bloco=modelo:GetAttribute("GradeStuds") or 3
	local versao=modelo:GetAttribute("VersaoHitbox") or 0
	local mudou=false
	if a and versao<1 then
		local antiga,nova=r.Vector3.new(table.unpack(a[1]))*bloco,r.Vector3.new(table.unpack(a[2]))*bloco
		assert((h.Size-antiga).Magnitude<.001,"Reserva anterior inesperada: "..modelo.Name)
		h.CFrame+=h.CFrame:VectorToWorldSpace(r.Vector3.new((antiga.X-nova.X)/2,-(antiga.Y-nova.Y)/2,0))
		h.Size=nova; versao=1; mudou=true
	end
	local reducao=reducoes[modelo.Name]
	if reducao and versao<2 then
		assert(h.Size.Y>reducao*bloco,"Altura anterior inválida: "..modelo.Name)
		h.CFrame+=h.CFrame:VectorToWorldSpace(r.Vector3.new(0,-reducao*bloco/2,0))
		h.Size-=r.Vector3.new(0,reducao*bloco,0)
		versao=2; mudou=true
	end
	if mudou then modelo:SetAttribute("VersaoHitbox",versao) end
	return mudou
end
local function arvore(raiz)
	local mudou=false
	for _,m in raiz:GetDescendants() do if m:IsA("Model") and M.Aplicar(m) then mudou=true end end
	if raiz:IsA("Model") and M.Aplicar(raiz) then mudou=true end
	return mudou
end
function M.Executar()
	local projeto=serde.decode("json",fs.readFile("default.project.json"))
	local total=0
	for id,entrada in projeto.tree.ReplicatedStorage.ModelosMaquinas do
		if not ajustes[id] and not reducoes[id] then continue end
		local modelo=r.deserializeModel(fs.readFile(entrada["$path"]))[1]
		if M.Aplicar(modelo) then fs.writeFile(entrada["$path"],r.serializeModel({modelo})); total+=1 end
	end
	for _,familia in {"modificadores","fornalhas","mineradoras"} do
		local pasta="modelos/"..familia.."/"
		local caminho=pasta.."geometria.json"
		local defs=serde.decode("json",fs.readFile(caminho))
		for _,d in defs do
			local a,reducao=ajustes[d.id],reducoes[d.id]
			if not a and not reducao then continue end
			local path=projeto.tree.ReplicatedStorage.ModelosMaquinas[d.id]["$path"]
			local h=r.deserializeModel(fs.readFile(path))[1].HitboxConstrucao
			local novo={h.Size.X/3,h.Size.Y/3,h.Size.Z/3}
			if familia=="modificadores" then d.blocos={novo[1],novo[3]}; d.altura=novo[2]
			elseif familia=="fornalhas" then d.blocos={novo[1],novo[3],novo[2]}
			else d.altura=novo[2] end
			for _,p in d.partes or {} do if p.name=="HitboxConstrucao" then p.size={h.Size.X,h.Size.Y,h.Size.Z}; p.cf={h.CFrame:GetComponents()} end end
		end
		fs.writeFile(caminho,serde.encode("json",defs,true))
		local nome=({modificadores="GaleriaModificadores.rbxm",fornalhas="GaleriaFornalhas.rbxm",mineradoras="GaleriaMineradoras.rbxlx"})[familia]
		local path=pasta..nome
		if familia=="mineradoras" then
			local mundo=r.deserializePlace(fs.readFile(path))
			if arvore(mundo) then fs.writeFile(path,r.serializePlace(mundo,"xml")) end
		else
			local galeria=r.deserializeModel(fs.readFile(path))[1]
			if arvore(galeria) then fs.writeFile(path,r.serializeModel({galeria})) end
		end
	end
	print("HITBOXES_AJUSTADAS",total)
end
return M
