local r=require("./suporte/modelos")
local fs=require("@lune/fs"); local serde=require("@lune/serde")
local carregar=require("./suporte/carregador")({Vector3=r.Vector3,CFrame=r.CFrame,typeof=r.typeof},{})
local ajustes=carregar("src/shared/AjustesHitbox")
local reducoes=carregar("src/shared/ReducoesAlturaHitbox")
local M=carregar("src/server/Data/MigracaoHitboxes")
local projeto=serde.decode("json",fs.readFile("default.project.json"))
local catalogo=carregar("src/shared/CatalogoMaquinas")
local Volume=carregar("src/shared/VolumeConstrucao")
local total=0
for id,a in ajustes do
	local modelo=r.deserializeModel(fs.readFile(projeto.tree.ReplicatedStorage.ModelosMaquinas[id]["$path"]))[1]
	local nova=r.Vector3.new(table.unpack(catalogo[id].Blocos))*3
	assert(modelo.HitboxConstrucao.Size==nova and modelo:GetAttribute("VersaoHitbox")==if reducoes[id] then 2 else 1)
	assert(r.Vector3.new(table.unpack(catalogo[id].Blocos))*3==nova)
	for _,x in {0,math.pi/2,math.pi,math.pi*1.5} do for _,y in {0,math.pi/2,math.pi,math.pi*1.5} do
		local rot=r.CFrame.Angles(x,y,0)
		local antiga=r.Vector3.new(table.unpack(a[1]))*3
		local origem=r.Vector3.new(30,30,30)
		local antes={MaquinaId=id,Posicao={30,30,30},Rotacao={select(4,rot:GetComponents())}}
		local dados={MaquinasColocadas={antes},Blueprints={}}
		local migrado=M.Preparar(dados)
		local pos=r.Vector3.new(table.unpack(migrado.MaquinasColocadas[1].Posicao))
		local ea=Volume.CalcularVolume(rot,antiga); local en=Volume.CalcularVolume(rot,nova)
		local centro=r.Vector3.new((antiga.X-nova.X)/2,-(antiga.Y-nova.Y)/2,0)
		assert(((pos+en)-(origem+ea+rot:VectorToWorldSpace(centro))).Magnitude<.001,"Mudou a posicao visual: "..id)
		assert(dados.VersaoHitboxes==nil and M.Preparar(migrado)==migrado and migrado.BackupHitboxes)
	end end
	total+=1
end
local bp={Blueprints={{Pecas={{MaquinaId="CamaraQuantica",DeslocamentoInicial={0,0,0},RotacaoInicial={1,0,0,0,1,0,0,0,1}},
	{MaquinaId="Esteira2x2",DeslocamentoInicial={9,0,0},RotacaoInicial={1,0,0,0,1,0,0,0,1}}}}}}
local migrado=M.Preparar(bp)
assert(migrado.Blueprints[1].Pecas[1].DeslocamentoInicial[1]==0)
assert(migrado.Blueprints[1].Pecas[2].DeslocamentoInicial[1]==7.5 and migrado.Blueprints[1].Pecas[2].DeslocamentoInicial[2]==1.5)
local regra=carregar("src/shared/RegraReencarnacao").new()
assert(regra:Calcular(string.rep("9",21),0,1).VidasDisponiveis==0)
for i=0,5 do
	local saldo="1"..string.rep("0",21+i*3)
	local estado=regra:Calcular(saldo,0,1)
	assert(estado.VidasDisponiveis==i+1 and estado.ExpoenteProximoMarco==24+i*3)
	assert(regra:Calcular(saldo.."00",0,1).VidasDisponiveis==i+1,"Dois zeros ainda nao completam outro marco.")
	assert(regra:Calcular("0",i,1).ExpoenteRequisito==21+i*3)
end
print("AJUSTES_HITBOXES_OK",total,"modelos; rotacoes, backup, idempotencia, blueprints e progressao 1Sx/x1000.")
