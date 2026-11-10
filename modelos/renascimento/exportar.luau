local fs=require("@lune/fs")
local r=require("@lune/roblox")
local serde=require("@lune/serde")
local modelos={}
for _,def in require("../../src/shared/RecompensasRenascimento") do
	if not def.Base then continue end
	local m=r.deserializeModel(fs.readFile("modelos/renascimento/assets/"..def.Id..".rbxm"))[1]
	local partes={}
	for _,p in m:GetDescendants() do if p:IsA("BasePart") then
		table.insert(partes,{name=p.Name,size={p.Size.X,p.Size.Y,p.Size.Z},cf={p.CFrame:GetComponents()},
			color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,
			shape=if p:IsA("Part") then p.Shape.Name else p.ClassName,transparency=p.Transparency})
	end end
	table.insert(modelos,{id=def.Id,nome=def.Nome,tipo=def.Tipo,partes=partes})
end
fs.writeFile("modelos/renascimento/geometria.json",serde.encode("json",modelos))
print("GEOMETRIA_RENASCIMENTO_OK",#modelos)
