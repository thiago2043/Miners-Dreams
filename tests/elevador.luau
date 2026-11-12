local serde = require("@lune/serde")
local r = require("./suporte/modelos")
local I, V, CF = r.Instance, r.Vector3, r.CFrame
local mundo = I.new("Workspace")
local modelos = require("./suporte/catalogo_modelos")()
local replicado = {ModelosMaquinas = modelos, WaitForChild = function(self, nome) return assert(self[nome]) end}
local Players = {GetPlayerByUserId = function(self, id) return self[id] end}
local jogador = {Name = "Elevador", UserId = 123, Parent = Players, atributos = {TerrenoId = 1}}
Players[123] = jogador
function jogador:GetAttribute(k) return self.atributos[k] end
function jogador:SetAttribute(k,v) self.atributos[k] = v end

local carregar, no = require("./suporte/carregador")({
	workspace=mundo, Instance=I, Vector3=V, CFrame=CF, Color3=r.Color3, Enum=r.Enum, typeof=r.typeof,
	Vector2=r.Vector2, ColorSequence=r.ColorSequence, ColorSequenceKeypoint=r.ColorSequenceKeypoint,
	OverlapParams={new=function() return {} end},
}, {Players=Players, ReplicatedStorage=replicado, ContextActionService={},
	UserInputService={GetFocusedTextBox=function() return nil end, IsKeyDown=function() return false end},
}, {["Packages/Networker"]={}})
replicado.Shared = no("src/shared")
replicado.Packages = no("Packages")
local Catalogo = carregar("src/shared/CatalogoMaquinas")
local Elevador = carregar("src/shared/ElevadorVertical")
local Construcao = carregar("src/server/ServicoConstrucao")
local Manager = carregar("src/server/Data/DataManager")
local Template = carregar("src/server/Data/Template")
local Corpo = carregar("src/shared/CorpoRigido")
local Fabrica = carregar("src/server/Fabrica")
local Minerio = carregar("src/server/Minerio")
r.implementMethod("Workspace", "GetPartBoundsInBox", function(_, pose, tamanho, consulta)
	local partes = {}
	for _, raiz in consulta.FilterDescendantsInstances do
		for _, parte in (if raiz:IsA("BasePart") then {raiz} else raiz:GetDescendants()) do
			if parte:IsA("BasePart") and (if consulta.RespectCanCollide then parte.CanCollide else parte.CanQuery)
				and Corpo.Intersecao(pose, tamanho, parte.CFrame, parte.Size) then table.insert(partes, parte) end
		end
	end
	return partes
end)

