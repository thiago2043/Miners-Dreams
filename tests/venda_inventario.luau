-- Executa o servico e os dados reais; nao acessa perfis persistidos do Roblox.
local serde = require("@lune/serde")
local jogadores = {}
local jogador = { Parent = jogadores, Name = "Teste", atributos = {} }
function jogador:GetAttribute(nome) return self.atributos[nome] end
function jogador:SetAttribute(nome, valor) self.atributos[nome] = valor end
local carregar = require("./suporte/carregador")({}, { Players = jogadores })
local manager = carregar("src/server/Data/DataManager")
local catalogo = carregar("src/shared/CatalogoMaquinas")
local servico = carregar("src/server/ServicoLoja").new()
local perfil = { ativo = true, Data = {
	Dinheiro = "10000", Inventory = {}, InventarioPersonalizado = {}, MaquinasColocadas = { { Id = "preservar" } },
} }
function perfil:IsActive() return self.ativo end
for id in catalogo do perfil.Data.Inventory[id] = 0 end
local dados = manager.RegistrarPerfil(jogador, perfil)
local function preparar(id, quantidade, variantes)
	perfil.Data.Inventory[id] = quantidade
	perfil.Data.InventarioPersonalizado[id] = variantes or {}
	dados:Sincronizar()
end
local function vender(id, configuracao)
	return servico:Vender(jogador, id, configuracao or jogador:GetAttribute("ConfiguracaoInventario_" .. id))
end
local function estado()
	return serde.encode("json", perfil.Data)
end
preparar("MineradoraBasica", 2)
assert(vender("MineradoraBasica"))
assert(perfil.Data.Dinheiro == "10100" and perfil.Data.Inventory.MineradoraBasica == 1)
assert(vender("MineradoraBasica"))
assert(perfil.Data.Dinheiro == "10200" and perfil.Data.Inventory.MineradoraBasica == 0)
local antes = estado()
assert(not vender("MineradoraBasica"))
assert(not servico:Vender(jogador, {}, "{}"))
assert(not vender("NaoExiste"))
assert(estado() == antes)
assert(perfil.Data.MaquinasColocadas[1].Id == "preservar")
print("PASS: venda de uma unidade por vez, reembolso integral e rejeicao de estoque vazio ou identificador invalido.")

local primeira = { Configuracao = { Componentes = { { Velocidade = 13 } } }, Dados = { Melhoria = 3 } }
local segunda = { Dados = { Melhoria = 7 } }
preparar("EsteiraBasica", 3, { primeira, segunda })
local comum = jogador:GetAttribute("ConfiguracaoInventario_EsteiraBasica")
assert(vender("EsteiraBasica"))
assert(#perfil.Data.InventarioPersonalizado.EsteiraBasica == 2)
local exibida = serde.decode("json", jogador:GetAttribute("ConfiguracaoInventario_EsteiraBasica"))
assert(exibida.Dados.Melhoria == 3)
antes = estado()
assert(not vender("EsteiraBasica", comum), "Uma ficha antiga nao pode consumir outra variante.")
assert(estado() == antes)
assert(vender("EsteiraBasica"))
assert(#perfil.Data.InventarioPersonalizado.EsteiraBasica == 1)
assert(perfil.Data.InventarioPersonalizado.EsteiraBasica[1].Dados.Melhoria == 7)
assert(vender("EsteiraBasica"))
assert(#perfil.Data.InventarioPersonalizado.EsteiraBasica == 0 and perfil.Data.Inventory.EsteiraBasica == 0)
assert(perfil.Data.Dinheiro == "10275")
print("PASS: consome primeiro a unidade comum, depois a variante exibida, preserva as demais e recusa ficha desatualizada.")

preparar("MineradoraBasica", 1)
perfil.ativo = false
antes = estado()
assert(not vender("MineradoraBasica") and estado() == antes)
perfil.ativo, jogador.Parent = true, nil
assert(not vender("MineradoraBasica") and estado() == antes)
jogador.Parent = jogadores
perfil.Data.Dinheiro = "invalido"
antes = estado()
assert(not vender("MineradoraBasica") and estado() == antes)
perfil.Data.Dinheiro = "10275"
perfil.Data.InventarioPersonalizado.MineradoraBasica = { primeira, segunda }
antes = estado()
assert(not vender("MineradoraBasica") and estado() == antes)
perfil.Data.Inventory.MineradoraBasica = 2
perfil.Data.InventarioPersonalizado.MineradoraBasica = { primeira, { Dados = { Invalido = function() end } } }
local saldo = perfil.Data.Dinheiro
assert(not vender("MineradoraBasica"))
assert(perfil.Data.Inventory.MineradoraBasica == 2 and perfil.Data.Dinheiro == saldo)
preparar("MineradoraBasica", 1)
antes = estado()
assert(not servico:Vender(jogador, "MineradoraBasica", nil) and estado() == antes)
print("PASS: perfil inativo, jogador desconectado, saldo, configuracao e variantes invalidos nao alteram os dados.")

local saldoInicial = perfil.Data.Dinheiro
assert(servico:Comprar(jogador, "FornalhaBasica"))
assert(vender("FornalhaBasica"))
assert(perfil.Data.Dinheiro == saldoInicial and perfil.Data.Inventory.FornalhaBasica == 0)
catalogo.MineradoraBasica.Preco = "1" .. string.rep("0", 100)
preparar("MineradoraBasica", 1)
assert(vender("MineradoraBasica"))
assert(perfil.Data.Dinheiro == "1" .. string.rep("0", 95) .. "10275")
print("PASS: comprar e vender devolve o mesmo saldo; reembolso de 101 digitos preserva a precisao inteira existente.")
