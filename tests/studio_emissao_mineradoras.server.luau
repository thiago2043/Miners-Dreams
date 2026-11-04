-- Mapear temporariamente no servidor, com FuncionamentoMaquinas desativado apenas durante a medicao.
-- Usa modelos e componentes reais; o dono sintetico nunca acessa perfis, inventarios ou pagamentos.
local RS=game:GetService("RunService")
assert(RS:IsStudio() and RS:IsServer())
local S=game:GetService("ServerScriptService")
local R=game:GetService("ReplicatedStorage")
local Fabrica=require(S.Fabrica)
local Maquina=require(S.Maquinas.Maquina)
local Catalogo=require(R.Shared.CatalogoMaquinas)
local Geometria=require(R.Shared.GeometriaColocacao)
local raiz=Instance.new("Folder"); raiz.Name="TesteEmissaoMineradoras"; raiz.Parent=workspace
local fabrica
local ok,erro=xpcall(function()
	for _, quantidade in {16,32,64,128} do
		local terrenos=Instance.new("Folder"); terrenos.Parent=raiz
		fabrica=Fabrica.new(terrenos)
		local primeiro
		local tempoEmissao=0
		for i=1,quantidade do
			local numero=math.floor((i-1)/64)
			local terreno=terrenos:FindFirstChild("Plot"..numero)
			if not terreno then
				terreno=Instance.new("Model"); terreno.Name="Plot"..numero; terreno.Parent=terrenos
				terreno:SetAttribute("DonoUserId",987654); terreno:SetAttribute("TerrenoId",numero+1)
				for _, nome in {"Maquinas","Minerios"} do local f=Instance.new("Folder"); f.Name=nome; f.Parent=terreno end
				local piso=Instance.new("Part"); piso.Name="Piso"; piso.Anchored=true
				piso.Size=Vector3.new(48,1,48); piso.CFrame=CFrame.new(numero*80,999.5,0); piso.Parent=terreno
			end
			local modelo=R.ModelosMaquinas.MineradoraBasica:Clone()
			local indice=(i-1)%64
			local caixa=Geometria.CaixaDeConstrucao(modelo)
			modelo:PivotTo(CFrame.new(numero*80+(indice%8)*6-21,1003,math.floor(indice/8)*6-21)*caixa:ToObjectSpace(modelo:GetPivot()))
			modelo:SetAttribute("DonoUserId",987654); modelo:SetAttribute("TerrenoId",numero+1); modelo.Parent=terreno.Maquinas
			local maquina=Maquina.new(modelo,terreno,Catalogo.MineradoraBasica,fabrica._simulacao)
			function maquina:ObterDadosDono() return {RegistrarRecorde=function() end} end
			local soltador=maquina._componentes[1]
			local atualizar=soltador.Atualizar
			function soltador:Atualizar(agora)
				if agora+.000000001<self._proximaGeracao then return atualizar(self,agora) end
				local inicio=os.clock(); atualizar(self,agora); tempoEmissao+=os.clock()-inicio
			end
			fabrica._maquinas[modelo]=maquina
			primeiro=primeiro or modelo
			if i%8==0 then task.wait() end
		end
		local consulta=OverlapParams.new(); consulta.FilterType=Enum.RaycastFilterType.Include
		consulta.FilterDescendantsInstances={primeiro.Parent.Parent}
		local saida=primeiro:FindFirstChild("SaidaMinerio",true).WorldCFrame
		local comuns=#workspace:GetPartBoundsInBox(saida,Vector3.one*18,consulta)
		consulta.RespectCanCollide=true
		local solidos=#workspace:GetPartBoundsInBox(saida,Vector3.one*18,consulta)
		print("EMISSAO_CONSULTA",quantidade,"decoracoes_e_solidos",comuns,"so_solidos",solidos)
		local inicio=os.clock()
		for _=1,30 do workspace:GetPartBoundsInBox(saida,Vector3.one*18,consulta) end
		local comFiltro=(os.clock()-inicio)/30*1000
		consulta.FilterType=Enum.RaycastFilterType.Exclude; consulta.FilterDescendantsInstances={}
		inicio=os.clock()
		for _=1,30 do workspace:GetPartBoundsInBox(saida,Vector3.one*18,consulta) end
		print("EMISSAO_CONSULTA_BRUTA",quantidade,"include_ms",comFiltro,"global_ms",(os.clock()-inicio)/30*1000)
		local sim=fabrica._simulacao
		local cadastro, candidatos=sim.RegistrarMinerio,sim._Candidatos
		local gerados,tempoConsultas=0,0
		local geometria=sim._Geometria
		local tempoGeometria,geometrias=0,0
		function sim:_Geometria(parte,regioes)
			if regioes.Geometrias[parte] then return geometria(self,parte,regioes) end
			local inicio=os.clock(); local item=geometria(self,parte,regioes)
			tempoGeometria+=os.clock()-inicio; geometrias+=1; return item
		end
		function sim:RegistrarMinerio(...)
			gerados+=1; return cadastro(self,...)
		end
		function sim:_Candidatos(...)
			local inicio=os.clock(); local a,b=candidatos(self,...)
			tempoConsultas+=os.clock()-inicio; return a,b
		end
		RS.Heartbeat:Wait()
		raiz:SetAttribute("Quantidade",quantidade); raiz:SetAttribute("Medindo",true)
		local duracao,quadros,trabalho,pico,picoEmissao,picoSem,consultas=0,0,0,0,0,0,0
		local picoQuente=0
		while duracao<(if quantidade==32 then 14 else 6) do
			local delta=RS.Heartbeat:Wait()
			local antes=gerados; tempoConsultas=0; tempoEmissao=0
			local inicio=os.clock(); fabrica:Avancar(delta); local custo=os.clock()-inicio
			duracao+=delta; quadros+=1; trabalho+=custo; consultas+=tempoConsultas; pico=math.max(pico,custo)
			if duracao>1 then picoQuente=math.max(picoQuente,custo) end
			if gerados>antes then
				picoEmissao=math.max(picoEmissao,custo)
				print("EMISSAO_ONDA",quantidade,"tempo_fisico",sim._passos*sim.Passo,"novos",gerados-antes,"quadro_ms",custo*1000,"criacao_ms",tempoEmissao*1000)
			else picoSem=math.max(picoSem,custo) end
		end
		local esperado=quantidade*math.ceil((sim._passos*sim.Passo-.000001)/2)
		raiz:SetAttribute("Medindo",false)
		assert(gerados==esperado,"A medicao perdeu ou duplicou emissoes.")
		local ultimoPasso=sim._passos-1
		local ondas=math.floor(ultimoPasso/240)+1
		assert(#sim._minerios==ondas*quantidade,"Sem perfil ativo, os minerios nao devem ser consumidos sem credito.")
		print("EMISSAO_CARGA",quantidade,"fps",quadros/duracao,"media_ms",trabalho/quadros*1000,
			"pico_ms",pico*1000,"pico_emissao_ms",picoEmissao*1000,"pico_sem_emissao_ms",picoSem*1000,
			"consultas_media_ms",consultas/quadros*1000,"atraso_s",sim._acumulado,"gerados",gerados,"vivos",#sim._minerios,"pico_apos_1s_ms",picoQuente*1000)
		local velocidade,solidos,regioes,apoiados=0,0,0,0
		for _,r in sim._minerios do velocidade=math.max(velocidade,r.Corpo.Velocidade.Magnitude); if r.Corpo._apoio then apoiados+=1 end end
		for _,grupo in sim._regioes do for _,regiao in grupo do if type(regiao)=="table" and regiao.Solidos then solidos=math.max(solidos,#regiao.Solidos); regioes+=1 end end end
		print("EMISSAO_DIAGNOSTICO","geometria_ms_quadro",tempoGeometria/quadros*1000,"geometrias_quadro",geometrias/quadros,
			"max_velocidade",velocidade,"max_solidos_regiao",solidos,"regioes",regioes,"apoiados",apoiados)
		fabrica:Destruir(); fabrica=nil; terrenos:Destroy(); task.wait()
	end
end,debug.traceback)
if fabrica then fabrica:Destruir() end
raiz:Destroy()
assert(ok,erro)
print("EMISSAO_CARGA_CONCLUIDA")
if S:FindFirstChild("TesteFisicaEmissao") then require(S.TesteFisicaEmissao) end
if S:FindFirstChild("TesteModificadoresEmissao") then require(S.TesteModificadoresEmissao) end
