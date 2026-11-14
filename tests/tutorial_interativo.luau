local roblox = require("./suporte/modelos")
local I, V, CF = roblox.Instance, roblox.Vector3, roblox.CFrame
local carregar = require("./suporte/carregador")({Instance = I, Vector3 = V, CFrame = CF, typeof = roblox.typeof}, {})
local Guia = carregar("src/shared/PrimeiraFabrica")
local e = Guia.Etapas
local Dados = carregar("src/server/Data/DadosJogador")
local Template = carregar("src/server/Data/Template")
local perfil = {Data = carregar("src/server/Data/ReinicioProgresso").new(Template, {}):Preparar({}), IsActive = function() return true end}
local atributos = {}
local jogador = {Name = "Teste", GetAttribute = function(_, n) return atributos[n] end, SetAttribute = function(_, n, v) atributos[n] = v end}
local dados = Dados.new(jogador, perfil)
dados:Sincronizar()
assert(atributos.TutorialModo == "Convite" and atributos.TutorialEtapa == e.Venda)
assert(not dados:DefinirTutorial(e.Concluido) and dados:DefinirTutorial("Ativo"))
assert(dados:AdicionarDinheiro("1")); dados:RegistrarQuedaTutorial(V.zero)
assert(atributos.TutorialQueda and atributos.TutorialEtapa == e.Venda)
dados:RegistrarVendaTutorial("0", true); assert(atributos.TutorialEtapa == e.Venda)
dados:RegistrarVendaTutorial("5", false); assert(atributos.TutorialEtapa == e.Modificador)
dados:RegistrarVendaTutorial("15", true)
assert(atributos.TutorialEtapa == e.Concluido and atributos.TutorialModo == "Ativo")
dados:RegistrarVendaTutorial("5", false)
assert(atributos.TutorialEtapa == e.Concluido)
assert(dados:DefinirTutorial("Pulado"))
local voltou = Dados.new(jogador, perfil)
for _, legado in {2, 3, 4, e.Concluido} do
	perfil.Data.Tutorial.Etapa = legado
	voltou:Sincronizar()
	assert(atributos.TutorialModo == "Pulado" and atributos.TutorialEtapa == e.Concluido)
end
local Regra = carregar("src/shared/RegraReencarnacao")
assert(voltou:AdicionarDinheiro(Regra.PrimeiroRequisito) and voltou:Reencarnar(0))
voltou:Sincronizar()
assert(atributos.TutorialEtapa == e.Concluido and atributos.Reencarnacoes == 1)

local modelos = require("./suporte/catalogo_modelos")()
local Plot = carregar("src/client/GuiaPlot")
local piso = I.new("Part")
piso.Size = V.new(36, 1, 36)
local function colocar(original, anteriores, apoio)
	local modelo = original:Clone()
	modelo:PivotTo(assert(Plot.Sugerir(piso, anteriores, original, apoio)))
	return modelo
