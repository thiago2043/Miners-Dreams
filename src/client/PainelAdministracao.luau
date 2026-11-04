local R=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Http=game:GetService("HttpService")
local Catalogo=require(R.Shared.CatalogoMaquinas)
local Upgrades=require(R.Shared.Upgrades)
local Abreviar=require(R.Shared.AbreviarInteiro)
local bloco=require(R.Shared.Medidas).Bloco
local Janela=require(script.Parent.PainelProgressao)
local Botao=require(script.Parent.Botao)
local Painel={}; Painel.__index=Painel
local tipos={"Dinheiro","Vidas","Upgrade","Inventario"}
local tiposPlot={"Adicionar","Reposicionar","Recolher","Remover"}
local nomes={Inventario="Inventário",Adicionar="Adicionar peça à plot",Reposicionar="Reposicionar peça",Recolher="Recolher peça da plot",Remover="Remover peça da plot",Zerar="Zerar todos os dados"}
local function data(t) return t and t>0 and os.date("!%d/%m/%Y %H:%M:%S",t).." UTC" or "sem amostra" end
local function dinheiro(v) return "$"..Abreviar(v or "0") end
local function tripla(texto)
	local valores={}
	for v in texto:gmatch("[^,%s]+") do table.insert(valores,tonumber(v) or false) end
	return valores
end

function Painel.new(pai,jogador,nav,rede,confirmacao)
	local janela=Janela.new(pai,nav,"Administracao","Administração",nil,nil,620,jogador)
	local self=setmetatable({_janela=janela,_grupo=janela._grupo,_jogador=jogador,_nav=nav,_rede=rede,
		_confirmacao=confirmacao,_botoes={},_aba="Jogadores",_tipo="Dinheiro",_pagina=1,_online={},_perfis={},_tempo=10},Painel)
	self._conexao=Run.Heartbeat:Connect(function(dt)
		if not self._grupo.Visible or not jogador:GetAttribute("Administrador") then return end
		self._tempo+=dt
		if self._tempo>=10 then
			self._tempo=0
			task.spawn(function() self:Listar(true) end)
		end
	end)
	self:_Desenhar()
	return self
end
function Painel:Atualizar()
	self._janela:Atualizar()
	if not self._jogador:GetAttribute("Administrador") then self._grupo.Visible=false end
	if self._grupo.Visible and not self._carregou then
		self._carregou=true; self._tempo=0
		task.spawn(function() self:Listar(false) end)
	end
end
function Painel:_Texto(nome,texto,y,altura,tamanho)
	return self._janela:Texto(self._janela.Conteudo,nome,texto,UDim2.fromOffset(0,y),UDim2.new(1,-8,0,altura),tamanho or 16)
end
function Painel:_Botao(nome,texto,y,callback,x,largura)
	local b=Botao.new(self._janela.Conteudo,nome,callback)
	local o=b:ObterInstancia()
	o.Text,o.Position,o.Size=texto,UDim2.new(x or 0,0,0,y),UDim2.new(largura or 1,-8,0,44)
	o.BackgroundColor3,o.TextColor3,o.Font,o.TextSize=Color3.fromRGB(34,42,52),Color3.new(1,1,1),Enum.Font.SourceSansBold,16
	o.TextWrapped,o.BorderSizePixel=true,0
	local canto=Instance.new("UICorner"); canto.CornerRadius,canto.Parent=UDim.new(0,6),o
	-- _ocupado protege os pedidos de rede; uma atualizacao em segundo plano nao deve desativar a navegacao.
	b:DefinirDisponivel(true)
	table.insert(self._botoes,b)
	return b
