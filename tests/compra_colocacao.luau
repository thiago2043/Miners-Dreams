-- Executar com Lune; perfis, rede e metodos de Model sao simulados.
local serde = require("@lune/serde")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("./suporte/modelos")
local Instance, CFrame, Vector3 = roblox.Instance, roblox.CFrame, roblox.Vector3

local function foiDestruida(instancia, pasta)
	-- Destroy bloqueia Parent; apenas ocultar com Parent = nil ainda permitiria recolocar a instancia.
	local podeReparentar = pcall(function() instancia.Parent = pasta end)
	if podeReparentar then instancia.Parent = nil end
	return not podeReparentar
end

local mundo = Instance.new("Workspace")
local modelos = Instance.new("Folder")
modelos.Name = "ModelosMaquinas"
local replicado = { ModelosMaquinas = modelos }
function replicado:WaitForChild(nome) return assert(self[nome]) end
local catalogo = luau.load(fs.readFile("src/shared/CatalogoMaquinas.luau"))()
require("./suporte/catalogo_modelos")(modelos)
local modificador = modelos.ModificadorBasico
local caixaModificador, tamanhoModificador = modificador:GetBoundingBox()
assert(tamanhoModificador == Vector3.new(4, 8, 4))
local caixaEsteira, tamanhoEsteira = modelos.EsteiraBasica:GetBoundingBox()
local topoModificador = modificador.Correia.CFrame.Position.Y + modificador.Correia.Size.Y / 2
	- (caixaModificador.Position.Y - tamanhoModificador.Y / 2)
local topoEsteira = modelos.EsteiraBasica.Correia.CFrame.Position.Y + modelos.EsteiraBasica.Correia.Size.Y / 2
	- (caixaEsteira.Position.Y - tamanhoEsteira.Y / 2)
assert(math.abs(topoModificador - topoEsteira) < 0.0001)
assert(modificador.Correia.Size.X == modelos.EsteiraBasica.Correia.Size.X)
assert(modificador.SensorEntrada.CanTouch and not modificador.SensorEntrada.CanCollide)
assert(not modificador.SensorEntrada.CanQuery and modificador.SensorEntrada.Transparency == 1)
assert(math.abs(modificador.SensorEntrada.CFrame.Position.Y - modificador.SensorEntrada.Size.Y / 2
	- modificador.Correia.CFrame.Position.Y - modificador.Correia.Size.Y / 2) < 0.0001)
for _, instancia in modificador:GetDescendants() do
	if instancia:IsA("BasePart") then assert(instancia.Anchored) end
	assert(not instancia:IsA("LuaSourceContainer"))
end
print("PASS: modificador real de 4x8x4, correia alinhada a esteira, sensor atravessavel e sem scripts internos.")

local terrenos = Instance.new("Folder")
terrenos.Name = "Terrenos"
terrenos.Parent = mundo
local terreno = Instance.new("Model")
terreno:SetAttribute("DonoUserId", 123)
terreno:SetAttribute("TerrenoId", 1)
terreno.Parent = terrenos
local piso = Instance.new("Part")
piso.Name = "Piso"
piso.Size = Vector3.new(64, 1, 64)
piso.Parent = terreno
local maquinas = Instance.new("Folder")
maquinas.Name = "Maquinas"
maquinas.Parent = terreno

local Players = { PlayerRemoving = { Connect = function() end } }
local atributos = { TerrenoId = 1 }
local jogador = { Parent = Players, UserId = 123, Name = "Teste" }
function jogador:GetAttribute(nome) return atributos[nome] end
function jogador:SetAttribute(nome, valor) atributos[nome] = valor end
local profile = {
	Data = { Dinheiro = "300", Inventory = { MineradoraBasica = 2, EsteiraBasica = 0, FornalhaBasica = 0, ModificadorBasico = 0 }, MaquinasColocadas = {} },
}
function profile:IsActive() return true end

local tempo = 0
local carregar, no = require("./suporte/carregador")({
	workspace = mundo, CFrame = CFrame, Vector3 = Vector3, Color3 = roblox.Color3, Enum = roblox.Enum, typeof = roblox.typeof,
	os = { clock = function() return tempo end },
}, { Players = Players, ReplicatedStorage = replicado, Debris = { AddItem = function() end } }, {
	["Packages/Networker"] = { server = { new = function(_, moduloServidor, acesso)
		assert(#acesso == 13 and acesso[3] == moduloServidor.Copiar and acesso[1] == moduloServidor.Colocar
			and acesso[2] == moduloServidor.Recolher and acesso[4] == moduloServidor.CopiarGrupo
			and acesso[5] == moduloServidor.ColocarGrupoCopia and acesso[6] == moduloServidor.CriarBlueprint
			and acesso[7] == moduloServidor.ListarBlueprints and acesso[8] == moduloServidor.PrepararBlueprint
			and acesso[9] == moduloServidor.IniciarMovimento and acesso[10] == moduloServidor.Mover
			and acesso[11] == moduloServidor.MoverGrupo and acesso[12] == moduloServidor.CancelarMovimento
			and acesso[13] == moduloServidor.VenderColocadas)
	end } },
})
replicado.Shared, replicado.Packages = no("src/shared"), no("Packages")
assert(not mundo:FindFirstChild("MineradoraBasica") and not mundo:FindFirstChild("ModificadorBasico"))
local inteiro = carregar("src/server/InteiroGrande")
local manager = carregar("src/server/Data/DataManager")
manager.RegistrarPerfil(jogador, profile)
local geometria = carregar("src/shared/GeometriaColocacao")
local construcao = carregar("src/server/Construcao")