end
for _, giro in {0, math.pi / 2} do
	piso.CFrame = CF.new(15, 1, 30) * CF.Angles(0, giro, 0)
	local mina = colocar(modelos.MineradoraBasica, {})
	local esteira = colocar(modelos.Esteira2x2, {mina}, mina)
	local segunda = colocar(modelos.Esteira2x2, {mina, esteira}, esteira)
	local fornalha = colocar(modelos.FornalhaBasica, {mina, esteira, segunda}, segunda)
	local correia, bandeja = segunda.Correia, fornalha.BandejaEntrada
	local saida = mina:FindFirstChild("SaidaMinerio", true).WorldCFrame.Position
	local naCorreia = esteira.Correia.CFrame:PointToObjectSpace(saida)
	assert(math.abs(naCorreia.X) < esteira.Correia.Size.X / 2 and math.abs(naCorreia.Z) < esteira.Correia.Size.Z / 2 and naCorreia.Y > 0)
	assert((correia.CFrame * CF.new(0, 0, correia.Size.Z / 2)).Position:FuzzyEq(
		(bandeja.CFrame * CF.new(0, 0, -bandeja.Size.Z / 2)).Position, .001))
	local solta = fornalha:Clone()
	solta:PivotTo(fornalha:GetPivot() * CF.new(9, 0, 0))
	local linha = Plot.Seguir(mina, {mina, segunda, solta, esteira, fornalha})
	assert(#linha == 3 and linha[1] == esteira and linha[2] == segunda and linha[3] == fornalha, "a fornalha vai depois da segunda esteira")
	correia:SetAttribute("DirecaoTransporte", -V.zAxis)
	local antes, invertida = Plot.Seguir(mina, {mina, esteira, fornalha, segunda})
	assert(#antes == 1 and invertida == segunda, "a esteira invertida interrompe a rota")
	correia:SetAttribute("DirecaoTransporte", V.zAxis)
	local livre, bloqueios, destino = Plot.Sugerir(piso, {mina, esteira, segunda, fornalha}, modelos.CamaraFissao, mina)
	assert(not livre and bloqueios[1] == esteira and destino, "recolher a primeira esteira libera o espaço do modificador")
	local camara = colocar(modelos.CamaraFissao, {mina}, mina)
	local novaFornalha = colocar(modelos.FornalhaBasica, {mina, camara}, camara)
	local melhorada = Plot.Seguir(mina, {novaFornalha, mina, camara})
	assert(#melhorada == 2 and melhorada[1] == camara and melhorada[2] == novaFornalha, "a linha melhorada volta a vender")
	assert((camara.Correia.CFrame * CF.new(0, camara.Correia.Size.Y / 2, camara.Correia.Size.Z / 2)).Position:FuzzyEq(
		(novaFornalha.BandejaEntrada.CFrame * CF.new(0, novaFornalha.BandejaEntrada.Size.Y / 2, -novaFornalha.BandejaEntrada.Size.Z / 2)).Position, .001))
	camara:Destroy(); novaFornalha:Destroy()
	mina:Destroy(); esteira:Destroy(); segunda:Destroy(); fornalha:Destroy(); solta:Destroy()
end
local ui = require("./suporte/interface")
local function instancia(classe)
	local objeto = ui.NovaInstancia(classe)
	local valores = {}
	function objeto:GetAttribute(nome) return valores[nome] end
	function objeto:SetAttribute(nome, valor) valores[nome] = valor end
	return objeto
end
local atributosUI, sinais = {TutorialModo = "Convite", TutorialEtapa = e.Venda, Inventario_MineradoraBasica = 1}, {}
local jogadorUI = {UserId = 7}
function jogadorUI:GetAttribute(nome) return atributosUI[nome] end
function jogadorUI:GetAttributeChangedSignal(nome)
	sinais[nome] = sinais[nome] or ui.Sinal()
	return sinais[nome]
end
function jogadorUI:SetAttribute(nome, valor)
	atributosUI[nome] = valor
	self:GetAttributeChangedSignal(nome):Fire()
end
local rede = {fetch = function(_, metodo, modo)
	assert(metodo == "DefinirTutorial")
	jogadorUI:SetAttribute("TutorialModo", modo)
	return true
end}
local mundo = instancia("Workspace")
local replicado = {ModelosMaquinas = modelos}
local tipoRoblox = roblox.typeof or typeof
local entrada = roblox.Enum.UserInputType.Touch
local render, gui = ui.Sinal(), {ReducedMotionEnabled = false}
local carregarUI, no = require("./suporte/carregador")({Instance = {new = instancia}, typeof = function(valor)
	return if type(valor) == "table" and valor.ClassName then "Instance" else tipoRoblox(valor)
end,
	Color3 = roblox.Color3, Vector2 = roblox.Vector2, Vector3 = V, CFrame = CF, UDim = roblox.UDim, UDim2 = roblox.UDim2, Enum = roblox.Enum,
	workspace = mundo, task = {delay = function() end},
}, {ReplicatedStorage = replicado, GuiService = gui, RunService = {RenderStepped = render},
	UserInputService = {LastInputTypeChanged = ui.Sinal(), GetLastInputType = function() return entrada end}}, {
	["src/client/AnimacaoInterface"] = {DefinirVisivel = function(p, v) p.Visible = v end, TransicaoSubAba = function() end},
	["src/client/GerenciadorJanelas"] = {Registrar = function() end, ObterRede = function() return rede end},
})
replicado.Shared = no("src/shared")
local nav = carregarUI("src/client/NavegacaoEstados").new()
local tela = instancia("ScreenGui")
local function botao(nome, pai)
	local b = instancia("TextButton")
	b.Name, b.Parent = nome, pai
	return {ObterInstancia = function() return b end}
end
local construcao = {Navegacao = nav}
function construcao:AbrirAba(aba) if not nav:Contem(aba) then nav:Abrir(aba) end end
function construcao:AlternarPainelCentral(aba) self:AbrirAba(aba) end
function construcao:ObterSelecao() return self.Selecao end
local inventario = {_botoesPecas = {MineradoraBasica = botao("Mineradora", tela), Esteira2x2 = botao("Esteira", tela)}, _acoes = {Colocar = botao("Colocar", tela)}}
local loja = {_botoesPecas = {CamaraFissao = botao("Câmara", tela)}, _acoes = {Comprar = botao("Comprar", tela)}}
local grade = {DestacarNoTutorial = function(self, id) self.Peca = id end}
inventario._grade = grade
local atalhos = {Inventario = botao("Inventário", tela), Loja = botao("Loja", tela), Tutorial = botao("Tutorial", tela)}
tela.AbsoluteSize = roblox.Vector2.new(1280, 500)
local botaoInventario, botaoTutorial = atalhos.Inventario:ObterInstancia(), atalhos.Tutorial:ObterInstancia()
botaoInventario.AbsolutePosition, botaoInventario.AbsoluteSize = roblox.Vector2.new(12, 100), roblox.Vector2.new(56, 56)
botaoTutorial.AbsolutePosition, botaoTutorial.AbsoluteSize = roblox.Vector2.new(1212, 100), roblox.Vector2.new(56, 56)
local guia = carregarUI("src/client/GuiaPrimeiraFabrica").new({
	_interface = tela, _paineis = {Inventario = inventario, Loja = loja}, _botoesAbas = atalhos,
}, jogadorUI, construcao)
local painel = carregarUI("src/client/PainelTutorial").new(tela, jogadorUI, nav)
painel.Guia = guia
local function botaoPainel(nome)
	for _, botao in painel._botoes do
		local objeto = botao:ObterInstancia()
		if objeto.Name == nome then return objeto end
	end
	error("Botão ausente: " .. nome)
end
assert(guia:BotaoParaFoco().Text == "Começar")
guia._botoes.Pular:ObterInstancia().Activated:Fire()
assert(atributosUI.TutorialModo == "Pulado" and not guia._cartao.Visible)
nav:Abrir("Tutorial"); painel:Atualizar()
local retomar = botaoPainel("RetomarGuia")
assert(retomar.Text == "Retomar")
retomar.Activated:Fire()
assert(atributosUI.TutorialModo == "Ativo" and guia._cartao.Visible and not nav:Contem("Tutorial"))
assert(guia._instrucao.Text:find("mineradora básica", 1, true))
nav:Abrir("Tutorial"); painel:Atualizar()
botaoPainel("PularGuia").Activated:Fire()
assert(atributosUI.TutorialModo == "Pulado" and botaoPainel("RetomarGuia").Text == "Retomar")
botaoPainel("RetomarGuia").Activated:Fire()
assert(guia._alvoBotao == atalhos.Inventario:ObterInstancia(), "o tutorial indica o botão real de inventário")
guia:_AnimarDestaque(1)
assert(guia._seta.Visible and guia._seta.Rotation == 180 and guia._selo.Thickness == 7)
assert(guia._seta:IsA("Frame") and #guia._seta:GetChildren() == 6)
assert(guia._setaMundo:FindFirstChildOfClass("Frame").Rotation == 90)
botaoInventario.Visible = false
render:Fire()
assert(not guia._seta.Visible)
botaoInventario.Visible = true
gui.ReducedMotionEnabled = true
render:Fire()
assert(guia._seta.Visible and guia._selo.Thickness == 4)
gui.ReducedMotionEnabled = false
entrada = roblox.Enum.UserInputType.Keyboard
guia:Atualizar()
assert(guia._instrucao.Text:find("Pressione E para abrir o Inventário.", 1, true))
jogadorUI:SetAttribute("Atalho_E", "I")
assert(guia._instrucao.Text:find("Pressione I para abrir o Inventário.", 1, true))
entrada = roblox.Enum.UserInputType.Touch
guia:Atualizar()
assert(not guia._instrucao.Text:find("Pressione", 1, true))
guia:BotaoParaFoco().Activated:Fire()
assert(grade.Peca == "MineradoraBasica" and guia._alvoBotao == inventario._botoesPecas.MineradoraBasica:ObterInstancia())
construcao.Selecao = {MaquinaId = "MineradoraBasica"}
nav:Abrir("FichaInventario")
assert(guia._alvoBotao == inventario._acoes.Colocar:ObterInstancia())
assert(guia._instrucao.Text:find("tocar duas vezes no ícone do inventário", 1, true))
entrada = roblox.Enum.UserInputType.Keyboard
guia:Atualizar()
assert(guia._instrucao.Text:find("clicar duas vezes no ícone do inventário", 1, true))
nav:Fechar("FichaInventario")
assert(guia._instrucao.Text:find("para ver os detalhes", 1, true) and guia._instrucao.Text:find("Para colocar na plot", 1, true))
jogadorUI:SetAttribute("Atalho_Q", "Backspace")
nav:Fechar("FichaInventario"); nav:Fechar("Inventario")
nav:Abrir("Colocacao")
jogadorUI:SetAttribute("MaquinaSelecionada", "MineradoraBasica")
guia:Colocou(nil, "Espaço ocupado")
assert(guia._instrucao.Text:find("Espaço ocupado", 1, true) and not guia._instrucao.Text:find("Backspace", 1, true))

-- Usa os modelos reais para o fluxo. A montagem da silhueta fica a cargo do motor gráfico.
guia._Guiar = function(self, _, _, id, anterior, _, _, destino)
	self.Silhueta, self.Apoio, self.Destino = id, anterior, destino
end
local terrenos, terreno, maqs = instancia("Folder"), instancia("Model"), instancia("Folder")
terrenos.Name, terrenos.Parent = "Terrenos", mundo
terreno.Name, terreno.Parent = "Terreno_1", terrenos
terreno:SetAttribute("DonoUserId", jogadorUI.UserId)
maqs.Name, maqs.Parent = "Maquinas", terreno
maqs.ChildAdded, maqs.ChildRemoved, maqs.DescendantAdded = ui.Sinal(), ui.Sinal(), ui.Sinal()
piso.Name = "Piso"
table.insert(terreno._filhos, piso)
local mina = colocar(modelos.MineradoraBasica, {})
local esteira = colocar(modelos.Esteira2x2, {mina}, mina)
local segunda = colocar(modelos.Esteira2x2, {mina, esteira}, esteira)
local forno = colocar(modelos.FornalhaBasica, {mina, esteira, segunda}, segunda)
local camara = colocar(modelos.CamaraFissao, {mina}, mina)
local function plot(lista)
	maqs._filhos = lista
	maqs.ChildAdded:Fire()
end
jogadorUI:SetAttribute("Inventario_Esteira2x2", 10)
jogadorUI:SetAttribute("Inventario_FornalhaBasica", 1)
jogadorUI:SetAttribute("TerrenoId", 1)
guia:Colocou("MineradoraBasica")
assert(guia._instrucao.Text:find("Pressione Backspace para encerrar a colocação.", 1, true))
plot({mina})
assert(guia.Silhueta == "Esteira2x2" and guia._acao == "Inventario" and guia._titulo.Text:find("✓"), "a prévia contínua da mineradora permite abrir o estoque para a esteira")
assert(guia._instrucao.Text:find("Pressione Backspace", 1, true))
entrada = roblox.Enum.UserInputType.Touch
guia:Atualizar()
assert(guia._instrucao.Text:find("Toque em Voltar para encerrar a colocação.", 1, true))
jogadorUI:SetAttribute("MaquinaSelecionada", "Esteira2x2")
assert(not guia._instrucao.Text:find("encerrar a colocação", 1, true))
local origem = carregar("src/shared/GeometriaColocacao").Origem(piso)
local parte = instancia("Part")
parte.CFrame = origem * CF.new(12, 1.5, 12)
guia._guiaNoMundo, guia._minimoGuia = parte, V.new(9, 0, 9)
construcao._rotacao, construcao._alvoColocacao = CF.Angles(0, math.pi / 2, 0), {minimo = guia._minimoGuia, livre = true}
guia:Atualizar()
assert(guia._instrucao.Text:find("Girar Y", 1, true) and guia._instrucao.Text:find("90°", 1, true))
construcao._rotacao = CF.identity
guia:Atualizar()
assert(guia._instrucao.Text:find("Toque em Confirmar para fixar a peça.", 1, true))
assert(not guia._instrucao.Text:find("Voltar", 1, true))
guia:Colocou("Esteira2x2")
assert(guia._instrucao.Text:find("Toque em Voltar", 1, true))
nav:Fechar("Colocacao")
nav:Abrir("Colocacao")
assert(not guia._instrucao.Text:find("Toque em Voltar", 1, true), "reabrir a colocação da mesma peça começa sem dica de saída")
guia._guiaNoMundo, guia._minimoGuia, construcao._alvoColocacao = nil, nil, nil
plot({mina, esteira, segunda})
assert(guia.Silhueta == "FornalhaBasica" and guia.Apoio == segunda and guia._acao == "Inventario")
plot({mina, esteira, segunda, forno})
jogadorUI:SetAttribute("Dinheiro", "50")
entrada = roblox.Enum.UserInputType.Keyboard
jogadorUI:SetAttribute("TutorialEtapa", e.Modificador)
assert(guia._alvoBotao == atalhos.Loja:ObterInstancia())
assert(guia._instrucao.Text:find("Pressione F para abrir a Loja.", 1, true))
jogadorUI:SetAttribute("Atalho_F", "L")
assert(guia._instrucao.Text:find("Pressione L para abrir a Loja.", 1, true))
guia:BotaoParaFoco().Activated:Fire()
assert(guia._alvoBotao == loja._botoesPecas.CamaraFissao:ObterInstancia())
assert(guia._instrucao.Text:find("clicar duas vezes no ícone da loja", 1, true))
construcao.Selecao = {MaquinaId = "CamaraFissao"}; nav:Abrir("FichaLoja")
assert(guia._alvoBotao == loja._acoes.Comprar:ObterInstancia())
assert(guia._instrucao.Text:find("a compra é feita ao confirmar na plot", 1, true))
jogadorUI:SetAttribute("Inventario_CamaraFissao", 1)
assert(guia.Destino and guia._focoMundo.Adornee == esteira and guia._instrucao.Text:find("Recolher"))
entrada = roblox.Enum.UserInputType.Keyboard
jogadorUI:SetAttribute("Atalho_Z", "G")
assert(guia._setaMundo.Enabled and guia._instrucao.Text:find("pressione G", 1, true))
nav:Abrir("Recolhimento")
assert(guia._instrucao.Text == "Clique na peça marcada para recolher.")
nav:Fechar("Recolhimento")
plot({mina, segunda, forno})
assert(guia.Destino and guia._focoMundo.Adornee == segunda, "o guia atualiza o obstáculo depois de recolher a primeira esteira")
plot({mina, forno})
assert(not guia.Destino and guia.Silhueta == "CamaraFissao" and guia._acao == "Inventario")
plot({mina, camara, forno})
assert(guia.Silhueta == "FornalhaBasica" and guia.Apoio == camara and guia._focoMundo.Adornee == forno)
nav:Fechar("FichaLoja"); nav:Fechar("Loja")
jogadorUI:SetAttribute("Atalho_X", "H")
assert(guia._instrucao.Text:find("pressione H", 1, true))
jogadorUI:SetAttribute("TutorialEtapa", e.Concluido)
assert(not guia._cartao.Visible and not guia._setaMundo.Enabled and not guia.Silhueta)
assert(guia._aviso.Visible and guia._seta.Visible and guia:BotaoParaFoco() == atalhos.Tutorial:ObterInstancia())
assert(guia._seta.Rotation == 0 and guia._aviso.Text:find("renascimento", 1, true))
nav:Abrir("Tutorial"); painel:Atualizar()
assert(not guia._aviso.Visible and not guia._seta.Visible)
for _, b in painel._botoes do assert(b:ObterInstancia().Name ~= "RetomarGuia") end
assert(painel._capitulos)
local capitulos = carregarUI("src/shared/Tutorial").Licoes
painel:AbrirCapitulo("blueprints")
assert(capitulos[painel._atual].Id == "blueprints")
assert(capitulos[painel._atual].Secoes[2][2]:find("escolha o local na plot e confirme", 1, true))
painel:AbrirCapitulo("renascimento")
assert(capitulos[painel._atual].Id == "renascimento")
nav:Fechar("Tutorial")
assert(not guia._cartao.Visible and not guia._aviso.Visible and not guia._alvoBotao)
guia:Destruir(); painel:Destruir(); nav:Destruir()
print("TUTORIAL_INTERATIVO_OK: montagem, pulsos, atalhos remapeados e conclusão após a venda modificada.")
