local fs=require("@lune/fs")
local serde=require("@lune/serde")
local r=require("../../tests/suporte/modelos")
local carregar=require("../../tests/suporte/carregador")({Vector3=r.Vector3,CFrame=r.CFrame,Instance=r.Instance,typeof=r.typeof},{})
local catalogo=carregar("src/shared/CatalogoMaquinas")
local modelos=require("../../tests/suporte/catalogo_modelos")()
local adaptar=carregar("src/shared/EsteiraInclinada")
local resultado={}
local function exportar(id,modelo)
	local partes={}
	for _,p in modelo:GetDescendants() do
		if not p:IsA("BasePart") then continue end
		table.insert(partes,{name=p.Name,size={p.Size.X,p.Size.Y,p.Size.Z},cf={p.CFrame:GetComponents()},
			shape=p:IsA("WedgePart") and "WedgePart" or p.Shape.Name,
			color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,transparency=p.Transparency})
	end
	local saida=modelo:FindFirstChild("SaidaMinerio",true)
	resultado[id]={id=id,partes=partes,saida=if saida then {saida.WorldCFrame.Position.X,saida.WorldCFrame.Position.Y,saida.WorldCFrame.Position.Z} else nil}
end
for _,id in {"MineradoraBasica","MineradoraCobre","MineradoraQuantica","CamaraMagnetica","RefinadorMolecular",
	"ProcessadorTermico","RessonadorPlasma","LaserDuplo","CamaraPlasma","FornalhaReforcada","FornalhaTermica","FornalhaMolecular","Esteira2x2"} do
	exportar(id,assert(modelos:FindFirstChild(id)))
end
local descida=modelos.Esteira2x2:Clone()
adaptar.Aplicar(descida,catalogo.Esteira2x2,r.CFrame.Angles(math.pi/4,0,0))
exportar("EsteiraDescida",descida)
fs.writeFile("divulgacao/referencias/modelos-do-build.json",serde.encode("json",resultado,true))
print("MODELOS_DO_BUILD_OK: assets relidos do mapeamento Rojo; descida gerada pelo adaptador do jogo.")