end
function Painel:_Entrada(nome,texto,dica,y)
	self:_Texto(nome.."Rotulo",dica,y,22,15)
	local b=Instance.new("TextBox")
	b.Name,b.Text,b.PlaceholderText=nome,texto or "",dica
	b.ClearTextOnFocus,b.TextXAlignment=false,Enum.TextXAlignment.Left
	b.Position,b.Size=UDim2.fromOffset(0,y+24),UDim2.new(1,-8,0,44)
	b.BackgroundColor3,b.TextColor3,b.TextSize,b.Font=Color3.fromRGB(30,32,40),Color3.new(1,1,1),16,Enum.Font.SourceSans
	b.BorderSizePixel,b.Parent=0,self._janela.Conteudo
	local padding=Instance.new("UIPadding"); padding.PaddingLeft,padding.Parent=UDim.new(0,8),b
	return b
end
function Painel:_Rede(metodo,...)
	local r=table.pack(pcall(self._rede.fetch,self._rede,metodo,...))
	if self._destruido then return end
	if not r[1] then self._mensagem="Não foi possível comunicar com o servidor."; return end
	return table.unpack(r,2,r.n)
end
function Painel:Listar(apenasOnline,cursor)
	if self._ocupado or self._destruido then return end
	self._ocupado=true
	local resposta,erro=self:_Rede("Listar",cursor,apenasOnline)
	self._ocupado=false
	if self._destruido then return end
	if resposta then
		self._online=resposta.Online
		if not apenasOnline then self._perfis,self._proxima=resposta.Perfis,resposta.Proxima end
		if not resposta.AoVivoDisponivel or not resposta.HistoricoDisponivel then self._mensagem="Serviços globais indisponíveis. Os jogadores deste servidor continuam disponíveis." end
		if self._dados then
			self._dados.Online=self._online[tostring(self._dados.UserId)]~=nil
			if self._dados.Online then self._dados.Resumo=self._online[tostring(self._dados.UserId)] end
		end
		if self._statusUltima then self._statusUltima.Text=self:_UltimaTexto() end
	else self._mensagem=erro or self._mensagem end
	-- A atualizacao automatica nao recria formularios que o administrador esta preenchendo.
	if self._aba=="Jogadores" or self._aba=="Progresso" then self:_Desenhar() end
