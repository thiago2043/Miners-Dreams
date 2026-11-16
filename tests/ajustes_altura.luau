local r=require("./suporte/modelos")
local fs=require("@lune/fs")
local serde=require("@lune/serde")
local carregar=require("./suporte/carregador")({Vector3=r.Vector3,CFrame=r.CFrame,typeof=r.typeof},{})
local reducoes=carregar("src/shared/ReducoesAlturaHitbox")
local variacoes=carregar("src/shared/AjustesAlturaV3")
local catalogo=carregar("src/shared/CatalogoMaquinas")
local migracao=carregar("src/server/Data/MigracaoHitboxes")
local volume=carregar("src/shared/VolumeConstrucao")
local projeto=serde.decode("json",fs.readFile("default.project.json"))
local aplicar=require("../modelos/ajustar_hitboxes")
local function conferirMigracao(id,nova,variacao,versao,backup)
	local velha=nova-r.Vector3.yAxis*variacao*3
	for _,x in {0,math.pi/2,math.pi,math.pi*1.5} do for _,y in {0,math.pi/2,math.pi,math.pi*1.5} do
		local rot=r.CFrame.Angles(x,y,0)
		local p={MaquinaId=id,Posicao={30,30,30},Rotacao={select(4,rot:GetComponents())}}
		local dados={VersaoHitboxes=versao,MaquinasColocadas={p},Blueprints={}}
		local novo=migracao.Preparar(dados)
		local pos=r.Vector3.new(table.unpack(novo.MaquinasColocadas[1].Posicao))
		local esperado=r.Vector3.new(30,30,30)+volume.CalcularVolume(rot,velha)
			+rot:VectorToWorldSpace(r.Vector3.yAxis*variacao*3/2)
		assert((pos+volume.CalcularVolume(rot,nova)-esperado).Magnitude<.001,id)
		assert(novo.VersaoHitboxes==3 and dados.VersaoHitboxes==versao and migracao.Preparar(novo)==novo,id)
		assert(novo[backup].MaquinasColocadas[1].Posicao[2]==30 and p.Posicao[2]==30,id)
	end end
end
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
	local variacao=variacoes[id] or 0
	assert(h.Size==nova and original:GetAttribute("VersaoHitbox")==if variacao~=0 then 3 else 2,id)
	assert(not aplicar.Aplicar(original),"Ajuste deve ser idempotente: "..id)
	assert((h.CFrame:PointToWorldSpace(r.Vector3.new(0,-h.Size.Y/2,0))-base).Magnitude<.001,id)
	assert(not parteVisual or parteVisual.CFrame==poseVisual,"A geometria visual não deve mudar: "..id)
	if versao<2 then assert(anterior.Y-h.Size.Y==(reducao-variacao)*3,id) end
	conferirMigracao(id,nova,variacao-reducao,1,"BackupHitboxesV2")
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
local reduzidas,aumentadas=0,0
for id,variacao in variacoes do
	local modelo=r.deserializeModel(fs.readFile(projeto.tree.ReplicatedStorage.ModelosMaquinas[id]["$path"]))[1]
	local nova=r.Vector3.new(table.unpack(catalogo[id].Blocos))*3
	assert(modelo.HitboxConstrucao.Size==nova and modelo:GetAttribute("VersaoHitbox")==3,id)
	assert(not aplicar.Aplicar(modelo),id)
	conferirMigracao(id,nova,variacao,2,"BackupHitboxesV3")
	if variacao==-1 then reduzidas+=1 else assert(variacao==1 and id=="RessonadorVacuo"); aumentadas+=1 end
end
assert(reduzidas==31 and aumentadas==1)
local novo=migracao.Preparar({VersaoHitboxes=2,Blueprints={{Pecas={
	{MaquinaId="RessonadorVacuo",DeslocamentoInicial={0,0,0},RotacaoInicial=ident},
	{MaquinaId="RefinadorCobre",DeslocamentoInicial={12,0,0},RotacaoInicial=ident},
	{MaquinaId="Esteira2x2",DeslocamentoInicial={21,0,0},RotacaoInicial=ident},
}}}})
local pecas=novo.Blueprints[1].Pecas
assert(pecas[1].DeslocamentoInicial[2]==0 and pecas[2].DeslocamentoInicial[2]==-3 and pecas[3].DeslocamentoInicial[2]==-1.5)
assert(carregar("src/server/Data/MigracaoCatalogo").Preparar(novo).BackupHitboxesV3.Blueprints[1].Pecas[1].DeslocamentoInicial[2]==0)
print("ALTURAS_OK",total,"modelos, rotacoes, blueprint, preservacao visual e migracao idempotente")
print("ALTURAS_V3_OK",reduzidas,aumentadas,"catalogo, modelos, rotacoes, backup e blueprints")
