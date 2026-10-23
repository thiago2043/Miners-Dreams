local roblox = require("@lune/roblox")
local suporte = require("./suporte/interface")
local carregar = require("./suporte/carregador")({
	Instance = { new = suporte.NovaInstancia }, Enum = roblox.Enum, Color3 = roblox.Color3,
	Vector2 = roblox.Vector2, UDim = roblox.UDim, UDim2 = roblox.UDim2, ColorSequence = roblox.ColorSequence,
}, {})
local Navegacao = carregar("src/client/NavegacaoEstados")
local Painel = carregar("src/client/PainelPrestigio")
local Barra = carregar("src/client/BarraProgressao")
local pai, nav = suporte.NovaInstancia("ScreenGui"), Navegacao.new()
local atributos = { Dinheiro = "10000000000000000000", Reencarnacoes = 0, Vidas = 1 }
local jogador = { GetAttribute = function(_, nome) return atributos[nome] end }
local pedidos, falhar, malformar = 0, false, false
local painel
local rede = { fetch = function(_, metodo, indice)
	assert(metodo == "Reencarnar" and indice == atributos.Reencarnacoes)
	pedidos += 1
	painel._reencarnar:ObterInstancia().Activated:Fire() -- Nao pode disparar um segundo pedido durante a espera.
	if falhar then error("Falha simulada") end
	if malformar then return "sim", "Invalido" end
	atributos.Dinheiro, atributos.Reencarnacoes, atributos.Vidas = "0", 1, 6
	return true, "Reencarnou: +5 vidas."
end }
painel = Painel.new(pai, jogador, nav, rede)
assert(not painel._grupo.Visible)
painel:Reencarnar()
assert(pedidos == 0)
nav:Abrir("Prestigio")
painel:Atualizar()
assert(painel._grupo.Visible and painel._vida.Text == "Vida 1" and painel._requisito.Text == "Requisito: $1qd")
assert(painel._estado.VidasDisponiveis == 5 and painel._saltos.Text:find("4 pulada", 1, true))
painel._reencarnar:ObterInstancia().Activated:Fire()
assert(pedidos == 1 and painel._vida.Text == "Vida 6" and painel._requisito.Text == "Requisito: $10qd")
assert(not painel._reencarnar:ObterInstancia().Active and painel._mensagem.Text == "Reencarnou: +5 vidas.")
atributos.Dinheiro = "100000000000000000"
falhar = true
painel:Atualizar()
painel:Reencarnar()
assert(pedidos == 2 and painel._mensagem.Text:find("Não foi possível", 1, true))
assert(painel._reencarnar:ObterInstancia().Active and not painel._enviando)
falhar, malformar = false, true
painel:Reencarnar()
assert(pedidos == 3 and atributos.Reencarnacoes == 1)
nav:Voltar()
painel:Atualizar()
assert(not painel._grupo.Visible)
nav:Abrir("Prestigio")
painel._fechar:ObterInstancia().Activated:Fire()
painel:Atualizar()
assert(not painel._grupo.Visible and nav:Atual() == nil)
atributos.Vidas = nil
painel:Atualizar()
assert(not painel._reencarnar:ObterInstancia().Active and painel._barra._preenchimento.Size.X.Scale == 0)
local barra = Barra.new(pai, roblox.Color3.new(1, 0, 0), roblox.Color3.new(0, 1, 0))
barra:Atualizar(0.5)
assert(barra._preenchimento.Size.X.Scale == 0.5)
barra:Atualizar(2)
assert(barra._preenchimento.Size.X.Scale == 1)
assert(not pcall(barra.Atualizar, barra, 0 / 0))
barra:Destruir(); barra:Destruir()
painel:Destruir(); painel:Destruir()
assert(painel._barra._destruido)
for _, botao in painel._botoes do assert(botao._destruido and not botao._conexao.ativa) end
nav:Destruir()
print("PASS: ficha de prestigio, saltos, requisito seguinte, bloqueio durante rede, erros, Q/fechar, barra e limpeza.")