end
function Painel:_UltimaTexto()
	local d=self._dados
	if not d then return "" end
	local a=d.Resumo.UltimaAlteracao or d.Historico.Alteracoes[#d.Historico.Alteracoes]
	return a and ("Última edição ["..a.Id:sub(1,8).."] • "..data(a.Instante).."\n"..(a.Sucesso and "Aplicada: " or "Recusada: ")..a.Mensagem) or "Nenhuma edição administrativa registrada."
end
function Painel:Consultar(id)
	if self._ocupado or self._destruido then return end
	self._ocupado=true
	local dados,erro=self:_Rede("Consultar",id)
	self._ocupado=false
	if self._destruido then return end
	if dados then self._dados=dados; self._pagina=1; self._peca=nil; self._mensagem=nil
		if self._aba=="Jogadores" then self._aba="Progresso" end
	else self._mensagem=erro or self._mensagem end
	self:_Desenhar()
end
function Painel:_Escolher(escopo)
	self._escolhendo=escopo; self._filtro=""; self:_Desenhar()
end
function Painel:_Seletor(y)
	local escopo=self._escolhendo
	local campo=self:_Entrada("Filtro",self._filtro,"Filtrar por nome",y)
	self:_Botao("Filtrar","Filtrar",y+76,function() self._filtro=campo.Text; self:_Desenhar() end,0,.5)
	self:_Botao("VoltarEditor","Voltar",y+76,function() self._escolhendo=nil; self:_Desenhar() end,.5,.5)
	y+=132
	local entradas={}
	if escopo=="Plot" then
		for _,r in self._dados.Plot do table.insert(entradas,{Id=r.Id,Nome=(Catalogo[r.MaquinaId] or {}).Nome or r.MaquinaId,Registro=r}) end
	elseif escopo=="Upgrade" then
		for _,u in Upgrades.Itens do table.insert(entradas,{Id=u.Id,Nome=u.Nome}) end
	else for id,c in Catalogo do table.insert(entradas,{Id=id,Nome=c.Nome}) end end
	table.sort(entradas,function(a,b) return a.Nome<b.Nome end)
	for _,e in entradas do
		if not e.Nome:lower():find(self._filtro:lower(),1,true) then continue end
		local texto=e.Nome
		if e.Registro then local p=e.Registro.Posicao; texto..=string.format(" • (%g, %g, %g) blocos",p[1]/bloco,p[2]/bloco,p[3]/bloco) end
		self:_Botao("Escolha_"..tostring(e.Id),texto,y,function()
			if escopo=="Plot" then self._peca=e.Registro else self._chave=e.Id end
			self._escolhendo=nil; self:_Desenhar()
		end)
		y+=50
	end
	return y
end
function Painel:_Editor(y)
	if self._escolhendo then return self:_Seletor(y) end
	if self._aba=="Plot" then
		for i,tipo in tiposPlot do
			local b=self:_Botao("Plot_"..tipo,nomes[tipo],y+math.floor((i-1)/2)*52,function()
				self._tipo=tipo; self._escolhendo=nil; self:_Desenhar()
			end,((i-1)%2)/2,.5)
			if self._tipo==tipo then b:ObterInstancia().BackgroundColor3=Color3.fromRGB(48,93,120) end
		end
		y+=110
	else
	self:_Botao("Campo","Editar: "..(nomes[self._tipo] or self._tipo).." ▸",y,function()
		self._tipo=tipos[(table.find(tipos,self._tipo) or 1)%#tipos+1]; self._chave=nil; self._peca=nil; self:_Desenhar()
	end)
	y+=54
	end
	local tipo=self._tipo
	if tipo=="Upgrade" or tipo=="Inventario" or tipo=="Adicionar" then
		if tipo=="Upgrade" and not Upgrades.Item(self._chave) then self._chave="Extracao" end
		if tipo~="Upgrade" and not Catalogo[self._chave] then self._chave="Esteira2x2" end
		local nome=tipo=="Upgrade" and Upgrades.Item(self._chave).Nome or Catalogo[self._chave].Nome
		self:_Botao("Chave",nome.." • escolher",y,function() self:_Escolher(tipo=="Upgrade" and "Upgrade" or "Catalogo") end)
		y+=54
	elseif tipo=="Reposicionar" or tipo=="Recolher" or tipo=="Remover" then
		self:_Botao("Peca",self._peca and ((Catalogo[self._peca.MaquinaId] or {}).Nome or self._peca.MaquinaId).." • trocar" or "Escolher peça da plot",y,function() self:_Escolher("Plot") end)
		y+=54
	end
	local d=self._dados
	local geracao=d.Resumo.Geracao or 0
	local esperado=if tipo=="Dinheiro" then d.Resumo.Dinheiro elseif tipo=="Vidas" then d.Resumo.Vidas
		elseif tipo=="Inventario" then d.Inventario[self._chave] or 0
		elseif tipo=="Upgrade" then (self._chave=="Expansao" and d.Resumo.Expansao or d.Resumo.Upgrades[self._chave]) or 0 else nil
	local valor,posicao,giro,confirmacaoId
	if tipo=="Zerar" then
		self:_Texto("AvisoLimpeza","Dinheiro, vidas, renascimentos, upgrades, peças, blueprints, recompensas, histórico e recordes voltarão ao início. O jogador recebe o kit inicial. Será criada uma cópia de recuperação.",y,100,16); y+=110
		confirmacaoId=self:_Entrada("ConfirmarUserId","","Digite o UserId "..d.UserId.." para confirmar",y); y+=80
	end
	if esperado~=nil then
		valor=self:_Entrada("Valor",tostring(esperado),tipo=="Dinheiro" and "Novo dinheiro • inteiro completo" or "Novo total / nível",y); y+=80
	elseif tipo=="Adicionar" or tipo=="Reposicionar" then
		local p=self._peca and self._peca.Posicao
		posicao=self:_Entrada("Posicao",p and string.format("%g, %g, %g",p[1]/bloco,p[2]/bloco,p[3]/bloco) or "0, 0, 0","Posição X, Y, Z em blocos, a partir do canto da plot",y); y+=80
		local rot="0, 0, 0"
		if self._peca then
			local x,a,z=CFrame.new(0,0,0,table.unpack(self._peca.Rotacao)):ToEulerAnglesXYZ()
			rot=string.format("%g, %g, %g",math.round(math.deg(x)/45)*45,math.round(math.deg(a)/90)*90,math.round(math.deg(z)/90)*90)
		end
		giro=self:_Entrada("Giro",rot,"Rotação X, Y, Z em graus • 90°; esteiras aceitam X de 45°",y); y+=80
	end
	local motivo=self:_Entrada("Motivo","","Motivo da alteração • obrigatório",y); y+=80
	self:_Botao("Aplicar","Revisar alteração",y,function()
		local pedido={Tipo=tipo,Chave=self._chave,Esperado=esperado,Motivo=motivo.Text,Geracao=geracao}
		if confirmacaoId then
			if confirmacaoId.Text~=tostring(d.UserId) then self._mensagem="Digite exatamente o UserId do jogador selecionado."; self:_Desenhar(); return end
			pedido.Confirmacao=confirmacaoId.Text
		end
		if valor then pedido.Valor=tipo=="Dinheiro" and valor.Text or tonumber(valor.Text) end
		if tipo=="Dinheiro" and not pedido.Valor:match("^%d+$") then self._mensagem="Digite o dinheiro inteiro usando apenas dígitos."; self:_Desenhar(); return end
		if posicao then pedido.Posicao=tripla(posicao.Text); pedido.Giro=tripla(giro.Text) end
		if tipo=="Adicionar" then pedido.MaquinaId=self._chave end
		if self._peca then pedido.PecaId=self._peca.Id; pedido.PosicaoAnterior=self._peca.Posicao end
		local aviso="Alterar "..(nomes[tipo] or tipo).." de "..d.Nome.."?\n\n"..motivo.Text
		if esperado~=nil then
			local antes=tipo=="Dinheiro" and dinheiro(esperado) or tostring(esperado)
			local depois=tipo=="Dinheiro" and dinheiro(pedido.Valor) or tostring(pedido.Valor)
			aviso..="\n"..(tipo=="Upgrade" and Upgrades.Item(pedido.Chave).Nome or tipo=="Inventario" and Catalogo[pedido.Chave].Nome or "Total")..": "..antes.." → "..depois
		elseif self._peca then
			local p=self._peca.Posicao
			aviso..="\n"..((Catalogo[self._peca.MaquinaId] or {}).Nome or self._peca.MaquinaId)..string.format(" • (%g, %g, %g) blocos",p[1]/bloco,p[2]/bloco,p[3]/bloco)
		end
		if posicao then aviso..="\nPosição: "..posicao.Text.." • Giro: "..giro.Text end
		if tipo=="Adicionar" then aviso..="\nA peça será concedida sem custo." end
		if tipo=="Remover" then aviso..="\nA peça será removida sem pagamento." end
		if tipo=="Zerar" then aviso..="\nTodo o progresso será reiniciado, incluindo plot, inventário, blueprints, recompensas e recordes. Volta com o kit inicial." end
		self._confirmacao:Pedir("Administracao",1,function()
			if self._ocupado or self._destruido then return end
			self._ocupado=true
			local _,mensagem,id=self:_Rede("Alterar",d.UserId,pedido)
			self._ocupado=false
			if self._destruido then return end
			self:Consultar(d.UserId)
			self._mensagem=mensagem and (mensagem..(id and " ["..id:sub(1,8).."]" or "")) or self._mensagem; self:_Desenhar()
		end,aviso)
	end)
	return y+54
end
function Painel:_Desenhar()
	if self._destruido then return end
	for _,b in self._botoes do b:Destruir() end
	table.clear(self._botoes)
	for _,c in self._janela.Conteudo:GetChildren() do c:Destroy() end
	self._statusUltima=nil
	local busca=self:_Entrada("Jogador","","Nome de usuário ou UserId",0)
	self:_Botao("Buscar","Buscar jogador",76,function() self:Consultar(busca.Text) end,0,.5)
	self:_Botao("Atualizar","Atualizar",76,function()
		if self._dados and self._aba~="Jogadores" then self:Consultar(self._dados.UserId) else self:Listar(false) end
	end,.5,.5)
	local abas={"Jogadores","Progresso","Histórico","Editar","Plot","Registro"}
	local colunas=self._janela.Conteudo.AbsoluteSize.X<380 and 3 or #abas
	for i,nome in abas do
		local b=self:_Botao(nome,nome,130+math.floor((i-1)/colunas)*52,function()
			if nome=="Plot" and not table.find(tiposPlot,self._tipo) then self._tipo="Adicionar"; self._chave=nil end
			if nome=="Editar" and not table.find(tipos,self._tipo) then self._tipo="Dinheiro"; self._chave=nil end
			self._aba=nome; self._pagina=1; self._escolhendo=nil; self:_Desenhar()
		end,((i-1)%colunas)/colunas,1/colunas)
		if self._aba==nome then b:ObterInstancia().BackgroundColor3=Color3.fromRGB(48,93,120) end
	end
	local y=132+math.ceil(#abas/colunas)*52
	if self._mensagem then self:_Texto("Resposta",self._mensagem,y,66,15); y+=74 end
	if self._aba=="Jogadores" then
		self:_Texto("Online","Online • até 100 recentes • atualização a cada 10 segundos",y,40,17); y+=46
		local linhas={}
		for id,r in self._online do table.insert(linhas,{Id=id,Resumo=r}) end
		table.sort(linhas,function(a,b) return (a.Resumo.Nome or "")<(b.Resumo.Nome or "") end)
		for _,e in linhas do
			local r=e.Resumo
			self:_Botao("Player_"..e.Id,(r.Nome or tostring(e.Id)).." • "..r.Vidas.." vidas\n"..dinheiro(r.Dinheiro).."  •  "..dinheiro(r.GanhosPorSegundo).."/s",y,function() self:Consultar(e.Id) end)
			y+=52
		end
		if #linhas==0 then self:_Texto("SemOnline","Nenhum jogador online disponível.",y,40); y+=48 end
		self:_Texto("Salvos","Perfis salvos • esta página",y,32,17); y+=38
		for _,id in self._perfis do
			if self._online[tostring(id)] then continue end
			self:_Botao("Salvo_"..id,"UserId "..id,y,function() self:Consultar(id) end); y+=50
		end
		if self._proxima then self:_Botao("Mais","Próxima página de perfis",y,function() self:Listar(false,self._proxima) end); y+=50 end
	elseif not self._dados then
		self:_Texto("Selecionar","Selecione um jogador na lista ou busque pelo nome.",y,70); y+=78
	else
		local d,r=self._dados,self._dados.Resumo
		self:_Texto("Alvo",d.Nome.." • "..d.UserId.." • "..(d.Online and "online" or "offline"),y,44,18); y+=50
		if self._aba=="Progresso" or self._aba=="Editar" or self._aba=="Plot" then self._statusUltima=self:_Texto("UltimaEdicao",self:_UltimaTexto(),y,76,14); y+=84 end
		if self._aba=="Progresso" then
			local texto=dinheiro(r.Dinheiro).." • "..dinheiro(r.GanhosPorSegundo).."/s\n"..r.Vidas.." vidas • "..r.Reencarnacoes.." renascimentos\n"..r.Plot.." peças na plot • "..Abreviar(r.Inventario).." no inventário\nTempo acompanhado: "..math.floor((r.Tempo or 0)/60).." minutos\nAmostra: "..data(r.Instante)
			self:_Texto("Resumo",texto,y,150,17); y+=160
			if not d.Local and d.SalvoEm then self:_Texto("DadosSalvos","Inventário, plot e histórico salvos em "..data(math.floor(d.SalvoEm/1000)),y,54,14); y+=62 end
			for _,u in Upgrades.Itens do
				local n=(u.Id=="Expansao" and r.Expansao or r.Upgrades[u.Id]) or 0
				self:_Texto(u.Id,u.Nome..": "..n.."/"..#u.Precos..(u.Precos[n+1] and " • próximo "..dinheiro(u.Precos[n+1]) or " • máximo"),y,44); y+=48
			end
			self:_Texto("Recordes","Recordes: "..dinheiro((r.Recordes or {}).Dinheiro).." • "..dinheiro((r.Recordes or {}).DinheiroPorSegundo).."/s • minério "..dinheiro((r.Recordes or {}).Minerio),y,64); y+=74
			local b=self:_Botao("ZerarDados","Zerar todos os dados do jogador…",y,function()
				self._aba="Editar"; self._tipo="Zerar"; self._chave=nil; self._peca=nil; self._escolhendo=nil; self:_Desenhar()
			end)
			b:ObterInstancia().BackgroundColor3=Color3.fromRGB(109,42,46); y+=54
		elseif self._aba=="Editar" or self._aba=="Plot" then y=self:_Editor(y)
		else
			local historico=self._aba=="Histórico"
			if historico then
				self:_Botao("Medidas",self._marcos and "Marcos • ver medidas" or "Medidas • ver marcos",y,function() self._marcos=not self._marcos; self._pagina=1; self:_Desenhar() end); y+=54
			end
			local lista=historico and (self._marcos and d.Historico.Eventos or d.Historico.Amostras) or d.Historico.Alteracoes
			local paginas=math.max(1,math.ceil(#lista/30)); self._pagina=math.clamp(self._pagina,1,paginas)
			self:_Botao("Anterior","◂ "..self._pagina.."/"..paginas,y,function() self._pagina=math.max(1,self._pagina-1); self:_Desenhar() end,0,.5)
			self:_Botao("Proxima","Próxima ▸",y,function() self._pagina=math.min(paginas,self._pagina+1); self:_Desenhar() end,.5,.5); y+=54
			if #lista==0 then self:_Texto("Vazio","Nenhum registro desde a ativação do acompanhamento.",y,60); y+=68 end
			for i=#lista-(self._pagina-1)*30,math.max(1,#lista-self._pagina*30+1),-1 do
				local a=lista[i]
				local texto=data(a.Instante).."\n"
				if historico and not self._marcos then
					texto..=dinheiro(a.Dinheiro).." • "..dinheiro(a.GanhosPorSegundo).."/s • "..a.Vidas.." vidas • "..a.Plot.." peças"
				elseif historico then texto..=a.Tipo.." • "..Http:JSONEncode(a.Detalhes)
				else texto..=(a.Sucesso and "Aplicada" or "Recusada").." ["..a.Id:sub(1,8).."] • "..a.Tipo.." • autor "..a.Autor.."\n"..a.Motivo.."\n"..a.Mensagem end
				local altura=historico and 70 or 122
				self:_Texto("Registro_"..i,texto,y,altura,15); y+=altura+8
				if not historico then
					local valores="Antes: "..Http:JSONEncode(a.Antes).."\nDepois: "..Http:JSONEncode(a.Depois)
					if a.Efeitos and a.Efeitos.Devolvidas then valores..="\nPeças devolvidas ao inventário: "..#a.Efeitos.Devolvidas end
					if a.Efeitos and a.Efeitos.Backup then valores..="\nCópia de recuperação: "..a.Efeitos.Backup end
					local h=math.max(60,math.ceil(#valores/45)*18)
					self:_Texto("Diferenca_"..i,valores,y,h,14); y+=h+12
				end
			end
		end
	end
	self._janela.Conteudo.CanvasSize=UDim2.fromOffset(0,y+12)
end
function Painel:Destruir()
	self._destruido=true; self._conexao:Disconnect()
	for _,b in self._botoes do b:Destruir() end
	self._janela:Destruir()
end
return Painel
