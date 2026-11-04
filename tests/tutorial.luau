local r=require("@lune/roblox")
local ui=require("./suporte/interface")
local carregar=require("./suporte/carregador")({
	Instance={new=ui.NovaInstancia},Enum=r.Enum,Color3=r.Color3,Vector2=r.Vector2,UDim=r.UDim,UDim2=r.UDim2,
},{})
local Tutorial=carregar("src/shared/Tutorial")
local palavras=0; for _,l in Tutorial.Licoes do for _,s in l.Secoes do for _ in s[2]:gmatch("%S+") do palavras+=1 end end end
assert(palavras<1600,"O guia deve permanecer curto.")
local atributos={Atalho_Q="K",Atalho_R="G"}
local jogador={GetAttribute=function(_,nome) return atributos[nome] end}
local ids,nivelAnterior={},1
for _,licao in Tutorial.Licoes do
	assert(not ids[licao.Id],"Capitulo repetido: "..licao.Id); ids[licao.Id]=licao
	local nivel=assert(table.find(Tutorial.Niveis,licao.Nivel))
	assert(nivel>=nivelAnterior,"A sequencia deve ir do basico ao avancado."); nivelAnterior=nivel
	assert(#licao.Titulo>0 and #licao.Resumo>0 and #licao.Secoes>=2)
	for _,s in licao.Secoes do
		assert(#s[1]>0 and #s[2]>0)
		assert(not Tutorial.Formatar(s[2],jogador):find("[{}]"),"Parametro nao resolvido: "..licao.Id)
	end
end
for _,id in {"inicio","primeira-fabrica","mineradoras","esteiras","fornalhas","modificadores","faixas-limites",
	"emissores","pc","mobile-controle","acoes","selecao-grupos","linhas","construcao-3d","blueprints",
	"upgrades","calibracao-expansao","renascimento","recompensas","configuracoes","classificacao-mapa","diagnostico"} do
	assert(ids[id],"Mecanica sem capitulo: "..id)
end
assert(Tutorial.Corresponde(ids["selecao-grupos"],"SELEÇÃO","Intermediário"))
assert(Tutorial.Corresponde(ids["selecao-grupos"],"selecao","Todos"))
assert(not Tutorial.Corresponde(ids["selecao-grupos"],"selecao","Básico"))
assert(not Tutorial.Corresponde(ids.inicio,".*","Todos"),"A busca deve ser literal.")
assert(Tutorial.Formatar("{Q} / {R} / {BLOCO} / {PLOT_INICIAL} / {PLOT_MAX} / {LIMITE_GRUPO} / {PASSO_UPGRADE} / {MAX_BONUS}",jogador)=="K / G / 3 / 12 / 32 / 1000 / 20 / 100")
assert(Tutorial.Formatar("{ATALHOS}",jogador):find("[K]  Cancelar / voltar",1,true))

local nav=carregar("src/client/NavegacaoEstados").new()
local painel=carregar("src/client/PainelTutorial").new(ui.NovaInstancia("ScreenGui"),jogador,nav)
local function botao(nome)
	for _,b in painel._botoes do if b:ObterInstancia().Name==nome then return b:ObterInstancia() end end
	error("Botao ausente: "..nome)
end
local function texto(nome)
	for _,o in painel._corpo:GetChildren() do if o.Name==nome and not o.destruido then return o end end
	error("Texto ausente: "..nome)
end
assert(painel._janela.Conteudo.AutomaticCanvasSize==r.Enum.AutomaticSize.Y)
assert(painel._corpo.AutomaticSize==r.Enum.AutomaticSize.Y)
for _,b in painel._capitulos do
	local o=b:ObterInstancia()
	assert(o.AutomaticSize==r.Enum.AutomaticSize.Y and o.Size.Y.Offset>=44 and o.Selectable,
		"Titulos devem crescer em telas estreitas e aceitar toque/controle.")
end
painel:Atualizar(); assert(not painel._grupo.Visible)
nav:Abrir("Tutorial"); painel:Atualizar(); assert(painel._grupo.Visible)
local primeiraPesquisa=painel._pesquisa
primeiraPesquisa.Text="SELEÇÃO"; primeiraPesquisa:GetPropertyChangedSignal("Text"):Fire()
assert(painel._pesquisa==primeiraPesquisa and botao("selecao-grupos").Visible and not botao("esteiras").Visible,
	"Pesquisar nao deve recriar o campo nem perder a digitacao.")
botao("Avançado").Activated:Fire()
for i,b in painel._capitulos do if b:ObterInstancia().Visible then assert(Tutorial.Licoes[i].Nivel=="Avançado") end end
botao("Intermediário").Activated:Fire()
botao("selecao-grupos").Activated:Fire()
assert(Tutorial.Licoes[painel._atual].Id=="selecao-grupos")
assert(texto("Explicacao2").Text:find("1000",1,true) and texto("Explicacao2").AutomaticSize==r.Enum.AutomaticSize.Y)
local antigo=botao("Indice")
botao("Proximo").Activated:Fire()
assert(Tutorial.Licoes[painel._atual].Id=="linhas" and antigo.destruido)
botao("Anterior").Activated:Fire(); botao("Indice").Activated:Fire()
assert(painel._nivel=="Intermediário" and painel._pesquisa.Text=="SELEÇÃO")
painel._pesquisa.Text="xyz-sem-resultado"; painel._pesquisa:GetPropertyChangedSignal("Text"):Fire()
assert(painel._resultado.Text:find("Nenhum capítulo",1,true))
painel:_Abrir(1); assert(not botao("Anterior").Active)
painel:_Abrir(#Tutorial.Licoes); assert(not botao("Proximo").Active)
local ultimo=painel._atual; botao("Proximo").Activated:Fire(); assert(painel._atual==ultimo)
for i,licao in Tutorial.Licoes do
	painel:_Abrir(i)
	assert(texto("Tema").Text==licao.Titulo)
	for s in licao.Secoes do assert(texto("Explicacao"..s).AutomaticSize==r.Enum.AutomaticSize.Y) end
end
for i,licao in Tutorial.Licoes do if licao.Id=="pc" then painel:_Abrir(i); break end end
assert(texto("Explicacao1").Text:find("[K]",1,true))
local corpoAntes=texto("Explicacao1")
painel:Atualizar(); assert(texto("Explicacao1")==corpoAntes,"Atualizacoes de inventario nao devem reconstruir o guia aberto.")
nav:Fechar("Tutorial"); painel:Atualizar(); atributos.Atalho_Q="J"
nav:Abrir("Tutorial"); painel:Atualizar(); assert(texto("Explicacao1").Text:find("[J]",1,true))
painel._janela._fechar:ObterInstancia().Activated:Fire(); painel:Atualizar(); assert(not painel._grupo.Visible)
painel:_Indice()
local conexaoBusca=painel._conexoes[1]
local botoes=table.clone(painel._botoes)
painel:Destruir(); painel:Destruir(); nav:Destruir()
assert(not conexaoBusca.ativa and painel._grupo.destruido)
for _,b in botoes do assert(b._destruido and not b._conexao.ativa) end
print("TUTORIAL_OK: "..#Tutorial.Licoes.." capitulos, busca literal sem acentos, niveis, sequencia, teclas atuais, rolagem e limpeza; GUI simulada.")
