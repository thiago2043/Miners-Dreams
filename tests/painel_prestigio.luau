local roblox = require("@lune/roblox")
local suporte = require("./suporte/interface")
local function instancia(classe)
	local objeto = suporte.NovaInstancia(classe)
	local atributos = {}
	function objeto:GetAttribute(nome) return atributos[nome] end
	function objeto:SetAttribute(nome, valor) atributos[nome] = valor end
	return objeto
end
local carregar = require("./suporte/carregador")({
	Instance = { new = instancia }, Enum = roblox.Enum, Color3 = roblox.Color3,
	Vector2 = roblox.Vector2, UDim = roblox.UDim, UDim2 = roblox.UDim2, ColorSequence = roblox.ColorSequence,
	typeof = function(valor) return if type(valor) == "table" and valor.ClassName then "Instance" else typeof(valor) end,
}, {}, {
	["src/client/AnimacaoInterface"] = {DefinirVisivel = function(p, v, _, callback) p.Visible = v; if callback then callback() end end,
		EstaVisivel = function(p) return p.Visible end},
	["src/client/GerenciadorJanelas"] = {Registrar = function() end},
})
local Navegacao = carregar("src/client/NavegacaoEstados")
local Painel = carregar("src/client/PainelPrestigio")
local Barra = carregar("src/client/BarraProgressao")
local pai, nav = suporte.NovaInstancia("ScreenGui"), Navegacao.new()
local atributos = { Dinheiro = "1"..string.rep("0",33), Reencarnacoes = 0, Vidas = 1, Ascensoes = 0, Transicoes = 0, GeracaoProgresso = 0 }
local jogador = { GetAttribute = function(_, nome) return atributos[nome] end }
local pedidos, pedidosAscensao, falhar, malformar = 0, 0, false, false
local painel
local rede = { fetch = function(_, metodo, indice, geracao)
	if metodo == "Ascender" then
		assert(indice == atributos.Ascensoes and geracao == atributos.GeracaoProgresso)
		pedidosAscensao += 1
		atributos.Ascensoes, atributos.Transicoes, atributos.Dinheiro = 1, 2, "0"
		return true, "Ascensão concluída."
	end
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
assert(painel._grupo.Visible and painel._vida.Text == "Vida 1" and painel._requisito.Text == "Requisito: $1Sx")
assert(painel._saldo.Text == "Saldo disponível: $1De")
assert(painel._estado.VidasDisponiveis == 5 and painel._saltos.Text:find("4 pulada", 1, true))
local confirmacao=carregar("src/client/Confirmacao").new(pai,jogador,nav)
painel.Confirmacao=confirmacao
painel._reencarnar:ObterInstancia().Activated:Fire()
assert(pedidos==0 and nav:Atual()=="Confirmacao")
nav:Voltar(); assert(pedidos==0 and atributos.Vidas==1)
painel._reencarnar:ObterInstancia().Activated:Fire()
confirmacao._sim:ObterInstancia().Activated:Fire()
confirmacao._sim:ObterInstancia().Activated:Fire()
painel.Confirmacao=nil
assert(pedidos == 1 and painel._vida.Text == "Vida 6" and painel._requisito.Text == "Requisito: $1Sp")
assert(not painel._reencarnar:ObterInstancia().Active and painel._mensagem.Text == "Reencarnou: +5 vidas.")
atributos.Dinheiro = "1"..string.rep("0",27)
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
nav:Abrir("Prestigio")
painel:Atualizar()
painel.Confirmacao = confirmacao
atributos.ConfirmarVenda, atributos.ConfirmarRenascimento = "Nunca", false
painel._abas["Ascensão"]:ObterInstancia().Activated:Fire()
assert(painel._requisito.Text == "Requisito: $1e308" and not painel._ascender:EstaDisponivel())
atributos.Dinheiro = "1" .. string.rep("0", 318)
painel:Atualizar()
assert(painel._ascender:EstaDisponivel() and painel._ascender:ObterInstancia().Text:find("+2", 1, true))
assert(painel._saltos.Text:find("1e328", 1, true))
painel._ascender:ObterInstancia().Activated:Fire()
assert(pedidosAscensao == 0 and nav:Atual() == "Confirmacao")
nav:Voltar()
assert(pedidosAscensao == 0)
painel._ascender:ObterInstancia().Activated:Fire()
confirmacao._sim:ObterInstancia().Activated:Fire()
assert(pedidosAscensao == 1 and painel._requisito.Text == "Requisito: $1e408" and not painel._ascender:EstaDisponivel())
local barra = Barra.new(pai, roblox.Color3.new(1, 0, 0), roblox.Color3.new(0, 1, 0))
barra:Atualizar(0.5)
assert(barra._preenchimento.Size.X.Scale == 0.5)
barra:Atualizar(2)
assert(barra._preenchimento.Size.X.Scale == 1)
assert(not pcall(barra.Atualizar, barra, 0 / 0))
barra:Destruir(); barra:Destruir()
painel:Destruir(); painel:Destruir(); confirmacao:Destruir()
assert(painel._barra._destruido)
for _, botao in painel._botoes do assert(botao._destruido and botao._conexao == nil) end
nav:Destruir()
print("PASS: ficha de prestigio, saltos, requisito seguinte, bloqueio durante rede, erros, Q/fechar, barra e limpeza.")
