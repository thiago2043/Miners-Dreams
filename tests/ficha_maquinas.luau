local carregar = require("./suporte/carregador")({}, {})
local Ficha = carregar("src/client/FichaMaquina")
local Catalogo = carregar("src/shared/CatalogoMaquinas")
local Personalizacao = carregar("src/shared/PersonalizacaoMaquina")
assert(Ficha.RotuloCatalogo(Catalogo.MineradoraBasica)=="$100")
assert(Ficha.RotuloCatalogo(Catalogo.SeloAurora)=="RN")
assert(Ficha.RotuloCatalogo(Catalogo.ComutadorFerroPrisma)=="Craft")
assert(Ficha.RotuloCatalogo({Preco="0",Obtencao="Ascensão"})=="AS")
assert(Ficha.RotuloCatalogo({Obtencao="Evento"})=="Evento")

local mineradora = Ficha.Descrever(Catalogo.MineradoraBasica)
for _, trecho in { "Minério: $5", "Intervalo de geração: 2 s", "0,75 × 0,75 × 0,75 studs" } do
	assert(mineradora:find(trecho, 1, true), trecho)
end
assert(Ficha.Descrever(Catalogo.Esteira2x2):find("Transporte: 2 blocos/s",1,true))
local modificador = Ficha.Descrever(Catalogo.PrensaMinerio)
assert(modificador:find("Transporte: 2 blocos/s", 1, true) and modificador:find("Modificação: ×1,4", 1, true))
assert(modificador:find("Limite: 4", 1, true) and not modificador:find("\nLimite:", modificador:find("Limite:", 1, true) + 1, true))
assert(not modificador:find("passagem") and not modificador:find("valor"))
assert(Ficha.Descrever(Catalogo.FornalhaBasica):find("Venda: ×1", 1, true))

local variante = Personalizacao.new({ Configuracao = { Componentes = { { Velocidade = 12.5 } } } })
assert(Ficha.Descrever(variante:ObterDefinicao(Catalogo.Esteira2x2)):find("Transporte: 4,166667 blocos/s",1,true))
assert(Catalogo.Esteira2x2.Componentes[1].Velocidade == 6)
local gigante = "1" .. string.rep("0", 100)
local especial = Personalizacao.new({ Configuracao = { Componentes = { { Minerio = { Valor = gigante } } } } })
assert(Ficha.Descrever(especial:ObterDefinicao(Catalogo.MineradoraBasica)):find("Minério: $10DTg", 1, true))
assert(Ficha.Descrever({ Componentes = { { Tipo = "Vendedor", Multiplicador = "3", Bonus = "25" } } }):find("×3 + 25", 1, true))
assert(Ficha.Descrever({ Componentes = { { Tipo = "Vendedor", Bonus = "1500000" } } }):find("+1,5M", 1, true))
local grandes = Ficha.Descrever({ Componentes = { { Tipo = "Modificador", Multiplicador = "2500000", LimiteUsos = 1000000 } } })
assert(grandes:find("×2,5M", 1, true) and grandes:find("Limite: 1M", 1, true))
assert(Ficha.Descrever({Componentes={{Tipo="Modificador", LimiteUsos=3}}}):find("Limite: 3", 1, true))
assert(Ficha.Descrever({Componentes={{Tipo="Modificador"}}}):find("Limite: inf", 1, true))
assert(Ficha.Descrever({ Componentes = { { Tipo = "Modificador" } } }):find("×1", 1, true))
assert(Ficha.Descrever({})=="")
assert(Ficha.Descrever({ Componentes = { { Tipo = "NovoComportamento" } } })=="")
print("PASS: ficha dos quatro tipos, combinacoes, variantes, bonus, decimais e valores grandes sem conversao para number.")

