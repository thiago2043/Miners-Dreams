-- Executa os modulos reais com entrada, rede e widgets simulados; nao renderiza o Studio.
local roblox = require("./suporte/modelos")
local Instance, Vector3, CFrame = roblox.Instance, roblox.Vector3, roblox.CFrame

local function sinal()
	local evento = { conexoes = {} }
	function evento:Connect(callback)
		local conexao = { ativa = true, callback = callback }
		function conexao:Disconnect() self.ativa = false end
		table.insert(self.conexoes, conexao)
		return conexao
	end
	function evento:Fire(...)
		for _, conexao in self.conexoes do
			if conexao.ativa then conexao.callback(...) end
		end
	end
	function evento:Contar()
		local quantidade = 0
		for _, conexao in self.conexoes do if conexao.ativa then quantidade += 1 end end
		return quantidade
	end
	return evento
end

local widgets = {}
local function novaInstancia(classe)
	if classe == "BindableEvent" then
		local evento = { Event = sinal() }
		function evento:Fire(...) self.Event:Fire(...) end
		function evento:Destroy() self.destruido = true end
		return evento
	end
	if table.find({ "ScreenGui", "Frame", "ScrollingFrame", "TextLabel", "TextBox", "TextButton", "UIGradient", "UICorner", "UIStroke", "UIPadding", "UIGridLayout", "UITextSizeConstraint", "UISizeConstraint", "UIScale", "UIListLayout", "Highlight" }, classe) then
		local widget = { ClassName=classe,ChildAdded=sinal(), Activated = sinal(), InputBegan=sinal(), MouseEnter = sinal(), MouseLeave = sinal(),
			SelectionGained = sinal(), SelectionLost = sinal(), ZIndex = 1, sinaisPropriedade = {}, AbsoluteSize = roblox.Vector2.new(340, 210),
			AbsolutePosition = roblox.Vector2.zero, AbsoluteWindowSize = roblox.Vector2.new(340,210) }
		function widget:IsA(tipo) return tipo==self.ClassName or (tipo=="GuiObject" and table.find({"Frame","TextLabel","TextBox","TextButton","ScrollingFrame"},self.ClassName)~=nil) end
		if classe=="ScreenGui" then widget.AbsoluteSize=roblox.Vector2.new(1280,720) end
		function widget:GetPropertyChangedSignal(nome)
			self.sinaisPropriedade[nome] = self.sinaisPropriedade[nome] or sinal()
			return self.sinaisPropriedade[nome]
		end
		function widget:Destroy() self.destruido = true end
		function widget:GetChildren()
			local filhos = {}
			for _, candidato in widgets do
				if candidato.Parent == self then table.insert(filhos, candidato) end
			end
			return filhos
		end
		function widget:FindFirstChild(nome)
			for _, filho in self:GetChildren() do if filho.Name == nome then return filho end end
		end
		function widget:FindFirstChildOfClass(nome)
			for _,filho in self:GetChildren() do if filho.ClassName==nome then return filho end end
		end
		table.insert(widgets, widget)
		return widget
	end
	return Instance.new(classe)
end

local mundo = Instance.new("Workspace")
local modelos = Instance.new("Folder")
modelos.Name = "ModelosMaquinas"
local replicado = { ModelosMaquinas = modelos }
function replicado:WaitForChild(nome) return assert(self[nome]) end
local terrenos = Instance.new("Folder")
terrenos.Name, terrenos.Parent = "Terrenos", mundo
require("./suporte/catalogo_modelos")(modelos)
local players = { PlayerRemoving = sinal() }
local function jogador(id)
	local p = { Name = "Jogador" .. id, UserId = id, Parent = players, atributos = {}, sinais = {} }
	function p:GetAttribute(nome) return self.atributos[nome] end
	function p:GetAttributeChangedSignal(nome)
		if not self.sinais[nome] then self.sinais[nome] = sinal() end
		return self.sinais[nome]
	end
	function p:SetAttribute(nome, valor)
		local anterior = self.atributos[nome]
		self.atributos[nome] = valor
		if anterior ~= valor then self:GetAttributeChangedSignal(nome):Fire() end
	end
	p.gui=novaInstancia("Frame")
	function p:WaitForChild(nome) assert(nome == "PlayerGui"); return self.gui end
	return p
end
local p1, p2 = jogador(123), jogador(456)
p1:SetAttribute("ConfirmarVenda","Nunca")
p1:SetAttribute("ConfirmarRenascimento",false)
players.LocalPlayer = p1
local input, render, destruirScript = sinal(), sinal(), sinal()
local heartbeat = sinal()
local mudou, terminou, perdeuFoco = sinal(), sinal(), sinal()
local mouse = roblox.Vector2.zero
local teclas = {}
for _, nome in { "One", "Two", "Three", "Four", "Five", "B", "G", "E", "Q", "F", "T", "R", "X", "Y", "Z", "C", "V", "LeftShift", "RightShift", "LeftControl", "RightControl", "LeftAlt", "RightAlt" } do
	teclas[nome] = roblox.Enum.KeyCode[nome]
end
-- Lune nao interna EnumItems como o Roblox; usa as mesmas referencias nas chaves do teste.
local enums = setmetatable({ KeyCode = teclas }, { __index = roblox.Enum })
local raio = { Origin = Vector3.new(-12, 37.5, -12), Direction = -Vector3.yAxis }
local raioPorTela
local resultado
local raycastGeometrico
local camera = Instance.new("Camera")
mundo.CurrentCamera = camera
camera.CFrame = CFrame.identity
camera.ViewportSize = roblox.Vector2.new(800, 600)
roblox.implementMethod("Camera", "WorldToViewportPoint", function(_, p) return camera:GetAttribute("ProjecaoTeste") or Vector3.new(400 + p.X * 10, 300 - p.Y * 10, 100), true end)
roblox.implementMethod("Camera", "ViewportPointToRay", function(_, x, y)
	return raioPorTela and raioPorTela(x, y) or raio
end)
roblox.implementMethod("Workspace", "Raycast", function(...)
	if raycastGeometrico then return raycastGeometrico(...) end
	return resultado
end)
roblox.implementMethod("Workspace", "GetPartBoundsInBox", function(_, destino, tamanho, consulta)
	local encontrados = {}
	for _, pasta in (if consulta.FilterType==roblox.Enum.RaycastFilterType.Exclude then {mundo} else consulta.FilterDescendantsInstances) do
		for _, parte in pasta:IsA("BasePart") and {pasta} or pasta:GetDescendants() do
			if not parte:IsA("BasePart") or not (if consulta.RespectCanCollide then parte.CanCollide else parte.CanQuery) then continue end
			local delta = parte.CFrame.Position - destino.Position
			local metade = (parte.Size + tamanho) / 2
			if math.abs(delta.X) < metade.X and math.abs(delta.Y) < metade.Y and math.abs(delta.Z) < metade.Z then
				table.insert(encontrados, parte)
			end
		end
	end
	return encontrados
end)
local redes, tempo, teclasAtivas = {}, 0, {}
local acaoRodaSelecao
local depoisResposta
local networker = {
	server = { new = function(nome, servidor, metodos)
		redes[nome] = servidor
		for _, metodo in metodos do assert(type(metodo) == "function") end
	end },
	client = { new = function(nome)
		return { fetch = function(_, metodo, ...)
			local resposta = table.pack(redes[nome][metodo](redes[nome], p1, ...))
			if depoisResposta then depoisResposta(nome, metodo) end
			return table.unpack(resposta, 1, resposta.n)
		end }
	end },
}
local textoFocado = false
local carregar, no = require("./suporte/carregador")({
	workspace = mundo, Instance = { new = novaInstancia }, Enum = enums,
	Vector3 = Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, UDim = roblox.UDim,
	CFrame = CFrame, Color3 = roblox.Color3, ColorSequence = roblox.ColorSequence,
	TweenInfo = {new=function(...) return {...} end},
	ColorSequenceKeypoint = roblox.ColorSequenceKeypoint, typeof = roblox.typeof,
	RaycastParams = { new = function() return {} end }, OverlapParams = { new = function() return {} end },
	os = { clock = function() return tempo end }, print = function() end,
}, {
	Players = players, RunService = { RenderStepped = render, Heartbeat = heartbeat },
	Lighting={GetDescendants=function() return {} end,DescendantAdded=sinal(),DescendantRemoving=sinal()},
	ContextActionService = {
		BindActionAtPriority = function(_, _, callback) acaoRodaSelecao = callback end,
		UnbindAction = function() acaoRodaSelecao = nil end,
	},
		UserInputService = { InputBegan = input, InputChanged = mudou, InputEnded = terminou, WindowFocusReleased = perdeuFoco,
			IsKeyDown = function(_, tecla) return teclasAtivas[tecla] == true end,
			GetFocusedTextBox = function() return textoFocado and {} or nil end,
		GetMouseLocation = function() return mouse end },
	Debris = { AddItem = function() end },
	TweenService = {Create=function(_,objeto,_,destino) return {Play=function() for k,v in destino do objeto[k]=v end end} end},
	ReplicatedStorage = replicado,
	TextService = { GetTextSize = function() return roblox.Vector2.new(200, 80) end },
}, {
	["Packages/Networker"] = networker,
	-- A renderizacao das miniaturas tem teste isolado; este cenario verifica as acoes e os dados do jogo.
	["src/client/MiniaturaPeca"] = { new = function() return { Destruir = function() end } end },
	["src/client/MineriosVisuais"] = { new = function() return { Destruir = function() end } end },
	["src/client/PreferenciasVisuais"] = { new = function() return { Destruir = function() end } end },
	-- As entradas de toque/controle e o movimento remapeado possuem teste proprio.
	["src/client/ControlesPlataforma"] = {new=function() return {Destruir=function() end} end},
})
replicado.Shared, replicado.Packages = no("src/shared"), no("Packages")

local Terreno = carregar("src/server/Terreno")
local catalogo = carregar("src/shared/CatalogoMaquinas")
catalogo.EsteiraRapida = {
	Nome = "Esteira rapida", Preco = "50", Atalho = "Five",
	Componentes = { { Tipo = "Transportador", Parte = "Correia", Velocidade = 12 } },
}
local modeloRapido = modelos.Esteira2x2:Clone()
modeloRapido.Name, modeloRapido.Parent = "EsteiraRapida", modelos
local t1 = Terreno.new(1, CFrame.identity, terrenos, CFrame.new(0, 1, -29))
local t2 = Terreno.new(2, CFrame.new(100, 0, 0), terrenos, CFrame.new(100, 1, -29))
t1._modelo.Piso.Size=Vector3.new(48,1,48); t2._modelo.Piso.Size=Vector3.new(48,1,48)
assert(t1:Atribuir(p1) and t2:Atribuir(p2))
assert(not t1:Atribuir(p2))
do
	local Previa = carregar("src/client/PreviaConstrucao")
	local Personalizacao = carregar("src/shared/PersonalizacaoMaquina")
	local original = modelos.PrensaMinerio:Clone()
	local guia,efeito = Instance.new("Part"),Instance.new("Part")
	guia.Name,guia.Size,guia.CFrame,guia.Transparency,guia.Parent = "GuiaTeste",original.PrimaryPart.Size,original.PrimaryPart.CFrame,1,original
	guia:SetAttribute("GuiaPosicionamento",true)
	guia:SetAttribute("TransparenciaPrevia",.65)
	efeito.Name,efeito.Size,efeito.CFrame,efeito.Transparency,efeito.Parent = "EfeitoTeste",original.PrimaryPart.Size,original.PrimaryPart.CFrame,.2,original
	efeito:SetAttribute("EfeitoOperacao",true)
	local particulas = Instance.new("ParticleEmitter")
	particulas.Name,particulas.Enabled,particulas.Parent = "JatoTeste",true,efeito
	local pasta = Instance.new("Folder")
	local previa = Previa.new(original,Personalizacao.new(),catalogo.PrensaMinerio,pasta)
	local clone = previa:ObterModelo()
	assert(math.abs(clone.GuiaTeste.Transparency-.65)<.0001 and clone.EfeitoTeste.Transparency==1 and not clone.EfeitoTeste.JatoTeste.Enabled)
	assert(guia.Transparency==1 and math.abs(efeito.Transparency-.2)<.0001 and particulas.Enabled,
		"A previa nao pode alterar a visibilidade do modelo colocado.")
	previa:Destruir(); original:Destroy(); pasta:Destroy()