local function colocar(posicao, rotacao)
	tempo += 1
	return construcao:Colocar(jogador, "MineradoraBasica", posicao, rotacao or CFrame.identity)
end
local function recusar(posicao, rotacao)
	local antes = serde.encode("json", profile.Data)
	local quantidade = #maquinas:GetChildren()
	assert(colocar(posicao, rotacao) == false)
	assert(serde.encode("json", profile.Data) == antes)
	assert(#maquinas:GetChildren() == quantidade)
end

for i, x in { 0, 12, 24, 36, 48 } do
	assert(colocar(Vector3.new(x, 0, 0)))
	assert(profile.Data.Inventory.MineradoraBasica == math.max(0, 2 - i))
	assert(profile.Data.Dinheiro == tostring(300 - math.max(0, i - 2) * 100))
	assert(#maquinas:GetChildren() == i and #profile.Data.MaquinasColocadas == i)
	recusar(Vector3.new(x, 0, 0))
end
assert(profile.Data.Dinheiro == "0")
recusar(Vector3.new(0, 0, 16))
profile.Data.Dinheiro = "99"
recusar(Vector3.new(0, 0, 16))
profile.Data.Dinheiro = "100"
recusar(Vector3.new(-4, 0, 16))
recusar(Vector3.new(1, 0, 16))
recusar(Vector3.new(60, 0, 16))
recusar(Vector3.new(0, -4, 16))
recusar(Vector3.new(0, 0, 16), CFrame.new(0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1))
recusar(Vector3.new(0, 0, 16), CFrame.Angles(0, math.rad(22.5), 0))
recusar(Vector3.new(0, 0, 16), CFrame.fromAxisAngle(Vector3.new(1, 1, 0).Unit, math.pi / 2))
terreno:SetAttribute("DonoUserId", 999)
recusar(Vector3.new(0, 0, 16))
terreno:SetAttribute("DonoUserId", 123)
for _, quantidade in { -1, 0.5, 2 ^ 53 } do
	profile.Data.Inventory.MineradoraBasica = quantidade
	recusar(Vector3.new(0, 0, 16))
end
profile.Data.Inventory.MineradoraBasica = 0
profile.Data.Dinheiro = "0"
tempo += 1
assert(construcao:Recolher(jogador, maquinas:GetChildren()[1]))
assert(profile.Data.Inventory.MineradoraBasica == 1 and profile.Data.Dinheiro == "0")
assert(colocar(Vector3.new(0, 0, 16)))
assert(profile.Data.Inventory.MineradoraBasica == 0 and profile.Data.Dinheiro == "0")

local dadosSalvos = serde.decode("json", serde.encode("json", profile.Data))
for _, maquina in maquinas:GetChildren() do maquina:Destroy() end
profile = { Data = dadosSalvos }
function profile:IsActive() return true end
manager.Profiles[jogador] = profile
assert(construcao.Restaurar(jogador))
assert(#maquinas:GetChildren() == 5 and profile.Data.Dinheiro == "0")
assert(profile.Data.Inventory.MineradoraBasica == 0)
print("PASS: inventario tem prioridade; estoque vazio compra e coloca por 100.")
print("PASS: sobreposicao, saldo, limites, grade, rotacao, dono e quantidade invalidos nao alteram dados.")
print("PASS: recolher/recolocar e restaurar nao cobram novamente.")

local template = carregar("src/server/Data/Template")
local kitInicial = { MineradoraBasica = 1, EsteiraBasica = 1, FornalhaBasica = 1 }
for maquinaId in catalogo do assert(template.Inventory[maquinaId] == (kitInicial[maquinaId] or 0)) end
profile.Data.Dinheiro = "100000"
local saldoEsperado = profile.Data.Dinheiro
local tipos = { "MineradoraBasica", "EsteiraBasica", "FornalhaBasica", "ModificadorBasico" }
local testadas = 0
for _, maquinaId in tipos do
	local rotacoes = {}
	for x = 0, 3 do
		for y = 0, 3 do
			for z = 0, 3 do
				local rotacao = CFrame.Angles(x * math.pi / 2, y * math.pi / 2, z * math.pi / 2)
				local r, u = rotacao.RightVector, rotacao.UpVector
				local chave = string.format("%.0f,%.0f,%.0f/%.0f,%.0f,%.0f", r.X + 0, r.Y + 0, r.Z + 0, u.X + 0, u.Y + 0, u.Z + 0):gsub("-0", "0")
				if rotacoes[chave] then continue end
				rotacoes[chave] = true
				testadas += 1
				local posicao = Vector3.new(0, testadas * 32, 0)
				local antes = #profile.Data.MaquinasColocadas
				tempo += 1
				assert(construcao:Colocar(jogador, maquinaId, posicao, rotacao))
				saldoEsperado = inteiro.subtrair(saldoEsperado, catalogo[maquinaId].Preco)
				assert(profile.Data.Dinheiro == saldoEsperado and profile.Data.Inventory[maquinaId] == 0)
				assert(#profile.Data.MaquinasColocadas == antes + 1)
				local criada = maquinas:GetChildren()[#maquinas:GetChildren()]
				assert(criada.Name == maquinaId and criada:GetAttribute("PodeRecolher") == true)
				local minimo = geometria.VolumeDoModelo(criada, geometria.Origem(piso))
				assert((minimo - posicao).Magnitude < 0.001)
				local caixaReal, tamanhoReal = geometria.CaixaDeConstrucao(criada)
				local caixaLocal = geometria.Origem(piso):ToObjectSpace(caixaReal)
				local extensaoReal = geometria.CalcularVolume(caixaLocal, tamanhoReal)
				local minimoReal = caixaLocal.Position - extensaoReal
				for _, eixo in { "X", "Y", "Z" } do
					assert(math.abs(math.floor(minimoReal[eixo] / 4 + geometria.Tolerancia) * 4 - posicao[eixo]) < 0.001)
				end
				local snapshot = serde.encode("json", profile.Data)
				tempo += 1
				assert(construcao:Colocar(jogador, maquinaId, posicao, rotacao) == false)
				assert(serde.encode("json", profile.Data) == snapshot)
				if x == 0 and y == 0 and z == 0 then
					tempo += 1
					assert(construcao:Recolher(jogador, criada))
					assert(profile.Data.Inventory[maquinaId] == 1 and profile.Data.Dinheiro == saldoEsperado)
					tempo += 1
					assert(construcao:Colocar(jogador, maquinaId, posicao, rotacao))
					assert(profile.Data.Inventory[maquinaId] == 0 and profile.Data.Dinheiro == saldoEsperado)
				end
			end
		end
	end
end
assert(testadas == 96)
local salvos = serde.decode("json", serde.encode("json", profile.Data))
local quantidadeAntes = #maquinas:GetChildren()
for _, maquina in maquinas:GetChildren() do maquina:Destroy() end
profile = { Data = salvos }
function profile:IsActive() return true end
manager.Profiles[jogador] = profile
assert(construcao.Restaurar(jogador))
assert(#maquinas:GetChildren() == quantidadeAntes and profile.Data.Dinheiro == saldoEsperado)
assert(construcao.Restaurar(jogador) and #maquinas:GetChildren() == quantidadeAntes)
tempo += 1
assert(construcao:Colocar(jogador, "Inexistente", Vector3.zero, CFrame.identity) == false)
print("PASS: modelos reais dos quatro tipos, 24 rotacoes cada, precos, sobreposicao e recolhimento correto por tipo.")
print("PASS: registros antigos e novos restaurados juntos, sem duplicacao ou nova cobranca.")

local dados = manager.ObterDados(jogador)
assert(dados == manager.ObterDados(jogador))
local outroJogador = { Name = "Outro", SetAttribute = function() end }
local outroPerfil = { Data = { Dinheiro = "50", Inventory = { EsteiraBasica = 0 } } }
function outroPerfil:IsActive() return true end
local outrosDados = manager.RegistrarPerfil(outroJogador, outroPerfil)
assert(outrosDados ~= dados)
assert(outrosDados:ComprarMaquina("EsteiraBasica"))
assert(outroPerfil.Data.Dinheiro == "25" and profile.Data.Dinheiro == saldoEsperado)
local copia = dados:ObterConstrucoes()
table.clear(copia)
assert(#dados:ObterConstrucoes() == quantidadeAntes)
profile.Data.Inventory.MineradoraBasica = 2 ^ 53 - 1
local snapshot = serde.encode("json", profile.Data)
assert(dados:ComprarMaquina("MineradoraBasica") == false)
assert(serde.encode("json", profile.Data) == snapshot)
manager.RemoverPerfil(jogador)
assert(manager.ObterDados(jogador) == nil)
print("PASS: dados por jogador, copia da lista e limite seguro do inventario.")

local Volume = carregar("src/shared/VolumeConstrucao")
local volume = Volume.new(Vector3.new(5, 6, 7), { 4, 3, 2 })
assert(volume:ObterBlocos() == Vector3.new(4, 3, 2))
assert(volume:ObterBlocos(CFrame.Angles(0, math.pi / 2, 0)) == Vector3.new(2, 3, 4))
assert(not pcall(Volume.new, Vector3.new(9, 1, 1), { 2, 1, 1 }))
local copiaModelo = modelos.MineradoraBasica:Clone()
copiaModelo.Name = "MineradoraGrande"
copiaModelo.Parent = modelos
catalogo.MineradoraGrande = table.clone(catalogo.MineradoraBasica)
catalogo.MineradoraGrande.Blocos = { 4, 3, 4 }
carregar("src/shared/CatalogoMaquinas").MineradoraGrande = catalogo.MineradoraGrande
local carregarTemplate = require("./suporte/carregador")({}, {}, {
	["src/shared/CatalogoMaquinas"] = catalogo,
})
assert(carregarTemplate("src/server/Data/Template").Inventory.MineradoraGrande == 0)
local jogador2 = { Name = "Construtor2", UserId = 456, Parent = Players }
function jogador2:GetAttribute() return 2 end
function jogador2:SetAttribute() end
local terreno2 = Instance.new("Model")
terreno2:SetAttribute("DonoUserId", 456)
terreno2:SetAttribute("TerrenoId", 2)
terreno2.Parent = terrenos
local piso2 = piso:Clone()
piso2.Parent = terreno2
local maquinas2 = Instance.new("Folder")
maquinas2.Name, maquinas2.Parent = "Maquinas", terreno2
local perfil2 = { Data = { Dinheiro = "100", Inventory = { MineradoraGrande = 0 }, MaquinasColocadas = {} } }
function perfil2:IsActive() return true end
manager.RegistrarPerfil(jogador2, perfil2)
local novoServico = carregar("src/server/ServicoConstrucao").new()
assert(novoServico:Colocar(jogador2, "MineradoraGrande", Vector3.zero, CFrame.identity))
local construida = maquinas2:GetChildren()[1]
local a, b = geometria.VolumeDoModelo(construida, geometria.Origem(piso2))
assert(a == Vector3.zero and b == Vector3.new(16, 12, 16))
local Maquina = carregar("src/server/Maquinas/Maquina")
local definicaoAssimetrica = table.clone(catalogo.MineradoraGrande)
definicaoAssimetrica.Blocos = { 5, 3, 4 }
-- O objeto usa dimensoes de criacao, mesmo quando a caixa atual troca seus eixos.
local caixaOriginal, tamanhoOriginal = geometria.CaixaDeConstrucao(copiaModelo)
local modeloGirado = copiaModelo:Clone()
modeloGirado:PivotTo(CFrame.Angles(0, math.pi / 2, 0) * caixaOriginal)
modeloGirado:SetAttribute("TamanhoConstrucao", tamanhoOriginal)
local objeto = Maquina.new(modeloGirado, terreno2, definicaoAssimetrica)
assert(objeto:ObterVolume():ObterBlocos() == Vector3.new(5, 3, 4))
objeto:Destruir()
local saldoAntes = perfil2.Data.Dinheiro
assert(not novoServico:Colocar(jogador2, "MineradoraGrande", Vector3.new(12, 0, 0), CFrame.identity))
assert(perfil2.Data.Dinheiro == saldoAntes)
print("PASS: classe de volume, rotacao dos blocos declarados e bloqueio pelo volume configurado.")

perfil2.Data.Dinheiro = "10000"
local esperadas = {}
for i, rotacao in {
	CFrame.Angles(math.pi / 2, 0, 0),
	CFrame.Angles(0, -math.pi / 2, 0),
	CFrame.Angles(0, 0, math.pi / 2),
	CFrame.Angles(math.pi / 2, math.pi, -math.pi / 2),
} do
	tempo += 1
	assert(novoServico:Colocar(jogador2, "MineradoraGrande", Vector3.new(0, i * 40, 0), rotacao))
	esperadas[i + 1] = rotacao
end
local dadosAngulados = serde.decode("json", serde.encode("json", perfil2.Data))
-- Simula um registro anterior a restricao de 90 graus: restaura-lo nao pode perder a peca.
esperadas[5] = CFrame.Angles(0, 0, math.rad(67.5))
local componentesAntigos = { esperadas[5]:GetComponents() }
dadosAngulados.MaquinasColocadas[5].Rotacao = { table.unpack(componentesAntigos, 4, 12) }
for _, modelo in maquinas2:GetChildren() do modelo:Destroy() end
perfil2 = { Data = dadosAngulados }
function perfil2:IsActive() return true end
manager.RegistrarPerfil(jogador2, perfil2)
assert(novoServico:Restaurar(jogador2))
assert(#maquinas2:GetChildren() == 5)
for i, registro in perfil2.Data.MaquinasColocadas do
	if not esperadas[i] then continue end
	local salva = CFrame.new(0, 0, 0, table.unpack(registro.Rotacao))
	assert((salva.RightVector - esperadas[i].RightVector).Magnitude < 0.0001)
	assert((salva.UpVector - esperadas[i].UpVector).Magnitude < 0.0001)
end
assert(perfil2.Data.Dinheiro == "9600")
local legada = maquinas2:GetChildren()[5]
local rotacaoLegada = legada:GetAttribute("RotacaoConstrucao")
assert((rotacaoLegada.RightVector - esperadas[5].RightVector).Magnitude < 0.0001)
tempo += 1
local copiouLegada, mensagemLegada, copiaLegada = novoServico:Copiar(jogador2, legada)
assert(copiouLegada, mensagemLegada)
local Rotacao = carregar("src/shared/RotacaoConstrucao")
assert(Rotacao.ValidarNaGrade(copiaLegada.Rotacao))
assert((copiaLegada.Rotacao.UpVector - CFrame.Angles(0, 0, math.pi / 2).UpVector).Magnitude < 0.0001)
assert(legada:GetAttribute("RotacaoConstrucao") == rotacaoLegada)
print("PASS: novas colocacoes de 90 graus; restauracao antiga preservada e copia encaixada na grade.")

local Personalizacao = carregar("src/shared/PersonalizacaoMaquina")
local visual = copiaModelo:Clone()
local parteVisual
for _, parte in visual:GetDescendants() do if parte:IsA("BasePart") then parteVisual = parte; break end end
parteVisual.Color = roblox.Color3.fromRGB(200, 30, 80)
parteVisual.Size *= 1.1
local modificacoes = Personalizacao.new({
	Configuracao = { Componentes = { { Intervalo = 3, Minerio = { Valor = "70", Tamanho = { 2, 3, 4 } } } } },
	Dados = { Melhorias = { Nivel = 4, Efeitos = { "Teste", "Outro" } }, CampoFuturo = { Ativo = true } },
}):Capturar(visual, copiaModelo):ObterDados()
visual:Destroy()
local source = maquinas2:GetChildren()[1]
local personalizou, mensagem, personalizada = novoServico:Personalizar(jogador2, source, modificacoes)
assert(personalizou, mensagem)
tempo += 1
local copiou, mensagemCopia, copiaPeca = novoServico:Copiar(jogador2, personalizada)
assert(copiou, mensagemCopia)
assert(copiaPeca.Modificacoes.Dados.Melhorias.Nivel == 4)
assert(novoServico:Copiar(jogador, personalizada) == false)
local saldoCopia = perfil2.Data.Dinheiro
local posCopia = Vector3.new(32, 0, 32)
assert(novoServico:Colocar(jogador2, "MineradoraGrande", posCopia, CFrame.identity, copiaPeca.Token + 1) == false)
assert(perfil2.Data.Dinheiro == saldoCopia)
copiaPeca.Modificacoes.Configuracao.Componentes[1].Intervalo = 999
assert(novoServico:Colocar(jogador2, "MineradoraGrande", posCopia, copiaPeca.Rotacao, copiaPeca.Token))
assert(perfil2.Data.Dinheiro == inteiro.subtrair(saldoCopia, "100"))
local novaCopia = maquinas2:GetChildren()[#maquinas2:GetChildren()]
local estadoCopiado = Personalizacao.DoModelo(novaCopia):ObterDados()
assert(estadoCopiado.Configuracao.Componentes[1].Intervalo == 3)
assert(estadoCopiado.Dados.CampoFuturo.Ativo and estadoCopiado.Dados.Melhorias.Nivel == 4)
assert(Personalizacao.Iguais(estadoCopiado.Partes, modificacoes.Partes))
assert(#maquinas2:GetChildren() == 6 and personalizada.Parent == maquinas2)
local vinculoMovido = novoServico._registrosPorMaquina[personalizada]
local registroMovido = assert(vinculoMovido and vinculoMovido.registro)
local quantidadeMovida = #perfil2.Data.MaquinasColocadas
local dinheiroMovido, estoqueMovido = perfil2.Data.Dinheiro, perfil2.Data.Inventory.MineradoraGrande
local destinoMovido = Vector3.new(48, 0, 48)
local rotacaoMovida = CFrame.Angles(0, math.pi / 2, 0)
personalizada:SetAttribute("TotalRecebido", "321")
tempo += 1
local iniciou, mensagemInicio, tokenMovimento = novoServico:IniciarMovimento(jogador2, { personalizada })
assert(iniciou, mensagemInicio)
assert(foiDestruida(personalizada, maquinas2) and not novoServico._registrosPorMaquina[personalizada],
	"A instancia antiga deve ser destruida ao iniciar o movimento.")
assert(#maquinas2:GetChildren() == 5)
local antesMovimentoInvalido = serde.encode("json", perfil2.Data)
tempo += 1
assert(not novoServico:Mover(jogador2, tokenMovimento, posCopia, CFrame.identity), "Nao deve sobrepor outra maquina.")
assert(not novoServico:Mover(jogador2, tokenMovimento, Vector3.new(1, 0, 0), CFrame.identity), "Nao deve sair da grade.")
assert(not novoServico:Mover(jogador, tokenMovimento, Vector3.new(40, 0, 40), CFrame.identity), "Outro jogador nao pode concluir o movimento.")
assert(serde.encode("json", perfil2.Data) == antesMovimentoInvalido)
local moveu, mensagemMoveu, novasInstancias = novoServico:Mover(jogador2, tokenMovimento, destinoMovido, rotacaoMovida)
assert(moveu, mensagemMoveu)
local instanciaAntiga = personalizada
personalizada = novasInstancias[1]
assert(personalizada ~= instanciaAntiga and instanciaAntiga.Parent == nil and personalizada.Parent == maquinas2)
assert(personalizada:GetAttribute("VolumeMinimo") == destinoMovido)
assert((personalizada:GetAttribute("RotacaoConstrucao").LookVector - rotacaoMovida.LookVector).Magnitude < 0.0001)
assert(personalizada:GetAttribute("TotalRecebido") == "321")
assert(registroMovido.Posicao[1] == 48 and registroMovido.Posicao[2] == 0 and registroMovido.Posicao[3] == 48)
local componentesMovidos = { rotacaoMovida:GetComponents() }
for indice = 4, 12 do assert(math.abs(registroMovido.Rotacao[indice - 3] - componentesMovidos[indice]) < 0.0001) end
assert(#perfil2.Data.MaquinasColocadas == quantidadeMovida and perfil2.Data.Dinheiro == dinheiroMovido
	and perfil2.Data.Inventory.MineradoraGrande == estoqueMovido)
local estadoMovido = Personalizacao.DoModelo(personalizada):ObterDados()
assert(estadoMovido.Dados.Melhorias.Nivel == 4 and estadoMovido.Configuracao.Componentes[1].Intervalo == 3)
assert(Personalizacao.Iguais(estadoMovido.Partes, modificacoes.Partes))
print("PASS: iniciar movimento destroi a instancia; concluir recria a peca, preserva dados e recusa token/destino invalidos.")

-- O lote move ambos os modelos somente quando todos os destinos cabem, e R preserva o centro da ancora.
local rotacaoGrupo = CFrame.Angles(0, math.pi / 2, 0)
tempo += 1
local inicioGrupo, mensagemGrupo, tokenGrupo = novoServico:IniciarMovimento(jogador2, { personalizada, novaCopia })
assert(inicioGrupo, mensagemGrupo)
assert(foiDestruida(personalizada, maquinas2) and foiDestruida(novaCopia, maquinas2),
	"Todas as instancias originais do grupo devem ser destruidas.")
local antesLoteInvalido = serde.encode("json", perfil2.Data)
assert(not novoServico:MoverGrupo(jogador2, tokenGrupo, {
	{ Minimo = Vector3.zero, Rotacao = CFrame.identity },
	{ Minimo = Vector3.zero, Rotacao = CFrame.identity },
}), "Duas pecas nao podem ocupar o mesmo volume no lote.")
assert(serde.encode("json", perfil2.Data) == antesLoteInvalido and novoServico._movimentosPendentes[jogador2])
local rotacaoGrupoGirado = CFrame.Angles(0, math.pi, 0)
tempo += 1
local moveuGrupo, mensagemMoveuGrupo, pecasRecriadas = novoServico:MoverGrupo(jogador2, tokenGrupo, {
	{ Minimo = Vector3.new(16, 0, 16), Rotacao = rotacaoGrupoGirado },
	{ Minimo = Vector3.new(0, 0, 32), Rotacao = rotacaoGrupoGirado },
})
assert(moveuGrupo, mensagemMoveuGrupo)
personalizada, novaCopia = pecasRecriadas[1], pecasRecriadas[2]
assert(personalizada:GetAttribute("VolumeMinimo") == Vector3.new(16, 0, 16)
	and novaCopia:GetAttribute("VolumeMinimo") == Vector3.new(0, 0, 32))
assert((personalizada:GetAttribute("RotacaoConstrucao").RightVector - rotacaoGrupoGirado.RightVector).Magnitude < 0.0001)
assert((novaCopia:GetAttribute("RotacaoConstrucao").RightVector - rotacaoGrupoGirado.RightVector).Magnitude < 0.0001)
destinoMovido, rotacaoMovida = Vector3.new(16, 0, 16), rotacaoGrupoGirado
print("PASS: mover grupo preserva a formacao, gira ao redor da ancora e rejeita destinos parcialmente sobrepostos.")

-- Copiar grupo captura configuracoes sem apagar as fontes e confirma o lote sem resultados parciais.
tempo += 1
local contagemAntesCopiaGrupo = #perfil2.Data.MaquinasColocadas
local sucessoCapturaGrupo, mensagemCapturaGrupo, dadosCopiaGrupo = novoServico:CopiarGrupo(
	jogador2, { personalizada, novaCopia }
)
assert(sucessoCapturaGrupo, mensagemCapturaGrupo)
assert(#dadosCopiaGrupo.Pecas == 2 and personalizada.Parent == maquinas2 and novaCopia.Parent == maquinas2)
assert(dadosCopiaGrupo.Pecas[1].DeslocamentoInicial == Vector3.zero)
local dadosCliente = dadosCopiaGrupo.Pecas[1].Modificacoes
dadosCliente.Dados.Melhorias.Nivel = 999
local estadoAntesCopiaInvalida = serde.encode("json", perfil2.Data)
assert(not novoServico:ColocarGrupoCopia(jogador2, dadosCopiaGrupo.Token, {
	{ Minimo = Vector3.new(16, 0, 16), Rotacao = rotacaoGrupoGirado },
	{ Minimo = Vector3.new(16, 0, 16), Rotacao = rotacaoGrupoGirado },
}), "Uma copia sobreposta deve recusar o grupo todo.")
assert(serde.encode("json", perfil2.Data) == estadoAntesCopiaInvalida
	and personalizada.Parent == maquinas2 and novaCopia.Parent == maquinas2)
tempo += 1
local copiouGrupo, mensagemCopiaGrupo, pecasCopiadas = novoServico:ColocarGrupoCopia(jogador2, dadosCopiaGrupo.Token, {
	{ Minimo = Vector3.new(16, 160, 16), Rotacao = rotacaoGrupoGirado },
	{ Minimo = Vector3.new(0, 160, 32), Rotacao = rotacaoGrupoGirado },
})
assert(copiouGrupo, mensagemCopiaGrupo)
assert(#pecasCopiadas == 2 and #perfil2.Data.MaquinasColocadas == contagemAntesCopiaGrupo + 2)
assert(personalizada.Parent == maquinas2 and novaCopia.Parent == maquinas2)
assert(pecasCopiadas[1]:GetAttribute("VolumeMinimo") == Vector3.new(16, 160, 16)
	and pecasCopiadas[2]:GetAttribute("VolumeMinimo") == Vector3.new(0, 160, 32))
assert(Personalizacao.DoModelo(pecasCopiadas[1]):ObterDados().Dados.Melhorias.Nivel == 4,
	"A resposta do cliente nao pode alterar as melhorias capturadas pelo servidor.")
print("PASS: copia em grupo conserva as fontes, a formacao e as personalizacoes; destinos invalidos nao cobram.")

local antesInvalida = serde.encode("json", perfil2.Data)
assert(not novoServico:Personalizar(jogador2, personalizada, { Configuracao = { Componentes = { { Intervalo = 0 } } } }))
assert(not novoServico:Personalizar(jogador2, personalizada, { Configuracao = { Componentes = { { Minerio = { Valor = "invalido" } } } } }))
assert(not novoServico:Personalizar(jogador2, personalizada, { Configuracao = { Componentes = { { Minerio = { Tamanho = { 0, 1, 1 } } } } } }))
assert(serde.encode("json", perfil2.Data) == antesInvalida)
local dinheiroDepois = perfil2.Data.Dinheiro
assert(novoServico:Recolher(jogador2, novaCopia))
assert(perfil2.Data.Inventory.MineradoraGrande == 1)
assert(#perfil2.Data.InventarioPersonalizado.MineradoraGrande == 1)
local salvosComMod = serde.decode("json", serde.encode("json", perfil2.Data))
for _, modelo in maquinas2:GetChildren() do modelo:Destroy() end
perfil2 = { Data = salvosComMod }
function perfil2:IsActive() return true end
manager.RegistrarPerfil(jogador2, perfil2)
assert(novoServico:Restaurar(jogador2))
assert(#maquinas2:GetChildren() == 7)
local encontrou = false
local encontrouGrupoCopiado = false
for _, modelo in maquinas2:GetChildren() do
	local estado = Personalizacao.DoModelo(modelo):ObterDados()
	if estado.Dados then
		encontrou = true
		assert(estado.Dados.Melhorias.Nivel == 4)
		if modelo:GetAttribute("VolumeMinimo") == destinoMovido then
			assert((modelo:GetAttribute("RotacaoConstrucao").LookVector - rotacaoMovida.LookVector).Magnitude < 0.0001,
				"O novo giro deve sobreviver ao restauro.")
		elseif modelo:GetAttribute("VolumeMinimo").Y == 160 then
			encontrouGrupoCopiado = true
		end
	end
end
assert(encontrou and encontrouGrupoCopiado)
assert(novoServico:Colocar(jogador2, "MineradoraGrande", posCopia, CFrame.identity))
assert(perfil2.Data.Inventory.MineradoraGrande == 0 and #perfil2.Data.InventarioPersonalizado.MineradoraGrande == 0)
assert(perfil2.Data.Dinheiro == dinheiroDepois)
local recolocada = maquinas2:GetChildren()[#maquinas2:GetChildren()]
assert(Personalizacao.DoModelo(recolocada):ObterDados().Dados.Melhorias.Nivel == 4)
assert(Personalizacao.Iguais({ Partes = { { CFrame = { 1, 0, 0 } } } }, { Partes = { { CFrame = { 1.000001, 0, 0 } } } }))
assert(not Personalizacao.Iguais({ Dados = { Nivel = 1 } }, { Dados = { Nivel = 1.000001 } }))
print("PASS: copia autenticada, estado isolado do cliente, visual/configuracao/dados futuros e custo normal.")

local DadosJogador = carregar("src/server/Data/DadosJogador")
local perfilLote = { Data = {
	Inventory = { MineradoraGrande = 2 }, MaquinasColocadas = {
		{ MaquinaId = "MineradoraGrande" }, { MaquinaId = "MineradoraGrande" },
	}, InventarioPersonalizado = {},
} }
function perfilLote:IsActive() return true end
local jogadorLote = { Atributos = {} }
function jogadorLote:SetAttribute(nome, valor) self.Atributos[nome] = valor end
local dadosLote = DadosJogador.new(jogadorLote, perfilLote)
local lote = {
	{ Registro = perfilLote.Data.MaquinasColocadas[1], Modificacoes = { Dados = { Nivel = 2 } } },
	{ Registro = perfilLote.Data.MaquinasColocadas[2], Modificacoes = { Dados = { Nivel = 3 } } },
}
local antesLoteDados = serde.encode("json", perfilLote.Data)
assert(not dadosLote:RegistrarRecolhimentos({ lote[1], lote[1] }))
assert(serde.encode("json", perfilLote.Data) == antesLoteDados, "Um lote invalido nao pode devolver parte do grupo.")
assert(dadosLote:RegistrarRecolhimentos(lote))
assert(#perfilLote.Data.MaquinasColocadas == 0 and perfilLote.Data.Inventory.MineradoraGrande == 4)
assert(#perfilLote.Data.InventarioPersonalizado.MineradoraGrande == 2)
assert(jogadorLote.Atributos.Inventario_MineradoraGrande == 4)
perfilLote.Data.Dinheiro = "100"
perfilLote.Data.Inventory.MineradoraGrande = 0
perfilLote.Data.MaquinasColocadas = {}
perfilLote.Data.InventarioPersonalizado = {}
local antesColocacaoLoteInvalido = serde.encode("json", perfilLote.Data)
assert(not dadosLote:RegistrarColocacoes({ { MaquinaId = "MineradoraGrande" }, { MaquinaId = "MineradoraGrande" } }))
assert(serde.encode("json", perfilLote.Data) == antesColocacaoLoteInvalido,
	"Se faltar saldo para uma das copias, o perfil deve voltar ao estado anterior ao grupo.")
assert(jogadorLote.Atributos.Dinheiro == "100" and jogadorLote.Atributos.Inventario_MineradoraGrande == 0,
	"O cliente deve receber os valores restaurados junto com o perfil.")
print("PASS: recolhimento em lote valida primeiro, preserva variantes e atualiza inventario sem resultados parciais.")
print("PASS: personalizacoes preservadas no save, no inventario e na recolocacao sem nova cobranca.")

local terrenoLinha = Instance.new("Model")
terrenoLinha:SetAttribute("DonoUserId", 789)
terrenoLinha:SetAttribute("TerrenoId", 3)
terrenoLinha.Parent = terrenos
local pisoLinha = piso:Clone()
pisoLinha.Parent = terrenoLinha
local maquinasLinha = Instance.new("Folder")
maquinasLinha.Name, maquinasLinha.Parent = "Maquinas", terrenoLinha
local jogadorLinha = { Name = "Alinhamento", UserId = 789, Parent = Players }
function jogadorLinha:GetAttribute() return 3 end
function jogadorLinha:SetAttribute() end
local perfilLinha = { Data = { Dinheiro = "0", MaquinasColocadas = {},
	Inventory = { EsteiraBasica = 1, ModificadorBasico = 1, FornalhaBasica = 1 } } }
function perfilLinha:IsActive() return true end
manager.RegistrarPerfil(jogadorLinha, perfilLinha)
local servicoLinha = carregar("src/server/ServicoConstrucao").new()
for i, item in { { "EsteiraBasica", 0 }, { "ModificadorBasico", 12 }, { "FornalhaBasica", 16 } } do
	tempo += 1
	assert(servicoLinha:Colocar(jogadorLinha, item[1], Vector3.new(0, 0, item[2]), CFrame.identity))
end
local esteiraLinha, modificadorLinha, fornalhaLinha = table.unpack(maquinasLinha:GetChildren())
assert(esteiraLinha:GetAttribute("VolumeOcupado") == Vector3.new(8, 4, 12))
assert(modificadorLinha:GetAttribute("VolumeOcupado") == Vector3.new(8, 8, 4))
local function conferirLinha()
	local x = esteiraLinha.Correia.CFrame.Position.X
	local y = esteiraLinha.Correia.CFrame.Position.Y + esteiraLinha.Correia.Size.Y / 2
	for _, correia in { modificadorLinha.Correia, fornalhaLinha.BandejaEntrada } do
		assert(math.abs(correia.CFrame.Position.X - x) + esteiraLinha.Correia.Size.X / 2 <= correia.Size.X / 2 + 0.0001,
			"A passagem seguinte deve comportar toda a largura da correia, mesmo com os detalhes assimetricos do forno.")
		assert(math.abs(correia.CFrame.Position.Y + correia.Size.Y / 2 - y) < 0.0001)
	end
	local fimEsteira = esteiraLinha.Correia.CFrame.Position.Z + esteiraLinha.Correia.Size.Z / 2
	local inicioModificador = modificadorLinha.Correia.CFrame.Position.Z - modificadorLinha.Correia.Size.Z / 2
	local fimModificador = modificadorLinha.Correia.CFrame.Position.Z + modificadorLinha.Correia.Size.Z / 2
	local inicioForno = fornalhaLinha.BandejaEntrada.CFrame.Position.Z - fornalhaLinha.BandejaEntrada.Size.Z / 2
	assert(math.abs(fimEsteira - inicioModificador) < 0.0001)
	assert(math.abs(fimModificador - inicioForno) < 0.0001)
end
conferirLinha()
local linhaSalva = serde.decode("json", serde.encode("json", perfilLinha.Data))
for _, modelo in maquinasLinha:GetChildren() do modelo:Destroy() end
perfilLinha = { Data = linhaSalva }
function perfilLinha:IsActive() return true end
manager.RegistrarPerfil(jogadorLinha, perfilLinha)
assert(servicoLinha:Restaurar(jogadorLinha))
esteiraLinha, modificadorLinha, fornalhaLinha = table.unpack(maquinasLinha:GetChildren())
assert(#maquinasLinha:GetChildren() == 3 and perfilLinha.Data.Dinheiro == "0")
conferirLinha()
print("PASS: esteira de dois blocos, modificador e fornalha alinhados, sem vao entre correias, antes/depois de restaurar.")
