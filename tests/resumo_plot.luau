local r=require("@lune/roblox")
local serde=require("@lune/serde")
local ui=require("./suporte/interface")
local carregar=require("./suporte/carregador")({},{})
local Dados=carregar("src/server/Data/DadosJogador")
local Catalogo=carregar("src/shared/CatalogoMaquinas")
local template=carregar("src/server/Data/Template")
local data=serde.decode("json",serde.encode("json",template))
data.Dinheiro="100000"
data.Inventory.Esteira2x2=30
data.MaquinasColocadas={{MaquinaId="MineradoraBasica"},{MaquinaId="Esteira2x2"}}
local perfil={Data=data,IsActive=function() return true end}
local atributos,publicacoes={},0
local jogador={Name="Teste",UserId=123}
function jogador:SetAttribute(id,v) atributos[id]=v; if id=="PecasNaPlot" then publicacoes+=1 end end
function jogador:GetAttribute(id) return atributos[id] end
local dados=Dados.new(jogador,perfil)
local function resumo() return serde.decode("json",assert(atributos.PecasNaPlot)) end
dados:Sincronizar()
assert(resumo().MineradoraBasica==1 and resumo().Esteira2x2==1)
local lote={}; for _=1,20 do table.insert(lote,{MaquinaId="Esteira2x2"}) end
local antes=publicacoes
assert(dados:RegistrarColocacoes(lote))
assert(publicacoes==antes+1 and resumo().Esteira2x2==21,"Um lote deve publicar uma unica contagem final.")
assert(dados:RegistrarRecolhimentos({{Registro=lote[1],Modificacoes={}},{Registro=lote[2],Modificacoes={}}}))
assert(resumo().Esteira2x2==19)
assert(dados:RegistrarRecolhimento(lote[3])); assert(resumo().Esteira2x2==18)
assert(dados:VenderConstrucoes({lote[4],lote[5]})); assert(resumo().Esteira2x2==16)
local original=dados.RegistrarColocacao
local tentativas=0
dados.RegistrarColocacao=function(self,...)
	tentativas+=1; if tentativas==2 then error("Falha simulada") end
	return original(self,...)