end
assert(#terrenos.Terreno_1.Maquinas:GetChildren() == 0 and #terrenos.Terreno_2.Maquinas:GetChildren() == 0)
assert(not mundo:FindFirstChild("MineradoraBasica") and not mundo:FindFirstChild("PrensaMinerio"))
local perfil = { Data = { Dinheiro = "10000", Inventory = {
	MineradoraBasica = 0, Esteira2x2 = 0, FornalhaBasica = 0, PrensaMinerio = 0,
	EsteiraRapida = 0,
}, MaquinasColocadas = {}, Blueprints = {} } }
for id in catalogo do if perfil.Data.Inventory[id] == nil then perfil.Data.Inventory[id] = 0 end end
function perfil:IsActive() return true end
local manager = carregar("src/server/Data/DataManager")
manager.RegistrarPerfil(p1, perfil):Sincronizar()
carregar("src/server/Construcao")
carregar("src/server/Loja.server")
local Controlador = carregar("src/client/ControladorConstrucao")
local Interface = carregar("src/client/InterfaceJogo")
local c1, c2 = Controlador.new(p1), Controlador.new(p2)
local interface = Interface.new(p1, c1)
assert(interface._botoesAbas.Configuracoes:ObterInstancia().Parent==interface._menuDireito)
assert(interface._botoesAbas.Classificacao:ObterInstancia().Parent==interface._menuDireito)
assert(interface._botoesAbas.Loja:ObterInstancia().Parent==interface._menuAbas)
assert(interface._botoesAbas.Craft:ObterInstancia().Parent==interface._menuAbas)
assert(interface._botoesAbas.Blueprints:ObterInstancia().Parent==interface._menuDireito)
assert(interface._botoesAbas.Blueprints:ObterInstancia().LayoutOrder==interface._botoesAbas.Configuracoes:ObterInstancia().LayoutOrder+1)
assert(interface._menuDireito.Position.X.Scale==1)
;(function()
	local tutorial=interface._paineisProgressao.Tutorial
	local b=interface._botoesAbas.Tutorial:ObterInstancia()
	assert(b.Parent==interface._menuDireito and b.LayoutOrder<interface._botoesAbas.Classificacao:ObterInstancia().LayoutOrder)
	assert(interface._botoesAbas.Classificacao:ObterInstancia().LayoutOrder<interface._botoesAbas.Configuracoes:ObterInstancia().LayoutOrder)
	b.MouseEnter:Fire(); assert(interface._dicaAba.Text=="Tutorial" and interface._dicaAba.Position.Y.Offset==-99)
	b.MouseLeave:Fire()
	p1:SetAttribute("Administrador",true)
	b.MouseEnter:Fire(); assert(interface._dicaAba.Position.Y.Offset==-132)
	b.MouseLeave:Fire(); p1:SetAttribute("Administrador",false)
	b.Activated:Fire()
	assert(tutorial._grupo.Visible and c1.Navegacao:Atual()=="Tutorial")
	for _,tipo in {roblox.Enum.UserInputType.MouseButton1,roblox.Enum.UserInputType.MouseButton3} do
		c1:ProcessarEntrada({UserInputType=tipo,KeyCode=roblox.Enum.KeyCode.Unknown},false)
		c1:FinalizarEntrada({UserInputType=tipo,KeyCode=roblox.Enum.KeyCode.Unknown})
	end
	c1:ProcessarEntrada({UserInputType=roblox.Enum.UserInputType.Keyboard,KeyCode=roblox.Enum.KeyCode.Z},false)
	assert(not c1._modoSelecao and not c1._previa and c1.Navegacao:Atual()=="Tutorial","O tutorial deve bloquear a construcao no mundo.")
	assert(c1:AlternarPainelCentral("Upgrades") and not tutorial._grupo.Visible)
	b.Activated:Fire(); assert(tutorial._grupo.Visible and not interface._paineisProgressao.Upgrades._grupo.Visible)
	c1:ProcessarEntrada({UserInputType=roblox.Enum.UserInputType.Keyboard,KeyCode=roblox.Enum.KeyCode.Q},false)
	assert(not tutorial._grupo.Visible and not c1.Navegacao:Atual())
	b.Activated:Fire(); tutorial._janela._fechar:ObterInstancia().Activated:Fire()
	assert(not tutorial._grupo.Visible and not c1.Navegacao:Atual())
	print("PASS: Tutorial acima de Classificacao/Configuracoes, dicas com/sem ADM, clique/atalhos bloqueados, troca de paineis e fechamento.")
end)()
do
	local esquerda, direita = interface._menuAbas, interface._menuDireito
	local lista = interface._paineis.Loja._painelLista
	local a, b, c = esquerda.AbsolutePosition, esquerda.AbsoluteSize, direita.AbsolutePosition
	local d, e, f, visivel = direita.AbsoluteSize, lista.AbsolutePosition, lista.AbsoluteSize, lista.Visible
	esquerda.AbsolutePosition, esquerda.AbsoluteSize = roblox.Vector2.new(0,100), roblox.Vector2.new(56,120)
	direita.AbsolutePosition, direita.AbsoluteSize = roblox.Vector2.new(244,100), roblox.Vector2.new(56,120)
	lista.AbsolutePosition, lista.AbsoluteSize, lista.Visible = roblox.Vector2.new(100,60), roblox.Vector2.new(200,300), true
	lista:GetPropertyChangedSignal("AbsolutePosition"):Fire()
	assert(esquerda.Visible and not direita.Visible, "A loja nao pode ser coberta pelo menu direito.")
	lista.AbsolutePosition = roblox.Vector2.new(65,60)
	interface:_AtualizarMenusLaterais(); assert(esquerda.Visible and not direita.Visible)
	lista.AbsolutePosition, lista.AbsoluteSize = roblox.Vector2.new(80,60), roblox.Vector2.new(100,300)
	interface:_AtualizarMenusLaterais(); assert(esquerda.Visible and direita.Visible, "Sem sobreposicao, os botoes devem permanecer disponiveis.")
	lista.AbsolutePosition, lista.AbsoluteSize = roblox.Vector2.new(0,60), roblox.Vector2.new(300,300)
	interface:_AtualizarMenusLaterais(); assert(not esquerda.Visible and not direita.Visible)
	lista.Visible = false; lista:GetPropertyChangedSignal("Visible"):Fire(); assert(esquerda.Visible and direita.Visible)
	esquerda.AbsolutePosition, esquerda.AbsoluteSize, direita.AbsolutePosition, direita.AbsoluteSize = a, b, c, d
	lista.AbsolutePosition, lista.AbsoluteSize, lista.Visible = e, f, visivel
end
assert(interface._interface.ZIndexBehavior==roblox.Enum.ZIndexBehavior.Sibling)
do
	local fundo=math.max(interface._paineis.Inventario._grupo.ZIndex,interface._paineis.Loja._grupo.ZIndex)
	assert(interface._painelBlueprints._grupo.ZIndex>fundo)
	for _,painel in interface._paineisProgressao do
		assert(painel._grupo.ZIndex>fundo,"Painel central deve cobrir os icones e quantidades das abas ao fundo.")
	end
end
c1:Iniciar()
c1:Iniciar()
assert(input:Contar() >= 2 and render:Contar() == 2)
local function tecla(nome)
	input:Fire({ KeyCode = teclas[nome], UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
	if nome == "R" then terminou:Fire({ KeyCode = teclas[nome], UserInputType = roblox.Enum.UserInputType.Keyboard }) end
end
local function clique()
	tempo += 1
	local entrada = { UserInputType = roblox.Enum.UserInputType.MouseButton1 }
	input:Fire(entrada, false)
	if c1._arrasteColocacao or c1._modoSelecao == "Selecao" or c1._modoSelecao == "Recolhimento" or c1._modoSelecao == "Venda"
		or ((c1._modoSelecao == "Movimentacao" or c1._modoSelecao == "Copia") and not c1._movimento)
	then
		terminou:Fire(entrada)
	end
end
local function quadro()
	tempo += 0.25
	heartbeat:Fire(0.25)
	render:Fire(0.25)
	if c1._gradeTerreno then
		assert(c1._gradeTerreno._visivel==(c1._previa~=nil),"A grade so aparece durante a colocacao.")
		assert(math.abs(c1._gradeTerreno._pisoTextura.Transparency-(if c1._previa then .384 else 1))<.000001)
		for _,linha in c1._gradeTerreno._linhas do
			assert(linha.Transparency==1 and linha.Traco.Transparency==(if c1._gradeTerreno._visibilidade[linha.Parent] then 0 else 1))
		end
	end
end
local function iniciarArraste(inicio)
	mouse = inicio
	local entrada = { UserInputType = roblox.Enum.UserInputType.MouseButton1 }
	input:Fire(entrada, false)
	return entrada
end
local function moverArraste(fim)
	mouse = fim
	mudou:Fire({ UserInputType = roblox.Enum.UserInputType.MouseMovement })
	assert(c1._caixaSelecao.Parent == mundo, "O volume 3D deve aparecer depois de arrastar o mouse.")
end
local function terminarArraste(entrada)
	terminou:Fire(entrada)
end
local function rolarSelecao(delta, shift)
	teclasAtivas[teclas.LeftShift] = shift == true
	assert(acaoRodaSelecao, "A roda deve ser capturada durante o arraste da selecao.")
	local resposta = acaoRodaSelecao("Selecao", "Change", {
		UserInputType = roblox.Enum.UserInputType.MouseWheel,
		Position = Vector3.new(0, 0, delta),
	})
	assert(resposta == roblox.Enum.ContextActionResult.Sink, "O scroll nao deve alterar o zoom da camera durante a selecao.")
	teclasAtivas[teclas.LeftShift] = false
end
local inventario, loja = interface._paineis.Inventario, interface._paineis.Loja
local plot = terrenos:FindFirstChild("Terreno_1")
do
	local function testarSelecaoDosModelos()
		local teste=Controlador.new(p1)
		local pasta=Instance.new("Folder"); pasta.Parent=plot
		teste._maquinas,teste._terreno,teste._piso=pasta,plot,plot.Piso
		teste._EncontrarTerreno=function() return true end
		local anterior=raio
		local geometria=carregar("src/shared/GeometriaColocacao")
		raycastGeometrico=function(_,inicio,deslocamento,consulta)
			local alvo,menor
			local direcao=deslocamento.Unit
			for _, raiz in consulta.FilterDescendantsInstances do
				for _, p in raiz:GetDescendants() do
					if not p:IsA("BasePart") or not (if consulta.RespectCanCollide then p.CanCollide else p.CanQuery) then continue end
					local _,distancia=geometria.PontoNaCaixa({Origin=inicio,Direction=direcao},p.CFrame,p.Size,deslocamento.Magnitude)
					if distancia and (not menor or distancia<menor) then alvo,menor=p,distancia end
				end
			end
			return alvo and {Instance=alvo,Position=inicio+direcao*menor,Distance=menor,Normal=Vector3.yAxis}
		end
		local total,semColisao=0,0
		for _, original in modelos:GetChildren() do
			if original==modeloRapido then continue end
			local m=original:Clone()
			m:SetAttribute("DonoUserId",p1.UserId); m:SetAttribute("TerrenoId",plot:GetAttribute("TerrenoId")); m:SetAttribute("PodeRecolher",true)
			m.Parent=pasta
			local corpo,solidos
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") then
					if p.CanCollide then solidos=true end
					if p.CanQuery and p.Transparency<1 and (not corpo or p.Size.Magnitude>corpo.Size.Magnitude) then corpo=p end
				end
			end
			assert(corpo,"Modelo sem corpo consultavel: "..m.Name)
			raio={Origin=corpo.CFrame.Position+Vector3.yAxis*60,Direction=-Vector3.yAxis}
			assert(teste:_MaquinaSobMouse()==m,"O clique precisa encontrar o corpo de "..m.Name..", mesmo sem colisao.")
			local entrada={UserInputType=roblox.Enum.UserInputType.MouseButton1}
			teste:ProcessarEntrada(entrada,false); teste:FinalizarEntrada(entrada)
			assert(teste._pecaFocada==m and teste.Navegacao:Contem("MenuPeca"),"O clique deve abrir o menu de "..m.Name)
			teste.Navegacao:Fechar("MenuPeca"); teste:EncerrarSelecaoTerreno()
			m:SetAttribute("DonoUserId",p2.UserId); assert(not teste:_MaquinaSobMouse(),"Peca de outro dono nao deve ser aceita.")
			m:SetAttribute("DonoUserId",p1.UserId); m:SetAttribute("TerrenoId",-1); assert(not teste:_MaquinaSobMouse(),"Peca de outra plot nao deve ser aceita.")
			if not solidos then semColisao+=1 end
			total+=1; m:Destroy()
		end
		assert(total==91 and semColisao==6,"Modelos verificados: "..total.."; sem colisao: "..semColisao)
		teste:Destruir(); pasta:Destroy(); raio=anterior
		raycastGeometrico=nil
		print("PASS: raios geometricos selecionam os 91 modelos e abrem o menu, incluindo seis sem colisao; dono e terreno continuam validados.")
	end
	testarSelecaoDosModelos()
end
local function maquinaNoLocal(maquinaId, minimo)
	for _, maquina in plot.Maquinas:GetChildren() do
		if maquina.Name == maquinaId and maquina:GetAttribute("VolumeMinimo") == minimo then return maquina end
	end
	return nil
end
resultado = { Instance = plot.Piso, Position = Vector3.new(-12, 0.5, -12), Normal = Vector3.yAxis, Distance = 49.5 }
local function clicarPeca(painel, id, intervalo)
	tempo += intervalo or 0.5
	input:Fire({ UserInputType = roblox.Enum.UserInputType.MouseButton1 }, true)
	painel._botoesPecas[id]:ObterInstancia().Activated:Fire()
end
local function verificarAbasFechadas()
	assert(not inventario._painelLista.Visible and not loja._painelLista.Visible)
	assert(not inventario._painelFicha.Visible and not loja._painelFicha.Visible)
	assert(not c1.Navegacao:Contem("Inventario") and not c1.Navegacao:Contem("Loja"))
	assert(not c1.Navegacao:Contem("FichaInventario") and not c1.Navegacao:Contem("FichaLoja"))
	assert(c1._previa and c1.Navegacao:Atual() == "Colocacao")
end
local function comprar(id)
	c1:SelecionarMaquina(id, "Loja")
	tempo += 1
	loja._acoes.Comprar:ObterInstancia().Activated:Fire()
end
local atalhosIds = { One = "MineradoraBasica", Two = "Esteira2x2", Three = "FornalhaBasica", Four = "PrensaMinerio", Five = "EsteiraRapida" }
local function selecionarParaColocar(teclaPeca)
	local id = atalhosIds[teclaPeca]
	if perfil.Data.Inventory[id] == 0 then comprar(id) end
	assert(c1:SelecionarMaquina(id, "Inventario"))
	assert(c1.Navegacao:Atual() == "FichaInventario" and not c1._previa)
	inventario._acoes.Colocar:ObterInstancia().Activated:Fire()
	assert(c1.Navegacao:Atual() == "Colocacao" and c1._previa)
end
assert(not inventario._painelLista.Visible and not loja._painelLista.Visible)
for _, nome in {"One", "Two", "Three"} do
	tecla(nome)
	assert(not c1.Navegacao:Atual() and not c1._previa, "Numeros nao devem selecionar pecas iniciais.")
end
tecla("B"); assert(c1.Navegacao:Atual() == "Blueprints"); tecla("Q"); tecla("G")
assert(not c1.Navegacao:Atual())
tecla("E"); tecla("F")
assert(inventario._painelLista.Visible and loja._painelLista.Visible)
for _, nome in {"One", "Two", "Three"} do
	tecla(nome)
	assert(not inventario._painelFicha.Visible and not loja._painelFicha.Visible and not c1._previa)
end
assert(inventario._grupo.AnchorPoint.X == 0 and loja._grupo.AnchorPoint.X == 1)
assert(inventario._painelLista.AnchorPoint.X == 0 and inventario._painelFicha.AnchorPoint.X == 1)
assert(loja._painelFicha.AnchorPoint.X == 0 and loja._painelLista.AnchorPoint.X == 1)
assert(inventario._textoVazio.Visible and not inventario._painelFicha.Visible and not loja._painelFicha.Visible)
clicarPeca(loja, "MineradoraBasica")
local selecaoProtegida = c1:ObterSelecao("Loja")
assert(not pcall(function() selecaoProtegida.MaquinaId = "Esteira2x2" end))
local definicaoIsolada = c1:ObterDefinicaoSelecionada("Loja")
definicaoIsolada.Componentes[1].Intervalo = 999
assert(catalogo.MineradoraBasica.Componentes[1].Intervalo == 2)
assert(c1:ObterDefinicaoSelecionada("Loja").Componentes[1].Intervalo == 2)
assert(loja._painelFicha.Visible and loja._painelLista.Visible and inventario._painelLista.Visible)
assert(not c1._previa and perfil.Data.Dinheiro == "10000")
assert(loja._acoes.Comprar and not loja._acoes.Colocar and not loja._acoes.Vender)
clicarPeca(loja, "FornalhaBasica", 0.1)
clicarPeca(loja, "MineradoraBasica", 0.1)
assert(not c1._previa, "Cliques em pecas diferentes nao formam clique duplo.")
clicarPeca(loja, "MineradoraBasica", 0.5)
assert(not c1._previa, "Dois cliques lentos nao podem iniciar a colocacao.")
clicarPeca(loja, "MineradoraBasica", 0.1)
assert(c1._previa and c1.Navegacao:Atual() == "Colocacao")
assert(perfil.Data.Dinheiro == "10000" and perfil.Data.Inventory.MineradoraBasica == 0)
verificarAbasFechadas()
tecla("Q")
assert(not c1._previa and not c1.Navegacao:Atual())
comprar("MineradoraBasica")
assert(perfil.Data.Dinheiro == "9900" and perfil.Data.Inventory.MineradoraBasica == 1)
tecla("E")
clicarPeca(inventario, "MineradoraBasica")
assert(inventario._painelFicha.Visible and loja._painelFicha.Visible and not c1._previa)
assert(inventario._acoes.Colocar and inventario._acoes.Vender and not inventario._acoes.Comprar)
inventario._acoes.Vender:ObterInstancia().Activated:Fire()
assert(perfil.Data.Dinheiro == "10000" and perfil.Data.Inventory.MineradoraBasica == 0)
assert(not inventario._acoes.Colocar:ObterInstancia().Active and not inventario._acoes.Vender:ObterInstancia().Active)
comprar("MineradoraBasica")
clicarPeca(inventario, "MineradoraBasica")
assert(not c1._previa)
inventario._acoes.Colocar:ObterInstancia().Activated:Fire()
verificarAbasFechadas()
tecla("Q")
assert(not c1._previa and not c1.Navegacao:Atual())
tecla("E")
clicarPeca(inventario, "MineradoraBasica")
clicarPeca(inventario, "MineradoraBasica", 0.1)
assert(c1._previa and c1._abaColocacao == "Inventario")
verificarAbasFechadas()
quadro()
assert(c1._previa:ObterModelo().Parent == mundo and not c2._previa and c1._alvoColocacao.livre)
tecla("R"); render:Fire(1 / 60); quadro()
local rotacaoColocada = c1._alvoColocacao.rotacao
clique()
assert(#perfil.Data.MaquinasColocadas == 1 and perfil.Data.Dinheiro == "9900")
quadro()
assert((c1._alvoColocacao.rotacao.RightVector - rotacaoColocada.RightVector).Magnitude < 0.0001)
clique()
assert(#perfil.Data.MaquinasColocadas == 2 and perfil.Data.Dinheiro == "9800")
tecla("Q")
assert(not c1._previa and not c1.Navegacao:Atual() and c1._rotacao == CFrame.identity)
c1:SelecionarMaquina("MineradoraBasica", "Loja")
c1:SelecionarMaquina("MineradoraBasica", "Inventario")
assert(not c1._previa and inventario._painelFicha.Visible and loja._painelFicha.Visible)
tecla("Q")
assert(not inventario._painelFicha.Visible and loja._painelFicha.Visible)
tecla("E")
assert(not inventario._painelLista.Visible and loja._painelLista.Visible and loja._painelFicha.Visible)
tecla("E")
assert(inventario._painelLista.Visible and loja._painelLista.Visible)
tecla("F")
assert(not loja._painelLista.Visible and not loja._painelFicha.Visible and inventario._painelLista.Visible)
print("PASS: E/F independentes, quatro paineis orientados para o centro, fichas preservam listas e Q fecha a selecao mais recente.")

tecla("Z")
assert(inventario._painelLista.Visible and c1._modoSelecao == "Recolhimento")
for _ = 1, 2 do
	local modelo = plot.Maquinas:GetChildren()[1]
	resultado = { Instance = modelo:FindFirstChildWhichIsA("BasePart", true) }
	quadro(); clique()
end
assert(#perfil.Data.MaquinasColocadas == 0 and perfil.Data.Inventory.MineradoraBasica == 2)
tecla("Q")
assert(c1._modoSelecao == nil and inventario._painelLista.Visible)
resultado = { Instance = plot.Piso, Position = Vector3.new(-12, 0.5, -12), Normal = Vector3.yAxis, Distance = 49.5 }
selecionarParaColocar("Two")
quadro()
tecla("T")
assert(c1._travamentoAltura and c1._travamentoAltura.altura == c1._alvoColocacao.minimo.Y)
for _ = 1, 3 do tecla("R"); quadro() end
assert(c1._alvoColocacao.minimo.Y == c1._travamentoAltura.altura)
tecla("T")
local anterior = c1._previa:ObterCaixa().CFrame.Position
resultado = { Instance = plot.Piso, Position = Vector3.new(12, 0.5, 12), Normal = Vector3.yAxis, Distance = 10 }
render:Fire(1 / 60)
assert((c1._previa:ObterCaixa().CFrame.Position - anterior).Magnitude > 0)
assert((c1._previa:ObterCaixa().CFrame.Position - c1._alvoColocacao.volumeDestino.Position).Magnitude
	< (anterior - c1._alvoColocacao.volumeDestino.Position).Magnitude * 0.5,
	"previsualizacao deve acompanhar o cursor sem atraso excessivo")
assert((c1._previa:ObterCaixa().CFrame.Position - c1._alvoColocacao.volumeDestino.Position).Magnitude > 0.01,
	"previsualizacao deve continuar suavizada sem teletransportar")
resultado = nil
raio = { Origin = Vector3.new(0, 22.5, 0), Direction = Vector3.new(1, -0.01, 0).Unit }
quadro()
assert(c1._previa:ObterModelo().Parent == mundo and c1._alvoColocacao.minimo.X <= 64)
local ultimo = c1._alvoColocacao
raio = { Origin = Vector3.new(0, 22.5, 0), Direction = Vector3.yAxis }
quadro()
assert(c1._alvoColocacao ~= ultimo and c1._alvoColocacao.minimo.Y + c1._alvoColocacao.ocupado.Y <= 48.001)
selecionarParaColocar("Five")
quadro()
assert(c1._previa:ObterModelo().Name == "PreviaEsteiraRapida")
-- O clique do arraste nao pode colocar/comprar, nem virar um toque de 90 graus ao soltar R.
quadro()
local antesArraste = #perfil.Data.MaquinasColocadas
local saldoArraste = perfil.Data.Dinheiro
local caixaArraste = c1._previa:ObterCFrameVisual()
local centroTela = camera:WorldToViewportPoint(caixaArraste.Position)
mouse = roblox.Vector2.new(centroTela.X, centroTela.Y)
raio = { Origin = caixaArraste.Position + Vector3.new(0, 75, 0), Direction = -Vector3.yAxis }
input:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
clique()
assert(c1._arraste and c1._rPressionado)
local minimoArraste = c1._ancoraRotacao.minimo
local centroArraste = c1._ancoraRotacao.caixaDestino.Position
local rotacaoInicial = c1._rotacao
local _, volumeAntesArraste = c1._previa:ObterVolume():Calcular(c1._rotacao)
local gesto = c1._arraste
mouse += roblox.Vector2.new(32, 0)
mudou:Fire({ UserInputType = roblox.Enum.UserInputType.MouseMovement })
assert(c1._rotacao == rotacaoInicial, "32 pixels nao devem disparar um giro.")
mouse += roblox.Vector2.new(16, 0)
mudou:Fire({ UserInputType = roblox.Enum.UserInputType.MouseMovement })
render:Fire(1 / 60)
local primeiroEixo = c1._rotacao
assert((primeiroEixo.RightVector - rotacaoInicial.RightVector).Magnitude > 0.1,
	"O arraste deve alterar a orientacao logica por um passo da grade.")
assert((c1._previa:ObterCFrameVisual().RightVector - c1._alvoColocacao.caixaDestino.RightVector).Magnitude > 0.1
	and (c1._previa:ObterCFrameVisual().RightVector - caixaArraste.RightVector).Magnitude > 0.1,
	"A previa deve animar o giro sem saltar diretamente para a orientacao final.")
assert(c1._previa:ObterCaixa().Size == c1._alvoColocacao.ocupado)
local centroDepois = c1._alvoColocacao.caixaDestino.Position
assert(math.abs(centroDepois.X - centroArraste.X) <= 2.0001 and math.abs(centroDepois.Z - centroArraste.Z) <= 2.0001)
for _ = 1, 3 do
	mouse += roblox.Vector2.new(96, 0)
	mudou:Fire({ UserInputType = roblox.Enum.UserInputType.MouseMovement })
	render:Fire(1 / 60)
end
assert((c1._rotacao.RightVector - rotacaoInicial.RightVector).Magnitude < 0.0001)
assert((c1._rotacao.UpVector - rotacaoInicial.UpVector).Magnitude < 0.0001)
assert(c1._alvoColocacao.minimo == minimoArraste, "Uma volta completa nao deve deslocar a origem de colocacao.")
tecla("T")
local alturaDuranteGiro = c1._travamentoAltura.altura
mouse += roblox.Vector2.new(0, 48)
mudou:Fire({ UserInputType = roblox.Enum.UserInputType.MouseMovement })
render:Fire(1 / 60)
local rotacaoArrastada = c1._rotacao
assert(c1._arraste == gesto, "Trocar de eixo nao deve exigir outro clique.")
assert((rotacaoArrastada.UpVector - primeiroEixo.UpVector).Magnitude > 0.01)
assert(c1._alvoColocacao.minimo.Y == math.min(alturaDuranteGiro, 48 - c1._alvoColocacao.ocupado.Y))
assert(c1._previa:ObterCaixa().Size == c1._alvoColocacao.ocupado)
tecla("T")
local volumeDepoisArraste = c1._alvoColocacao.ocupado
assert(volumeAntesArraste.X * volumeAntesArraste.Y * volumeAntesArraste.Z
	== volumeDepoisArraste.X * volumeDepoisArraste.Y * volumeDepoisArraste.Z)
assert(carregar("src/shared/RotacaoConstrucao").ValidarNaGrade(rotacaoArrastada))
assert(#perfil.Data.MaquinasColocadas == antesArraste and perfil.Data.Dinheiro == saldoArraste)
terminou:Fire({ UserInputType = roblox.Enum.UserInputType.MouseButton1 })
terminou:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard })
assert(not c1._arraste and not c1._rPressionado)
assert((c1._rotacao.RightVector - rotacaoArrastada.RightVector).Magnitude < 0.0001)
input:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
perdeuFoco:Fire()
terminou:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard })
assert(not c1._rPressionado and (c1._rotacao.RightVector - rotacaoArrastada.RightVector).Magnitude < 0.0001)
print("PASS: giro logico de 90 graus com previa suave, centro na grade, volta sem deriva e altura T preservada.")
print("PASS: R + arraste troca de eixo sem soltar, nao coloca nem cobra; liberacao e perda de foco corretas.")

do
	local rotAntes=c1._rotacao
	local raioAntes,resultadoAntes,alvoAntes=raio,resultado,c1._alvoColocacao
	raio={Origin=Vector3.new(0, 75, 0),Direction=-Vector3.yAxis}
	resultado={Instance=plot.Piso,Position=Vector3.new(0,.5,0),Normal=Vector3.yAxis,Distance=99.5}
	for i=1,8 do
		c1:Girar("X"); quadro()
		assert(carregar("src/shared/RotacaoConstrucao").ValidarNaGrade(c1._rotacao,catalogo.EsteiraRapida))
		if i==1 then assert(c1._previa:ObterModelo():GetAttribute("InclinacaoEsteira")) end
	end
	assert((c1._rotacao.UpVector-rotAntes.UpVector).Magnitude<.001)
	assert(not c1._previa:ObterModelo():GetAttribute("InclinacaoEsteira"))
	assert(#perfil.Data.MaquinasColocadas==antesArraste and perfil.Data.Dinheiro==saldoArraste)
	raio,resultado,c1._alvoColocacao=raioAntes,resultadoAntes,alvoAntes
end
print("PASS: X inclina a esteira em passos de 45 graus, recompõe a previa e volta sem deriva nem cobranca.")

input:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
assert(c1.Navegacao:Atual() == "Rotacao")
tecla("Q")
assert(c1.Navegacao:Atual() == "Colocacao" and c1._previa and not c1._rPressionado)
terminou:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard })
assert(c1._rotacao == rotacaoArrastada, "Q durante R nao pode aplicar outro giro ao soltar R.")
textoFocado = true
tecla("Q")
assert(c1.Navegacao:Atual() == "Colocacao", "Q no chat nao deve cancelar a acao.")
textoFocado = false
input:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
local fechouTela = false
c1.Navegacao:Abrir("TelaDeTeste", function() fechouTela = true end)
local antesTela = #perfil.Data.MaquinasColocadas
clique()
assert(#perfil.Data.MaquinasColocadas == antesTela, "Uma tela sobreposta nao pode clicar na construcao abaixo.")
terminou:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard })
assert(c1.Navegacao:Atual() == "TelaDeTeste" and not c1.Navegacao:Contem("Rotacao"))
assert(c1._rotacao == rotacaoArrastada, "Soltar R sob uma nova tela nao pode gira-la nem fechar essa tela.")
tecla("Q")
assert(fechouTela and c1.Navegacao:Atual() == "Colocacao" and c1._previa)
print("PASS: Q sai de R sem giro extra, respeita caixa de texto e cancela um estado novo sem alterar o controlador.")

local alvoGirado = c1._alvoColocacao
assert(alvoGirado.livre)
clique()
assert(#perfil.Data.MaquinasColocadas == antesArraste + 1)
local colocadaGirando = plot.Maquinas:GetChildren()[1]
assert(colocadaGirando.Name == "EsteiraRapida")
local caixaColocada = colocadaGirando:GetBoundingBox()
assert((caixaColocada.Position - alvoGirado.caixaDestino.Position).Magnitude < 0.0001)
assert((caixaColocada.RightVector - alvoGirado.caixaDestino.RightVector).Magnitude < 0.0001)
assert((caixaColocada.UpVector - alvoGirado.caixaDestino.UpVector).Magnitude < 0.0001)
tempo += 1
assert(redes.Construcao:Recolher(p1, colocadaGirando))
assert(#perfil.Data.MaquinasColocadas == antesArraste)
print("PASS: servidor aceita a posicao centralizada e cria a peca na orientacao exibida pela previa.")

-- C usa a mesma selecao 3D do mover, destaca em azul e coloca uma copia sem retirar a fonte.
tempo += 1
assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.zero, CFrame.Angles(0, math.pi / 2, 0)))
local fonte = plot.Maquinas:GetChildren()[1]
local okPersonalizar, mensagemPersonalizar, fonteNova = redes.Construcao.Personalizar(p1, fonte, {
	Configuracao = { Componentes = { { Velocidade = 13 } } }, Dados = { Melhoria = 3 },
})
assert(okPersonalizar, mensagemPersonalizar)
fonteNova.Correia.Color = roblox.Color3.fromRGB(210, 70, 40)
resultado = { Instance = fonteNova.Correia }
tecla("C")
assert(c1._modoSelecao == "Copia" and c1._caixaSelecao.Color.B > 0.9
	and c1._destaqueSelecao.FillColor.B > 0.9)
quadro(); clique()
assert(c1._movimento and c1._movimento.Copia and fonteNova.Parent == plot.Maquinas)
assert(c1._previa:ObterModelo().Correia.Color == fonteNova.Correia.Color)
resultado = { Instance = plot.Piso, Position = Vector3.new(12, 0.5, 12), Normal = Vector3.yAxis, Distance = 10 }
raio = { Origin = Vector3.new(12, 75, 12), Direction = -Vector3.yAxis }
quadro()
local saldoAntesCopia = perfil.Data.Dinheiro
clique()
assert(#perfil.Data.MaquinasColocadas == antesArraste + 2)
assert(perfil.Data.Dinheiro == carregar("src/server/InteiroGrande").subtrair(saldoAntesCopia, "25"))
assert(fonteNova.Parent == plot.Maquinas and c1._previa and c1._movimento.Copia)
local criadaCopia = plot.Maquinas:GetChildren()[#plot.Maquinas:GetChildren()]
assert(criadaCopia.Correia.Color == fonteNova.Correia.Color)
assert(carregar("src/shared/PersonalizacaoMaquina").DoModelo(criadaCopia):ObterDados().Dados.Melhoria == 3)
tecla("Q"); tecla("Q")
assert(not c1._movimento and c1._modoSelecao == nil and c1._rotacao == CFrame.identity)
print("PASS: C copia configuracoes e orientacao para uma previa azul sem retirar a peca original.")

-- A loja coloca a configuracao padrao sem consumir uma variante diferente.
local dados = manager.ObterDados(p1)
local variante = { Configuracao = { Componentes = { { Velocidade = 17 } } } }
perfil.Data.Inventory.Esteira2x2 = 1
perfil.Data.InventarioPersonalizado = { Esteira2x2 = { variante } }
dados:Sincronizar()
local totalAntesOrigemInvalida, saldoAntesOrigemInvalida = #perfil.Data.MaquinasColocadas, perfil.Data.Dinheiro
for _, pedido in { { Padrao = "true" }, { Padrao = true, Token = 1 } } do
	tempo += 1
	assert(not redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.new(-12, 0, 12), CFrame.identity, pedido.Token, pedido.Padrao))
	assert(#perfil.Data.MaquinasColocadas == totalAntesOrigemInvalida and perfil.Data.Dinheiro == saldoAntesOrigemInvalida)
	assert(perfil.Data.Inventory.Esteira2x2 == 1 and #perfil.Data.InventarioPersonalizado.Esteira2x2 == 1)
end
clicarPeca(inventario, "Esteira2x2")
assert(inventario._textoFicha.Text:find("Transporte: 5,666667 blocos/s", 1, true))
clicarPeca(loja, "Esteira2x2")
local saldoAntesLoja = perfil.Data.Dinheiro
clicarPeca(loja, "Esteira2x2", 0.1)
assert(c1._abaColocacao == "Loja" and c1._previa and not c1._copia)
verificarAbasFechadas()
assert(perfil.Data.Dinheiro == saldoAntesLoja, "Clique duplo nao pode cobrar antes da confirmacao no terreno.")
resultado = { Instance = plot.Piso, Position = Vector3.new(-12, 0.5, 12), Normal = Vector3.yAxis, Distance = 10 }
raio = { Origin = Vector3.new(-12, 75, 12), Direction = -Vector3.yAxis }
quadro(); clique()
assert(perfil.Data.Inventory.Esteira2x2 == 1 and #perfil.Data.InventarioPersonalizado.Esteira2x2 == 1)
assert(perfil.Data.Dinheiro == carregar("src/server/InteiroGrande").subtrair(saldoAntesLoja, "25"))
local registroPadrao = perfil.Data.MaquinasColocadas[#perfil.Data.MaquinasColocadas]
assert(not registroPadrao.Modificacoes or next(registroPadrao.Modificacoes) == nil)
tecla("Q")
assert(not c1.Navegacao:Atual())
c1:AbrirAba("Inventario")
clicarPeca(inventario, "Esteira2x2")
clicarPeca(inventario, "Esteira2x2", 0.1)
verificarAbasFechadas()
assert(c1:ObterPersonalizacaoSelecionada():ObterDefinicao(catalogo.Esteira2x2).Componentes[1].Velocidade == 17,
	"Fechar as abas no clique duplo deve preservar a configuracao da unidade selecionada.")
tecla("Q")
assert(not c1.Navegacao:Atual() and perfil.Data.Inventory.Esteira2x2 == 1)
c1:SelecionarMaquina("Esteira2x2", "Inventario")
c1:SelecionarMaquina("Esteira2x2", "Loja")
local configuracaoAnterior = p1:GetAttribute("ConfiguracaoInventario_Esteira2x2")
p1:SetAttribute("ConfiguracaoInventario_Esteira2x2", "{invalida")
assert(not inventario._acoes.Colocar:ObterInstancia().Active and not inventario._acoes.Vender:ObterInstancia().Active)
assert(loja._fichaValida)
p1:SetAttribute("ConfiguracaoInventario_Esteira2x2", configuracaoAnterior)
print("PASS: clique duplo na loja usa o padrao, cobra so na confirmacao e preserva a variante do inventario.")
print("PASS: clique duplo fecha ambas as abas e fichas, preserva a configuracao e Q encerra sem reabrir paineis.")

-- Uma operacao pendente nao pode reabrir uma ficha fechada.
c1:SelecionarMaquina("FornalhaBasica", "Loja")
tempo += 1
depoisResposta = function() coroutine.yield() end
local compraPendente = coroutine.create(function() loja._acoes.Comprar:ObterInstancia().Activated:Fire() end)
assert(coroutine.resume(compraPendente))
assert(loja._negociando == "Comprar")
tecla("Q")
assert(not loja._painelFicha.Visible and inventario._painelFicha.Visible)
assert(coroutine.resume(compraPendente))
assert(not loja._painelFicha.Visible and loja._textoResposta.Text == "")
depoisResposta = nil
c1:SelecionarMaquina("FornalhaBasica", "Inventario")
local quantidadeAntesVenda = perfil.Data.Inventory.FornalhaBasica
p1:SetAttribute("ConfirmarVenda","Sempre")
inventario._acoes.Vender:ObterInstancia().Activated:Fire()
assert(c1.Navegacao:Contem("Confirmacao") and perfil.Data.Inventory.FornalhaBasica==quantidadeAntesVenda)
interface._confirmacao._nao:ObterInstancia().Activated:Fire()
assert(perfil.Data.Inventory.FornalhaBasica==quantidadeAntesVenda and not inventario._negociando)
p1:SetAttribute("ConfirmarVenda","Nunca")
depoisResposta = function() coroutine.yield() end
local vendaPendente = coroutine.create(function() inventario._acoes.Vender:ObterInstancia().Activated:Fire() end)
assert(coroutine.resume(vendaPendente))
tecla("E")
assert(not inventario._painelLista.Visible and loja._painelLista.Visible)
assert(coroutine.resume(vendaPendente))
assert(not inventario._painelLista.Visible and inventario._textoResposta.Text == "")
assert(perfil.Data.Inventory.FornalhaBasica == quantidadeAntesVenda - 1)
depoisResposta = nil
c1.Navegacao:Limpar()
resultado = { Instance = fonteNova.Correia }
depoisResposta = function() coroutine.yield() end
tecla("C")
quadro()
local copiaPendente = coroutine.create(clique)
tempo += 1
assert(coroutine.resume(copiaPendente))
tecla("Q")
assert(coroutine.resume(copiaPendente))
assert(not c1._previa and not c1._movimento and c1._modoSelecao == "Copia")
tecla("Q")
assert(c1._modoSelecao == nil and not c1.Navegacao:Atual())
depoisResposta = nil
assert(manager.AddDinheiro(p1,"10000"))
selecionarParaColocar("Four")
resultado = { Instance = plot.Piso, Position = Vector3.new(12, 0.5, -12), Normal = Vector3.yAxis, Distance = 10 }
raio = { Origin = Vector3.new(12, 75, -12), Direction = -Vector3.yAxis }
quadro()
depoisResposta = function() coroutine.yield() end
local colocacaoPendente = coroutine.create(clique)
assert(coroutine.resume(colocacaoPendente))
tecla("Q")
assert(coroutine.resume(colocacaoPendente))
assert(not c1._previa and not c1.Navegacao:Atual() and not c1._colocando)
depoisResposta = nil

-- M permite reposicionar. O proprio espaco antigo deve ficar livre para a previa e aceitar recolocar ali.
tecla("X")
assert(c1.Navegacao:Atual() == "Movimentacao" and c1._modoSelecao == "Movimentacao")
resultado = { Instance = fonteNova.Correia }
quadro()
assert(c1._maquinaSelecionada == fonteNova)
local posicaoAntesMover = fonteNova:GetAttribute("VolumeMinimo")
local registroFonte
for _, registro in perfil.Data.MaquinasColocadas do
	if registro.MaquinaId == "Esteira2x2" and registro.Modificacoes
		and registro.Posicao[1] == posicaoAntesMover.X and registro.Posicao[2] == posicaoAntesMover.Y
		and registro.Posicao[3] == posicaoAntesMover.Z
		and registro.Modificacoes.Dados and registro.Modificacoes.Dados.Melhoria == 3 then
		registroFonte = registro
		break
	end
end
assert(registroFonte)
local saldoAntesMover, estoqueAntesMover = perfil.Data.Dinheiro, perfil.Data.Inventory.Esteira2x2
local quantidadeAntesMover = #perfil.Data.MaquinasColocadas
local volumeAntesMover = fonteNova:GetAttribute("VolumeOcupado")
clique()
assert(c1.Navegacao:Atual() == "Reposicionamento" and c1._movimento.Pecas[1].Maquina == fonteNova)
assert(fonteNova.Parent == nil, "O servidor deve apagar a instancia original ao comecar a movimentacao.")
local geometria = carregar("src/shared/GeometriaColocacao")
local origemMover = geometria.Origem(plot.Piso)
local caixaAntiga = posicaoAntesMover + volumeAntesMover / 2
local pontoAntigo = origemMover:PointToWorldSpace(Vector3.new(caixaAntiga.X, 0, caixaAntiga.Z))
resultado = { Instance = plot.Piso, Position = pontoAntigo, Normal = origemMover.UpVector, Distance = 10 }
raio = { Origin = pontoAntigo + origemMover.UpVector * 100, Direction = -origemMover.UpVector }
quadro()
assert(c1._alvoColocacao.livre and c1._alvoColocacao.minimo == posicaoAntesMover,
	"A propria ocupacao antiga deve ser ignorada pela previa de movimento.")
local cancelarMovimentoOriginal = redes.Construcao.CancelarMovimento
redes.Construcao.CancelarMovimento = function() return false, "Recusa simulada." end
tecla("Q")
redes.Construcao.CancelarMovimento = cancelarMovimentoOriginal
assert(fonteNova.Parent == nil and c1._movimento and c1._previa,
	"Se o servidor recusa o cancelamento, a instancia continua apagada e a previa permanece ativa.")
assert(perfil.Data.Dinheiro == saldoAntesMover and perfil.Data.Inventory.Esteira2x2 == estoqueAntesMover
	and #perfil.Data.MaquinasColocadas == quantidadeAntesMover)
tecla("Q")
assert(fonteNova.Parent == nil and perfil.Data.Inventory.Esteira2x2 == estoqueAntesMover + 1
	and #perfil.Data.MaquinasColocadas == quantidadeAntesMover - 1)
local varianteDevolvida
for _, variante in perfil.Data.InventarioPersonalizado.Esteira2x2 do
	if variante.Configuracao and variante.Configuracao.Componentes[1].Velocidade == 13
		and variante.Dados and variante.Dados.Melhoria == 3 and variante.Partes and #variante.Partes > 0 then
		varianteDevolvida = variante
		break
	end
end
assert(varianteDevolvida, "Cancelar deve devolver a configuracao, melhoria e diferenca visual da peca movida.")
tecla("Q")
assert(c1._modoSelecao == nil and not c1.Navegacao:Contem("Movimentacao"))

-- A unidade personalizada retornou ao inventario; a proxima colocacao usa a variante restante em primeiro lugar.
selecionarParaColocar("Two")
resultado = { Instance = plot.Piso, Position = pontoAntigo, Normal = origemMover.UpVector, Distance = 10 }
raio = { Origin = pontoAntigo + origemMover.UpVector * 100, Direction = -origemMover.UpVector }
quadro()
assert(c1._alvoColocacao.livre, "A variante devolvida deve poder ser recolocada.")
posicaoAntesMover = c1._alvoColocacao.minimo
clique()
fonteNova = maquinaNoLocal("Esteira2x2", posicaoAntesMover)
assert(fonteNova and fonteNova:GetAttribute("VolumeMinimo") == posicaoAntesMover)
registroFonte = nil
for _, registro in perfil.Data.MaquinasColocadas do
	if registro.MaquinaId == "Esteira2x2" and registro.Modificacoes
		and registro.Posicao[1] == posicaoAntesMover.X and registro.Posicao[2] == posicaoAntesMover.Y
		and registro.Posicao[3] == posicaoAntesMover.Z then
		registroFonte = registro
		break
	end
end
assert(registroFonte and perfil.Data.Inventory.Esteira2x2 == estoqueAntesMover
	and #perfil.Data.MaquinasColocadas == quantidadeAntesMover)
assert(registroFonte.Modificacoes.Configuracao.Componentes[1].Velocidade == 17
	and registroFonte.Modificacoes.Dados == nil)

-- Confirmar o movimento recria a instancia selecionada e preserva sua configuracao, saldo e estoque.
tecla("X")
resultado = { Instance = fonteNova.Correia }
quadro(); clique()
local pontoMover = origemMover:PointToWorldSpace(Vector3.new(30, 0, 30))
resultado = { Instance = plot.Piso, Position = pontoMover, Normal = origemMover.UpVector, Distance = 10 }
raio = { Origin = pontoMover + origemMover.UpVector * 100, Direction = -origemMover.UpVector }
quadro()
assert(c1._alvoColocacao.livre, "A previa deve encaixar em uma celula livre da plot.")
local destinoEsperado = c1._alvoColocacao.minimo
local rotacaoEsperada = c1._alvoColocacao.rotacao
clique()
local instanciaAntesMover = fonteNova
fonteNova = maquinaNoLocal("Esteira2x2", destinoEsperado)
assert(fonteNova and fonteNova ~= instanciaAntesMover and instanciaAntesMover.Parent == nil)
assert(fonteNova.Parent == plot.Maquinas and fonteNova:GetAttribute("VolumeMinimo") == destinoEsperado)
assert((fonteNova:GetAttribute("RotacaoConstrucao").RightVector - rotacaoEsperada.RightVector).Magnitude < 0.0001)
assert(registroFonte.Posicao[1] == destinoEsperado.X and registroFonte.Posicao[2] == destinoEsperado.Y
	and registroFonte.Posicao[3] == destinoEsperado.Z)
assert(#perfil.Data.MaquinasColocadas == quantidadeAntesMover and perfil.Data.Dinheiro == saldoAntesMover
	and perfil.Data.Inventory.Esteira2x2 == estoqueAntesMover)
local personalizacaoMovida = carregar("src/shared/PersonalizacaoMaquina").DoModelo(fonteNova):ObterDados()
assert(personalizacaoMovida.Configuracao.Componentes[1].Velocidade == 17 and personalizacaoMovida.Dados == nil)
assert(c1.Navegacao:Atual() == "Movimentacao" and c1._modoSelecao == "Movimentacao")
tecla("Q")
assert(c1._modoSelecao == nil and not c1.Navegacao:Contem("Movimentacao"))

-- A caixa e um volume 3D: o clique em uma peca define a altura inicial; scroll altera sua altura e Shift+scroll
-- desloca esse plano. Uma copia na mesma coluna, oito studs acima, so entra quando o volume a alcança.
tecla("X")
local contornoSelecao = c1._caixaSelecao:FindFirstChild("ContornoSelecao")
assert(c1._caixaSelecao.Transparency == 1
	and c1._caixaSelecao.Color.R > 0.99 and c1._caixaSelecao.Color.G > 0.7
	and c1._caixaSelecao.Color.B < 0.01 and contornoSelecao
	and contornoSelecao:IsA("SelectionBox") and contornoSelecao.Adornee == c1._caixaSelecao
	and math.abs(contornoSelecao.LineThickness - 0.1) < 0.001
	and contornoSelecao.SurfaceTransparency == 1 and contornoSelecao.Color3.R > 0.99
	and contornoSelecao.Color3.G > 0.8 and contornoSelecao.Color3.B < 0.4,
	"A area 3D deve usar preenchimento por SurfaceGui e borda amarela sem uma segunda camada de faces na Part.")
resultado = { Instance = criadaCopia.Correia }
quadro()
local origemSelecao = carregar("src/shared/GeometriaColocacao").Origem(plot.Piso)
local minimoSelecao = criadaCopia:GetAttribute("VolumeMinimo")
local ocupadoSelecao = criadaCopia:GetAttribute("VolumeOcupado")
local altoSelecao = criadaCopia:Clone()
altoSelecao:SetAttribute("VolumeMinimo", minimoSelecao + Vector3.new(0, 6, 0))
altoSelecao.Parent = plot.Maquinas
raioPorTela = function(x, z)
	return {
		Origin = origemSelecao:PointToWorldSpace(Vector3.new(x, 100, z)),
		Direction = -origemSelecao.UpVector,
	}
end
local inicioSelecao = roblox.Vector2.new(minimoSelecao.X + ocupadoSelecao.X,
	minimoSelecao.Z + ocupadoSelecao.Z)
local fimSelecao = roblox.Vector2.new(minimoSelecao.X, minimoSelecao.Z)
local function arrastarVolume(modelo, alturaHit, alturaVolume)
	resultado = {
		Instance = modelo:FindFirstChildWhichIsA("BasePart", true),
		Position = origemSelecao:PointToWorldSpace(Vector3.new(inicioSelecao.X, alturaHit, inicioSelecao.Y)),
	}
	local entrada = iniciarArraste(inicioSelecao)
	moverArraste(fimSelecao)
	if alturaVolume then
		assert(c1._arrasteSelecao.AlturaInicial == alturaVolume,
			"A superficie clicada deve definir o plano vertical inicial da selecao.")
	end
	return entrada
end
local entradaVolume = arrastarVolume(criadaCopia, minimoSelecao.Y + 1.5, minimoSelecao.Y)
assert(c1._caixaSelecao.Size.Y == 3, "A caixa deve iniciar com uma celula de altura.")
assert(table.find(c1._pecasSelecionadas, criadaCopia) and c1._destaquesPecas[criadaCopia],
	"A peca deve ganhar contorno assim que entra na caixa, antes de soltar o mouse.")
moverArraste(inicioSelecao)
assert(not table.find(c1._pecasSelecionadas, criadaCopia) and not c1._destaquesPecas[criadaCopia],
	"A peca deve perder o contorno ao sair da caixa durante o mesmo arraste.")
moverArraste(fimSelecao)
assert(table.find(c1._pecasSelecionadas, criadaCopia) and c1._destaquesPecas[criadaCopia])
terminarArraste(entradaVolume)
assert(table.find(c1._pecasSelecionadas, criadaCopia), "O volume deve selecionar a peca que contem por inteiro.")
assert(not table.find(c1._pecasSelecionadas, altoSelecao),
	"Uma peca na mesma coluna, mas fora da altura, nao deve ser selecionada.")
arrastarVolume(criadaCopia, minimoSelecao.Y + 1.5, minimoSelecao.Y)
assert(not table.find(c1._pecasSelecionadas, criadaCopia) and not c1._destaquesPecas[criadaCopia],
	"Uma peca ja selecionada deve perder o contorno quando a caixa a alcança.")
terminarArraste({ UserInputType = roblox.Enum.UserInputType.MouseButton1 })
assert(not table.find(c1._pecasSelecionadas, criadaCopia), "Repetir o volume deve desmarcar a peca selecionada.")

entradaVolume = arrastarVolume(criadaCopia, minimoSelecao.Y + 1.5, minimoSelecao.Y)
local alturaVisualInicial = c1._caixaSelecao.Size.Y
local centroVisualInicial = c1._caixaSelecao.CFrame.Position.Y
rolarSelecao(1, false)
rolarSelecao(1, false)
assert(table.find(c1._pecasSelecionadas, altoSelecao) and c1._destaquesPecas[altoSelecao],
	"A peca elevada deve ganhar contorno no instante em que passa a caber na caixa.")
assert(c1._arrasteSelecao.VolumeMaximo.Y - c1._arrasteSelecao.VolumeMinimo.Y == 9
	and c1._caixaSelecao.Size.Y == alturaVisualInicial
	and c1._caixaSelecao.CFrame.Position.Y == centroVisualInicial,
	"O volume e os contornos mudam imediatamente, enquanto a altura visual aguarda a interpolacao.")
heartbeat:Fire(1 / 60)
local alturaVisualInterpolada = c1._caixaSelecao.Size.Y
local centroVisualInterpolado = c1._caixaSelecao.CFrame.Position.Y
local centroVisualAlvo = origemSelecao:PointToWorldSpace(Vector3.new(0, minimoSelecao.Y + 4.5, 0)).Y
assert(alturaVisualInterpolada > alturaVisualInicial and alturaVisualInterpolada < 9
	and centroVisualInterpolado > centroVisualInicial and centroVisualInterpolado < centroVisualAlvo,
	string.format("Caixa deve interpolar: altura %.4f -> %.4f -> 12; centro %.4f -> %.4f -> %.4f", alturaVisualInicial, alturaVisualInterpolada, centroVisualInicial, centroVisualInterpolado, centroVisualAlvo))
for _ = 1, 30 do heartbeat:Fire(1 / 60) end
assert(math.abs(c1._caixaSelecao.Size.Y - 9) < 0.01
	and math.abs(c1._caixaSelecao.CFrame.Position.Y - centroVisualAlvo) < 0.01,
	"A animacao vertical deve convergir para a altura indicada pela roda.")
terminarArraste(entradaVolume)
assert(table.find(c1._pecasSelecionadas, criadaCopia) and table.find(c1._pecasSelecionadas, altoSelecao),
	"Aumentar a altura deve incluir as pecas que passaram a caber no volume.")

-- Shift+scroll move o plano inicial; o clique na instancia elevada tambem escolhe sua altura sem projetar em tela.
resultado = { Instance = altoSelecao:FindFirstChildWhichIsA("BasePart", true),
	Position = origemSelecao:PointToWorldSpace(Vector3.new(inicioSelecao.X, minimoSelecao.Y + 7.5, inicioSelecao.Y)) }
local entradaAlta = iniciarArraste(inicioSelecao)
moverArraste(fimSelecao)
assert(c1._arrasteSelecao.AlturaInicial == minimoSelecao.Y + 6)
local centroAntesDeMoverPlano = c1._caixaSelecao.CFrame.Position.Y
rolarSelecao(-1, true)
local centroAlvoPlano = origemSelecao:PointToWorldSpace(Vector3.new(0, minimoSelecao.Y + 4.5, 0)).Y
assert(c1._arrasteSelecao.AlturaInicial == minimoSelecao.Y + 3
	and c1._arrasteSelecao.VolumeMinimo.Y == minimoSelecao.Y + 3
	and c1._arrasteSelecao.VolumeMaximo.Y == minimoSelecao.Y + 6
	and c1._caixaSelecao.CFrame.Position.Y == centroAntesDeMoverPlano,
	"Shift+scroll deve mover o plano logico sem saltar a caixa visual.")
heartbeat:Fire(1 / 60)
assert(c1._caixaSelecao.CFrame.Position.Y < centroAntesDeMoverPlano
	and c1._caixaSelecao.CFrame.Position.Y > centroAlvoPlano,
	"A posicao vertical deve acompanhar suavemente o plano inicial.")
for _ = 1, 30 do heartbeat:Fire(1 / 60) end
assert(math.abs(c1._caixaSelecao.CFrame.Position.Y - centroAlvoPlano) < 0.01,
	"A caixa deve convergir para o novo plano inicial.")
rolarSelecao(1, true)
assert(c1._arrasteSelecao.AlturaInicial == minimoSelecao.Y + 6)
terminarArraste(entradaAlta)
local selecaoAntesPerderFoco = table.clone(c1._pecasSelecionadas)
arrastarVolume(criadaCopia, minimoSelecao.Y + 1.5, minimoSelecao.Y)
assert(not c1._destaquesPecas[criadaCopia], "A pre-selecao deve reagir antes de o foco ser perdido.")
perdeuFoco:Fire()
assert(not c1._arrasteSelecao and #c1._pecasSelecionadas == #selecaoAntesPerderFoco,
	"Perder o foco durante o arraste deve restaurar a quantidade de selecoes anterior.")
for _, maquina in selecaoAntesPerderFoco do
	assert(c1._destaquesPecas[maquina], "Perder o foco deve restaurar os contornos anteriores.")
end

-- A camada inicial continua no volume quando a roda acrescenta uma camada acima ou abaixo dela.
local abaixoSelecao = criadaCopia:Clone()
abaixoSelecao:SetAttribute("VolumeMinimo", minimoSelecao + Vector3.new(0, 3, 0))
abaixoSelecao.Parent = plot.Maquinas
assert(not c1._destaquesPecas[altoSelecao])
resultado = {
	Instance = altoSelecao:FindFirstChildWhichIsA("BasePart", true),
	Position = origemSelecao:PointToWorldSpace(Vector3.new(inicioSelecao.X, minimoSelecao.Y + 7.5, inicioSelecao.Y)),
}
local entradaParaBaixo = iniciarArraste(inicioSelecao)
moverArraste(fimSelecao)
assert(c1._arrasteSelecao.AlturaInicial == minimoSelecao.Y + 6)
local alturaAntesDeExpandir = c1._caixaSelecao.Size.Y
local centroAntesDeExpandir = c1._caixaSelecao.CFrame.Position.Y
rolarSelecao(-1, false)
assert(math.abs(c1._arrasteSelecao.Altura + 3) < 0.001
	and c1._arrasteSelecao.VolumeMinimo.Y == minimoSelecao.Y + 3
	and c1._arrasteSelecao.VolumeMaximo.Y == minimoSelecao.Y + 9
	and table.find(c1._pecasSelecionadas, abaixoSelecao) and c1._destaquesPecas[abaixoSelecao]
	and table.find(c1._pecasSelecionadas, altoSelecao) and c1._destaquesPecas[altoSelecao],
	"Ao incluir a camada abaixo, a caixa deve manter selecionadas as pecas da camada inicial.")
assert(c1._caixaSelecao.Size.Y == alturaAntesDeExpandir
	and c1._caixaSelecao.CFrame.Position.Y == centroAntesDeExpandir,
	"Expandir o volume para baixo nao deve mover a caixa verticalmente de uma vez.")
heartbeat:Fire(1 / 60)
assert(c1._caixaSelecao.Size.Y > alturaAntesDeExpandir and c1._caixaSelecao.Size.Y < 6
	and c1._caixaSelecao.CFrame.Position.Y < centroAntesDeExpandir,
	"A expansao para baixo deve suavizar tanto o tamanho quanto a posicao da caixa.")
for _ = 1, 30 do heartbeat:Fire(1 / 60) end
assert(math.abs(c1._caixaSelecao.Size.Y - 6) < 0.01
	and math.abs(c1._caixaSelecao.CFrame.Position.Y - origemSelecao:PointToWorldSpace(
		Vector3.new(0, minimoSelecao.Y + 6, 0)).Y) < 0.01,
	"A expansao vertical deve convergir ao novo limite do volume.")
perdeuFoco:Fire()
assert(not c1._destaquesPecas[abaixoSelecao], "Cancelar o arraste deve restaurar o estado anterior da peca inferior.")
abaixoSelecao:Destroy()
altoSelecao:Destroy()
c1:_LimparSelecaoPecas()

-- Mesmo com o cursor entre coordenadas, os limites horizontais devem acompanhar celulas inteiras de 3 studs.
local inicioForaDaGrade = roblox.Vector2.new(inicioSelecao.X - 0.5, inicioSelecao.Y - 0.5)
local fimForaDaGrade = roblox.Vector2.new(fimSelecao.X + 0.5, fimSelecao.Y + 0.5)
resultado = {
	Instance = criadaCopia:FindFirstChildWhichIsA("BasePart", true),
	Position = origemSelecao:PointToWorldSpace(Vector3.new(inicioForaDaGrade.X, minimoSelecao.Y + 1.5, inicioForaDaGrade.Y)),
}
local entradaGrade = iniciarArraste(inicioForaDaGrade)
moverArraste(fimForaDaGrade)
local volumeGrade = c1._arrasteSelecao
for _, eixo in { "X", "Z" } do
	assert(math.abs(volumeGrade.VolumeMinimo[eixo] / 3 - math.round(volumeGrade.VolumeMinimo[eixo] / 3)) < 0.001
		and math.abs(volumeGrade.VolumeMaximo[eixo] / 3 - math.round(volumeGrade.VolumeMaximo[eixo] / 3)) < 0.001
		and math.abs(c1._caixaSelecao.Size[eixo] / 3 - math.round(c1._caixaSelecao.Size[eixo] / 3)) < 0.001,
		"Os limites e o tamanho da caixa devem saltar em blocos de tres studs.")
end
assert(volumeGrade.VolumeMinimo.X == minimoSelecao.X and volumeGrade.VolumeMinimo.Z == minimoSelecao.Z
	and volumeGrade.VolumeMaximo.X == minimoSelecao.X + ocupadoSelecao.X
	and volumeGrade.VolumeMaximo.Z == minimoSelecao.Z + ocupadoSelecao.Z,
	"Ao arrastar entre blocos, a caixa deve arredondar para fora e cobrir a peca inteira.")

local tamanhoAntesDoSalto = c1._caixaSelecao.Size.X
moverArraste(roblox.Vector2.new(fimForaDaGrade.X + 3, fimForaDaGrade.Y))
local tamanhoAlvo = c1._arrasteSelecao.VolumeMaximo.X - c1._arrasteSelecao.VolumeMinimo.X
assert(math.abs(tamanhoAlvo - tamanhoAntesDoSalto) >= 3,
	"Mover o cursor por um bloco deve atualizar o alvo da caixa.")
heartbeat:Fire(1 / 60)
local tamanhoInterpolado = c1._caixaSelecao.Size.X
assert(tamanhoInterpolado > math.min(tamanhoAntesDoSalto, tamanhoAlvo)
	and tamanhoInterpolado < math.max(tamanhoAntesDoSalto, tamanhoAlvo),
	"A caixa visual deve deslizar entre dois tamanhos de bloco em vez de saltar.")
for _ = 1, 30 do heartbeat:Fire(1 / 60) end
assert(math.abs(c1._caixaSelecao.Size.X - tamanhoAlvo) < 0.01,
	"A animacao deve convergir para o bloco indicado pelo cursor.")
moverArraste(fimForaDaGrade)
for _ = 1, 30 do heartbeat:Fire(1 / 60) end
terminarArraste(entradaGrade)
assert(table.find(c1._pecasSelecionadas, criadaCopia), "A caixa alinhada deve continuar selecionando a peca contida.")
c1:_LimparSelecaoPecas()

-- A parede virtual da plot pode iniciar a selecao e fornecer a altura mesmo sem um piso fisico sob o cursor.
local inicioNaParede, fimNaParede = roblox.Vector2.new(10, 10), roblox.Vector2.new(40, 40)
raioPorTela = function(x)
	if x < 20 then
		return {
			Origin = origemSelecao:PointToWorldSpace(Vector3.new(plot.Piso.Size.X / 2, 20, plot.Piso.Size.Z / 2)),
			Direction = origemSelecao.RightVector,
		}
	end
	return {
		Origin = origemSelecao:PointToWorldSpace(Vector3.new(plot.Piso.Size.X / 2, 40, plot.Piso.Size.Z / 2)),
		Direction = origemSelecao:VectorToWorldSpace(roblox.Vector3.new(1, -.5, 0).Unit),
	}
end
resultado = nil
local entradaParede = iniciarArraste(inicioNaParede)
moverArraste(fimNaParede)
assert(c1._arrasteSelecao.InicioLocal == Vector3.new(plot.Piso.Size.X, 18, plot.Piso.Size.Z / 2)
	and c1._arrasteSelecao.VolumeMinimo.Y == 18
	and c1._arrasteSelecao.VolumeMinimo.X == plot.Piso.Size.X - 3
	and c1._arrasteSelecao.VolumeMaximo.X == plot.Piso.Size.X,
	"Parede: inicio="..tostring(c1._arrasteSelecao.InicioLocal).." minimo="..tostring(c1._arrasteSelecao.VolumeMinimo).." maximo="..tostring(c1._arrasteSelecao.VolumeMaximo))
terminarArraste(entradaParede)
c1:_LimparSelecaoPecas()
raioPorTela = nil
resultado = { Instance = criadaCopia.Correia }
local function shiftClick(modelo)
	resultado = { Instance = modelo:FindFirstChildWhichIsA("BasePart", true) }
	quadro()
	teclasAtivas[teclas.LeftShift] = true
	clique()
	teclasAtivas[teclas.LeftShift] = false
end
shiftClick(fonteNova)
shiftClick(criadaCopia)
assert(#c1._pecasSelecionadas == 2)
local centroOriginalAncora = criadaCopia:GetAttribute("VolumeMinimo")
	+ criadaCopia:GetAttribute("VolumeOcupado") / 2
local centroOriginalOutra = fonteNova:GetAttribute("VolumeMinimo") + fonteNova:GetAttribute("VolumeOcupado") / 2
local deslocamentoGrupo = centroOriginalOutra - centroOriginalAncora
resultado = { Instance = criadaCopia.Correia }
quadro()
clique()
assert(c1._movimento.Grupo and c1._movimento.Pecas[1].Maquina == criadaCopia,
	"A peca clicada deve ser a ancora do grupo.")
assert(fonteNova.Parent == nil and criadaCopia.Parent == nil,
	"As originais selecionadas devem sair da cena local ao iniciar o movimento do conjunto.")
local origemGrupo = carregar("src/shared/GeometriaColocacao").Origem(plot.Piso)
local pontoAncoraGrupo = origemGrupo:PointToWorldSpace(Vector3.new(24, 0, 24))
resultado = { Instance = plot.Piso, Position = pontoAncoraGrupo, Normal = origemGrupo.UpVector, Distance = 10 }
raio = { Origin = pontoAncoraGrupo + origemGrupo.UpVector * 100, Direction = -origemGrupo.UpVector }
render:Fire(1 / 60)
tecla("R")
render:Fire(1 / 60)
assert(#c1._alvosGrupo == 2 and c1._alvoColocacao.livre, "O conjunto deve manter uma formacao valida na nova posicao.")
local alvoAncoraGrupo, alvoOutraGrupo
for _, item in c1._alvosGrupo do
	if item.Peca.Maquina == criadaCopia then alvoAncoraGrupo = item.Alvo else alvoOutraGrupo = item.Alvo end
end
local centroAlvoCursor = c1._alvoColocacao.minimo + c1._alvoColocacao.ocupado / 2
local centroAncoraGrupo = alvoAncoraGrupo.minimo + alvoAncoraGrupo.ocupado / 2
assert((centroAncoraGrupo - centroAlvoCursor).Magnitude < 0.001,
	"A peca clicada deve permanecer no ponto de destino do cursor.")
local rotacaoRelativa = alvoAncoraGrupo.rotacao * CFrame.Angles(0, -math.pi / 2, 0)
local deslocamentoEsperado = rotacaoRelativa:VectorToWorldSpace(deslocamentoGrupo)
local deslocamentoAlvo = (alvoOutraGrupo.minimo + alvoOutraGrupo.ocupado / 2)
	- (alvoAncoraGrupo.minimo + alvoAncoraGrupo.ocupado / 2)
assert((deslocamentoAlvo - deslocamentoEsperado).Magnitude < 0.001,
	"R deve girar as distancias do conjunto ao redor da peca clicada.")
do
	local visualAncora = c1._movimento.Pecas[1].Previa:ObterCFrameVisual()
	local visualOutra = c1._movimento.Pecas[2].Previa:ObterCFrameVisual()
	local relativoVisual = visualAncora:ToObjectSpace(visualOutra)
	local relativoAlvo = alvoAncoraGrupo.caixaDestino:ToObjectSpace(alvoOutraGrupo.caixaDestino)
	assert((relativoVisual.Position - relativoAlvo.Position).Magnitude < 0.001
		and (relativoVisual.RightVector - relativoAlvo.RightVector).Magnitude < 0.001
		and (relativoVisual.UpVector - relativoAlvo.UpVector).Magnitude < 0.001,
		"Durante o giro, todas as previas devem manter o transform relativo do grupo.")
end
clique()
local instanciaFonteMovida, instanciaCopiaMovida = fonteNova, criadaCopia
fonteNova = maquinaNoLocal("Esteira2x2", alvoOutraGrupo.minimo)
criadaCopia = maquinaNoLocal("Esteira2x2", alvoAncoraGrupo.minimo)
assert(fonteNova and criadaCopia and fonteNova ~= instanciaFonteMovida and criadaCopia ~= instanciaCopiaMovida)
assert(instanciaFonteMovida.Parent == nil and instanciaCopiaMovida.Parent == nil)
assert(c1._modoSelecao == "Movimentacao" and not c1._movimento)
assert((fonteNova:GetAttribute("RotacaoConstrucao").RightVector - alvoOutraGrupo.rotacao.RightVector).Magnitude < 0.0001)
tecla("Q")
assert(c1._modoSelecao == nil)
print("PASS: caixa 3D seleciona por altura; scroll expande para cima e para baixo, Shift move o plano e R gira o grupo na ancora.")

-- Cancelar o movimento envia a peca apagada ao inventario. Uma recusa mantem a previa para nova tentativa.
tecla("X")
resultado = { Instance = criadaCopia.Correia }
quadro()
local inventarioAntesCancelar = perfil.Data.Inventory.Esteira2x2
local construcoesAntesCancelar = #perfil.Data.MaquinasColocadas
clique()
assert(criadaCopia.Parent == nil, "A copia original tambem deve sair da cena local durante o movimento.")
local cancelarOriginal = redes.Construcao.CancelarMovimento
redes.Construcao.CancelarMovimento = function() return false, "Recusa simulada." end
tecla("Q")
redes.Construcao.CancelarMovimento = cancelarOriginal
assert(criadaCopia.Parent == nil and c1._movimento and c1._previa)
assert(perfil.Data.Inventory.Esteira2x2 == inventarioAntesCancelar
	and #perfil.Data.MaquinasColocadas == construcoesAntesCancelar)
assert(c1._modoSelecao == "Movimentacao")
tecla("Q")
assert(criadaCopia.Parent == nil and perfil.Data.Inventory.Esteira2x2 == inventarioAntesCancelar + 1)
assert(#perfil.Data.MaquinasColocadas == construcoesAntesCancelar - 1)
local varianteRecolhida
for _, variante in perfil.Data.InventarioPersonalizado.Esteira2x2 do
	if variante.Dados and variante.Dados.Melhoria == 3
		and variante.Configuracao and variante.Configuracao.Componentes[1].Velocidade == 13 then
		varianteRecolhida = variante
		break
	end
end
assert(varianteRecolhida and varianteRecolhida.Partes and #varianteRecolhida.Partes > 0,
	"O cancelamento deve preservar melhorias, configuracao e diferencas visuais no inventario.")
tecla("Q")
assert(c1._modoSelecao == nil and not c1.Navegacao:Contem("Movimentacao"))

tecla("Z")
resultado = { Instance = fonteNova.Correia }
quadro()
depoisResposta = function() coroutine.yield() end
local recolhimentoPendente = coroutine.create(clique)
assert(coroutine.resume(recolhimentoPendente))
tecla("Q")
assert(coroutine.resume(recolhimentoPendente))
assert(c1._modoSelecao == nil and not c1._colocando and not inventario._painelLista.Visible and not loja._painelLista.Visible)
depoisResposta = nil

-- Q no reposicionamento do grupo devolve todas as unidades juntas, inclusive suas variantes personalizadas.
tempo += 1
assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.zero, CFrame.identity))
local esteiraLote = plot.Maquinas:GetChildren()[#plot.Maquinas:GetChildren()]
tempo += 1
assert(redes.Construcao:Colocar(p1, "MineradoraBasica", Vector3.new(24, 30, 24), CFrame.identity))
local mineradoraAlta = plot.Maquinas:GetChildren()[#plot.Maquinas:GetChildren()]
local estoqueEsteiraAntesGrupo = perfil.Data.Inventory.Esteira2x2
local estoqueMineradoraAntesGrupo = perfil.Data.Inventory.MineradoraBasica
local construcoesAntesGrupo = #perfil.Data.MaquinasColocadas
tecla("X")
shiftClick(esteiraLote)
shiftClick(mineradoraAlta)
assert(#c1._pecasSelecionadas == 2)
resultado = { Instance = esteiraLote.Correia }
quadro(); clique()
assert(c1._movimento.Grupo and esteiraLote.Parent == nil and mineradoraAlta.Parent == nil)
tecla("Q")
assert(not c1._movimento and esteiraLote.Parent == nil and mineradoraAlta.Parent == nil)
assert(perfil.Data.Inventory.Esteira2x2 == estoqueEsteiraAntesGrupo + 1)
assert(perfil.Data.Inventory.MineradoraBasica == estoqueMineradoraAntesGrupo + 1)
assert(#perfil.Data.MaquinasColocadas == construcoesAntesGrupo - 2)
assert(#perfil.Data.InventarioPersonalizado.Esteira2x2 > 0,
	"Cancelar o grupo deve preservar a personalizacao da esteira no inventario.")
tecla("Q")
assert(c1._modoSelecao == nil)
print("PASS: mover retira a peca da cena local, confirma no destino ou recolhe ao inventario no cancelamento.")

-- O modo Z reutiliza o volume 3D, destaca em vermelho e devolve o grupo ao inventario numa transacao.
tempo += 1
assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.new(0, 0, 0), CFrame.identity))
local esteiraRecolhida1 = maquinaNoLocal("Esteira2x2", Vector3.new(0, 0, 0))
tempo += 1
assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.new(24, 0, 24), CFrame.identity))
local esteiraRecolhida2 = maquinaNoLocal("Esteira2x2", Vector3.new(24, 0, 24))
assert(esteiraRecolhida1 and esteiraRecolhida2)

-- C seleciona o mesmo grupo com contorno azul, mas abrir a previa nao retira nenhuma fonte.
do
tecla("C")
assert(c1._caixaSelecao.Color.B > 0.9 and c1._caixaSelecao.ContornoSelecao.Color3.B > 0.9)
local origemCopia = carregar("src/shared/GeometriaColocacao").Origem(plot.Piso)
local inicioCopia = roblox.Vector2.new(.75, .75)
local fimCopia = roblox.Vector2.new(30.75, 30.75)
raioPorTela = function(x, z)
	return {
		Origin = origemCopia:PointToWorldSpace(Vector3.new(x, 100, z)),
		Direction = -origemCopia.UpVector,
	}
end
resultado = {
	Instance = esteiraRecolhida1.Correia,
	Position = origemCopia:PointToWorldSpace(Vector3.new(0.75, 1.5, 0.75)),
}
local arrasteCopia = iniciarArraste(inicioCopia)
moverArraste(fimCopia)
assert(#c1._pecasSelecionadas == 2 and c1._destaquesPecas[esteiraRecolhida1].FillColor.B > 0.9
	and c1._destaquesPecas[esteiraRecolhida2].FillColor.B > 0.9)
terminarArraste(arrasteCopia)
raioPorTela = nil
resultado = { Instance = esteiraRecolhida1.Correia }
quadro(); clique()
assert(c1._movimento and c1._movimento.Copia and #c1._movimento.Pecas == 2
	and esteiraRecolhida1.Parent == plot.Maquinas and esteiraRecolhida2.Parent == plot.Maquinas,
	"Copiar duas pecas deve abrir uma previa em grupo e conservar as originais.")

local deslocamentoTopo = origemCopia:PointToWorldSpace(Vector3.new(3, 3, 3))
resultado = {
	Instance = esteiraRecolhida1.Correia, Position = deslocamentoTopo,
	Normal = origemCopia.UpVector, Distance = 10,
}
raio = { Origin = origemCopia:PointToWorldSpace(Vector3.new(3, 75, 3)), Direction = -origemCopia.UpVector }
quadro()
assert(c1._alvosGrupo and #c1._alvosGrupo == 2 and c1._alvoColocacao.minimo.Y == 3
	and c1._alvoColocacao.livre, "O grupo copiado deve acompanhar o alvo e caber acima das fontes.")
c1._estoqueAntesRecolherGrupo = perfil.Data.Inventory.Esteira2x2
c1._colocadasAntesRecolherGrupo = #perfil.Data.MaquinasColocadas
clique()
assert(#perfil.Data.MaquinasColocadas == c1._colocadasAntesRecolherGrupo + 2
	and esteiraRecolhida1.Parent == plot.Maquinas and esteiraRecolhida2.Parent == plot.Maquinas,
	"Confirmar a previa deve colocar o grupo inteiro e manter suas fontes.")
assert(maquinaNoLocal("Esteira2x2", Vector3.new(0, 3, 0))
	and maquinaNoLocal("Esteira2x2", Vector3.new(24, 3, 24)))
c1._estoqueAntesRecolherGrupo = perfil.Data.Inventory.Esteira2x2
c1._colocadasAntesRecolherGrupo = #perfil.Data.MaquinasColocadas
tecla("Q")
assert(not c1._movimento and esteiraRecolhida1.Parent == plot.Maquinas and esteiraRecolhida2.Parent == plot.Maquinas)
tecla("Q")
assert(c1._modoSelecao == nil)
end

resultado = { Instance = esteiraRecolhida1.Correia }
local origemRetirada = carregar("src/shared/GeometriaColocacao").Origem(plot.Piso)
local inicioRetirada = roblox.Vector2.new(30, 33)
local fimRetirada = roblox.Vector2.new(0, 0)
raioPorTela = function(x, z)
	return {
		Origin = origemRetirada:PointToWorldSpace(Vector3.new(x, 100, z)),
		Direction = -origemRetirada.UpVector,
	}
end
resultado = {
	Instance = esteiraRecolhida2:FindFirstChildWhichIsA("BasePart", true),
	Position = origemRetirada:PointToWorldSpace(Vector3.new(30, 1.5, 33)),
}
tecla("Z")
assert(c1._caixaSelecao.Color.R > 0.99 and c1._caixaSelecao.Color.G < 0.3
	and c1._caixaSelecao.Color.B < 0.3 and c1._caixaSelecao.ContornoSelecao.Color3.R > 0.99
	and c1._caixaSelecao.ContornoSelecao.Color3.G < 0.3
	and c1._destaqueSelecao.FillColor.R > 0.99 and c1._destaqueSelecao.FillColor.G < 0.3,
	"O modo de retirada deve usar vermelho na area, na borda e no destaque sob o cursor.")
local entradaRetirada = iniciarArraste(inicioRetirada)
moverArraste(fimRetirada)
assert(#c1._pecasSelecionadas == 2
	and c1._destaquesPecas[esteiraRecolhida1] and c1._destaquesPecas[esteiraRecolhida2]
	and c1._destaquesPecas[esteiraRecolhida1].FillColor.G < 0.3
	and c1._destaquesPecas[esteiraRecolhida2].FillColor.G < 0.3,
	"O volume vermelho deve selecionar as duas pecas e aplicar contornos vermelhos.")
terminarArraste(entradaRetirada)

resultado = { Instance = esteiraRecolhida1:FindFirstChildWhichIsA("BasePart", true) }
shiftClick(esteiraRecolhida1)
assert(#c1._pecasSelecionadas == 1 and not c1._destaquesPecas[esteiraRecolhida1]
	and c1._destaquesPecas[esteiraRecolhida2],
	"Shift+clique deve desmarcar individualmente uma peca do grupo.")
shiftClick(esteiraRecolhida1)
assert(#c1._pecasSelecionadas == 2)
local estoqueAntesDoPedidoDuplicado = perfil.Data.Inventory.Esteira2x2
assert(not redes.Construcao:Recolher(p1, { esteiraRecolhida1, esteiraRecolhida1 })
	and esteiraRecolhida1.Parent == plot.Maquinas and esteiraRecolhida2.Parent == plot.Maquinas
	and perfil.Data.Inventory.Esteira2x2 == estoqueAntesDoPedidoDuplicado,
	"Um lote duplicado deve falhar sem remover maquinas nem alterar o inventario.")
resultado = { Instance = esteiraRecolhida1:FindFirstChildWhichIsA("BasePart", true) }
quadro()
clique()
assert(esteiraRecolhida1.Parent == nil and esteiraRecolhida2.Parent == nil
	and #c1._pecasSelecionadas == 0 and not next(c1._destaquesPecas),
	"Clicar numa selecionada deve recolher o grupo e limpar seus destaques locais.")
assert(perfil.Data.Inventory.Esteira2x2 == c1._estoqueAntesRecolherGrupo + 2
	and #perfil.Data.MaquinasColocadas == c1._colocadasAntesRecolherGrupo - 2,
	"O recolhimento em lote deve devolver todas as unidades sem registrar colocacoes extras.")
tecla("Q")
raioPorTela = nil
print("PASS: Z seleciona com Shift e volume 3D vermelho, e recolhe grupos atomicamente para o inventario.")
print("PASS: compra, venda, copia, colocacao e recolhimento atrasados respeitam Q e fechamento independente dos paineis.")

-- Em uma face vertical, o cursor escolhe a camada Y tanto ao colocar pelo inventario quanto ao mover uma peca.
selecionarParaColocar("Three")
resultado = { Instance = plot.Piso, Position = Vector3.new(-12, 7.125, -12), Normal = Vector3.xAxis, Distance = 40.5 }
quadro()
assert(c1._alvoColocacao.minimo.Y == 6,
	"A fornalha deve subir para a camada indicada pelo cursor, sem centralizar seus 12 studs de volume no ponto.")
resultado = { Instance = plot.Piso, Position = Vector3.new(-12, 0.5, -12), Normal = Vector3.yAxis, Distance = 49.5 }
quadro()
local minimoFornalha = c1._alvoColocacao.minimo
clique()
local fornalha = maquinaNoLocal("FornalhaBasica", minimoFornalha)
assert(fornalha, "O teste precisa colocar a fornalha antes de verificar o reposicionamento.")
local inventarioFornalhaAntesDoMovimento = perfil.Data.Inventory.FornalhaBasica

tecla("X")
resultado = { Instance = fornalha:FindFirstChildWhichIsA("BasePart", true) }
quadro()
clique()
assert(c1._movimento and fornalha.Parent == nil, "O reposicionamento deve remover a fornalha original.")
resultado = { Instance = plot.Piso, Position = Vector3.new(-12, 7.125, -12), Normal = Vector3.xAxis, Distance = 40.5 }
quadro()
assert(c1._alvoColocacao.minimo.Y == 6,
	"O reposicionamento deve usar a mesma camada indicada pelo cursor que a colocacao nova.")
tecla("Q")
assert(not c1._movimento and fornalha.Parent == nil
	and perfil.Data.Inventory.FornalhaBasica == inventarioFornalhaAntesDoMovimento + 1,
	"Cancelar deve encerrar o movimento e devolver a fornalha ao inventario.")
tecla("Q")
assert(c1._modoSelecao == nil)
print("PASS: camada vertical da fornalha segue o cursor em colocacao e reposicionamento.")

-- O clique do meio executa a acao de uma unica peca sem exigir abrir Z, X ou C.
do
	tempo += 1
	assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.new(0, 39, 0), CFrame.identity))
	tempo += 1
	assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.new(24, 39, 24), CFrame.identity))
	local copiaRapida = maquinaNoLocal("Esteira2x2", Vector3.new(0, 39, 0))
	local segundaPeca = maquinaNoLocal("Esteira2x2", Vector3.new(24, 39, 24))
	assert(copiaRapida and segundaPeca)
	local function cliqueMeio(maquina, shift, ctrl, alt, modificadorDireito)
		resultado = { Instance = maquina:FindFirstChildWhichIsA("BasePart", true) }
		teclasAtivas[teclas.LeftShift] = shift == true and not modificadorDireito
		teclasAtivas[teclas.RightShift] = shift == true and modificadorDireito == true
		teclasAtivas[teclas.LeftControl] = ctrl == true and not modificadorDireito
		teclasAtivas[teclas.RightControl] = ctrl == true and modificadorDireito == true
		teclasAtivas[teclas.LeftAlt] = alt == true and not modificadorDireito
		teclasAtivas[teclas.RightAlt] = alt == true and modificadorDireito == true
		input:Fire({ UserInputType = roblox.Enum.UserInputType.MouseButton3 }, false)
		table.clear(teclasAtivas)
	end

	local copiasAntes = #perfil.Data.MaquinasColocadas
	cliqueMeio(copiaRapida)
	assert(c1._movimento and c1._movimento.Copia and #c1._movimento.Pecas == 1
		and copiaRapida.Parent == plot.Maquinas and #perfil.Data.MaquinasColocadas == copiasAntes,
		"O clique do meio deve abrir uma previa de copia de uma unica peca e preservar a origem.")
	tecla("Q")
	assert(not c1._movimento)

	-- Mesmo com duas pecas marcadas no modo C, o atalho copia apenas a peca sob o cursor.
	tecla("C")
	resultado = { Instance = copiaRapida:FindFirstChildWhichIsA("BasePart", true) }
	shiftClick(copiaRapida)
	resultado = { Instance = segundaPeca:FindFirstChildWhichIsA("BasePart", true) }
	shiftClick(segundaPeca)
	assert(#c1._pecasSelecionadas == 2)
	cliqueMeio(copiaRapida)
	assert(c1._movimento and c1._movimento.Copia and #c1._movimento.Pecas == 1
		and #c1._pecasSelecionadas == 0 and copiaRapida.Parent == plot.Maquinas and segundaPeca.Parent == plot.Maquinas,
		"O atalho de copia deve ignorar a selecao de grupo e copiar somente o alvo.")
	tecla("Q")
	tecla("Q")
	assert(c1._modoSelecao == nil)

	local estoqueAntesMover = perfil.Data.Inventory.Esteira2x2
	cliqueMeio(copiaRapida, true, false, false, true)
	assert(c1._movimento and not c1._movimento.Grupo and #c1._movimento.Pecas == 1
		and copiaRapida.Parent == nil,
		"Shift+clique do meio deve iniciar o movimento de uma unica peca e retirar a origem do terreno.")
	tecla("Q")
	assert(not c1._movimento and perfil.Data.Inventory.Esteira2x2 == estoqueAntesMover + 1,
		"Cancelar o movimento rapido deve devolver a peca ao inventario.")

	local estoqueAntesExcluir = perfil.Data.Inventory.Esteira2x2
	cliqueMeio(segundaPeca, false, true)
	assert(segundaPeca.Parent == nil and perfil.Data.Inventory.Esteira2x2 == estoqueAntesExcluir + 1,
		"Ctrl+clique do meio deve retirar uma unica peca e devolve-la ao inventario sem exigir modo Z.")
end
print("PASS: Mouse3 copia uma peca, Shift+Mouse3 move uma peca e Ctrl+Mouse3 a retira do terreno.")

do
	local venda = {}
	tempo += 1
	assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.new(0, 42, 0), CFrame.identity))
	tempo += 1
	assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.new(24, 42, 24), CFrame.identity))
	venda.A = maquinaNoLocal("Esteira2x2", Vector3.new(0, 42, 0))
	venda.B = maquinaNoLocal("Esteira2x2", Vector3.new(24, 42, 24))
	assert(venda.A and venda.B)
	venda.Saldo = perfil.Data.Dinheiro
	venda.Estoque = perfil.Data.Inventory.Esteira2x2
	venda.Construcoes = #perfil.Data.MaquinasColocadas
	assert(not redes.Construcao:VenderColocadas(p1, { venda.A, venda.A })
		and venda.A.Parent == plot.Maquinas and venda.B.Parent == plot.Maquinas
		and perfil.Data.Dinheiro == venda.Saldo,
		"Uma venda com peça duplicada deve recusar o lote sem remover nem pagar parcialmente.")
	tecla("V")
	assert(c1._modoSelecao == "Venda" and c1._caixaSelecao.Color.G > 0.6
		and c1._caixaSelecao.ContornoSelecao.Color3.G > 0.9
		and not interface._interface:FindFirstChild("ModoAtual"),
		"V deve abrir a seleção de venda com destaque verde.")
	resultado = { Instance = venda.A:FindFirstChildWhichIsA("BasePart", true) }
	shiftClick(venda.A)
	resultado = { Instance = venda.B:FindFirstChildWhichIsA("BasePart", true) }
	shiftClick(venda.B)
	assert(#c1._pecasSelecionadas == 2)
	p1:SetAttribute("ConfirmarVenda","Sempre")
	assert(c1:ConfirmarVendaTerreno() and c1.Navegacao:Contem("Confirmacao"))
	assert(venda.A.Parent==plot.Maquinas and venda.B.Parent==plot.Maquinas)
	resultado=nil; quadro()
	interface._confirmacao._nao:ObterInstancia().Activated:Fire()
	assert(not c1.Navegacao:Contem("Confirmacao") and venda.A.Parent==plot.Maquinas and venda.B.Parent==plot.Maquinas)
	resultado={Instance=venda.A:FindFirstChildWhichIsA("BasePart",true)}; quadro()
	assert(c1:ConfirmarVendaTerreno())
	resultado=nil; quadro()
	-- Simula o alvo mudando enquanto o usuario move o mouse ate o botao do dialogo.
	c1._maquinaSelecionada=nil
	interface._confirmacao._sim:ObterInstancia().Activated:Fire()
	p1:SetAttribute("ConfirmarVenda","Nunca")
	resultado = nil
	quadro()
	assert(venda.A.Parent == nil and venda.B.Parent == nil
		and perfil.Data.Dinheiro == carregar("src/server/InteiroGrande").somar(venda.Saldo,
			carregar("src/server/InteiroGrande").somar(catalogo.Esteira2x2.Preco, catalogo.Esteira2x2.Preco))
		and perfil.Data.Inventory.Esteira2x2 == venda.Estoque
		and #perfil.Data.MaquinasColocadas == venda.Construcoes - 2,
		"V deve vender o grupo inteiro, somar os preços exatos e não devolver as peças ao inventário.")
	tecla("Q")
	assert(c1._modoSelecao == nil)

	-- Alt+Mouse3 vende exatamente o alvo, mesmo com outra peça próxima na plot.
	tempo += 1
	assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.new(0, 45, 0), CFrame.identity))
	tempo += 1
	assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.new(24, 45, 24), CFrame.identity))
	venda.A = maquinaNoLocal("Esteira2x2", Vector3.new(0, 45, 0))
	venda.B = maquinaNoLocal("Esteira2x2", Vector3.new(24, 45, 24))
	venda.Saldo = perfil.Data.Dinheiro
	venda.Estoque = perfil.Data.Inventory.Esteira2x2
	resultado = { Instance = venda.A:FindFirstChildWhichIsA("BasePart", true) }
	teclasAtivas[teclas.RightAlt] = true
	input:Fire({ UserInputType = roblox.Enum.UserInputType.MouseButton3 }, false)
	table.clear(teclasAtivas)
	assert(venda.A.Parent == nil and venda.B.Parent == plot.Maquinas
		and perfil.Data.Dinheiro == carregar("src/server/InteiroGrande").somar(venda.Saldo, catalogo.Esteira2x2.Preco)
		and perfil.Data.Inventory.Esteira2x2 == venda.Estoque,
		"Alt+Mouse3 deve vender somente a peça apontada e creditar o preço do catálogo.")
end
print("PASS: V vende grupos atomicamente e Alt+Mouse3 vende uma unica peca pelo preco do catalogo.")

do
	local contexto = { Alvo = plot.Maquinas:GetChildren()[1], Chamadas = {} }
	assert(contexto.Alvo, "O teste precisa de uma peca colocada para abrir o menu contextual.")
	resultado = { Instance = contexto.Alvo:FindFirstChildWhichIsA("BasePart", true) }
	quadro()
	assert(c1._destaqueHover.Adornee == contexto.Alvo and c1._destaqueHover.Enabled
		and c1._destaqueHover.OutlineColor.R == 1 and c1._destaqueHover.OutlineColor.G == 1
		and c1._destaqueHover.OutlineColor.B == 1 and c1._destaqueHover.FillTransparency == 1,
		"O mouse deve contornar em branco apenas a peca sob o cursor.")
	clique()
	assert(c1.Navegacao:Atual() == "MenuPeca" and interface._menuPeca.Visible
		and interface._menuPeca.Parent == interface._menuGui and interface._menuPeca.AnchorPoint.Y == 0.5,
		"Clicar na peca deve abrir o cartao contextual sobre o corpo.")
	assert(interface._menuPeca.Size == roblox.UDim2.fromOffset(208, 202)
		and interface._tituloPeca.Text == catalogo[contexto.Alvo.Name].Nome
		and interface._selecaoPeca.Text == "1 selecionada" and interface._tipoPeca.Text == "Esteira")
	assert(interface._contornoPeca.Visible and interface._contornoPeca.Adornee == interface._volumePeca
		and not interface._volumePeca.CanCollide and not interface._volumePeca.CanQuery)
	for _, acao in { "Estatisticas", "Copiar", "Mover", "Excluir", "Vender" } do
		assert(interface._botoesPecaContexto[acao], "O menu deve oferecer " .. acao .. ".")
	end
	contexto.Atalhos = { Excluir = "Z", Mover = "X", Copiar = "C", Vender = "V" }
	for acao, atalho in contexto.Atalhos do
		assert(interface._botoesPecaContexto[acao]:ObterInstancia():FindFirstChild("Atalho").Text == atalho)
	end
	assert(interface._botoesPecaContexto.Excluir:ObterInstancia():FindFirstChild("Rotulo").Text == "Recolher")
	for _, linha in { { "Excluir", "Mover" }, { "Copiar", "Vender" } } do
		local esquerda = interface._botoesPecaContexto[linha[1]]:ObterInstancia()
		local direita = interface._botoesPecaContexto[linha[2]]:ObterInstancia()
		assert(esquerda.Position.Y == direita.Position.Y and esquerda.Size == direita.Size
			and esquerda.Position.X.Offset + esquerda.Size.X.Offset < direita.Position.X.Offset,
			"Cada linha da grade deve ter duas acoes iguais sem sobreposicao.")
	end
	contexto.PrimeiraAcao = interface._botoesPecaContexto.Excluir:ObterInstancia()
	contexto.SegundaLinha = interface._botoesPecaContexto.Copiar:ObterInstancia()
	assert(contexto.PrimeiraAcao.Position.Y.Offset + contexto.PrimeiraAcao.Size.Y.Offset < contexto.SegundaLinha.Position.Y.Offset
		and contexto.SegundaLinha.Position.Y.Offset + contexto.SegundaLinha.Size.Y.Offset
			< interface._botoesPecaContexto.Estatisticas:ObterInstancia().Position.Y.Offset,
		"A grade compacta deve deixar a lupa no rodape, abaixo das acoes.")
	interface._botoesPecaContexto.Estatisticas:ObterInstancia().Activated:Fire()
	assert(interface._estatisticasPeca.Visible and interface._areaEstatisticasPeca.Visible
		and interface._menuPeca.Size.Y.Offset == 338 and interface._estatisticasPeca.Text:find("Transporte:", 1, true),
		"Ver estatisticas deve exibir as caracteristicas efetivas da unidade selecionada.")
	interface._botoesPecaContexto.Estatisticas:ObterInstancia().Activated:Fire()
	assert(not interface._areaEstatisticasPeca.Visible and interface._menuPeca.Size.Y.Offset == 202)

	contexto.Original = {
		IniciarCopiaGrupo = c1.IniciarCopiaGrupo,
		IniciarReposicionamento = c1.IniciarReposicionamento,
		ConfirmarRecolhimento = c1.ConfirmarRecolhimento,
		ConfirmarVendaTerreno = c1.ConfirmarVendaTerreno,
	}
	c1.IniciarCopiaGrupo = function(_, maquina, somente)
		contexto.Chamadas.Copiar = { maquina, somente }; return true
	end
	c1.IniciarReposicionamento = function(_, maquina, somente)
		contexto.Chamadas.Mover = { maquina, somente }; return true
	end
	c1.ConfirmarRecolhimento = function(self)
		contexto.Chamadas.Excluir = { self._maquinaSelecionada }; return true
	end
	c1.ConfirmarVendaTerreno = function(_, maquina)
		contexto.Chamadas.Vender = { maquina }; return true
	end
	for _, acao in { "Copiar", "Mover", "Excluir", "Vender" } do
		for _, entrada in { "Botao", "Tecla" } do
			c1:_AbrirMenuPeca(contexto.Alvo)
			contexto.Chamadas[acao] = nil
			if entrada == "Botao" then interface._botoesPecaContexto[acao]:ObterInstancia().Activated:Fire()
			else tecla(contexto.Atalhos[acao]) end
			assert(contexto.Chamadas[acao] and contexto.Chamadas[acao][1] == contexto.Alvo
				and not interface._menuPeca.Visible and not interface._contornoPeca.Visible,
				acao .. " deve agir somente sobre a peca clicada e fechar o menu.")
		end
	end
	for nome, metodo in contexto.Original do c1[nome] = nil; assert(metodo) end
	contexto.Broca = modelos.MineradoraGalactica:Clone()
	contexto.Broca:SetAttribute("PodeRecolher", true)
	contexto.Broca.Parent = plot.Maquinas
	c1:_AbrirMenuPeca(contexto.Broca)
	assert(interface._tipoPeca.Text == "Mineradora" and interface._volumePeca.Size == contexto.Broca.HitboxConstrucao.Size
		and interface._volumePeca.CFrame == contexto.Broca.HitboxConstrucao.CFrame,
		"A broca externa nao deve deslocar o menu ou aumentar o contorno do corpo.")
	contexto.Viewport = camera.ViewportSize
	camera.ViewportSize = roblox.Vector2.new(320, 240)
	interface._botoesPecaContexto.Estatisticas:ObterInstancia().Activated:Fire()
	contexto.Escala = interface._escalaMenuPeca.Scale
	contexto.Posicao = interface._menuPeca.Position
	assert(contexto.Escala < 1 and contexto.Posicao.X.Offset - 104 * contexto.Escala >= 7.99
		and contexto.Posicao.X.Offset + 104 * contexto.Escala <= 312.01
		and contexto.Posicao.Y.Offset - 169 * contexto.Escala >= 7.99
		and contexto.Posicao.Y.Offset + 169 * contexto.Escala <= 232.01,
		"O cartao expandido deve permanecer inteiro numa viewport pequena.")
	camera.ViewportSize = contexto.Viewport
	contexto.Broca:Destroy()
	interface:_AtualizarMenuPeca()
	assert(not interface._menuPeca.Visible and not interface._contornoPeca.Visible)
	print("PASS: cartao compacto 208x202, grade 2x2, lupa no rodape, contorno do corpo, tela pequena e acoes Z/X/C/V.")
end

do
	local comum = { Origem = carregar("src/shared/GeometriaColocacao").Origem(plot.Piso) }
	c1:_EncerrarAcao()
	local function criarPar()
		while perfil.Data.Inventory.Esteira2x2 < 2 do
			assert(manager.ObterDados(p1):ComprarMaquina("Esteira2x2"))
		end
		for _, posicao in { Vector3.new(0, 30, 0), Vector3.new(24, 30, 24) } do
			tempo += 1
			assert(redes.Construcao:Colocar(p1, "Esteira2x2", posicao, CFrame.identity))
		end
		return maquinaNoLocal("Esteira2x2", Vector3.new(0, 30, 0)),
			maquinaNoLocal("Esteira2x2", Vector3.new(24, 30, 24))
	end
	local function selecionarPar(abrirMenu)
		c1:_LimparSelecaoPecas()
		raioPorTela = function(x, z)
			return { Origin = comum.Origem:PointToWorldSpace(Vector3.new(x, 100, z)), Direction = -comum.Origem.UpVector }
		end
		resultado = { Instance = comum.A.Correia, Position = comum.Origem:PointToWorldSpace(Vector3.new(0.75, 31.5, 0.75)) }
		local entrada = iniciarArraste(roblox.Vector2.new(1, 1))
		moverArraste(roblox.Vector2.new(41, 41))
		assert(c1._modoSelecao == "Selecao" and c1._caixaSelecao.Color == roblox.Color3.new(1, 1, 1)
			and c1._caixaSelecao.ContornoSelecao.Color3 == roblox.Color3.new(1, 1, 1))
		assert(#c1._pecasSelecionadas == 2 and c1._destaquesPecas[comum.A].OutlineColor == roblox.Color3.new(1, 1, 1)
			and c1._destaquesPecas[comum.B].FillColor == roblox.Color3.new(1, 1, 1))
		terminarArraste(entrada)
		assert(not interface._menuPeca.Visible and not c1._caixaSelecao.Parent and not acaoRodaSelecao,
			"Soltar a selecao branca deve manter o grupo marcado sem abrir o cartao ou prender a roda.")
		raioPorTela = nil
		if abrirMenu == false then return end
		resultado = { Instance = comum.A.Correia }
		clique()
		assert(interface._menuPeca.Visible and interface._selecaoPeca.Text == "2 selecionadas"
			and interface._tituloPeca.Text == "Seleção de peças" and #c1:ObterPecasFocadas() == 2,
			"Clicar numa peca do grupo deve abrir o cartao compacto para ambas as unidades.")
	end
	comum.A, comum.B = criarPar()
	selecionarPar()
	interface._botoesPecaContexto.Estatisticas:ObterInstancia().Activated:Fire()
	assert(interface._estatisticasPeca.Text:find("Peça de referência:", 1, true),
		"As estatisticas de uma unidade nao devem ser apresentadas como dados do grupo inteiro.")
	shiftClick(comum.B)
	assert(#c1._pecasSelecionadas == 1 and not interface._menuPeca.Visible)
	shiftClick(comum.B)
	assert(#c1._pecasSelecionadas == 2)
	resultado = { Instance = plot.Piso }
	clique()
	assert(#c1._pecasSelecionadas == 0 and not next(c1._destaquesPecas) and not interface._menuPeca.Visible,
		"Um clique vazio deve limpar o grupo sem mover, vender ou recolher pecas.")
	selecionarPar()
	interface._botoesPecaContexto.Copiar:ObterInstancia().Activated:Fire()
	assert(c1._movimento and c1._movimento.Copia and #c1._movimento.Pecas == 2
		and comum.A.Parent == plot.Maquinas and comum.B.Parent == plot.Maquinas)
	comum.Colocadas = #perfil.Data.MaquinasColocadas
	resultado = { Instance = plot.Piso, Position = comum.Origem:PointToWorldSpace(Vector3.new(3, 18, 3)),
		Normal = comum.Origem.UpVector, Distance = 10 }
	raio = { Origin = resultado.Position + comum.Origem.UpVector * 100, Direction = -comum.Origem.UpVector }
	quadro()
	assert(c1._alvoColocacao.livre and #c1._alvosGrupo == 2)
	clique()
	assert(#perfil.Data.MaquinasColocadas == comum.Colocadas + 2 and not c1._arrasteSelecao,
		"O clique durante a previa do grupo branco deve colocar a copia, sem iniciar outra selecao.")
	tecla("Q")
	selecionarPar(false)
	tecla("C")
	assert(c1._movimento and c1._movimento.Copia and #c1._movimento.Pecas == 2
		and comum.A.Parent == plot.Maquinas and comum.B.Parent == plot.Maquinas,
		"C deve copiar o grupo branco sem um clique extra para abrir o cartao.")
	tecla("Q")
	selecionarPar(false)
	comum.Estoque = perfil.Data.Inventory.Esteira2x2
	tecla("X")
	assert(c1._movimento and not c1._movimento.Copia and #c1._movimento.Pecas == 2
		and comum.A.Parent == nil and comum.B.Parent == nil)
	tecla("Q")
	assert(perfil.Data.Inventory.Esteira2x2 == comum.Estoque + 2,
		"Cancelar o movimento do grupo branco deve devolver as duas unidades ao inventario.")
	comum.A, comum.B = criarPar()
	selecionarPar(false)
	comum.Estoque = perfil.Data.Inventory.Esteira2x2
	tecla("Z")
	assert(comum.A.Parent == nil and comum.B.Parent == nil and perfil.Data.Inventory.Esteira2x2 == comum.Estoque + 2)
	comum.A, comum.B = criarPar()
	selecionarPar(false)
	comum.Saldo, comum.Estoque = perfil.Data.Dinheiro, perfil.Data.Inventory.Esteira2x2
	tecla("V")
	assert(comum.A.Parent == nil and comum.B.Parent == nil and perfil.Data.Inventory.Esteira2x2 == comum.Estoque
		and perfil.Data.Dinheiro == carregar("src/server/InteiroGrande").somar(comum.Saldo, "50"),
		"Vender pelo cartao branco deve vender o lote inteiro pelo preco do servidor.")
	resultado = { Instance = plot.Piso }
	clique()
	assert(c1:AlternarPainelCentral("Prestigio") and not c1._modoSelecao and not c1.Navegacao:Contem("Selecao"),
		"A selecao comum nao deve bloquear a abertura de outros paineis.")
	tecla("Q")
	print("PASS: arraste branco, cartao opcional, Shift, clique vazio e atalhos C/X/Z/V diretos sobre a selecao sem clique extra.")
end

do
	local function testarBlueprints()
		tempo += 100
		local dadosJogador = manager.ObterDados(p1)
		while dadosJogador:ObterQuantidade("Esteira2x2") < 2 do
			assert(dadosJogador:ComprarMaquina("Esteira2x2"), "O teste precisa de duas esteiras no inventário.")
		end
		assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.new(0, 36, 0), CFrame.identity))
		tempo += 1
		assert(redes.Construcao:Colocar(p1, "Esteira2x2", Vector3.new(24, 36, 24), CFrame.Angles(0, math.pi / 2, 0)))
		local fonteA = maquinaNoLocal("Esteira2x2", Vector3.new(0, 36, 0))
		local fonteB = maquinaNoLocal("Esteira2x2", Vector3.new(24, 36, 24))
		assert(fonteA and fonteB)
		local personalizada, _, fontePersonalizada = redes.Construcao.Personalizar(p1, fonteA, {
			Configuracao = { Componentes = { { Velocidade = 11 } } }, Dados = { Melhoria = 5 },
		})
		assert(personalizada, "A fonte do blueprint precisa aceitar uma configuração de teste.")
		fonteA = fontePersonalizada
		-- Personalizar recria A no fim da pasta; o cenario usa A como ancora do grupo.
		fonteB.Parent = nil; fonteB.Parent = plot.Maquinas

		tecla("B")
		local painelBlueprints = interface._painelBlueprints
		assert(painelBlueprints._grupo.Visible and #painelBlueprints._listaBlueprints == 0,
			"B deve abrir a lista persistente de blueprints.")
		painelBlueprints._nome.Text = "Esteiras de teste"
		painelBlueprints._botaoCriar:ObterInstancia().Activated:Fire()
		assert(c1._modoSelecao == "Blueprint" and not painelBlueprints._grupo.Visible
			and c1._caixaSelecao.Transparency == 1
			and c1._caixaSelecao.ContornoSelecao.Color3.B > 0.6,
			"Criar blueprint deve fechar as abas e iniciar uma seleção 3D azul.")
		local listras = c1._faixasSelecao
		local origemBlueprint = carregar("src/shared/GeometriaColocacao").Origem(plot.Piso)
		raioPorTela = function(x, z)
			return { Origin = origemBlueprint:PointToWorldSpace(Vector3.new(x, 500, z)), Direction = -origemBlueprint.UpVector }
		end
		resultado = {
			Instance = fonteA:FindFirstChildWhichIsA("BasePart", true),
			Position = origemBlueprint:PointToWorldSpace(Vector3.new(1.5, 37.5, 1.5)),
		}
		local arrasteBlueprint = iniciarArraste(roblox.Vector2.new(2, 2))
		moverArraste(roblox.Vector2.new(42, 42))
		local passoBlueprint = carregar("src/shared/GeometriaColocacao").Passo
		local periodoListras = 2 * passoBlueprint
		local function conferirCobertura(tamanho, deslocamento)
			listras.deslocamento = deslocamento
			c1:_AtualizarListrasSelecao(tamanho)
			for _, face in listras.faces do
				assert(not face.Superficie.AlwaysOnTop and face.Superficie.ClipsDescendants
					and face.Superficie.SizingMode == roblox.Enum.SurfaceGuiSizingMode.FixedSize
					and face.Superficie.Parent == c1._caixaSelecao,
					"As listras devem preencher a face e respeitar a profundidade das pecas.")
				local largura, altura
				-- O esperado vem dos eixos do canvas medidos no Studio, sem reutilizar o mapeamento do controlador.
				local lado = face.Superficie.Face
				if lado == roblox.Enum.NormalId.Front or lado == roblox.Enum.NormalId.Back then
					largura, altura = tamanho.X, tamanho.Y
				elseif lado == roblox.Enum.NormalId.Left or lado == roblox.Enum.NormalId.Right then
					largura, altura = tamanho.Z, tamanho.Y
				else
					largura, altura = tamanho.Z, tamanho.X
				end
				assert(math.abs(face.Largura - largura) < 0.01 and math.abs(face.Altura - altura) < 0.01,
					"As faixas devem seguir a largura e a altura reais do canvas de cada face.")
				local pixelsPorStud = face.Superficie.CanvasSize.X / largura
				assert(pixelsPorStud == 24,
					"A densidade fisica da face deve manter cada listra com a mesma largura em qualquer retangulo.")
				local lado = 2 * passoBlueprint * math.sqrt(2)
				local quantidade = 0
				for _, faixa in face.Faixas do
					local f = faixa.Instancia
					if not f.Visible then continue end
					quantidade += 1
					assert((f.Rotation or 0) == 0 and f.BackgroundTransparency == 0.7,
						"O recorte deve usar quadrados sem giro e preservar a transparencia.")
					assert(f.Size.X.Offset == math.ceil(lado * pixelsPorStud) + 1
						and f.Size.Y.Offset == f.Size.X.Offset,
						"O padrao deve ter tamanho fixo em qualquer retangulo.")
				end
				local canto = (face.Normal-face.U-face.V)*tamanho/2
	            local faseFace = ((face.U.X+face.U.Y+face.U.Z)*(deslocamento-canto.X-canto.Y-canto.Z))%lado
	            local colunas = math.ceil((largura-faseFace)/lado)-math.floor(-faseFace/lado)
				assert(quantidade == colunas * math.ceil(altura / lado),
					"A quantidade de quadrados deve cobrir toda a face, incluindo as pontas parciais.")
			end
		end
		assert(#listras.faces == 6, "As listras devem cobrir todas as faces do volume.")
		local tamanhoOriginalListras = c1._caixaSelecao.Size
		for _, tamanho in {
			tamanhoOriginalListras,
			roblox.Vector3.new(3, 3, 3),
			roblox.Vector3.new(24, 9, 6),
			roblox.Vector3.new(6, 9, 24),
			roblox.Vector3.new(120, 3, 48),
			roblox.Vector3.new(15, 27, 6),
		} do
			for _, fase in { 0, periodoListras * math.sqrt(2) / 2, periodoListras * math.sqrt(2) - 1e-4 } do
				conferirCobertura(tamanho, fase)
			end
		end
		listras.deslocamento = 0
		c1:_AtualizarListrasSelecao(tamanhoOriginalListras)
		assert(not c1._caixaSelecao.ContornoSelecao.Visible,
			"O contorno liso nao deve aparecer por cima das bordas listradas do blueprint.")
		local deslocamentoListras = listras.deslocamento
		local faixaMovel = listras.faces[1].Faixas[1].Instancia
		local posicaoInicialListras = faixaMovel.Position
		heartbeat:Fire(1 / 60)
		assert(listras.deslocamento ~= deslocamentoListras, "As listras devem se mover enquanto a seleção está ativa.")
		local posicaoAtualListras = faixaMovel.Position
		local deslocamentoVisual = roblox.Vector2.new(
			posicaoAtualListras.X.Offset - posicaoInicialListras.X.Offset,
			posicaoAtualListras.Y.Offset - posicaoInicialListras.Y.Offset
		)
		assert(deslocamentoVisual.Magnitude > 0.1,
			"A animacao deve mover as faixas visiveis, nao apenas atualizar uma variavel.")
		local segmentosBorda = 0
		for _, borda in listras.bordas do
			assert(#borda.Segmentos > 0, "Cada aresta do volume deve ter segmentos listrados.")
			for _, segmento in borda.Segmentos do
				if segmento.Transparency < 1 then
					assert(segmento.Transparency >= 0.4,
						"As listras das bordas tambem devem deixar o interior mais visivel.")
					segmentosBorda += 1
				end
			end
		end
		assert(segmentosBorda > 0, "As bordas devem acompanhar a caixa de selecao com listras visiveis.")
		local segmentoMovel
		for _, segmento in listras.bordas[1].Segmentos do
			if segmento.Transparency < 1 and math.abs(segmento.Size.X - 3*math.sqrt(2)) < 0.01 then
				segmentoMovel = segmento
				break
			end
		end
		assert(segmentoMovel, "A aresta deve conter ao menos a projecao de uma listra diagonal inteira.")
		local posicaoInicialBorda, corInicialBorda = segmentoMovel.CFrame.Position, segmentoMovel.Color
		quadro()
		assert((segmentoMovel.CFrame.Position - posicaoInicialBorda).Magnitude > 0.1
			and segmentoMovel.Color == corInicialBorda,
			"As listras da borda devem deslizar continuamente, sem trocar de cor em saltos.")
		local tamanhoCaixaOriginal = c1._caixaSelecao.Size
		local deslocamentoBordaOriginal = listras.deslocamento
		local function conferirCoberturaBorda(comprimento, deslocamento)
			c1._caixaSelecao.Size = roblox.Vector3.new(comprimento, 4, 4)
			listras.deslocamento = deslocamento
			c1:_AtualizarBordasListradas(c1._caixaSelecao)
			local intervalos = {}
			for _, segmento in listras.bordas[1].Segmentos do
				if segmento.Transparency < 1 then
					local centro = c1._caixaSelecao.CFrame:PointToObjectSpace(segmento.CFrame.Position).X
					table.insert(intervalos, { centro - segmento.Size.X / 2, centro + segmento.Size.X / 2 })
				end
			end
			local inicioFase = deslocamento + comprimento/2 + 4
	        local passoAresta = passoBlueprint*math.sqrt(2)
	        local primeiraFaixa = math.floor(-inicioFase/passoAresta)
	        local ultimaFaixa = math.ceil((comprimento-inicioFase)/passoAresta)-1
			assert(#intervalos == ultimaFaixa - primeiraFaixa + 1,
				"A borda deve criar exatamente as faixas cujo intervalo cruza seu comprimento.")
			table.sort(intervalos, function(a, b) return a[1] < b[1] end)
			local cobertoAte = -comprimento / 2
			for _, intervalo in intervalos do
				assert(intervalo[1] <= cobertoAte + 0.01,
					"O calculo das faixas nao pode deixar lacunas entre segmentos consecutivos.")
				cobertoAte = math.max(cobertoAte, intervalo[2])
			end
			assert(cobertoAte >= comprimento / 2 - 0.01,
				"A ultima listra precisa alcancar a extremidade da aresta, mesmo se for parcial.")
		end
		for _, comprimento in { 4, 5.5, 8, 9, 32, 33.25, 65 } do
			for _, fase in { 0, 0.01, 3.99, 4, 7.99 } do
				conferirCoberturaBorda(comprimento, fase)
			end
		end
		c1._caixaSelecao.Size = tamanhoCaixaOriginal
		listras.deslocamento = deslocamentoBordaOriginal
		c1:_AtualizarBordasListradas(c1._caixaSelecao)
		assert(#c1._pecasSelecionadas == 2 and c1._destaquesPecas[fonteA].FillColor.B > 0.6
			and c1._destaquesPecas[fonteB].FillColor.B > 0.6,
			"A caixa 3D de blueprint deve selecionar e destacar as peças que contém.")
		terminarArraste(arrasteBlueprint)
		raioPorTela = nil
		assert(#perfil.Data.Blueprints == 1 and perfil.Data.Blueprints[1].Nome == "Esteiras de teste"
			and #perfil.Data.Blueprints[1].Pecas == 2
			and perfil.Data.Blueprints[1].Pecas[1].Modificacoes.Dados.Melhoria == 5
			and perfil.Data.Blueprints[1].Pecas[1].Modificacoes.Configuracao.Componentes[1].Velocidade == 11,
			"Salvar deve persistir nome, peças e personalizações no perfil.")
		assert(painelBlueprints._grupo.Visible and #painelBlueprints._listaBlueprints == 1
			and painelBlueprints._status.Text == "Blueprint salvo." and painelBlueprints._nome.Text == "",
			"Após salvar, a lista deve reabrir e mostrar o resultado e o blueprint.")

		painelBlueprints._listaBlueprints[1]:ObterInstancia().Activated:Fire()
		assert(c1._movimento and c1._movimento.Blueprint and c1._movimento.BlueprintNome == "Esteiras de teste"
			and #c1._movimento.Pecas == 2 and painelBlueprints._grupo.Visible == false,
			"Selecionar um item deve abrir a prévia do conjunto sem as fontes saírem da plot.")
		tecla("Q")
		assert(not c1._movimento and fonteA.Parent == plot.Maquinas and fonteB.Parent == plot.Maquinas,
			"Cancelar a prévia do blueprint deve preservar as peças originais.")

		tempo += 5
		local sucessoPrevia, _, previaBlueprint = redes.Construcao:PrepararBlueprint(p1, perfil.Data.Blueprints[1].Id)
		assert(sucessoPrevia and previaBlueprint.BlueprintNome == "Esteiras de teste"
			and previaBlueprint.Pecas[1].Modificacoes.Dados.Melhoria == 5
			and (previaBlueprint.Pecas[2].RotacaoInicial.RightVector - CFrame.Angles(0, math.pi / 2, 0).RightVector).Magnitude < 0.0001,
			"Preparar deve restaurar melhorias e orientação do blueprint salvo.")
		local saldoAntesBlueprint = perfil.Data.Dinheiro
		local estoqueAntesBlueprint = perfil.Data.Inventory.Esteira2x2
		local colocacoesAntesBlueprint = #perfil.Data.MaquinasColocadas
		local custoBlueprint = math.max(0, 2 - estoqueAntesBlueprint) * 25
		local pedidosBlueprint = {
			{ Minimo = Vector3.new(0, 24, 0), Rotacao = previaBlueprint.Pecas[1].RotacaoInicial },
			{ Minimo = Vector3.new(24, 24, 24), Rotacao = previaBlueprint.Pecas[2].RotacaoInicial },
		}
		local colocouBlueprint, mensagemBlueprint = redes.Construcao:ColocarGrupoCopia(p1, previaBlueprint.Token, pedidosBlueprint)
		assert(colocouBlueprint, mensagemBlueprint)
		local InteiroGrande = carregar("src/server/InteiroGrande")
		local saldoEsperado = custoBlueprint > 0
			and InteiroGrande.subtrair(saldoAntesBlueprint, tostring(custoBlueprint)) or saldoAntesBlueprint
		assert(perfil.Data.Dinheiro == saldoEsperado
			and perfil.Data.Inventory.Esteira2x2 == math.max(0, estoqueAntesBlueprint - 2)
			and #perfil.Data.MaquinasColocadas == colocacoesAntesBlueprint + 2
			and maquinaNoLocal("Esteira2x2", Vector3.new(0, 24, 0))
			and maquinaNoLocal("Esteira2x2", Vector3.new(24, 24, 24)),
			"Colocar o blueprint deve manter o conjunto, consumir estoque e cobrar somente as unidades faltantes.")
		tempo += 5
		local segundaA = maquinaNoLocal("Esteira2x2", Vector3.new(0, 24, 0))
		local segundaB = maquinaNoLocal("Esteira2x2", Vector3.new(24, 24, 24))
		local criouAutomatico, _, blueprintAutomatico = redes.Construcao:CriarBlueprint(p1, "", { segundaA, segundaB })
		assert(criouAutomatico and blueprintAutomatico.Nome == "Blueprint 2"
			and #perfil.Data.Blueprints == 2,
			"Um nome vazio deve gerar o próximo nome automático sem substituir o blueprint anterior.")
		print("PASS: blueprints 3D são nomeados, persistidos, reconstruídos e colocados como grupo com cobrança normal.")
	end
	testarBlueprints()
end

do
	local function testarMilSelecionadas()
		local limite=carregar("src/shared/LimitesConstrucao").PecasPorGrupo
		assert(limite==1000)
		local Controlador=carregar("src/client/ControladorConstrucao")
		local grande=Controlador.new(p1)
		local pasta=Instance.new("Folder"); pasta.Parent=plot
		grande._maquinas,grande._piso,grande._terreno=pasta,plot.Piso,plot
		grande._modoSelecao="Selecao"
		local original=Instance.new("Model"); original.Name="Parede1x1"
		local caixa=Instance.new("Part"); caixa.Name="HitboxConstrucao"; caixa.Size=Vector3.one*3; caixa.Parent=original
		grande._modelosOriginais.Parede1x1=original
		for i=1,limite+1 do
			local m=original:Clone(); m.Parent=pasta
			assert(grande:_DefinirPecaSelecionada(m,true)==(i<=limite))
			if i==250 then assert(grande._destaquesPecas[m].FillColor==roblox.Color3.new(1,1,1)) end
			if i==251 then assert(grande._destaquesPecas[m].Color3==roblox.Color3.new(1,1,1)) end
		end
		assert(#grande._pecasSelecionadas==1000)
		grande:_LimparSelecaoPecas()
		local pecas={}
		for i=1,limite do pecas[i]={MaquinaId="Parede1x1",Modificacoes={},DeslocamentoInicial=Vector3.new(0,i*3,0),RotacaoInicial=CFrame.identity} end
		assert(grande:_IniciarPreviaCopiaGrupo({Token=1,Pecas=pecas},nil,1000))
		local volumes=grande._previa._volumes
		local chamadas=0
		for _,peca in grande._movimento.Pecas do
			assert(peca.Previa._volumes==volumes)
			peca.Previa.AtualizarVolumes=function() chamadas+=1 end
		end
		local resultadoAntes=resultado
		local origem=carregar("src/shared/GeometriaColocacao").Origem(plot.Piso)
		resultado={Instance=plot.Piso,Position=origem:PointToWorldSpace(Vector3.new(24,0,24)),Normal=origem.UpVector,Distance=10}
		grande:Atualizar(1/60); resultado=resultadoAntes
		assert(chamadas==1,"O controlador deve atualizar os volumes uma vez por grupo e por quadro.")
		grande:EncerrarColocacao()
		assert(volumes.Usuarios==0 and volumes.Pasta.Parent==nil)
		table.insert(pecas,pecas[1])
		assert(not grande:_IniciarPreviaCopiaGrupo({Token=2,Pecas=pecas},nil,nil))
		grande:Destruir(); pasta:Destroy(); original:Destroy()
		print("PASS: cliente seleciona 1.000, recusa 1.001, preserva as cores e monta grupo com uma atualizacao de volumes por quadro.")
	end
	testarMilSelecionadas()
end

do
	local function testarArrasteColocacao()
		local c=Controlador.new(p1)
		local pasta=Instance.new("Folder"); pasta.Parent=plot
		c._terreno,c._piso,c._maquinas=plot,plot.Piso,pasta
		c._EncontrarTerreno=function() return true end
		c._PontoNoPlanoSelecao=function(_,p,altura) return Vector3.new(p.X,altura,p.Y) end
		local chamadas={}
		c._redeConstrucao={fetch=function(_,metodo,...)
			table.insert(chamadas,{Metodo=metodo,Argumentos=table.pack(...)})
			return true,"Colocacao simulada."
		end}
		c:Iniciar()
		local mouseAnterior=mouse
		local origem=carregar("src/shared/GeometriaColocacao").Origem(plot.Piso)
		local inicial=Vector3.new(15,9,15)
		local function preparar(id,rotacao)
			c.Navegacao:Limpar()
			c._maquinaIdSelecionada,c._abaColocacao,c._rotacao=id or "Esteira2x2","Loja",rotacao or CFrame.identity
			c:IniciarColocacao()
			local extensao,ocupado=c._previa:ObterVolume(c._rotacao):Calcular(c._rotacao)
			c._alvoColocacao={maquinaId=c._maquinaIdSelecionada,minimo=inicial,rotacao=c._rotacao,ocupado=ocupado,livre=true,
				caixaDestino=origem*CFrame.new(inicial+Vector3.new(ocupado.X/2,extensao.Y,ocupado.Z/2))*c._rotacao,
				volumeDestino=origem*CFrame.new(inicial+ocupado/2)}
			c._previa:Animar(c._alvoColocacao,1)
			c.Navegacao:Abrir("Colocacao",function() c:EncerrarColocacao() end)
			mouse=roblox.Vector2.new(20,20)
		end
		local entrada={UserInputType=roblox.Enum.UserInputType.MouseButton1}
		for _,dir in {Vector3.xAxis,-Vector3.xAxis,Vector3.zAxis,-Vector3.zAxis} do
			preparar()
			local antes=#chamadas
			c:ProcessarEntrada(entrada,false)
			assert(c._arrasteColocacao and #chamadas==antes,"Pressionar nao pode colocar antes de soltar.")
			mouse+=roblox.Vector2.new(dir.X*12,dir.Z*12)
			c:_AtualizarArrasteColocacao(mouse,1/60)
			local a=c._arrasteColocacao
			assert(#a.Alvos==3 and a.Alvos[1].minimo==inicial and a.Alvos[3].minimo==inicial+dir*12)
			assert(a.Previas[1]._volumes==a.Previas[3]._volumes and a.Previas[1]._volumes.Usuarios==3)
			for _,alvo in a.Alvos do assert(alvo.rotacao==CFrame.identity and alvo.minimo.Y==inicial.Y) end
			c:FinalizarEntrada(entrada)
			assert(#chamadas==antes+1 and chamadas[#chamadas].Metodo=="ColocarMultiplos")
			assert(#chamadas[#chamadas].Argumentos[2]==3 and not c._arrasteColocacao and c._previa._volumes.Usuarios==1)
			c:FinalizarEntrada(entrada); assert(#chamadas==antes+1,"Soltar repetidamente nao pode duplicar o pedido.")
		end
		preparar(); c:ProcessarEntrada(entrada,false)
		mouse+=roblox.Vector2.new(12,0); c:_AtualizarArrasteColocacao(mouse,1/60)
		local extra=c._arrasteColocacao.Previas[3]
		mouse=roblox.Vector2.new(20,8); c:_AtualizarArrasteColocacao(mouse,1/60)
		assert(c._arrasteColocacao.Alvos[3].minimo==inicial-Vector3.zAxis*12,"Mudar o eixo deve substituir a linha, sem formar L.")
		mouse=roblox.Vector2.new(20,20); c:_AtualizarArrasteColocacao(mouse,1/60)
		assert(#c._arrasteColocacao.Previas==1 and extra._destruida)
		local antes=#chamadas
		c:FinalizarEntrada(entrada); assert(#chamadas==antes+1 and chamadas[#chamadas].Metodo=="Colocar")
		preparar()
		local projetar=c._PontoNoPlanoSelecao
		c._PontoNoPlanoSelecao=function() return nil end
		c:ProcessarEntrada(entrada,false); c:FinalizarEntrada(entrada)
		assert(chamadas[#chamadas].Metodo=="Colocar","Clique simples deve preservar o alvo mesmo sem intersecao com o plano.")
		c._PontoNoPlanoSelecao=projetar
		preparar("JatoMineral",CFrame.Angles(0,math.pi/2,0)); c:ProcessarEntrada(entrada,false)
		mouse+=roblox.Vector2.new(6,0); c:_AtualizarArrasteColocacao(mouse,1/60)
		assert(#c._arrasteColocacao.Alvos==3 and c._arrasteColocacao.Alvos[3].minimo.X==inicial.X+6)
		assert(c._arrasteColocacao.Alvos[3].rotacao==CFrame.Angles(0,math.pi/2,0))
		c:ProcessarEntrada({KeyCode=teclas.Q,UserInputType=roblox.Enum.UserInputType.Keyboard},false)
		antes=#chamadas; c:FinalizarEntrada(entrada)
		assert(not c._arrasteColocacao and not c._previa and #chamadas==antes)
		preparar(); c:ProcessarEntrada(entrada,false)
		mouse+=roblox.Vector2.new(12,0); c:_AtualizarArrasteColocacao(mouse,1/60)
		perdeuFoco:Fire(); antes=#chamadas; c:FinalizarEntrada(entrada)
		assert(not c._arrasteColocacao and c._previa._volumes.Usuarios==1 and #chamadas==antes)
		local obstaculo=Instance.new("Model")
		obstaculo:SetAttribute("VolumeMinimo",inicial); obstaculo:SetAttribute("VolumeOcupado",Vector3.new(6,3,6)); obstaculo.Parent=pasta
		preparar(); c._previa:AtualizarVolumes(origem,1); c:ProcessarEntrada(entrada,false)
		mouse+=roblox.Vector2.new(12,0); c:_AtualizarArrasteColocacao(mouse,1/60)
		assert(not c._arrasteColocacao.Alvos[1].livre and c._arrasteColocacao.Alvos[2].livre)
		c:FinalizarEntrada(entrada); assert(chamadas[#chamadas].Metodo=="ColocarMultiplos","Ancora bloqueada nao deve impedir o resto da linha.")
		c:EncerrarColocacao()
		local item={MaquinaId="Esteira2x2",Modificacoes={Dados={Nivel=7}},DeslocamentoInicial=Vector3.zero,RotacaoInicial=CFrame.identity}
		assert(c:_IniciarPreviaCopiaGrupo({Token=321,Pecas={item}},nil,1))
		local alvoCopia={maquinaId="Esteira2x2",minimo=inicial,rotacao=CFrame.identity,ocupado=Vector3.new(6,3,6),livre=false,
			caixaDestino=origem*CFrame.new(inicial+Vector3.new(3,1.5,3)),volumeDestino=origem*CFrame.new(inicial+Vector3.new(3,1.5,3))}
		c._previa:AtualizarVolumes(origem,1); c._alvoColocacao=alvoCopia
		c:_AtualizarAlvosGrupo(alvoCopia,origem,1/60)
		mouse=roblox.Vector2.new(20,20); antes=#chamadas
		c:ProcessarEntrada(entrada,false)
		assert(c._arrasteColocacao and #chamadas==antes)
		mouse+=roblox.Vector2.new(12,0); c:_AtualizarArrasteColocacao(mouse,1/60)
		assert(#c._arrasteColocacao.Alvos==3 and not c._arrasteColocacao.Alvos[1].livre and c._arrasteColocacao.Alvos[2].livre)
		assert(c._arrasteColocacao.Personalizacao:ObterDados().Dados.Nivel==7)
		c:FinalizarEntrada(entrada)
		assert(#chamadas==antes+1 and chamadas[#chamadas].Metodo=="ColocarMultiplos")
		assert(chamadas[#chamadas].Argumentos[3]==321 and chamadas[#chamadas].Argumentos[4]==false)
		assert(not c._arrasteColocacao and c._previa._volumes.Usuarios==1)
		c.Navegacao:Limpar()
		local pecas={}
		for i=1,2 do pecas[i]={MaquinaId="Esteira2x2",Modificacoes={},DeslocamentoInicial=Vector3.xAxis*((i-1)*6),RotacaoInicial=CFrame.identity} end
		assert(c:_IniciarPreviaCopiaGrupo({Token=123,Pecas=pecas},nil,2))
		local alvo={maquinaId="Esteira2x2",minimo=inicial,rotacao=CFrame.identity,ocupado=Vector3.new(6,3,6),livre=true,
			caixaDestino=origem*CFrame.new(inicial+Vector3.new(3,1.5,3)),volumeDestino=origem*CFrame.new(inicial+Vector3.new(3,1.5,3))}
		c._previa:AtualizarVolumes(origem,1); c._alvoColocacao=alvo
		c:_AtualizarAlvosGrupo(alvo,origem,1/60)
		assert(not c._alvosGrupo[1].Alvo.livre and c._alvosGrupo[2].Alvo.livre)
		antes=#chamadas; c:ConfirmarColocacao()
		assert(#chamadas==antes+1 and chamadas[#chamadas].Metodo=="ColocarGrupoCopia")
		c:Destruir(); pasta:Destroy(); mouse=mouseAnterior
		print("PASS: arraste nas quatro direcoes a partir de celula arbitraria, linha reversivel, dimensoes/rotacao, volumes compartilhados, clique simples, Q/foco e colocacao parcial com ancora bloqueada.")
	end
	testarArrasteColocacao()
end

local botoesBlueprintAntesDeDestruir = table.clone(interface._painelBlueprints._botoes)
do
	c1:_EncerrarAcao(); c1:AbrirAba("Loja"); c1:SelecionarMaquina("MineradoraBasica","Loja")
	p1:SetAttribute("Upgrade_Extracao",3)
	assert(loja._textoFicha.Text:find("Minério: $8",1,true),"Ficha aberta deve reagir ao upgrade.")
	c1:SelecionarMaquina("Esteira2x2","Loja"); p1:SetAttribute("Upgrade_Motores",3); p1:SetAttribute("VelocidadeMotores",2)
	assert(loja._textoFicha.Text:find("2,8 blocos/s",1,true))
	p1:SetAttribute("VelocidadeMotores",0); assert(loja._textoFicha.Text:find("2 blocos/s",1,true))
	local modelo=modelos.MineradoraBasica:Clone(); modelo.Parent=plot.Maquinas; modelo:SetAttribute("PodeRecolher",true)
	p1:SetAttribute("Upgrade_Extracao",0); c1:_AbrirMenuPeca(modelo)
	interface._botoesPecaContexto.Estatisticas:ObterInstancia().Activated:Fire()
	assert(interface._estatisticasPeca.Text:find("Minério: $5",1,true))
	p1:SetAttribute("Upgrade_Extracao",2)
	assert(interface._estatisticasPeca.Text:find("Minério: $7",1,true),"Menu aberto deve reagir ao upgrade.")
	camera:SetAttribute("ProjecaoTeste",Vector3.new(400,300,100))
	local viewportAnterior=camera.ViewportSize; camera.ViewportSize=roblox.Vector2.new(1000,800)
	for _,escala in {.8,1,1.2} do
		p1:SetAttribute("EscalaInterface",escala); interface:_AtualizarMenuPeca()
		assert(math.abs(interface._menuPeca.Position.X.Offset*escala-400)<=escala and math.abs(interface._menuPeca.Position.Y.Offset*escala-300)<=escala,"A ancora deve ser preservada, com arredondamento de um pixel.")
	end
	camera.ViewportSize=viewportAnterior; camera:SetAttribute("ProjecaoTeste",nil)
	c1:_EncerrarAcao(); modelo:Destroy()
	p1:SetAttribute("EscalaInterface",nil); p1:SetAttribute("Upgrade_Extracao",0); p1:SetAttribute("Upgrade_Motores",0)
	print("PASS: descricoes reativas na loja e na plot; escala preserva a ancora visual; confirmacoes preservam o lote e cancelam sem vender.")
end
c1:_EncerrarAcao(); c1.Navegacao:Fechar("Inventario"); c1.Navegacao:Fechar("Loja")
p1:SetAttribute("Atalho_E","J")
input:Fire({KeyCode=roblox.Enum.KeyCode.J,UserInputType=roblox.Enum.UserInputType.Keyboard},false)
assert(c1.Navegacao:Contem("Inventario"))
tecla("E"); assert(c1.Navegacao:Contem("Inventario"),"A tecla antiga deve ficar livre depois do remapeamento.")
input:Fire({KeyCode=roblox.Enum.KeyCode.J,UserInputType=roblox.Enum.UserInputType.Keyboard},false)
assert(not c1.Navegacao:Contem("Inventario"))
p1:SetAttribute("Atalho_E",nil)
do
	p1:SetAttribute("Atalho_Q","K")
	tecla("E"); tecla("Q")
	assert(c1.Navegacao:Contem("Inventario"),"Cancelar remapeado nao pode continuar preso ao Q.")
	input:Fire({KeyCode=roblox.Enum.KeyCode.K,UserInputType=roblox.Enum.UserInputType.Keyboard},false)
	assert(not c1.Navegacao:Contem("Inventario"))
	p1:SetAttribute("Atalho_Q",nil)
	tecla("E"); tecla("F")
	interface._interface.AbsoluteSize=roblox.Vector2.new(390,700)
	interface._interface:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	assert(loja._painelLista.Visible and not inventario._painelLista.Visible)
	clicarPeca(loja,"Esteira2x2")
	assert(loja._painelFicha.Visible and not loja._painelLista.Visible and loja._painelFicha.Size.X.Scale==1)
	c1:FecharFicha("Loja"); assert(loja._painelLista.Visible)
	interface._interface.AbsoluteSize=roblox.Vector2.new(1280,720)
	interface._interface:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	c1.Navegacao:Fechar("Loja"); c1.Navegacao:Fechar("Inventario")
	print("PASS: cancelamento remapeado e loja/inventario em uma coluna em tela de celular, sem fichas sobrepostas.")
end
(function()
	local raioAnterior,resultadoAnterior,ponteiroAnterior=raioPorTela,resultado,c1._ponteiro
	local geo=carregar("src/shared/GeometriaColocacao")
	local origem=geo.Origem(plot.Piso)
	local ponto=Vector3.new(6,0,6)
	c1._ponteiro=function() return roblox.Vector2.new(400,300) end
	raioPorTela=function() return {Origin=origem:PointToWorldSpace(ponto+Vector3.new(0,60,0)),Direction=-Vector3.yAxis} end
	resultado={Instance=plot.Piso,Position=origem:PointToWorldSpace(ponto)}
	local clique={UserInputType=roblox.Enum.UserInputType.MouseButton1,KeyCode=roblox.Enum.KeyCode.Unknown}
	c1:ProcessarEntrada(clique,false)
	assert(c1._arrasteSelecao)
	c1._arrasteSelecao.PorComando=true
	c1:Atualizar(0)
	local area=c1._arrasteSelecao
	assert(area.Arrastando and area.VolumeMaximo)
	local inicio=area.VolumeMaximo
	ponto=Vector3.new(18,0,18); resultado.Position=origem:PointToWorldSpace(ponto)
	c1:Atualizar(1/60)
	assert(area.VolumeMaximo.X>inicio.X and area.VolumeMaximo.Z>inicio.Z,
		"A area deve acompanhar o segundo canto e a camera sem exigir MouseMovement.")
	c1:FinalizarEntrada(clique); c1:_EncerrarAcao()
	raioPorTela,resultado,c1._ponteiro=raioAnterior,resultadoAnterior,ponteiroAnterior
	print("PASS: area por comando atualiza seu volume em cada quadro, inclusive com ponteiro fixo de toque/controle.")
end)()
;(function()
	c1:_EncerrarAcao(); c1.Navegacao:Fechar("Loja"); c1.Navegacao:Fechar("Inventario")
	interface:AtualizarInventario()
	local botao=interface._botaoLimparPlot:ObterInstancia()
	assert(botao.Size==roblox.UDim2.fromOffset(44,44) and botao.AnchorPoint==roblox.Vector2.one)
	local antes=#plot.Maquinas:GetChildren()
	assert(antes>0 and botao.Active)
	botao.Activated:Fire()
	assert(c1.Navegacao:Contem("Confirmacao") and #plot.Maquinas:GetChildren()==antes)
	c1.Navegacao:Voltar(); assert(#plot.Maquinas:GetChildren()==antes)
	botao.Activated:Fire(); tempo+=10
	interface._confirmacao._sim:ObterInstancia().Activated:Fire()
	assert(#plot.Maquinas:GetChildren()==0 and #perfil.Data.MaquinasColocadas==0 and not botao.Active)
	assert(interface._limparStatus.Visible)
	print("PASS: botão pequeno, confirmação mesmo sem confirmar vendas, cancelamento e limpeza pelo cliente/servidor reais.")
end)()
for _, botao in interface._painelBlueprints._listaBlueprints do
	table.insert(botoesBlueprintAntesDeDestruir, botao)
end
interface:Destruir()
for _, painel in { inventario, loja } do
	for _, botao in painel._grade._botoes do assert(botao:ObterInstancia().Activated:Contar() == 0) end
	for _, conexao in painel._grade._conexoes do assert(not conexao.ativa) end
end
for _, botao in interface._botoesPecaContexto do assert(botao:ObterInstancia().Activated:Contar() == 0) end
for _, botao in botoesBlueprintAntesDeDestruir do
	assert(botao:ObterInstancia().Activated:Contar() == 0)
end
c1:Destruir(); c2:Destruir()
for _, evento in p1.sinais do assert(evento:Contar() == 0) end
assert(input:Contar() == 0 and render:Contar() == 0 and mudou:Contar() == 0 and terminou:Contar() == 0 and perdeuFoco:Contar() == 0)
t1:Liberar()
assert(t1:EstaLivre() and #plot.Maquinas:GetChildren() == 0 and not plot.Spawn.Enabled)
assert(t1:Atribuir(p2))
no("src/client").Destroying = destruirScript
carregar("src/client/init.client")
assert(input:Contar() >= 2 and render:Contar() == 2)
destruirScript:Fire()
assert(input:Contar() == 0 and render:Contar() == 0)
for _, evento in p1.sinais do assert(evento:Contar() == 0) end
print("PASS: paineis, botoes e bootstrap encerram suas conexoes; terreno pode ser reutilizado.")
