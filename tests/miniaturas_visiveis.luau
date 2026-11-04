local r=require("@lune/roblox")
local suporte=require("./suporte/interface")
local modelos={WaitForChild=function(_,id) return {Name=id} end}
local criadas={}
local carregar=require("./suporte/carregador")({Instance={new=suporte.NovaInstancia},
	Vector2=r.Vector2,UDim=r.UDim,UDim2=r.UDim2,Color3=r.Color3,Enum=r.Enum,
	ColorSequence=r.ColorSequence,ColorSequenceKeypoint=r.ColorSequenceKeypoint}, {}, {
	["src/client/MiniaturaPeca"]={new=function(_,modelo)
		local m={Nome=modelo.Name,Destruir=function(self) self.destruido=true end}
		table.insert(criadas,m); return m
	end},
})
local Catalogo=carregar("src/shared/CatalogoMaquinas")
local Grade=carregar("src/client/GradePecas")
local ids={}; for id in Catalogo do table.insert(ids,id) end; table.sort(ids)
local grade=Grade.new(suporte.NovaInstancia("Frame"),ids,modelos,function() error("Nao deve selecionar.") end,function() end,"Loja")
for _,id in ids do grade:AtualizarItem(id,0,true,false,false) end
grade:ConcluirAtualizacao()
assert(#ids==91 and #criadas==0,"Uma grade fechada nao deve criar miniaturas.")
local area=grade._area
area.AbsolutePosition=r.Vector2.new(100,200)
area.AbsoluteWindowSize=r.Vector2.new(128,128)
area.AbsoluteSize=r.Vector2.new(132,132)
local function foraTodos()
	for _,item in grade._itens do
		local b=item.Botao:ObterInstancia(); b.AbsolutePosition=r.Vector2.new(5000,5000); b.AbsoluteSize=r.Vector2.new(56,56)
	end
end
local function mostrarQuatro(inicio)
	foraTodos()
	for i=inicio,inicio+3 do
		local k=i-inicio
		grade._itens[ids[i]].Botao:ObterInstancia().AbsolutePosition=r.Vector2.new(100+k%2*64,200+math.floor(k/2)*64)
	end
end
mostrarQuatro(1)
grade._grupo.Visible=true; grade._grupo:GetPropertyChangedSignal("Visible"):Fire()
assert(#criadas==4,"Abrir deve criar so os quatro cartoes na area visivel, nao os 82.")
local primeira=grade._itens[ids[1]].Miniatura
grade:ConcluirAtualizacao(); assert(#criadas==4)
mostrarQuatro(5); area:GetPropertyChangedSignal("CanvasPosition"):Fire()
assert(#criadas==8)
mostrarQuatro(1); area:GetPropertyChangedSignal("CanvasPosition"):Fire()
assert(#criadas==8 and grade._itens[ids[1]].Miniatura==primeira)
grade._grupo.Visible=false
mostrarQuatro(9); area:GetPropertyChangedSignal("CanvasPosition"):Fire()
assert(#criadas==8)
grade._grupo.Visible=true; grade._grupo:GetPropertyChangedSignal("Visible"):Fire()
assert(#criadas==12)
foraTodos()
local function posicionar(i,x,y,tamanho)
	local b=grade._itens[ids[i]].Botao:ObterInstancia()
	b.AbsolutePosition=r.Vector2.new(x,y); b.AbsoluteSize=tamanho or r.Vector2.new(56,56)
	return b
end
posicionar(13,45,200) -- Um pixel visivel.
posicionar(14,44,200) -- Apenas encosta na borda.
posicionar(15,228,200)
posicionar(16,100,328)
posicionar(17,100,145)
posicionar(18,230,200) -- Dentro do tamanho bruto, fora da janela util.
local semTamanho=posicionar(19,100,200,r.Vector2.zero)
area.AbsoluteWindowSize=r.Vector2.zero; area:GetPropertyChangedSignal("AbsoluteWindowSize"):Fire()
assert(#criadas==12)
area.AbsoluteWindowSize=r.Vector2.new(128,128); area:GetPropertyChangedSignal("AbsoluteWindowSize"):Fire()
assert(#criadas==14 and grade._itens[ids[13]].Miniatura and grade._itens[ids[17]].Miniatura)
for _,i in {14,15,16,18,19} do assert(not grade._itens[ids[i]].Miniatura) end
semTamanho.AbsoluteSize=r.Vector2.new(56,56); semTamanho:GetPropertyChangedSignal("AbsoluteSize"):Fire()
assert(#criadas==15)
local movido=posicionar(20,100,200)
movido:GetPropertyChangedSignal("AbsolutePosition"):Fire()
assert(#criadas==16,"Reposicionar na ordenacao deve carregar sem depender do tamanho total do layout.")
foraTodos()
local geradora=grade._itens.MineradoraBasica
geradora.Botao:ObterInstancia().AbsolutePosition=r.Vector2.new(100,200)
grade._categoria="Vendedor"; grade:ConcluirAtualizacao()
assert(not geradora.Miniatura and not geradora.Botao:ObterInstancia().Visible)
grade._categoria="Todos"; grade._busca.Text="nao existe"; grade:ConcluirAtualizacao()
assert(not geradora.Miniatura)
grade._busca.Text="MINERADORA BASICA"; grade:ConcluirAtualizacao()
assert(geradora.Miniatura and geradora.Botao:ObterInstancia().Visible)
grade:Destruir(); grade:Destruir()
for _,m in criadas do assert(m.destruido) end
for _,c in grade._conexoes do assert(not c.ativa) end
local antes=#criadas
area:GetPropertyChangedSignal("CanvasPosition"):Fire(); movido:GetPropertyChangedSignal("AbsolutePosition"):Fire()
assert(#criadas==antes)
print("PASS: 91 cartoes, quatro miniaturas na abertura; rolagem, reutilizacao, aba fechada, recorte, tamanho zero, reordenacao, filtros e limpeza.")
