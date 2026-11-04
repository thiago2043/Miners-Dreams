-- Exercita a ficha real com eventos/GUI simulados; a aparencia em pixels exige a previa no editor.
local roblox=require("@lune/roblox")
local suporte=require("./suporte/interface")
local miniaturas={}
local carregar=require("./suporte/carregador")({
	Instance={new=suporte.NovaInstancia}, Enum=roblox.Enum, Color3=roblox.Color3,
	Vector2=roblox.Vector2, UDim=roblox.UDim, UDim2=roblox.UDim2, ColorSequence=roblox.ColorSequence,
},{},{
	["src/client/MiniaturaPeca"]={new=function(_,modelo,personalizacao)
		local m={Nome=modelo.Name, Dados=personalizacao:ObterDados()}
		function m:Destruir() self.destruido=true end
		table.insert(miniaturas,m)
		return m
	end},
})
local Ficha=carregar("src/client/FichaPeca")
local Catalogo=carregar("src/shared/CatalogoMaquinas")
local pai=suporte.NovaInstancia("Frame")
local acoes,fechou={},false
local ficha=Ficha.new(pai,{WaitForChild=function(_,id) return {Name=id} end},
	function(acao) table.insert(acoes,acao) end, function() fechou=true end)
local campos=ficha:ObterCampos()
assert(ficha._conteudo.Position.Y.Offset==4, "A borda superior do retrato precisa ficar dentro da area rolavel.")
assert(ficha:ObterInstancia().AnchorPoint.X==1)
assert(campos.Acoes.Colocar and campos.Acoes.Vender and not campos.Acoes.Comprar)
assert(campos.Acoes.Colocar:ObterInstancia().Parent.Parent==ficha:ObterInstancia())

