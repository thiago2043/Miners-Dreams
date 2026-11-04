local Shared=game:GetService("ReplicatedStorage").Shared
local ajustes=require(Shared.AjustesHitbox)
local reducoes=require(Shared.ReducoesAlturaHitbox)
local catalogo=require(Shared.CatalogoMaquinas)
local Volume=require(Shared.VolumeConstrucao)
local bloco=require(Shared.Medidas).Bloco
local M={}
local function copiar(v)
	if type(v)~="table" then return v end
	local n={}; for k,x in v do n[k]=copiar(x) end; return n
end
local novos={}
for id,reducao in reducoes do
	local depois=table.clone(catalogo[id].Blocos)
	local antes=table.clone(depois); antes[2]+=reducao
	novos[id]={antes,depois}
end
local function deslocamento(tabela,id,rotacao)
	local a=tabela[id]; if not a then return Vector3.zero end
	local antiga,nova=Vector3.new(table.unpack(a[1]))*bloco,Vector3.new(table.unpack(a[2]))*bloco
	local ea=Volume.CalcularVolume(rotacao,antiga)
	local en=Volume.CalcularVolume(rotacao,nova)
	local centro=Vector3.new((antiga.X-nova.X)/2,-(antiga.Y-nova.Y)/2,0)
	return ea-en+rotacao:VectorToWorldSpace(centro)
end
function M.Deslocamento(id,rotacao) return deslocamento(ajustes,id,rotacao) end
local function centro(tabela,id,r)
	local a=tabela[id]; if not a then return Vector3.zero end
	return r:VectorToWorldSpace(Vector3.new(a[1][1]-a[2][1],-(a[1][2]-a[2][2]),0)*bloco/2)
end
local function ajustar(tabela,p,posicao,rotacao)
	if not tabela[p.MaquinaId] then return end
	local r=CFrame.new(0,0,0,table.unpack(p[rotacao]))
	local d=deslocamento(tabela,p.MaquinaId,r)
	for i,eixo in {"X","Y","Z"} do p[posicao][i]+=math.round(d[eixo]/bloco)*bloco end
end
local function migrar(dados,tabela,versao,chaveBackup)
	local novo=copiar(dados)
	-- Guarda so coordenadas alteradas; duplicar personalizacoes poderia exceder o tamanho do perfil.
	local backup={MaquinasColocadas={},Blueprints={}}
	novo[chaveBackup]=novo[chaveBackup] or backup
	for i,p in novo.MaquinasColocadas or {} do
		if tabela[p.MaquinaId] then table.insert(backup.MaquinasColocadas,{Indice=i,Posicao=table.clone(p.Posicao)}) end
		ajustar(tabela,p,"Posicao","Rotacao")
	end
	for indice,b in novo.Blueprints or {} do
		local origem=Vector3.zero
		local anteriores={}
		for i,p in b.Pecas do
			local d=centro(tabela,p.MaquinaId,CFrame.new(0,0,0,table.unpack(p.RotacaoInicial)))
			if i==1 then origem=d end
			if d~=origem then table.insert(anteriores,{Indice=i,DeslocamentoInicial=table.clone(p.DeslocamentoInicial)}) end
			for j,eixo in {"X","Y","Z"} do p.DeslocamentoInicial[j]+=d[eixo]-origem[eixo] end
		end
		if #anteriores>0 then table.insert(backup.Blueprints,{Indice=indice,Pecas=anteriores}) end
	end
	novo.VersaoHitboxes=versao
	return novo
end
function M.Preparar(dados)
	local atual=dados.VersaoHitboxes or 0
	if atual<1 then dados=migrar(dados,ajustes,1,"BackupHitboxes") end
	if atual<2 then dados=migrar(dados,novos,2,"BackupHitboxesV2") end
	return dados
end
return M