end
assert(not dados:RegistrarColocacoes({{MaquinaId="Esteira2x2"},{MaquinaId="Esteira2x2"}}))
assert(resumo().Esteira2x2==16,"Falha no lote deve restaurar tambem a contagem exibida.")
dados.RegistrarColocacao=original
antes=publicacoes
assert(dados:AdicionarDinheiro("10")); assert(publicacoes==antes,"Vender minerio nao deve recontar a plot.")
perfil.Data.Dinheiro="1"..string.rep("0",21)
assert(dados:Reencarnar(0)); dados:Sincronizar()
assert(next(resumo())==nil,"Renascimento deve publicar a plot vazia.")
print("RESUMO_PLOT_SERVIDOR_OK: carga, lote unico, recolhimentos, venda, rollback, renda sem recontagem e renascimento.")
do
	local perfilNovo={Data=serde.decode("json",serde.encode("json",template)),IsActive=function() return true end}
	perfilNovo.Data.Dinheiro="500"
	local d=Dados.new(jogador,perfilNovo); d:Sincronizar()
	assert(atributos.DinheiroRecebido=="0")
	assert(d:AdicionarDinheiro("50") and d:ComprarMaquina("Esteira2x2"))
	assert(d:VenderMaquina("Esteira2x2",atributos.ConfiguracaoInventario_Esteira2x2))
	assert(atributos.DinheiroRecebido=="0","Recebimentos são agrupados, sem replicar cada venda.")
	d:PublicarRecebimentos(); assert(atributos.DinheiroRecebido=="75","Comprar no mesmo intervalo não reduz o valor recebido.")
	perfilNovo.Data.Dinheiro="999999"; d:Sincronizar()
	assert(atributos.DinheiroRecebido=="75","Edição administrativa não é uma venda.")
	local devolucoes={}
	for i=1,1001 do
		local registro={MaquinaId="Esteira2x2"}; perfilNovo.Data.MaquinasColocadas[i]=registro
		devolucoes[i]={Registro=registro,Modificacoes={}}
	end
	local estoque=perfilNovo.Data.Inventory.Esteira2x2
	assert(not d:RegistrarRecolhimentos(devolucoes) and #perfilNovo.Data.MaquinasColocadas==1001)
	assert(d:RegistrarRecolhimentos(devolucoes,true))
	assert(#perfilNovo.Data.MaquinasColocadas==0 and perfilNovo.Data.Inventory.Esteira2x2==estoque+1001)
end
print("LIMPEZA_RECEBIMENTOS_OK: 1001 peças, limite da seleção preservado, crédito real agrupado e edição sem animação falsa.")

local atributosUI={PecasNaPlot='{"MineradoraBasica":2,"Esteira2x2":3}',Dinheiro="10000"}
for id in Catalogo do atributosUI["Inventario_"..id]=0 end
atributosUI.Inventario_Esteira2x2=4
local replicado={WaitForChild=function() return {WaitForChild=function(_,id) return {Name=id} end} end}
local inputUI={TouchEnabled=false,KeyboardEnabled=true}
local carregarUI,no=require("./suporte/carregador")({Instance={new=ui.NovaInstancia},Enum=r.Enum,Vector2=r.Vector2,
	UDim=r.UDim,UDim2=r.UDim2,Color3=r.Color3,ColorSequence=r.ColorSequence,ColorSequenceKeypoint=r.ColorSequenceKeypoint},
	{ReplicatedStorage=replicado,UserInputService=inputUI},{["src/client/MiniaturaPeca"]={new=function() return {Destruir=function() end} end}})
replicado.Shared=no("src/shared")
local nav=carregarUI("src/client/NavegacaoEstados").new()
local selecoes,selecionadas={},{}
local construcao={Navegacao=nav}
local painel
function construcao:ObterSelecao(aba) return selecoes[aba] end
function construcao:ObterDefinicaoSelecionada(aba) return Catalogo[selecoes[aba].MaquinaId] end
function construcao:SelecionarMaquina(id,aba)
	table.insert(selecionadas,{id,aba}); selecoes[aba]={Id=#selecionadas,MaquinaId=id}
	if not nav:Contem("Ficha"..aba) then nav:Abrir("Ficha"..aba) end
	painel:Atualizar(); return true
end
function construcao:ColocarSelecionada() error("Consultar o resumo nao deve colocar pecas.") end
function construcao:FecharFicha(aba) nav:Fechar("Ficha"..aba) end
function construcao:AlternarAba(aba) nav:Fechar(aba) end
local p={GetAttribute=function(_,id) return atributosUI[id] end}
local pai=ui.NovaInstancia("ScreenGui"); pai.AbsoluteSize=r.Vector2.new(1280,720)
nav:Abrir("Inventario")
painel=carregarUI("src/client/PainelPecas").new(pai,"Inventario",p,construcao,{fetch=function() error("Sem compras na consulta.") end},68)
local grade=painel._grade
assert(grade._itens.Esteira2x2.Botao:ObterInstancia().Visible and not grade._itens.MineradoraBasica.Botao:ObterInstancia().Visible)
grade._modos.Plot:ObterInstancia().Activated:Fire()
assert(grade._layout.FillDirectionMaxCells==1 and grade._itens.MineradoraBasica.Botao:ObterInstancia().Visible)
assert(not grade._itens.PrensaMinerio.Botao:ObterInstancia().Visible)
local detalhe=grade._itens.MineradoraBasica.Detalhes
assert(detalhe.Text:find("Na plot: 2",1,true) and detalhe.Text:find("Inventário: 0",1,true) and detalhe.Text:find("$100",1,true))
grade._conteudo.AbsoluteSize=r.Vector2.new(480,400); grade:_DimensionarGrade()
assert(grade._itens.MineradoraBasica.Retrato.Visible and grade._layout.CellSize.X.Offset==480)
grade._conteudo.AbsoluteSize=r.Vector2.new(150,400); grade:_DimensionarGrade()
assert(not grade._itens.MineradoraBasica.Retrato.Visible and detalhe.Visible and detalhe.TextWrapped)
grade._modos.Novas:ObterInstancia().Activated:Fire()
assert(grade._itens.PrensaMinerio.Botao:ObterInstancia().Visible and not grade._itens.MineradoraBasica.Botao:ObterInstancia().Visible)
atributosUI.Dinheiro="9999"; painel:Atualizar()
assert(not grade._itens.PrensaMinerio.Botao:ObterInstancia().Visible)
atributosUI.Inventario_PrensaMinerio=1; painel:Atualizar()
assert(grade._itens.PrensaMinerio.Botao:ObterInstancia().Visible,"Estoque permite usar uma peça mesmo sem saldo.")
atributosUI.Dinheiro="10000"; atributosUI.Inventario_PrensaMinerio=0; painel:Atualizar()
grade._itens.PrensaMinerio.Botao:ObterInstancia().Activated:Fire()
assert(selecionadas[#selecionadas][1]=="PrensaMinerio" and selecionadas[#selecionadas][2]=="Loja","Sem estoque, abrir o fluxo de compra existente.")
local renascimento
for id,item in Catalogo do if item.Renascimento then renascimento=id; break end end
assert(grade._itens[renascimento].Detalhes.Text:find("Recompensa de renascimento",1,true))
assert(not grade._itens[renascimento].Botao:ObterInstancia().Visible,"Sem estoque, recompensas não estão disponíveis para compra.")
atributosUI["Inventario_"..renascimento]=1; painel:Atualizar()
grade._itens[renascimento].Botao:ObterInstancia().Activated:Fire()
assert(selecionadas[#selecionadas][2]=="Inventario" and painel._acoes.Colocar:ObterInstancia().Active)
assert(painel._textoQuantidade.Text:find("Na plot: 0",1,true))
atributosUI.PecasNaPlot='{"PrensaMinerio":1}'
painel:Atualizar()
assert(not grade._itens.PrensaMinerio.Botao:ObterInstancia().Visible and grade._itens.MineradoraBasica.Botao:ObterInstancia().Visible)
grade._busca.Text="MINERADORA BÁSICA"; grade._busca:GetPropertyChangedSignal("Text"):Fire()
assert(grade._itens.MineradoraBasica.Botao:ObterInstancia().Visible and not grade._itens.Esteira2x2.Botao:ObterInstancia().Visible)
atributosUI.PecasNaPlot="invalido"; painel:Atualizar()
assert(grade._vazio.Visible and grade._vazio.Text:find("Carregando",1,true))
grade._modos.Estoque:ObterInstancia().Activated:Fire()
grade._busca.Text=""; grade._busca:GetPropertyChangedSignal("Text"):Fire()
assert(grade._itens.Esteira2x2.Quantidade.Visible and not grade._itens.Esteira2x2.Detalhes.Visible)
local botoes=table.clone(grade._botoes)
inputUI.TouchEnabled,inputUI.KeyboardEnabled=true,false
pai.AbsoluteSize=r.Vector2.new(2400,1080); painel:Atualizar()
assert(painel._grupo.Size.X.Scale*2400+painel._grupo.Size.X.Offset==440)
assert(painel._grupo.Size.Y.Scale*1080+painel._grupo.Size.Y.Offset==420 and grade._compacta)
painel:Destruir(); painel:Destruir(); nav:Destruir()
for _,b in botoes do assert(b._destruido and not b._conexao.ativa) end
print("RESUMO_PLOT_UI_OK: estoque/colocadas/nao usadas, precos, compra explicita, renascimento, busca, atualizacao, tela estreita e limpeza; GUI simulada.")
