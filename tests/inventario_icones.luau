local roblox = require("./suporte/modelos")
local suporte = require("./suporte/interface")
local modelos = roblox.Instance.new("Folder")
require("./suporte/catalogo_modelos")(modelos)

-- Miniaturas reais, fora do Studio: clone, camera, enquadramento e remocao de scripts.
local env = {
	Instance=roblox.Instance, Vector2=roblox.Vector2, Vector3=roblox.Vector3, CFrame=roblox.CFrame,
	UDim=roblox.UDim, UDim2=roblox.UDim2, Color3=roblox.Color3, Enum=roblox.Enum,
	ColorSequence=roblox.ColorSequence, ColorSequenceKeypoint=roblox.ColorSequenceKeypoint,
}
local alvoCamera
-- O lookAt do Lune instalado gera uma base incorreta; aqui conferimos seus argumentos e o enquadramento.
local ambienteMiniatura=table.clone(env)
ambienteMiniatura.CFrame={ lookAt=function(posicao,alvo)
	alvoCamera=alvo
	return roblox.CFrame.new(posicao)
end }
local carregarMiniatura = require("./suporte/carregador")(ambienteMiniatura,{},{})
local Miniatura=carregarMiniatura("src/client/MiniaturaPeca")
local original=modelos:FindFirstChild("MineradoraBasica")
local scriptTeste=roblox.Instance.new("Script")
scriptTeste.Name,scriptTeste.Parent="NaoExecutar",original
for _, modelo in modelos:GetChildren() do
	local pai=roblox.Instance.new("Frame")
	local m=Miniatura.new(pai,modelo)
	local v=m._viewport
	local clone=v:FindFirstChildOfClass("WorldModel"):FindFirstChildOfClass("Model")
	assert(clone and clone~=modelo and modelo.Parent==modelos)
	for _, objeto in clone:GetDescendants() do
		assert(not objeto:IsA("LuaSourceContainer"))
		if objeto:IsA("BasePart") then assert(objeto.Anchored and not objeto.CanCollide and not objeto.CanQuery) end
	end
	local caixa,tamanho=clone:GetBoundingBox()
	local camera=v:FindFirstChildOfClass("Camera")
	local distancia=(camera.CFrame.Position-caixa.Position).Magnitude
	assert(distancia*math.sin(math.rad(camera.FieldOfView/2)) > tamanho.Magnitude/2)
	assert((alvoCamera-caixa.Position).Magnitude<1e-5)
	m:Destruir(); m:Destruir(); pai:Destroy()
end
assert(original:FindFirstChild("NaoExecutar"), "A limpeza nao deve modificar o modelo original.")
scriptTeste:Destroy()

