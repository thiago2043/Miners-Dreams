-- Command Bar do servidor do Play; somente leitura dos modelos e do perfil ja carregado.
do
	assert(game:GetService("RunService"):IsServer(),"Execute no contexto Servidor.")
	local R,S=game.ReplicatedStorage,game.ServerScriptService
	local Catalogo=require(R.Shared.CatalogoMaquinas)
	local Geometria=require(R.Shared.GeometriaColocacao)
	assert(require(R.Shared.Medidas).Bloco==3 and Geometria.Passo==3)
	assert(require(S.Data.Template).TamanhoBloco==3)
	local total=0
	for id,def in Catalogo do
		local modelo=assert(R.ModelosMaquinas:FindFirstChild(id),id)
		assert(modelo:GetAttribute("GradeStuds")==3,"Escala antiga: "..id)
		local _,tamanho=Geometria.CaixaDeConstrucao(modelo)
		if def.Blocos then
			local volume=require(R.Shared.VolumeConstrucao).new(tamanho,def.Blocos,def)
			assert((volume:ObterBlocos()-Vector3.new(table.unpack(def.Blocos))).Magnitude<.001,id)
		end
		for _,c in def.Componentes do if c.Tipo=="Soltador" then assert(c.Minerio.Tamanho[1]==.75) end end
		total+=1
	end
	assert(total==91)
	local perfis=0
	for jogador,perfil in require(S.Data.DataManager).Profiles do
		assert(perfil.Data.TamanhoBloco==3,"Perfil ainda na escala antiga.")
		local terreno
		for _,t in workspace.Terrenos:GetChildren() do if t:GetAttribute("DonoUserId")==jogador.UserId then terreno=t end end
		assert(terreno and terreno.Piso.Size==Vector3.new(48,1,48))
		assert(#terreno.Maquinas:GetChildren()==#perfil.Data.MaquinasColocadas,"Restauro incompleto.")
		for _,m in terreno.Maquinas:GetChildren() do
			local minimo=m:GetAttribute("VolumeMinimo")
			for _,v in {minimo.X,minimo.Y,minimo.Z} do assert(math.abs(v/3-math.round(v/3))<.001) end
		end
		print("STUDIO_PERFIL_ESCALA_OK",#perfil.Data.MaquinasColocadas,"pecas restauradas; backup antigo:",perfil.Data.BackupGrade4~=nil)
		perfis+=1
	end
	local antigo={MaquinasColocadas={{Posicao={4,8,12}}},Blueprints={{Pecas={{DeslocamentoInicial={-4,0,8}}}}}}
	local convertido=require(S.Data.MigracaoGrade).Preparar(antigo)
	assert(antigo.MaquinasColocadas[1].Posicao[1]==4 and convertido.MaquinasColocadas[1].Posicao[1]==3)
	assert(convertido.BackupGrade4.MaquinasColocadas[1].Posicao[1]==4 and convertido.Blueprints[1].Pecas[1].DeslocamentoInicial[1]==-3)
	print("STUDIO_ESCALA_3_STUDS_OK",total,"modelos; migracao isolada com backup; perfis disponiveis:",perfis)
end