local attrs={Upgrade_Extracao=3,Upgrade_Fundicao=3,Upgrade_Motores=3,Upgrade_Calibracao=3,VelocidadeMotores=2}
local jogador={GetAttribute=function(_,id) return attrs[id] end}
assert(Ficha.Descrever(Catalogo.MineradoraBasica,jogador):find("Minério: $8",1,true))
assert(Ficha.Descrever(Catalogo.Esteira2x2,jogador):find("Transporte: 2,8 blocos/s",1,true))
local mod={Componentes={{Tipo="Modificador",Multiplicador="2",LimiteUsos=3}}}
assert(Ficha.Descrever(mod,jogador):find("Limite: 5",1,true))
assert(Ficha.Descrever(Catalogo.FornalhaBasica,jogador):find("Venda: ×1,6",1,true))
local fracao=Ficha.Descrever({Componentes={{Tipo="Vendedor",Multiplicador="1.25",Bonus="5"}}},jogador)
assert(fracao:find("Venda: ≈×2 + 8",1,true) and fracao:find("Cálculo: (×1,25 + 5) → ×1,6",1,true))
attrs.VelocidadeMotores=0
assert(Ficha.Descrever(Catalogo.Esteira2x2,jogador):find("Transporte: 2 blocos/s",1,true))
attrs.Upgrade_Extracao,attrs.Upgrade_Fundicao,attrs.Upgrade_Motores,attrs.Upgrade_Calibracao,attrs.VelocidadeMotores=5,5,5,5,5
assert(Ficha.Descrever(Catalogo.MineradoraBasica,jogador):find("Minério: $10",1,true))
assert(Ficha.Descrever(Catalogo.Esteira2x2,jogador):find("Transporte: 4 blocos/s",1,true))
assert(Ficha.Descrever(Catalogo.FornalhaBasica,jogador):find("Venda: ×2",1,true))
assert(Ficha.Descrever(mod,jogador):find("Limite: 6",1,true))
assert(Catalogo.MineradoraBasica.Componentes[1].Minerio.Valor=="5" and mod.Componentes[1].LimiteUsos==3)
local I=carregar("src/shared/InteiroGrande")
assert(I.multiplicarDecimal("0.01","0.01")=="0.0001" and I.multiplicarDecimal("0","1.3")=="0")
assert(I.multiplicarDecimal("1000000000000000000000000","1.3")=="1300000000000000000000000")
print("FICHAS_UPGRADES_OK: numeros efetivos, velocidade selecionada, limites, fundicao e arredondamento sem alterar o catalogo.")

assert(Ficha.Descrever(Catalogo.Centralizadora1x1):find("Transporte: 2 blocos/s",1,true))
assert(Ficha.Descrever(Catalogo.FornalhaBasica):find("Venda: ×1",1,true))
assert(Ficha.Descrever(Catalogo.Parede1x1):find("1 × 1 × 1",1,true))
assert(Ficha.Descrever(Catalogo.CamaraFissao):find("Modificação: ×1,2",1,true))
assert(Ficha.Descrever(Catalogo.PrensaTripla):find("Modificação: ×1,73\n",1,true))
assert(Ficha.Descrever(Catalogo.PortalDeVanAllen):find("Modificação: ×360",1,true))
assert(Ficha.FormatarMultiplicador("1.005")=="1,01")
assert(Ficha.FormatarMultiplicador("1.999")=="2")
assert(Ficha.FormatarMultiplicador("2.5000")=="2,5")
assert(Ficha.FormatarMultiplicador("1234567.891")=="1,23M")
assert(Ficha.Descrever({Componentes={{Tipo="Vendedor",Multiplicador="1.728"}}})=="Venda: ×1,73")

local roblox = require("@lune/roblox")
local carregarGrade = require("./suporte/carregador")(
	{Color3=roblox.Color3, ColorSequence=roblox.ColorSequence}, {TweenService={}}
)
local Grade = carregarGrade("src/client/GradePecas")
local itens = {CamaraFissao={}, PrensaTripla={}, PortalDeVanAllen={}, FornalhaBasica={}}
local grade = setmetatable({_itens=itens}, Grade)
grade:AtualizarDescricao("CamaraFissao", Ficha.Descrever(Catalogo.CamaraFissao), 0)
assert(itens.CamaraFissao.Metadados.ValorLimite==2)
grade:AtualizarDescricao("CamaraFissao", Ficha.Descrever(Catalogo.CamaraFissao, jogador), 5)
assert(itens.CamaraFissao.Metadados.ValorLimite==4)
grade:AtualizarDescricao("FornalhaBasica", Ficha.Descrever(Catalogo.FornalhaBasica), 5)
assert(not itens.FornalhaBasica.Metadados.TemLimite)
grade:AtualizarDescricao("PrensaTripla", Ficha.Descrever(Catalogo.PrensaTripla), 0)
assert(itens.PrensaTripla.Metadados.MultPrincipal==1.728 and #itens.PrensaTripla.Metadados.Multiplicadores==1)
grade:AtualizarDescricao("PortalDeVanAllen", Ficha.Descrever(Catalogo.PortalDeVanAllen), 0)
assert(itens.PortalDeVanAllen.Metadados.MultPrincipal==360)
grade._itemFoco,grade._dica="PrensaTripla",{}
itens.PrensaTripla.Botao={ObterInstancia=function() return {Visible=true} end}
grade:_AtualizarDica()
assert(grade._dica.Text:find("×1,73 •",1,true))
grade._filtroTamX,grade._filtroTamY,grade._filtroTamZ="","",""
grade._filtroMultExato,grade._filtroMultMin=true,"1,73"
assert(grade:_AtendeFiltrosAvancados(itens.PrensaTripla))
grade._filtroMultMin="1,728"
assert(grade:_AtendeFiltrosAvancados(itens.PrensaTripla))
grade._filtroMultMin="1,74"
assert(not grade:_AtendeFiltrosAvancados(itens.PrensaTripla))
print("GRADE_FICHA_OK: limite efetivo, fator com duas casas e filtro por valor exibido ou exato.")
