-- Command Bar do servidor em Executar; objetos isolados, sem perfis ou rede de construcao.
do
	assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer())
	local Client=game.StarterPlayer.StarterPlayerScripts.Client
	local Previa=require(Client.PreviaConstrucao)
	local Controlador=require(Client.ControladorConstrucao)
	local Navegacao=require(Client.NavegacaoEstados)
	local raiz=Instance.new("Folder"); raiz.Name="TestePreviasCompartilhadas"; raiz.Parent=workspace
	local maquinas=Instance.new("Folder"); maquinas.Parent=raiz
	local selecionaveis=Instance.new("Folder"); selecionaveis.Parent=raiz
	local piso=Instance.new("Part"); piso.Anchored=true; piso.Size=Vector3.new(48,1,48); piso.Parent=raiz
	local origem=CFrame.new(12000,1000,12000)
	local original=Instance.new("Model"); original.Name="Parede1x1"; original.Parent=raiz
	local hitbox=Instance.new("Part"); hitbox.Name="HitboxConstrucao"; hitbox.Size=Vector3.one*3
	hitbox.CFrame=CFrame.new(1.5,1.5,1.5); hitbox.Anchored=true; hitbox.Parent=original
	for i=1,100 do
		local m=original:Clone(); m.Parent=maquinas
		local minimo=Vector3.new((i-1)%10*3,0,math.floor((i-1)/10)*3)
		m:SetAttribute("VolumeMinimo",minimo); m:SetAttribute("VolumeOcupado",Vector3.one*3)
		m:PivotTo(origem*CFrame.new(minimo+Vector3.one*1.5))
	end
	local contextos={}
	local function contexto()
		local c=setmetatable({_modelosOriginais={Parede1x1=original},_jogador=raiz,_maquinas=maquinas,_piso=piso,
			_pecasSelecionadas={},_destaquesPecas={},_modoSelecao="Selecao",_consulta=RaycastParams.new(),Navegacao=Navegacao.new()},Controlador)
		table.insert(contextos,c); return c
	end
	local function resposta(n)
		local pecas={}
		for i=1,n do
			local k=i-1
			pecas[i]={MaquinaId="Parede1x1",Modificacoes={},RotacaoInicial=CFrame.identity,
				DeslocamentoInicial=Vector3.new(k%16*3,math.floor(k/256)*3,math.floor(k/16)%16*3)}
		end
		return {Token=1,Pecas=pecas}
	end
	local criadas,atualizadas=0,0
	local criar,atualizar=Previa._CriarCaixa,Previa._AtualizarCaixa
	local ok,erro=xpcall(function()
		Previa._CriarCaixa=function(self,nome,...)
			if nome~="VolumePrevia" then criadas+=1 end
			return criar(self,nome,...)
		end
		Previa._AtualizarCaixa=function(self,caixa,...)
			if caixa.Name~="VolumePrevia" then atualizadas+=1 end
			return atualizar(self,caixa,...)
		end
		local c=contexto()
		assert(c:_IniciarPreviaCopiaGrupo(resposta(60),nil,60))
		c._previa:AtualizarVolumes(origem,0)
		assert(criadas==100)
		atualizadas=0
		for _=1,5 do c._previa:AtualizarVolumes(origem,.2) end
		assert(atualizadas==500)
		for _,peca in c._movimento.Pecas do
			assert(peca.Previa._volumes==c._previa._volumes)
			assert(not peca.Previa:VolumeLivre(origem,Vector3.zero,Vector3.one*3))
			assert(peca.Previa:VolumeLivre(origem,Vector3.new(0,30,0),Vector3.one*3))
		end
		local recurso=c._previa._volumes
		local segunda=c._movimento.Pecas[2].Previa
		c._previa:Destruir(); c._previa:Destruir()
		assert(recurso.Usuarios==59 and recurso.Pasta.Parent==workspace)
		segunda:ForcarAtualizacao(); segunda:AtualizarVolumes(origem,0)
		c:EncerrarColocacao(); assert(recurso.Usuarios==0 and not recurso.Pasta.Parent)
		local grande=contexto()
		for i=1,1001 do
			local m=original:Clone(); m.Parent=selecionaveis
			assert(grande:_DefinirPecaSelecionada(m,true)==(i<=1000))
		end
		local highlights,contornos=0,0
		for _,destaque in grande._destaquesPecas do
			if destaque:IsA("Highlight") then highlights+=1 else contornos+=1; assert(destaque.Color3==Color3.new(1,1,1)) end
		end
		assert(#grande._pecasSelecionadas==1000 and highlights==250 and contornos==750)
		grande:_LimparSelecaoPecas()
		criadas=0
		assert(grande:_IniciarPreviaCopiaGrupo(resposta(1000),nil,1000))
		grande._previa:AtualizarVolumes(origem,0)
		local volumes=grande._previa._volumes
		assert(criadas==100 and volumes.Usuarios==1000 and #volumes.Pasta:GetChildren()==1100)
		for _,peca in grande._movimento.Pecas do assert(peca.Previa._volumes==volumes) end
		grande:EncerrarColocacao(); assert(volumes.Usuarios==0 and not volumes.Pasta.Parent)
		assert(not grande:_IniciarPreviaCopiaGrupo(resposta(1001),nil,nil))
		print("PREVIAS_COMPARTILHADAS_STUDIO_OK: 60x100 = 100 caixas/500 atualizacoes em cinco revisoes; 1.000 selecionadas e previas, 1.001 recusada, 250 highlights/750 contornos, filtro compartilhado e limpeza.")
	end,debug.traceback)
	Previa._CriarCaixa,Previa._AtualizarCaixa=criar,atualizar
	for _,c in contextos do c:EncerrarColocacao(); c:_LimparSelecaoPecas(); c.Navegacao:Destruir() end
	raiz:Destroy()
	assert(ok,erro)
end
return true
