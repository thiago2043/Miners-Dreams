-- Command Bar do cliente em Play; cria uma GUI isolada, sem compras ou pedidos de inventario.
do
	local RS=game:GetService("RunService")
	assert(RS:IsStudio() and RS:IsClient(),"Execute na Command Bar do cliente durante Play.")
	local jogador=game:GetService("Players").LocalPlayer
	local Client=jogador.PlayerScripts.Client
	local Grade=require(Client.GradePecas)
	local R=game:GetService("ReplicatedStorage")
	local Catalogo=require(R.Shared.CatalogoMaquinas)
	local ids={}; for id in Catalogo do table.insert(ids,id) end; table.sort(ids)
	local gui=Instance.new("ScreenGui"); gui.Name="TesteMiniaturasVisiveis"; gui.DisplayOrder=100; gui.IgnoreGuiInset=true
	gui.ResetOnSpawn=false; gui.Parent=jogador.PlayerGui
	local quadro=Instance.new("Frame"); quadro.Size=UDim2.fromOffset(568,520); quadro.Position=UDim2.fromOffset(24,48); quadro.Parent=gui
	local grade
	local function esperar() for _=1,4 do RS.RenderStepped:Wait() end end
	local function visivel(item)
		local b=item.Botao:ObterInstancia()
		local a,j,p,t=grade._area.AbsolutePosition,grade._area.AbsoluteWindowSize,b.AbsolutePosition,b.AbsoluteSize
		return b.Visible and t.X>0 and t.Y>0 and j.X>0 and j.Y>0
			and p.X<a.X+j.X and p.X+t.X>a.X and p.Y<a.Y+j.Y and p.Y+t.Y>a.Y
	end
	local function conferir()
		local carregadas,naTela=0,0
		for _,item in grade._itens do
			if item.Miniatura then carregadas+=1 end
			if grade._grupo.Visible and visivel(item) then naTela+=1; assert(item.Miniatura,"Cartao visivel sem miniatura: "..item.Modelo.Name) end
		end
		return carregadas,naTela
	end
	local ok,erro=xpcall(function()
		grade=Grade.new(quadro,ids,R.ModelosMaquinas,function() error("Selecao inesperada.") end,function() end,"Loja")
		for _,id in ids do grade:AtualizarItem(id,0,true,false,false) end
		grade:ConcluirAtualizacao(); esperar()
		assert(conferir()==0)
		grade._grupo.Visible=true; esperar()
		local inicial,naTela=conferir()
		assert(inicial==naTela and inicial>0 and inicial<#ids,"A abertura clonou cartoes fora do recorte.")
		local partesInicial,partesCatalogo=0,0
		local retratos={}
		for id,item in grade._itens do
			for _,obj in item.Modelo:GetDescendants() do if obj:IsA("BasePart") then partesCatalogo+=1 end end
			if item.Miniatura then
				retratos[id]=item.Miniatura
				for _,obj in item.Miniatura._viewport:GetDescendants() do if obj:IsA("BasePart") then partesInicial+=1 end end
			end
		end
		grade._area.CanvasPosition=Vector2.new(0,grade._layout.AbsoluteContentSize.Y)
		esperar()
		local depois=conferir(); assert(depois>inicial)
		grade._area.CanvasPosition=Vector2.zero; esperar()
		for id,m in retratos do assert(grade._itens[id].Miniatura==m) end
		grade._grupo.Visible=false
		grade._area.CanvasPosition=Vector2.new(0,400); esperar()
		assert(conferir()==depois,"Rolar a aba fechada criou miniaturas.")
		grade._grupo.Visible=true; esperar(); conferir()
		grade._categoria="Modificador"; grade:ConcluirAtualizacao(); esperar(); conferir()
		grade._busca.Text="mineradora"; esperar()
		assert(grade._vazio.Visible)
		grade._categoria="Todos"; grade:ConcluirAtualizacao(); esperar(); conferir()
		grade._busca.Text=""; grade._ordem="Nome"; grade:ConcluirAtualizacao(); esperar(); conferir()
		quadro.Size=UDim2.fromOffset(320,400); esperar(); conferir()
		quadro.Position=UDim2.fromOffset(90,60); esperar(); conferir()
		local conexoes=table.clone(grade._conexoes)
		grade:Destruir(); grade:Destruir()
		for _,c in conexoes do assert(not c.Connected) end
		print("MINIATURAS_VISIVEIS_STUDIO_OK",#ids,inicial,partesInicial,partesCatalogo,"catalogo/miniaturas iniciais/partes iniciais/partes totais; rolagem, reuso, aba fechada, filtros, ordem, tamanho e limpeza.")
	end,debug.traceback)
	if grade then grade:Destruir() end
	gui:Destroy()
	assert(ok,erro)
end
return true