-- A ficha pode aplicar a aparencia da unidade ao clone; nunca altera o original nem deixa um viewport
-- abandonado quando uma personalizacao aponta para uma parte inexistente.
local PersonalizacaoReal=carregarMiniatura("src/shared/PersonalizacaoMaquina")
local esteiraOriginal=modelos:FindFirstChild("Esteira2x2")
local corOriginal=esteiraOriginal.Correia.Color
local holder=roblox.Instance.new("Frame")
local varianteVisual=PersonalizacaoReal.new({Partes={{Caminho={{Nome="Correia",Indice=1}},Cor={0.9,0.1,0.2}}}})
local miniaturaVariante=Miniatura.new(holder,esteiraOriginal,varianteVisual)
local cloneVariante=miniaturaVariante._viewport:FindFirstChildOfClass("WorldModel"):FindFirstChildOfClass("Model")
assert((cloneVariante.Correia.Color.R-0.9)^2<1e-8 and esteiraOriginal.Correia.Color==corOriginal)
miniaturaVariante:Destruir()
assert(not pcall(function()
	Miniatura.new(holder,esteiraOriginal,PersonalizacaoReal.new({Partes={{Caminho={{Nome="NaoExiste",Indice=1}}}}}))
end))
assert(#holder:GetChildren()==0, "Uma miniatura invalida deve liberar seu viewport e clone.")
holder:Destroy()

-- O restante exercita painel/grade reais com GUI e rede isoladas, sem abrir um perfil.
local miniaturas={}
local replicado={ ModelosMaquinas=modelos }
function replicado:WaitForChild(nome) return assert(self[nome]) end
local ambiente=table.clone(env)
ambiente.Instance={ new=suporte.NovaInstancia }
local carregar,no=require("./suporte/carregador")(ambiente,{ ReplicatedStorage=replicado },{
	["src/client/MiniaturaPeca"]={ new=function(_, modelo)
		local m={ Nome=modelo.Name, Destruir=function(self) self.destruido=true end }
		table.insert(miniaturas,m)
		return m
	end },
})
replicado.Shared=no("src/shared")
local Painel=carregar("src/client/PainelPecas")
local Catalogo=carregar("src/shared/CatalogoMaquinas")
local nav=carregar("src/client/NavegacaoEstados").new()
local estoque={ MineradoraBasica=3, Esteira2x2=5, FornalhaBasica=1, PrensaMinerio=0 }
for id in Catalogo do if estoque[id] == nil then estoque[id] = 0 end end
local jogador={ GetAttribute=function(_, nome) return estoque[nome:match("^Inventario_(.+)$")] end }
local paineis,selecoes,sequencia={}, {},0
local construcao={ Navegacao=nav }
function construcao:ObterSelecao(aba) return selecoes[aba] end
function construcao:ObterDefinicaoSelecionada(aba) return Catalogo[selecoes[aba].MaquinaId] end
function construcao:SelecionarMaquina(id,aba)
	if not selecoes[aba] or selecoes[aba].MaquinaId~=id then
		sequencia+=1; selecoes[aba]={Id=sequencia,MaquinaId=id}
	end
	if not nav:Contem("Ficha"..aba) then nav:Abrir("Ficha"..aba) end
	paineis[aba]:Atualizar()
	return true
end
function construcao:FecharFicha(aba) nav:Fechar("Ficha"..aba); paineis[aba]:Atualizar() end
function construcao:AlternarAba(aba) nav:Fechar(aba); paineis[aba]:Atualizar() end
local colocou
function construcao:ColocarSelecionada(aba,fechar)
	colocou={aba,fechar}; nav:Limpar()
	for _, p in paineis do p:Atualizar() end
end
local pedidos={}
local rede={fetch=function(_,acao,id)
	assert(acao=="Comprar", "Este teste so solicita a compra pela ficha da loja.")
	table.insert(pedidos,id)
	estoque[id]+=1
	return true,"Compra confirmada."
end}
nav:Abrir("Inventario"); nav:Abrir("Loja")
local pai=suporte.NovaInstancia("ScreenGui")
pai.AbsoluteSize=roblox.Vector2.new(1280,720)
paineis.Inventario=Painel.new(pai,"Inventario",jogador,construcao,rede,68)
paineis.Loja=Painel.new(pai,"Loja",jogador,construcao,rede,68)
local p,loja=paineis.Inventario,paineis.Loja
local g=p._grade
local gl=loja._grade
local totalCatalogo=0
for _,item in Catalogo do if not item.Renascimento then totalCatalogo+=1 end end

assert(g and gl and #miniaturas==totalCatalogo+3)
assert(not g._itens.PrensaMinerio.Miniatura, "Uma peca sem estoque nao deve clonar uma miniatura.")
assert(p._painelLista.AnchorPoint.X==0 and loja._painelLista.AnchorPoint.X==1)
assert(g._layout.FillDirectionMaxCells==4 and g._layout.CellSize.X.Offset==58)
assert(p._grupo.Position.X.Offset==84 and loja._grupo.Position.X.Offset==-16)
assert(g._itens.MineradoraBasica.Quantidade.Text=="x3")
assert(not p._botoesPecas.PrensaMinerio:ObterInstancia().Visible)
assert(loja._botoesPecas.MineradoraBasica:ObterInstancia().Text=="")
assert(gl._itens.MineradoraBasica.Quantidade.Text=="$100")
assert(gl._itens.PrensaMinerio.Quantidade.Text=="$10K")
assert(loja._botoesPecas.PrensaMinerio:ObterInstancia().Visible, "A loja inclui pecas sem estoque.")
for id, item in Catalogo do
	if item.Preco == "25" then
		assert(loja._botoesPecas[id]:ObterInstancia().LayoutOrder < loja._botoesPecas.JatoMineral:ObterInstancia().LayoutOrder,
			"Pecas de $25 devem preceder o jato de $50, inclusive quando empatam entre si.")
	end
end

-- A ultima categoria inclui utilidades e exclui as tres familias de maquinas, mesmo com correia.
local function categoria(id) gl._categorias[id].Botao:ObterInstancia().Activated:Fire() end
categoria("Soltador")
assert(loja._botoesPecas.MineradoraBasica:ObterInstancia().Visible)
assert(not loja._botoesPecas.FornalhaBasica:ObterInstancia().Visible)
categoria("Vendedor")
assert(loja._botoesPecas.FornalhaBasica:ObterInstancia().Visible)
assert(not loja._botoesPecas.MineradoraBasica:ObterInstancia().Visible)
categoria("Modificador")
assert(loja._botoesPecas.PrensaMinerio:ObterInstancia().Visible)
assert(loja._botoesPecas.JatoMineral:ObterInstancia().Visible and loja._botoesPecas.NucleoDimensional:ObterInstancia().Visible)
categoria("Transportador")
for _, id in { "JatoMineral", "LaserIndustrial", "FornalhaBasica", "PrensaMinerio", "MineradoraBasica" } do
	assert(not loja._botoesPecas[id]:ObterInstancia().Visible)
end
for _, id in { "Esteira2x2", "Esteira1x1", "Centralizadora2x2", "Centralizadora1x1", "Parede1x1" } do
	assert(loja._botoesPecas[id]:ObterInstancia().Visible)
end
assert(gl._categorias.Soltador.Botao:ObterInstancia().Position.X.Scale<gl._categorias.Modificador.Botao:ObterInstancia().Position.X.Scale)
assert(gl._categorias.Modificador.Botao:ObterInstancia().Position.X.Scale<gl._categorias.Vendedor.Botao:ObterInstancia().Position.X.Scale)
assert(gl._categorias.Vendedor.Botao:ObterInstancia().Position.X.Scale<gl._categorias.Transportador.Botao:ObterInstancia().Position.X.Scale)
categoria("Todos")
assert(loja._botoesPecas.Parede1x1:ObterInstancia().Visible)
gl._busca.Text="fornalha"; gl._busca:GetPropertyChangedSignal("Text"):Fire()
categoria("Transportador")
assert(not loja._botoesPecas.FornalhaBasica:ObterInstancia().Visible and gl._vazio.Visible)
assert(not loja._botoesPecas.Esteira2x2:ObterInstancia().Visible, "Busca e categoria devem ser combinadas.")
gl._busca.Text="sem resultado"; gl._busca:GetPropertyChangedSignal("Text"):Fire()
assert(gl._vazio.Visible and gl._vazio.Text=="Nenhuma peça encontrada.")
gl._busca.Text=""; gl._busca:GetPropertyChangedSignal("Text"):Fire()
categoria("Todos")
local bc=gl._categorias.Modificador.Botao:ObterInstancia()
bc.SelectionGained:Fire(); assert(gl._dica.Text=="Modificadores")
bc.SelectionLost:Fire()
gl._conteudo.AbsoluteSize=roblox.Vector2.new(310,400)
gl:_DimensionarGrade(); assert(gl._layout.FillDirectionMaxCells==5)
gl._conteudo.AbsoluteSize=roblox.Vector2.new(110,400)
gl:_DimensionarGrade(); assert(gl._layout.FillDirectionMaxCells==1 and gl._layout.CellSize.X.Offset>0)
assert(#pedidos==0, "Filtros e navegacao nao compram pecas.")
assert(not p._botoesPecas.PrensaMinerio:ObterInstancia().Visible, "Os filtros da loja nao alteram o inventario.")

local function buscar(valor)
	g._busca.Text=valor; g._busca:GetPropertyChangedSignal("Text"):Fire()
end
buscar("MINERADORA BÁSICA")
assert(p._botoesPecas.MineradoraBasica:ObterInstancia().Visible)
assert(not p._botoesPecas.Esteira2x2:ObterInstancia().Visible)
buscar("[nao e padrao]")
assert(g._vazio.Visible and g._vazio.Text=="Nenhuma peça encontrada.")
buscar("")
g._ordenar:ObterInstancia().Activated:Fire()
assert(p._botoesPecas.Esteira2x2:ObterInstancia().LayoutOrder==1)
g._conteudo.AbsoluteSize=roblox.Vector2.new(190,400)
g._conteudo:GetPropertyChangedSignal("AbsoluteSize"):Fire()
assert(g._layout.FillDirectionMaxCells==3 and g._layout.CellSize.X.Offset==58)
g._layout.AbsoluteContentSize=roblox.Vector2.new(190,256)
g._layout:GetPropertyChangedSignal("AbsoluteContentSize"):Fire()
assert(g._area.CanvasSize.Y.Offset==268)

local b=p._botoesPecas.MineradoraBasica:ObterInstancia()
b.MouseEnter:Fire(); assert(g._dica.Text==Catalogo.MineradoraBasica.Nome)
b.MouseLeave:Fire()
b.Activated:Fire()
assert(p._painelFicha.Visible and p._fichaValida and selecoes.Inventario.MaquinaId=="MineradoraBasica")
assert(p._ficha and loja._ficha and p._ficha~=loja._ficha)
assert(p._ficha._nome.Text==Catalogo.MineradoraBasica.Nome)
assert(p._ficha._raridade.Text=="Comum" and p._ficha._quantidade.Text=="x3")
assert(p._textoFicha.Text:find("Minério: $5",1,true))
assert(not p._textoFicha.Text:find(Catalogo.MineradoraBasica.Nome,1,true), "O nome ja aparece acima das estatisticas.")
assert(p._acoes.Colocar:ObterInstancia().Parent.Name=="Acoes", "As acoes ficam fora da area rolavel.")
assert(g._itens.MineradoraBasica.Borda.Thickness==2)
g._ordenar:ObterInstancia().Activated:Fire()
b.Activated:Fire()
assert(not colocou, "Ordenar entre cliques nao deve produzir um clique duplo.")
buscar("mineradora")
b.Activated:Fire()
assert(not colocou, "Pesquisar entre cliques nao deve produzir um clique duplo.")
b.Activated:Fire()
assert(colocou and colocou[1]=="Inventario" and colocou[2]==true)
assert(not p._painelLista.Visible and not loja._painelLista.Visible)
nav:Abrir("Inventario"); p:Atualizar()
buscar("")
p._negociando="Vender"; p:Atualizar(); assert(not b.Active)
p._negociando=nil
estoque.MineradoraBasica=nil; p:Atualizar(); assert(not b.Active and g._itens.MineradoraBasica.Quantidade.Text=="...")
estoque.MineradoraBasica="3"; p:Atualizar(); assert(not b.Active and g._itens.MineradoraBasica.Quantidade.Text=="!")
for id in estoque do estoque[id]=0 end
p:Atualizar(); assert(g._vazio.Visible and g._vazio.Text:find("vazio"))
assert(#miniaturas==totalCatalogo+4, "Atualizar estoque, busca e ordem preserva as miniaturas da grade e o retrato selecionado.")
g._fechar:ObterInstancia().Activated:Fire(); assert(not p._painelLista.Visible)

-- Clique simples abre a ficha. Trocar categoria ou busca invalida o clique duplo; Comprar continua
-- enviando apenas o pedido ao servidor. A colocacao pelo clique duplo preserva o fluxo normal da loja.
colocou=nil
nav:Abrir("Loja"); loja:Atualizar()
local bm=loja._botoesPecas.MineradoraBasica:ObterInstancia()
bm.Activated:Fire()
assert(loja._painelFicha.Visible and loja._fichaValida and #pedidos==0)
assert(loja._ficha._quantidade.Text=="$100" and loja._ficha._nome.Text==Catalogo.MineradoraBasica.Nome)
assert(loja._acoes.Comprar:ObterInstancia().Parent.Name=="Acoes")
assert(not loja._textoFicha.Text:find(Catalogo.MineradoraBasica.Nome,1,true))
assert(gl._itens.MineradoraBasica.Borda:FindFirstChild("Raridade").Color==loja._ficha._faixaRaridade.Color,"Selecionar preserva a raridade na borda.")
categoria("Soltador"); bm.Activated:Fire(); assert(not colocou)
gl._busca.Text="MINERADORA BÁSICA"; gl._busca:GetPropertyChangedSignal("Text"):Fire()
bm.Activated:Fire(); assert(not colocou)
loja._acoes.Comprar:ObterInstancia().Activated:Fire()
assert(#pedidos==1 and pedidos[1]=="MineradoraBasica" and loja._textoResposta.Text=="Compra confirmada.")
bm.Activated:Fire(); bm.Activated:Fire()
assert(colocou and colocou[1]=="Loja" and colocou[2]==true and not loja._painelLista.Visible)

-- A ordem conserva cada digito; o cartao abrevia o preco para caber na miniatura.
local precoAnterior=Catalogo.MineradoraBasica.Preco
local precoEsteira=Catalogo.Esteira2x2.Preco
Catalogo.MineradoraBasica.Preco="100000000000000000000000000000000000001"
Catalogo.Esteira2x2.Preco="100000000000000000000000000000000000000"
gl._busca.Text=""; categoria("Todos"); loja:Atualizar()
assert(gl._itens.MineradoraBasica.Quantidade.Text=="$100UDe")
assert(bm.LayoutOrder==totalCatalogo)
assert(loja._botoesPecas.Esteira2x2:ObterInstancia().LayoutOrder==totalCatalogo-1, "Precos grandes com um digito de diferenca mantem a ordem exata.")
nav:Abrir("Loja"); loja:Selecionar("NucleoDimensional")
assert(gl._itens.NucleoDimensional.Quantidade.Text=="$250De")
assert(loja._ficha._quantidade.Text=="$250De" and loja._acoes.Comprar:ObterInstancia().Text=="Comprar: $250De")
nav:Abrir("Inventario"); estoque.MineradoraBasica=1234567; p:Selecionar("MineradoraBasica")
assert(g._itens.MineradoraBasica.Quantidade.Text=="x1,23M" and p._ficha._quantidade.Text=="x1,23M")
assert(p._acoes.Vender:ObterInstancia().Text=="Vender: $100UDe (100%)")
Catalogo.MineradoraBasica.Preco=precoAnterior
Catalogo.Esteira2x2.Preco=precoEsteira
p:Destruir(); p:Destruir(); loja:Destruir()
for _, m in miniaturas do assert(m.destruido) end
for _, c in g._conexoes do assert(not c.ativa) end
for _, c in gl._conexoes do assert(not c.ativa) end
for _, c in gl._botoes do assert(c._destruido and not c._conexao.ativa) end
nav:Destruir(); pai:Destroy(); modelos:Destroy()
print("PASS: miniaturas, grade compartilhada, busca, categorias, precos exatos, ficha/compra, clique duplo e limpeza.")