local terrenos = I.new("Folder"); terrenos.Name, terrenos.Parent = "Terrenos", mundo
local terreno = I.new("Model"); terreno.Parent = terrenos
terreno:SetAttribute("DonoUserId", jogador.UserId)
terreno:SetAttribute("TerrenoId", 1)
local piso = I.new("Part")
piso.Name, piso.Size, piso.CFrame, piso.Anchored, piso.Parent = "Piso", V.new(96, 1, 96), CF.new(48, -.5, 48), true, terreno
for _, nome in {"Maquinas", "Minerios"} do local f = I.new("Folder"); f.Name, f.Parent = nome, terreno end
local pasta = terreno.Maquinas
local perfil = {Data = serde.decode("json", serde.encode("json", Template))}
function perfil:IsActive() return true end
perfil.Data.Dinheiro = "4000000000000"
local dados = Manager.RegistrarPerfil(jogador, perfil)
local servico = Construcao.new()
local id = "ElevadorVertical"
local minimo = V.new(12, 0, 12)
local giro = CF.Angles(0, math.pi / 2, 0)
assert(Catalogo[id].Preco == "1000000000000" and dados:ComprarMaquina(id))
assert(perfil.Data.Dinheiro == "3000000000000")
assert(not servico:Colocar(jogador, id, minimo, CF.Angles(math.pi / 2, 0, 0)))
assert(servico:Colocar(jogador, id, minimo, giro))
local elevador = assert(pasta:FindFirstChild(id))
assert(elevador.HitboxConstrucao.Size == V.new(3, 6, 3))
assert(servico:Colocar(jogador, "Parede1x1", minimo + V.yAxis * 6, CF.identity))
assert(not servico:ConfigurarElevador(jogador, elevador, 5, "+Z", "-X", "subir"))
assert(not servico:ConfigurarElevador(jogador, elevador, 3, "+Y", "-X", "subir"))
assert(not servico:ConfigurarElevador({UserId=999, GetAttribute=jogador.GetAttribute, atributos={TerrenoId=1}}, elevador, 3, "+Z", "-X", "subir"))
assert(elevador.Parent == pasta and elevador:GetAttribute("AlturaBlocos") == 2)
assert(servico:Recolher(jogador, pasta:FindFirstChild("Parede1x1")))
local ok, erro, nova = servico:ConfigurarElevador(jogador, elevador, 5, "+Z", "-X", "subir")
assert(ok, erro)
elevador = nova
assert(elevador:GetAttribute("VolumeOcupado") == V.new(3, 15, 3))
assert(not servico:Colocar(jogador, "Parede1x1", minimo + V.yAxis * 12, CF.identity))
assert(servico:AtualizarPrevia(jogador, {{id, 12, 0, 12, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, {5, "+Z", "-X", "subir"}}}))
assert(serde.decode("json", terreno:GetAttribute("PreviaConstrucao"))[1][15][3] == "-X")
assert(servico:CriarBlueprint(jogador, "Elevador", {elevador}))
servico:Sincronizar(jogador)
local salvo = serde.encode("json", perfil.Data)
pasta:ClearAllChildren(); perfil.Data = serde.decode("json", salvo)
servico = Construcao.new()
assert(servico:Restaurar(jogador))
elevador = assert(pasta:FindFirstChild(id))
assert(Elevador.Ler(elevador).Saida == "-X" and elevador:GetAttribute("VolumeOcupado") == V.new(3, 15, 3))
local preparou, mensagem, blueprint = servico:PrepararBlueprint(jogador, perfil.Data.Blueprints[1].Id)
assert(preparou, mensagem)
assert(blueprint.Pecas[1].Modificacoes.Elevador.Altura == 5)
assert(servico:ColocarGrupoCopia(jogador, blueprint.Token, {{Minimo=V.new(60, 0, 60), Rotacao=giro}}))
assert(#pasta:GetChildren() == 2)
assert(servico:Desfazer(jogador) and #pasta:GetChildren() == 1)
assert(servico:Recolher(jogador, elevador) and dados:ObterModificacoesInventario(id).Elevador.Altura == 5)
assert(servico:Colocar(jogador, id, minimo, giro))
elevador = assert(pasta:FindFirstChild(id))

local function testarFluxo(elevadorAtual, varios)
	local pivo = elevadorAtual:GetPivot()
	local entrada = pivo:PointToWorldSpace(elevadorAtual:GetAttribute("PortaEntrada"))
	local saida = pivo:PointToWorldSpace(elevadorAtual:GetAttribute("PortaSaida"))
	local entrar = pivo:VectorToWorldSpace(elevadorAtual:GetAttribute("DirecaoEntrada"))
	local sair = pivo:VectorToWorldSpace(elevadorAtual:GetAttribute("DirecaoSaida"))
	local correias = {}
	for _, porta in {{entrada, entrar, -1}, {saida, sair, 1}} do
		local pos, fluxo, lado = table.unpack(porta)
		local parte = I.new("Part")
		local centro = pos + fluxo * (3 * lado) - V.yAxis * .1
		parte.Name, parte.Size, parte.CFrame = "EsteiraTeste", V.new(3, .2, 6), CF.lookAt(centro, centro - fluxo)
		parte.Anchored, parte.CanCollide, parte.Parent = true, true, pasta
		table.insert(correias, {parte, fluxo})
	end
	local fabrica = Fabrica.new(terrenos)
	local sim = fabrica._simulacao
	local componente = {EstaAtivo=function() return true end}
	for _, correia in correias do sim:RegistrarTransportador(componente, correia[1], correia[2] * 6) end
	local saldo = perfil.Data.Dinheiro
	local minerios, saiu = {}, {}
	local function criar(lateral)
		local inicio = entrada - entrar * 1.6 + V.yAxis * .39 + entrar:Cross(V.yAxis) * lateral
		local ore = Minerio.Criar({Valor="175", Tamanho={.75,.75,.75}}, CF.new(inicio), terreno)
		sim:RegistrarMinerio(ore)
		table.insert(minerios, ore)
	end
	criar(.42)
	for i = 1, 60 * (if varios then 35 else 5) do
		if varios and i == 120 then criar(-.6) end
		mundo:SetAttribute("TempoServidorTeste", i / 60)
		fabrica:Avancar(1 / 60)
		for _, ore in minerios do
			if saiu[ore] then continue end
			local corpo = assert(sim:ObterCorpo(ore:ObterParte()), "Minério desapareceu antes da saída")
			local pos = corpo.CFrame.Position
			if (pos - saida):Dot(sair) > 1 and math.abs(pos.Y - saida.Y - .375) < .1 then
				assert(ore:ObterValor() == "175")
				saiu[ore] = true
				ore:Consumir(false)
			end
		end
		if #minerios == (if varios then 2 else 1) then
			local todos = true
			for _, ore in minerios do todos = todos and saiu[ore] == true end
			if todos then break end
		end
	end
	for _, ore in minerios do assert(saiu[ore], "Minério não alcançou a correia de saída") end
	assert(perfil.Data.Dinheiro == saldo, "Elevador vendeu minério em espera ou em trânsito")
	fabrica:Destruir()
	for _, correia in correias do correia[1]:Destroy() end
end

testarFluxo(elevador, false)
ok, erro, nova = servico:ConfigurarElevador(jogador, elevador:GetAttribute("IdUnidade"), 16, "-Z", "-Z", "descer")
assert(ok, erro)
testarFluxo(nova, true)

local Previa = carregar("src/client/PreviaConstrucao")
local Controller = carregar("src/client/ControladorConstrucao")
local Personalizacao = carregar("src/shared/PersonalizacaoMaquina")
local Geometria = carregar("src/shared/GeometriaColocacao")
local mods = dados:ObterModificacoesInventario(id)
assert(mods.Elevador, "A colocação deve consumir a variante comprada ou recolhida.")
local personalizacao = Personalizacao.new(mods)
local previa = Previa.new(modelos[id], personalizacao, personalizacao:ObterDefinicao(Catalogo[id]), pasta)
local camera = I.new("Camera")
camera.Parent, mundo.CurrentCamera = mundo, camera
r.implementMethod("Camera", "WorldToViewportPoint", function(_, pos) return V.new(pos.X * 8, -pos.Y * 8, 1), true end)
local ponteiro = r.Vector2.new(300, 250)
local pedidos = 0
local ctrl = setmetatable({
	_previa = previa, _piso = piso, _jogador = jogador, _atalhosMaquinas = {}, _rotacao = CF.identity,
	_maquinaIdSelecionada = id, _ponteiro = function() return ponteiro end,
	_AtualizarConfiguracaoInventario = function() end,
	Navegacao = {Atual=function() return "Colocacao" end},
	_redeConstrucao = {fetch = function(_, acao, ...) assert(acao == "Colocar"); pedidos += 1; return servico:Colocar(jogador, ...) end},
}, Controller)
ctrl:_ReiniciarEntradaElevador()
local origem = Geometria.Origem(piso)
local entrada = V.new(45, 12, 45)
local ocupado = V.one * 3
local alvo = {minimo=entrada, ocupado=ocupado, rotacao=CF.identity, livre=true,
	caixaDestino=Geometria.CFrameDoVolume(origem, entrada, ocupado), volumeDestino=Geometria.CFrameDoVolume(origem, entrada, ocupado)}
previa:Animar(alvo, 0)
ctrl._alvoColocacao = alvo
assert(previa:ObterTamanho() == ocupado and #previa:ObterModelo().SetaTransporte:GetChildren() == 1)
local tecla = {UserInputType=r.Enum.UserInputType.Keyboard, KeyCode=r.Enum.KeyCode.R}
local clique = {UserInputType=r.Enum.UserInputType.MouseButton1, KeyCode=r.Enum.KeyCode.Unknown}
ctrl:ProcessarEntrada(tecla, false)
local giroEntrada = ctrl._rotacao
assert(giroEntrada ~= CF.identity)
ctrl:ProcessarEntrada(clique, false)
assert(ctrl:FaseElevador() == "Saida" and pedidos == 0)
assert(ctrl._alvoColocacao.rotacao == giroEntrada)
ponteiro -= r.Vector2.new(0, 48)
ctrl:_AtualizarSaidaElevador(origem, 0)
assert(ctrl._alvoColocacao.minimo == entrada and ctrl._alvoColocacao.elevador[1] == 3)
assert(previa:ObterModelo().SetaTransporte.Sentido.Haste.CFrame.LookVector.Y > .999)
ponteiro += r.Vector2.new(0, 48)
ponteiro += r.Vector2.new(0, 72)
ctrl:ProcessarEntrada(tecla, false)
local destino = V.new(45, 3, 45)
assert(ctrl._alvoColocacao.minimo == destino and ctrl._alvoColocacao.rotacao == giroEntrada)
assert(ctrl._alvoColocacao.elevador[3] == Elevador.ProximaFace(mods.Elevador.Saida))
assert(ctrl._alvoColocacao.elevador[1] == 4 and ctrl._alvoColocacao.elevador[4] == "descer")
assert(previa:ObterModelo().SetaTransporte.Sentido.Haste.CFrame.LookVector.Y < -.999)
local saldo = perfil.Data.Dinheiro
local quantidade = dados:ObterQuantidade(id)
assert(servico:Colocar(jogador, "Parede1x1", V.new(45, 6, 45), CF.identity))
previa:AtualizarVolumes(origem, 1)
ctrl:ProcessarEntrada(clique, false)
assert(pedidos == 0 and ctrl._alvoColocacao.livre == false)
assert(not servico:Colocar(jogador, id, destino, giroEntrada, nil, false, ctrl._alvoColocacao.elevador))
assert(dados:ObterQuantidade(id) == quantidade)
assert(servico:Recolher(jogador, pasta:FindFirstChild("Parede1x1")))
previa:AtualizarVolumes(origem, 1)
ctrl:ProcessarEntrada(clique, false)
assert(pedidos == 1 and ctrl:FaseElevador() == "Entrada" and dados:ObterQuantidade(id) == quantidade - 1)
assert(perfil.Data.Dinheiro == saldo)
local colocado = perfil.Data.MaquinasColocadas[#perfil.Data.MaquinasColocadas]
assert(colocado.Modificacoes.Elevador.Altura == 4 and colocado.Modificacoes.Elevador.Sentido == "descer")
previa:Destruir()
print("ELEVADOR_OK", "compra, rotação, colisão, perfil, blueprint, inventário, subida e descida com espera superior a 5 s")
print("ELEVADOR_COLOCACAO_OK", "dois cliques, faces independentes, descida, setas e variante de origem preservada")
