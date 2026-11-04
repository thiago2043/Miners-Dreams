-- Command Bar do cliente no Play. A rede e substituida somente nesta instancia de teste.
local jogador=game.Players.LocalPlayer
local Controlador=require(jogador.PlayerScripts.Client.ControladorConstrucao)
local Geometria=require(game.ReplicatedStorage.Shared.GeometriaColocacao)
local Input=game:GetService("UserInputService")
local camera=workspace.CurrentCamera
local tipo,pose=camera.CameraType,camera.CFrame
local selecao=jogador:GetAttribute("MaquinaSelecionada")
local raiz=Instance.new("Folder"); raiz.Name="TesteArrasteColocacao"; raiz.Parent=workspace
local plot=Instance.new("Model"); plot:SetAttribute("DonoUserId",jogador.UserId); plot.Parent=raiz
local piso=Instance.new("Part"); piso.Name,piso.Size,piso.CFrame,piso.Anchored,piso.Parent="Piso",Vector3.new(48,1,48),CFrame.new(0,2000,0),true,plot
local maquinas=Instance.new("Folder"); maquinas.Name,maquinas.Parent="Maquinas",plot
local c=Controlador.new(jogador)
local ok,erro=xpcall(function()
	c._terreno,c._piso,c._maquinas,c._pastaTerrenos=plot,piso,maquinas,raiz
	c._EncontrarTerreno=function() return true end
	local chamadas={}
	c._redeConstrucao={fetch=function(_,metodo,...)
		table.insert(chamadas,{Metodo=metodo,Argumentos=table.pack(...)})
		return true,"Teste sem chamada de rede."
	end}
	camera.CameraType=Enum.CameraType.Scriptable
	local origem=Geometria.Origem(piso)
	local function apontar(ponto)
		local mundo=origem:PointToWorldSpace(ponto)
		local mouse=Input:GetMouseLocation()
		local base=CFrame.lookAt(mundo+Vector3.new(0,35,35),mundo)
		camera.CFrame=base
		local dir=base:VectorToObjectSpace(camera:ViewportPointToRay(mouse.X,mouse.Y).Direction)
		camera.CFrame=base*CFrame.lookAt(Vector3.zero,dir):Inverse()
	end
	local function preparar()
		c.Navegacao:Limpar()
		c._maquinaIdSelecionada,c._abaColocacao,c._rotacao="Esteira2x2","Loja",CFrame.identity
		c:IniciarColocacao()
		c.Navegacao:Abrir("Colocacao",function() c:EncerrarColocacao() end)
		apontar(Vector3.new(18,0,18)); c:Atualizar(.25)
		assert(c._alvoColocacao.minimo==Vector3.new(15,0,15),"Ancora inicial fora da celula escolhida.")
	end
	local entrada={UserInputType=Enum.UserInputType.MouseButton1}
	for _,dir in {Vector3.xAxis,-Vector3.xAxis,Vector3.zAxis,-Vector3.zAxis} do
		preparar()
		local antes=#chamadas
		c:ProcessarEntrada(entrada,false)
		assert(c._arrasteColocacao and #chamadas==antes)
		apontar(Vector3.new(18,0,18)+dir*12); c:Atualizar(1/60)
		local a=c._arrasteColocacao
		assert(#a.Alvos==3 and a.Alvos[3].minimo==Vector3.new(15,0,15)+dir*12)
		assert(a.Previas[1]._volumes==a.Previas[3]._volumes)
		for i,previa in a.Previas do
			assert(previa:ObterModelo().Parent==workspace and previa:ObterCaixa().Size==Vector3.new(6,3,6))
			assert(a.Alvos[i].rotacao==CFrame.identity and a.Alvos[i].livre)
		end
		c:FinalizarEntrada(entrada)
		assert(#chamadas==antes+1 and chamadas[#chamadas].Metodo=="ColocarMultiplos" and #chamadas[#chamadas].Argumentos[2]==3)
		assert(not c._arrasteColocacao and c._previa._volumes.Usuarios==1)
	end
	preparar(); c:ProcessarEntrada(entrada,false)
	local obstaculo=Instance.new("Model")
	obstaculo:SetAttribute("VolumeMinimo",Vector3.new(15,0,15)); obstaculo:SetAttribute("VolumeOcupado",Vector3.new(6,3,6)); obstaculo.Parent=maquinas
	c._previa:AtualizarVolumes(origem,.25)
	apontar(Vector3.new(30,0,18)); c:Atualizar(1/60)
	assert(not c._arrasteColocacao.Alvos[1].livre and c._arrasteColocacao.Alvos[2].livre)
	c:FinalizarEntrada(entrada); assert(chamadas[#chamadas].Metodo=="ColocarMultiplos")
	c.Navegacao:Limpar()
	local item={MaquinaId="Esteira2x2",Modificacoes={Dados={Nivel=7}},DeslocamentoInicial=Vector3.zero,RotacaoInicial=CFrame.identity}
	assert(c:_IniciarPreviaCopiaGrupo({Token=321,Pecas={item}},nil,1))
	obstaculo.Parent=nil
	apontar(Vector3.new(18,0,18)); c:Atualizar(.25)
	obstaculo.Parent=maquinas; c._previa:AtualizarVolumes(origem,.25)
	local antes=#chamadas
	c:ProcessarEntrada(entrada,false)
	assert(c._arrasteColocacao and #chamadas==antes,"Copia individual deve iniciar o gesto sem enviar.")
	apontar(Vector3.new(30,0,18)); c:Atualizar(1/60)
	local linhaCopia=c._arrasteColocacao.Alvos
	assert(#linhaCopia==3 and not linhaCopia[1].livre and linhaCopia[2].livre,
		string.format("Linha da copia: %d alvos, ancora %s livre=%s, segundo livre=%s.",#linhaCopia,tostring(linhaCopia[1].minimo),tostring(linhaCopia[1].livre),tostring(linhaCopia[2] and linhaCopia[2].livre)))
	assert(c._arrasteColocacao.Personalizacao:ObterDados().Dados.Nivel==7)
	c:FinalizarEntrada(entrada)
	assert(#chamadas==antes+1 and chamadas[#chamadas].Metodo=="ColocarMultiplos" and chamadas[#chamadas].Argumentos[3]==321)
	assert(not c._arrasteColocacao and c._previa._volumes.Usuarios==1)
	obstaculo:Destroy()
	preparar(); c:ProcessarEntrada(entrada,false)
	apontar(Vector3.new(30,0,18)); c:Atualizar(1/60)
	local antes=#chamadas
	c:ProcessarEntrada({KeyCode=Enum.KeyCode.Q,UserInputType=Enum.UserInputType.Keyboard},false)
	c:FinalizarEntrada(entrada)
	assert(not c._previa and not c._arrasteColocacao and #chamadas==antes)
	print("ARRASTE_COLOCACAO_STUDIO_OK",4,3,"direcoes/pecas por linha; raios e previas nativos, compartilhamento, envio ao soltar, ancora bloqueada e Q.")
end,debug.traceback)
c:Destruir(); raiz:Destroy()
jogador:SetAttribute("MaquinaSelecionada",selecao)
camera.CameraType,camera.CFrame=tipo,pose
assert(ok,erro)