-- Nao cria retratos enquanto a ficha esta fechada. Repetir estado/quantidade conserva o mesmo clone.
ficha:ObterInstancia().Visible=false
assert(ficha:Atualizar("MineradoraBasica","Mineradora básica",3,false,Catalogo.MineradoraBasica,nil))
assert(#miniaturas==0)
ficha:ObterInstancia().Visible=true
assert(ficha:Atualizar("MineradoraBasica","Mineradora básica",3,false,Catalogo.MineradoraBasica,nil))
assert(#miniaturas==1 and ficha._quantidade.Text=="x3" and ficha._raridade.Text=="Comum")
ficha:Atualizar("MineradoraBasica","Mineradora básica",2,false,Catalogo.MineradoraBasica,nil)
assert(#miniaturas==1 and ficha._quantidade.Text=="x2")

-- Uma troca de unidade ou personalizacao substitui somente o retrato. A copia conserva seus metadados.
local dados={Configuracao={Componentes={{Velocidade=17}}},Dados={Melhoria=3}}
assert(ficha:Atualizar("Esteira2x2","Esteira básica",1,true,Catalogo.Esteira2x2,dados))
assert(#miniaturas==2 and miniaturas[1].destruido and miniaturas[2].Dados.Dados.Melhoria==3)
assert(ficha._nome.Text=="Esteira básica (cópia)" and ficha._raridade.Text=="Comum")
ficha:Atualizar("Esteira2x2","Esteira básica",1,true,Catalogo.Esteira2x2,dados)
assert(#miniaturas==2)
local novaChave='{"Dados":{"Melhoria":4}}'
assert(ficha:Atualizar("Esteira2x2","Esteira básica",1,false,Catalogo.Esteira2x2,novaChave))
assert(#miniaturas==3 and miniaturas[2].destruido and miniaturas[3].Dados.Dados.Melhoria==4)

-- Dados malformados ficam explicitos; uma selecao nova valida se recupera, sem reutilizar o modelo anterior.
assert(not ficha:Atualizar("Esteira2x2","Esteira básica",1,false,Catalogo.Esteira2x2,"json invalido"))
assert(ficha._erroRetrato.Visible and miniaturas[3].destruido)
assert(ficha:Atualizar("FornalhaBasica","Fornalha básica",1,false,Catalogo.FornalhaBasica,nil))
assert(ficha._raridade.Text=="Comum" and not ficha._erroRetrato.Visible)
ficha:Atualizar("FornalhaBasica","Fornalha básica",nil,false,nil,nil)
assert(ficha._miniatura==nil and ficha._erroRetrato.Visible and ficha._quantidade.Text=="…")

-- A janela curta da captura tem uma ficha de cerca de 315px: o retrato encolhe e as acoes dividem
-- a mesma linha, liberando a area rolavel para as estatisticas.
ficha:ObterInstancia().AbsoluteSize=roblox.Vector2.new(280,315)
ficha:ObterInstancia():GetPropertyChangedSignal("AbsoluteSize"):Fire()
assert(ficha._retrato.Size.X.Offset==63 and ficha._retrato.Size.Y.Offset==63)
local colocar=campos.Acoes.Colocar:ObterInstancia()
local vender=campos.Acoes.Vender:ObterInstancia()
assert(colocar.Position.Y.Offset==0 and vender.Position.Y.Offset==0)
assert(colocar.Size.Y.Offset==32 and vender.Size.Y.Offset==32 and vender.Position.X.Scale==0.5)
assert(ficha._rolagem.Size.Y.Offset==-84)
ficha:ObterInstancia().AbsoluteSize=roblox.Vector2.new(280,520)
ficha:ObterInstancia():GetPropertyChangedSignal("AbsoluteSize"):Fire()
assert(ficha._retrato.Size.Y.Offset==96)
ficha:Atualizar("FornalhaBasica","Fornalha básica",2,false,Catalogo.FornalhaBasica,nil)
assert(not campos.Quantidade.Visible, "No inventario, o retrato ja mostra a quantidade.")

-- O tamanho do retrato tambem acompanha larguras estreitas; o canvas acompanha o conteudo.
ficha._conteudo.AbsoluteSize=roblox.Vector2.new(90,300)
ficha._conteudo:GetPropertyChangedSignal("AbsoluteSize"):Fire()
assert(ficha._retrato.Size.X.Offset==86 and ficha._retrato.Size.Y.Offset==86)
local layout=ficha._conteudo:FindFirstChildOfClass("UIListLayout")
layout.AbsoluteContentSize=roblox.Vector2.new(90,600)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Fire()
assert(ficha._rolagem.CanvasSize.Y.Offset==608)

-- O painel controla Active; a ficha apenas representa o estado e Botao impede callbacks bloqueados.
campos.Acoes.Colocar:DefinirDisponivel(false)
ficha:AtualizarDisponibilidade()
campos.Acoes.Colocar:ObterInstancia().Activated:Fire()
assert(#acoes==0)
campos.Acoes.Colocar:DefinirDisponivel(true)
ficha:AtualizarDisponibilidade()
campos.Acoes.Colocar:ObterInstancia().Activated:Fire()
campos.Acoes.Vender:ObterInstancia().Activated:Fire()
assert(acoes[1]=="Colocar" and acoes[2]=="Vender")
ficha._botoes[1]:ObterInstancia().Activated:Fire(); assert(fechou)

-- A loja usa outro objeto da mesma classe, ancorado a esquerda e sem as acoes do inventario.
local compras=0
local loja=Ficha.new(pai,{WaitForChild=function(_,id) return {Name=id} end},
	function(acao) assert(acao=="Comprar"); compras+=1 end, function() end,"Loja")
local camposLoja=loja:ObterCampos()
assert(loja:ObterInstancia().AnchorPoint.X==0 and loja:ObterInstancia().Position.X.Scale==0)
assert(camposLoja.Acoes.Comprar and not camposLoja.Acoes.Colocar and not camposLoja.Acoes.Vender)
assert(camposLoja.Acoes.Comprar:ObterInstancia().Parent.Parent==loja:ObterInstancia())
assert(loja:Atualizar("MineradoraBasica","Mineradora básica",0,true,Catalogo.MineradoraBasica,"json invalido"))
assert(loja._quantidade.Text=="$100" and loja._nome.Text=="Mineradora básica")
assert(next(miniaturas[#miniaturas].Dados)==nil, "A loja ignora as personalizacoes e copias do inventario.")
local quantidadeMiniaturas=#miniaturas
loja:Atualizar("MineradoraBasica","Mineradora básica",7,false,Catalogo.MineradoraBasica,dados)
assert(#miniaturas==quantidadeMiniaturas, "Alterar estoque/configuracao do inventario nao recria o retrato da loja.")
local gigante=table.clone(Catalogo.MineradoraBasica)
gigante.Preco="100000000000000000001"
loja:Atualizar("MineradoraBasica","Mineradora básica",7,false,gigante,nil)
assert(loja._quantidade.Text=="$100Qn" and gigante.Preco=="100000000000000000001")
camposLoja.Acoes.Comprar:DefinirDisponivel(false); loja:AtualizarDisponibilidade()
camposLoja.Acoes.Comprar:ObterInstancia().Activated:Fire(); assert(compras==0)
camposLoja.Acoes.Comprar:DefinirDisponivel(true); loja:AtualizarDisponibilidade()
assert(camposLoja.Acoes.Comprar:ObterInstancia().BackgroundColor3==roblox.Color3.fromRGB(45,245,163))
camposLoja.Acoes.Comprar:ObterInstancia().Activated:Fire(); assert(compras==1)
assert(ficha:ObterInstancia().AnchorPoint.X==1 and ficha._nome.Text=="Fornalha básica", "A ficha do inventario permanece independente.")
for nome, estilo in carregar("src/client/Raridades").Estilos do
	local definicao=table.clone(Catalogo.FornalhaBasica); definicao.Raridade=nome
	ficha:Atualizar("FornalhaBasica","Fornalha básica",2,false,definicao,nil)
	local gradiente=ficha._bordaRetrato:FindFirstChild("Raridade")
	assert(ficha._raridade.Text==nome and ficha._faixaRaridade.Color==estilo.Cores)
	assert(gradiente.Color==estilo.Cores and #ficha._bordaRetrato:GetChildren()==1,"Faixa e borda devem combinar sem acumular gradientes.")
end
loja:Destruir(); loja:Destruir()
for _, b in loja._botoes do assert(b._destruido and not b._conexao.ativa) end
ficha:Destruir(); ficha:Destruir()
for _, m in miniaturas do assert(m.destruido) end
for _, c in ficha._conexoes do assert(not c.ativa) end
for _, b in ficha._botoes do assert(b._destruido and not b._conexao.ativa) end
pai:Destroy()
print("PASS: fichas independentes, precos, compra padrao, variantes do inventario, cache, falhas, rolagem, acoes e limpeza.")
