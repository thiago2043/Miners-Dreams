-- Perfil e mundo locais: nao abre ProfileStore, Studio ou dados reais de jogadores.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("./suporte/modelos")
local Instance, Vector3, CFrame = roblox.Instance, roblox.Vector3, roblox.CFrame
local mundo, modelos = Instance.new("Workspace"), Instance.new("Folder")
local replicado = { ModelosMaquinas = modelos }
function replicado:WaitForChild(nome) return assert(self[nome]) end
local Players = {}
local construcao, canal
local carregar, no = require("./suporte/carregador")({
	workspace = mundo, Instance = Instance, Vector3 = Vector3, CFrame = CFrame,
	Color3 = roblox.Color3, Enum = roblox.Enum, typeof = roblox.typeof,
}, { Players = Players, ReplicatedStorage = replicado }, {
	["src/server/Construcao"] = { ReiniciarProgresso = function(quem, callback)
		return construcao:ReiniciarProgresso(quem, callback)
	end },
	["Packages/Networker"] = { server = { new = function(nome, modulo, permitidos)
		assert(nome == "Prestigio" and #permitidos == 2 and permitidos[1] == modulo.Reencarnar and permitidos[2] == modulo.Ascender)
		assert(modulo.ReiniciarProgresso == nil, "O reset generico nao pode ser exposto ao cliente.")
		canal = modulo
	end } },
})
replicado.Shared = no("src/shared")
replicado.Packages = no("Packages")
local Template = carregar("src/server/Data/Template")
local Reinicio = carregar("src/server/Data/ReinicioProgresso")
local Regra = carregar("src/shared/RegraReencarnacao").new()
local DataManager = carregar("src/server/Data/DataManager")
local Construcao = carregar("src/server/ServicoConstrucao")
local Prestigio = carregar("src/server/ServicoPrestigio")
require("./suporte/catalogo_modelos")(modelos)
local terrenos = Instance.new("Folder")
terrenos.Name, terrenos.Parent = "Terrenos", mundo
local terreno = Instance.new("Model")
terreno:SetAttribute("DonoUserId", 123)
terreno:SetAttribute("TerrenoId", 1)
terreno.Parent = terrenos
local piso = Instance.new("Part")
piso.Name, piso.Size, piso.Parent = "Piso", Vector3.new(64, 1, 64), terreno
local maquinas, minerios = Instance.new("Folder"), Instance.new("Folder")
maquinas.Name, maquinas.Parent, minerios.Name, minerios.Parent = "Maquinas", terreno, "Minerios", terreno
local outroTerreno = Instance.new("Model")
outroTerreno:SetAttribute("DonoUserId", 456)
outroTerreno.Parent = terrenos
local pecaAlheia = Instance.new("Part")
pecaAlheia.Parent = outroTerreno
local atributos = { TerrenoId = 1 }
local jogador = { Parent = Players, UserId = 123, Name = "Teste" }
function jogador:GetAttribute(nome) return atributos[nome] end
function jogador:SetAttribute(nome, valor) atributos[nome] = valor end
local ativo = true
local perfil = { Data = Reinicio.new(Template, {}):Preparar({}), IsActive = function() return ativo end }
DataManager.RegistrarPerfil(jogador, perfil)
local dados = DataManager.ObterDados(jogador)
construcao = Construcao.new()
local servico = Prestigio.new({ ReiniciarProgresso = function(quem, callback)
	return construcao:ReiniciarProgresso(quem, callback)
end })
assert(construcao:Colocar(jogador, "MineradoraBasica", Vector3.new(0, 0, 0), CFrame.identity))
assert(construcao:Colocar(jogador, "Esteira2x2", Vector3.new(12, 0, 0), CFrame.identity))
local mineradora = maquinas:FindFirstChild("MineradoraBasica")
local copiou, _, copia = construcao:Copiar(jogador, mineradora)
assert(copiou and construcao._copias[jogador])
assert(construcao:CopiarGrupo(jogador, { mineradora, maquinas:FindFirstChild("Esteira2x2") }))
assert(construcao._copiasGrupo[jogador])
local moveu, _, movimento = construcao:IniciarMovimento(jogador, { mineradora })
assert(moveu and construcao._movimentosPendentes[jogador])
local minerio = Instance.new("Part")
minerio.Parent = minerios
perfil.Data.Dinheiro = "999999999999999"
local anterior = serde.encode("json", perfil.Data)
assert(not servico:Reencarnar(jogador, 0))
assert(serde.encode("json", perfil.Data) == anterior and minerio.Parent == minerios)
for _, indice in { -1, 0.5, "0", false, math.huge, 0 / 0 } do assert(not servico:Reencarnar(jogador, indice)) end
assert(not servico:Reencarnar(jogador, nil))
perfil.Data.Dinheiro = "1"..string.rep("0",33) -- 1e19: cinco vidas, mas apenas uma operacao.
perfil.Data.Inventory.FornalhaBasica = 27
perfil.Data.InventarioPersonalizado = { FornalhaBasica = { { Dados = { Nivel = 3 } } } }
perfil.Data.Blueprints = { { Id = "b1", Nome = "Fabrica", Pecas = { { MaquinaId = "Esteira2x2" } } } }
perfil.Data.RecompensasReencarnacao = { PremioAnterior = { Quantidade = 7 } }
perfil.Data.ProgressoExtra = { Nivel = 15 }
local blueprints, recompensas = serde.encode("json", perfil.Data.Blueprints), serde.encode("json", perfil.Data.RecompensasReencarnacao)
local sucesso, _, resultado = servico:Reencarnar(jogador, 0)
assert(sucesso and resultado.VidasDisponiveis == 5 and resultado.VidasPuladas == 4)
assert(perfil.Data.Reencarnacoes == 1 and perfil.Data.Vidas == 6 and perfil.Data.Dinheiro == "0")
assert(atributos.Reencarnacoes == 1 and atributos.Vidas == 6 and atributos.Dinheiro == "0")
assert(#maquinas:GetChildren() == 0 and #minerios:GetChildren() == 0 and #perfil.Data.MaquinasColocadas == 0)
assert(next(perfil.Data.InventarioPersonalizado) == nil and perfil.Data.ProgressoExtra == nil)
assert(perfil.Data.Inventory.MineradoraBasica == 1 and perfil.Data.Inventory.Esteira2x2 == 10
	and perfil.Data.Inventory.FornalhaBasica == 1 and perfil.Data.Inventory.PrensaMinerio == 0)
assert(serde.encode("json", perfil.Data.Blueprints) == blueprints and perfil.Data.RecompensasReencarnacao.PremioAnterior.Quantidade == 7)
local premios = carregar("src/shared/RecompensasRenascimento")
local totalPremios = 0
for _, premio in premios do
	totalPremios += perfil.Data.Inventory[premio.Id]
	assert(not dados:ComprarMaquina(premio.Id) and not dados:VenderMaquina(premio.Id,"{}"))
end
assert(totalPremios==5,"Saltos devem sortear uma peca por vida, nao por operacao.")
local premioColocado
for _, premio in premios do if perfil.Data.Inventory[premio.Id]>0 then premioColocado=premio.Id; break end end
assert(construcao:Colocar(jogador,premioColocado,Vector3.zero,CFrame.identity))
maquinas:FindFirstChild(premioColocado):SetAttribute("Personalizacao", '{"Dados":{"Nivel":3}}')
assert(not construcao._copias[jogador] and not construcao._copiasGrupo[jogador] and not construcao._movimentosPendentes[jogador])
assert(pecaAlheia.Parent == outroTerreno)
assert(not pcall(function() minerio.Parent = minerios end), "Minerio precisa ser destruido, nao escondido.")
assert(not construcao:CancelarMovimento(jogador, movimento))
construcao:Sincronizar(jogador)
assert(#perfil.Data.MaquinasColocadas == 1 and perfil.Data.MaquinasColocadas[1].MaquinaId==premioColocado)
assert(dados:ObterReencarnacao().ExpoenteRequisito == 24, "Saltos nao aumentam o custo por vida pulada.")
perfil.Data.Dinheiro = "1"..string.rep("0",24)
assert(not servico:Reencarnar(jogador, 0), "Pedido repetido precisa ser recusado mesmo havendo saldo.")
assert(servico:Reencarnar(jogador, 1))
assert(perfil.Data.Vidas == 7 and perfil.Data.Reencarnacoes == 2)
local totalSeguinte=0
for _, premio in premios do totalSeguinte+=perfil.Data.Inventory[premio.Id] end
assert(totalSeguinte==6 and #perfil.Data.MaquinasColocadas==0,"Recompensa colocada deve voltar ao inventario e somar o premio novo.")
assert(perfil.Data.InventarioPersonalizado[premioColocado][1].Dados.Nivel==3,"Preservar a personalizacao atual da recompensa colocada.")
-- Simula recarregar os mesmos dados salvos em outro objeto de sessao.
local recarregado = carregar("src/server/Data/DadosJogador").new(jogador, perfil)
assert(recarregado:ObterReencarnacao().ExpoenteRequisito == 27 and perfil.Data.Vidas == 7)
perfil.Data.Dinheiro = "1"..string.rep("0",27)
ativo = false
assert(not servico:Reencarnar(jogador, 2))
ativo = true
perfil.Data.RecompensasReencarnacao = "invalido"
local antesFalha = serde.encode("json", perfil.Data)
assert(not servico:Reencarnar(jogador, 2))
assert(serde.encode("json", perfil.Data) == antesFalha, "Dados persistentes invalidos nao autorizam o reinicio.")
perfil.Data.RecompensasReencarnacao = { PremioAnterior = { Quantidade = 7 } }
local apagandoRecompensas = Reinicio.new(Template, { "Blueprints" }):Preparar(perfil.Data)
assert(next(apagandoRecompensas.RecompensasReencarnacao) == nil and #apagandoRecompensas.Blueprints == 1)
assert(serde.encode("json", perfil.Data.RecompensasReencarnacao) == recompensas, "Preparar outro reinicio nao altera os dados originais.")
for zeros = 0, 5 do
	local estado = Regra:Calcular("1" .. string.rep("0", 21 + zeros*3), 0, 1)
	assert(estado.VidasDisponiveis == zeros + 1 and estado.VidaDestino == zeros + 2)
end
assert(Regra:Calcular("1"..string.rep("0",33), 1, 6).VidasDisponiveis == 4)
assert(Regra:Calcular("1"..string.rep("0",21), 1, 6).VidasDisponiveis == 0)
assert(Regra:Calcular("0", 2 ^ 52, 1).VidasDisponiveis == 0, "Indices grandes nao podem alocar strings gigantes.")
assert(Regra:Calcular("-1", 0, 1) == nil and Regra:Calcular("0", -1, 1) == nil)
carregar("src/server/Prestigio.server")
assert(canal and not canal:Reencarnar(jogador, "2"))
local Ascensao = carregar("src/shared/RegraAscensao")
local function potencia(e) return "1" .. string.rep("0", e) end
assert(Ascensao.Calcular(string.rep("9", 308), 0, 0).Disponiveis == 0)
assert(Ascensao.Calcular("00" .. potencia(308), 0, 0).Disponiveis == 1)
assert(Ascensao.Calcular(string.rep("9", 318), 0, 0).Disponiveis == 1)
assert(Ascensao.Calcular(potencia(318), 0, 0).Disponiveis == 2)
assert(Ascensao.Calcular(potencia(328), 0, 0).Disponiveis == 3)
assert(Ascensao.Calcular(potencia(408), 1, 3).Disponiveis == 1)
assert(Ascensao.Calcular(potencia(418), 1, 3).Disponiveis == 2)
assert(Ascensao.Calcular(potencia(500), 1, 0) == nil)
assert(construcao:Colocar(jogador, "Esteira2x2", Vector3.zero, CFrame.identity))
local ultimaPeca = maquinas:FindFirstChild("Esteira2x2")
local ultimoMinerio = Instance.new("Part")
ultimoMinerio.Parent = minerios
perfil.Data.Dinheiro = string.rep("9", 308)
assert(not canal:Ascender(jogador, 0, 0) and ultimaPeca.Parent == maquinas)
assert(not canal:Ascender(jogador, "0", 0) and not canal:Ascender(jogador, 0, 1))
perfil.Data.Dinheiro = potencia(328)
perfil.Data.ExpansaoPlot = 3
perfil.Data.Upgrades.Extracao = 4
perfil.Data.Recordes.Dinheiro = potencia(328)
perfil.Data.Configuracoes.ConfirmarVenda = "Sempre"
local salvamentos = 0
function perfil:Save() salvamentos += 1 end
assert(canal:Ascender(jogador, 0, 0))
assert(salvamentos == 1 and atributos.Ascensoes == 1 and atributos.Transicoes == 3 and atributos.GeracaoProgresso == 1)
assert(atributos.MarcoDinheiroE308 and atributos.GanhosPorSegundo == "0")
assert(perfil.Data.Reencarnacoes == 0 and perfil.Data.Vidas == 1 and perfil.Data.Dinheiro == "0")
assert(perfil.Data.ExpansaoPlot == 0 and perfil.Data.Upgrades.Extracao == 0 and perfil.Data.Inventory.Esteira2x2 == 10)
assert(#perfil.Data.Blueprints == 0 and next(perfil.Data.RecompensasReencarnacao) == nil)
assert(next(perfil.Data.Configuracoes) == nil and perfil.Data.Recordes.Dinheiro == "0")
assert(#maquinas:GetChildren() == 0 and #minerios:GetChildren() == 0 and pecaAlheia.Parent == outroTerreno)
assert(next(perfil.Data.RecompensasAscensao) == nil, "Transições são salvas sem fabricar máquinas inexistentes.")
perfil.Data.Dinheiro = potencia(418)
assert(not canal:Ascender(jogador, 0, 0) and not canal:Ascender(jogador, 1, 0))
assert(canal:Ascender(jogador, 1, 1))
assert(salvamentos == 2 and perfil.Data.Ascensoes == 2 and perfil.Data.Transicoes == 5)

-- Fixtures isoladas verificam entregas futuras e a devolução de máquinas instaladas ao inventário.
local Catalogo = carregar("src/shared/CatalogoMaquinas")
local Migracao = carregar("src/server/Data/MigracaoCatalogo")
Catalogo.AscensaoTeste = {Obtencao = "Ascensão", TransicaoAscensao = 3, Preco = "0"}
Catalogo.AscensaoTeste2 = {Obtencao = "Ascensão", TransicaoAscensao = 6, Preco = "0"}
perfil.Data = Migracao.Preparar(perfil.Data)
assert(perfil.Data.Inventory.AscensaoTeste == 1 and perfil.Data.Inventory.AscensaoTeste2 == nil)
perfil.Data = Migracao.Preparar(perfil.Data)
assert(perfil.Data.Inventory.AscensaoTeste == 1 and perfil.Data.RecompensasAscensao["3"])
assert(not dados:ComprarMaquina("AscensaoTeste") and not dados:VenderMaquina("AscensaoTeste", "{}"))
local registro = {MaquinaId = "AscensaoTeste", Modificacoes = {Dados = {Nivel = 3}}}
perfil.Data.Inventory.AscensaoTeste = 0
table.insert(perfil.Data.MaquinasColocadas, registro)
assert(not dados:VenderConstrucoes({registro}))
perfil.Data.Dinheiro = potencia(508)
assert(canal:Ascender(jogador, 2, 2))
assert(perfil.Data.Transicoes == 6 and perfil.Data.Inventory.AscensaoTeste2 == 1 and perfil.Data.Inventory.AscensaoTeste == 1)
assert(perfil.Data.InventarioPersonalizado.AscensaoTeste[1].Dados.Nivel == 3)
perfil.Data.Dinheiro = potencia(21)
assert(canal:Reencarnar(jogador, 0) and perfil.Data.Ascensoes == 3 and perfil.Data.Transicoes == 6)
assert(perfil.Data.Inventory.AscensaoTeste2 == 1 and perfil.Data.Inventory.AscensaoTeste == 1)
print("ASCENSAO_OK: limites exatos, saltos, reinício, recompensas futuras, persistência e repetição recusada.")
print("PASS: requisito por ciclo, salto de vidas, reset real de objetos locais, kit, patrimonio, tokens, repeticoes e sessao inativa.")
