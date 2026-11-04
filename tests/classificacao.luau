local r = require("./suporte/modelos")
local ui = require("./suporte/interface")
local task = require("@lune/task")
local carregar = require("./suporte/carregador")({ Instance = { new = ui.NovaInstancia }, Enum = r.Enum, Color3 = r.Color3,
	Vector2 = r.Vector2, UDim = r.UDim, UDim2 = r.UDim2, task = task }, {})
local Regras = carregar("src/shared/Classificacao")
local Servico = carregar("src/server/ServicoClassificacao")
local valores, falhar, durante = {}, false, nil
local store = {}
function store:UpdateAsync(id, transformar)
	if falhar then error("Falha simulada") end
	local original = valores[id]
	-- O DataStore pode repetir a transformacao por concorrencia.
	transformar(original)
	valores[id] = transformar(original)
	if durante then local acao = durante; durante = nil; acao() end
	return valores[id]
end
function store:GetAsync(id) return valores[id] end
local a, b = Servico.new(store), Servico.new(store)
local jogador = { UserId = 12, Name = "Teste" }
local grande = "1234567890123456789012345678901234567890"
local maior = "1234567890123456789012345678901234567891"
a:Registrar(jogador, { Vidas = "12", Dinheiro = grande, Minerio = "9", DinheiroPorSegundo = "99" })
assert(a:Atualizar())
b:Registrar(jogador, { Vidas = "3", Dinheiro = "100", Minerio = "10", DinheiroPorSegundo = "1" })
b:Registrar({ UserId = 13, Name = "Outro" }, { Dinheiro = maior })
assert(b:Atualizar())
assert(valores.Dinheiro.Lista[1].UserId == 13 and valores.Dinheiro.Lista[2].Valor == grande)
assert(valores.Vidas.Lista[1].Valor == "12" and valores.Minerio.Lista[1].Valor == "10")
assert(valores.DinheiroPorSegundo.Lista[1].Valor == "99")
local empate = Regras.Mesclar({}, { { UserId=2,Nome="B",Valor="00010" }, { UserId=1,Nome="A",Valor="10" } })
assert(empate[1].UserId == 1 and empate[2].Valor == "10")
a:Registrar(jogador, { Minerio = "20" })
falhar = true; assert(not a:Atualizar() and a._pendentes.Minerio[1].Valor == "20")
falhar = false
durante = function() a:Registrar(jogador, { Minerio = "30" }) end
assert(a:Atualizar() and a._pendentes.Minerio[1].Valor == "30")
assert(a:Atualizar() and valores.Minerio.Lista[1].Valor == "30")
local reiniciado = Servico.new(store)
assert(reiniciado:Atualizar() and reiniciado:Consultar().Tabelas.Dinheiro[1].Valor == maior)
local lote = {}
for i=1,70 do table.insert(lote,{UserId=i,Nome="P"..i,Valor=tostring(i)}) end
assert(#Regras.Mesclar({},lote)==50 and Regras.Mesclar({},lote)[50].Valor=="21")
-- A geracao persiste fora do top 50 para caches anteriores nao ressuscitarem recordes apagados.
a:Registrar(jogador,{Vidas="1",Dinheiro="0",Minerio="0",DinheiroPorSegundo="0"},1)
falhar=true; assert(not a:Atualizar())
falhar=false; assert(a:Atualizar())
assert(valores.Dinheiro.Geracoes["12"]==1 and valores.Vidas.Lista[1].Valor=="1")
b:Registrar(jogador,{Dinheiro=grande,Vidas="99"},0)
assert(b:Atualizar())
for _,r in valores.Dinheiro.Lista do assert(r.UserId~=12,"Um servidor atrasado nao pode recuperar o recorde antigo.") end
assert(valores.Vidas.Lista[1].Valor=="1")
b:Registrar(jogador,{Dinheiro="5",Vidas="2"},1); assert(b:Atualizar())
local achou=false
for _,r in valores.Dinheiro.Lista do if r.UserId==12 then assert(r.Valor=="5" and r.Geracao==1); achou=true end end
assert(achou)

local modeloJogador = { Name="Dados", UserId=99, atributos={}, sinais={}, _filhos={}, Destroying=ui.Sinal() }
function modeloJogador:GetAttribute(id) return self.atributos[id] end
function modeloJogador:GetAttributeChangedSignal(id) self.sinais[id]=self.sinais[id] or ui.Sinal(); return self.sinais[id] end
function modeloJogador:SetAttribute(id,v) self.atributos[id]=v; self:GetAttributeChangedSignal(id):Fire() end
local Dados = carregar("src/server/Data/DadosJogador")
local perfil = { Data=carregar("src/server/Data/ReinicioProgresso").new(carregar("src/server/Data/Template"),{}):Preparar({}), IsActive=function() return true end }
local dados = Dados.new(modeloJogador, perfil)
dados:Sincronizar()
assert(dados:AdicionarDinheiro(grande))
dados:PublicarGanhosPorSegundo(2)
assert(perfil.Data.Recordes.Dinheiro == grande)
assert(perfil.Data.Recordes.DinheiroPorSegundo == carregar("src/server/InteiroGrande").multiplicarArredondado(grande,"0.5"))
local parte = r.Instance.new("Part"); parte.Name="Minerio"
local minerio = carregar("src/server/Minerio").new(parte); minerio._dadosDono=dados
assert(minerio:DefinirValor(maior)); assert(minerio:DefinirValor("1"))
assert(perfil.Data.Recordes.Minerio==maior)
dados:_DefinirSaldo("0"); dados:PublicarGanhosPorSegundo(2)
assert(perfil.Data.Recordes.Dinheiro==grande and perfil.Data.Recordes.DinheiroPorSegundo~="0")
local placar = carregar("src/server/Data/PlacarJogador")(modeloJogador)
assert(#placar:GetChildren()==2 and placar:FindFirstChild("Vidas").Value==1)
modeloJogador:SetAttribute("Dinheiro", grande); modeloJogador:SetAttribute("Vidas",42)
assert(placar:FindFirstChild("Vidas").Value==42 and placar:FindFirstChild("Dinheiro").Value=="$"..carregar("src/shared/AbreviarInteiro")(grande))
modeloJogador.Destroying:Fire()
for _,s in modeloJogador.sinais do for _,c in s.conexoes do assert(not c.ativa) end end
dados:_DefinirSaldo("1"..string.rep("0",50))
assert(dados:Reencarnar(0))
assert(perfil.Data.Recordes.Dinheiro=="1"..string.rep("0",50) and tonumber(perfil.Data.Recordes.Vidas)>1)

local nav = carregar("src/client/NavegacaoEstados").new()
local painel = carregar("src/client/PainelClassificacao").new(ui.NovaInstancia("ScreenGui"), modeloJogador, nav, {fetch=function() return reiniciado:Consultar() end})
nav:Abrir("Classificacao"); painel:Atualizar(); task.wait()
assert(painel._grupo.Visible and painel._linhas[1].Nome.Text=="1.  @Teste")
painel._abas.Dinheiro:ObterInstancia().Activated:Fire()
assert(painel._linhas[1].Nome.Text=="1.  @Outro" and not painel._linhas[3].Nome.Visible)
painel._linhas[1].Valor.MouseEnter:Fire()
assert(painel._dica._caixa.Visible and painel._dica._texto.Text==carregar("src/shared/NomeNumero")(maior))
painel._abas.Vidas:ObterInstancia().Activated:Fire(); assert(not painel._dica._caixa.Visible)
painel._linhas[1].Valor.MouseEnter:Fire(); assert(painel._dica._texto.Text=="doze")
nav:Voltar(); painel:Atualizar(); assert(not painel._grupo.Visible)
assert(not painel._dica._caixa.Visible)
painel:Destruir()
print("CLASSIFICACAO_OK: quatro recordes, inteiros exatos, concorrencia, falha/repeticao, top 50, cache, renascimento, placar e interface.")
