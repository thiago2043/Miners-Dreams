local r=require("./suporte/modelos")
local fs=require("@lune/fs")
local serde=require("@lune/serde")
local carregar=require("./suporte/carregador")({Vector3=r.Vector3,CFrame=r.CFrame,typeof=r.typeof},{})
local reducoes=carregar("src/shared/ReducoesAlturaHitbox")
local catalogo=carregar("src/shared/CatalogoMaquinas")
local antigo=carregar("src/shared/AjustesHitbox")
local migracao=carregar("src/server/Data/MigracaoHitboxes")
local volume=carregar("src/shared/VolumeConstrucao")
local projeto=serde.decode("json",fs.readFile("default.project.json"))
local aplicar=require("../modelos/ajustar_hitboxes")
local total=0
for id,reducao in reducoes do
	local modelo=r.deserializeModel(fs.readFile(projeto.tree.ReplicatedStorage.ModelosMaquinas[id]["$path"]))[1]
	local original=modelo:Clone()
	local h=original.HitboxConstrucao
	local anterior=h.Size
	local versao=original:GetAttribute("VersaoHitbox") or 0
	local parteVisual
	for _,p in original:GetDescendants() do if p:IsA("BasePart") and p~=h then parteVisual=p; break end end
	local poseVisual=parteVisual and parteVisual.CFrame
	local base=h.CFrame:PointToWorldSpace(r.Vector3.new(0,-h.Size.Y/2,0))
	aplicar.Aplicar(original)
	local nova=r.Vector3.new(table.unpack(catalogo[id].Blocos))*3
	assert(h.Size==nova and original:GetAttribute("VersaoHitbox")==2,id)
	assert(not aplicar.Aplicar(original),"Ajuste deve ser idempotente: "..id)
	assert((h.CFrame:PointToWorldSpace(r.Vector3.new(0,-h.Size.Y/2,0))-base).Magnitude<.001,id)
	assert(not parteVisual or parteVisual.CFrame==poseVisual,"A geometria visual não deve mudar: "..id)
	if versao<2 then assert(anterior.Y-h.Size.Y==reducao*3,id) end
	local velha=r.Vector3.new(nova.X,nova.Y+reducao*3,nova.Z)
	for _,x in {0,math.pi/2,math.pi,math.pi*1.5} do for _,y in {0,math.pi/2,math.pi,math.pi*1.5} do
		local rot=r.CFrame.Angles(x,y,0)
		local p={MaquinaId=id,Posicao={30,30,30},Rotacao={select(4,rot:GetComponents())}}
		local dados={VersaoHitboxes=1,MaquinasColocadas={p},Blueprints={}}
		local novo=migracao.Preparar(dados)
		local pos=r.Vector3.new(table.unpack(novo.MaquinasColocadas[1].Posicao))
		local esperado=r.Vector3.new(30,30,30)+volume.CalcularVolume(rot,velha)
			+rot:VectorToWorldSpace(r.Vector3.new(0,-reducao*3/2,0))
		assert((pos+volume.CalcularVolume(rot,nova)-esperado).Magnitude<.001,id)
		assert(dados.VersaoHitboxes==1 and novo.BackupHitboxesV2 and migracao.Preparar(novo)==novo)
	end end
	total+=1
end
assert(total==37 and reducoes.FeixeMolecular==2)
local ident={1,0,0,0,1,0,0,0,1}
local dados={VersaoHitboxes=1,Blueprints={{Pecas={
	{MaquinaId="LaserQuantico",DeslocamentoInicial={0,0,0},RotacaoInicial=ident},
	{MaquinaId="Esteira2x2",DeslocamentoInicial={6,0,0},RotacaoInicial=ident},
}}}}
local bp=migracao.Preparar(dados)
assert(bp.Blueprints[1].Pecas[2].DeslocamentoInicial[2]==1.5 and bp.BackupHitboxesV2.Blueprints[1])
local salvo=carregar("src/server/Data/MigracaoCatalogo").Preparar(bp)
assert(salvo.BackupHitboxesV2.Blueprints[1],"Backup deve sobreviver aos próximos carregamentos.")
print("ALTURAS_OK",total,"modelos, rotacoes, blueprint, preservacao visual e migracao idempotente")
