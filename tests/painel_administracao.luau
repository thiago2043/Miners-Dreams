local r=require("@lune/roblox")
local ui=require("./suporte/interface")
local tarefa=require("@lune/task")
local heartbeat=ui.Sinal()
local carregar=require("./suporte/carregador")({Instance={new=ui.NovaInstancia},Enum=r.Enum,
	Color3=r.Color3,Vector2=r.Vector2,Vector3=r.Vector3,CFrame=r.CFrame,UDim=r.UDim,UDim2=r.UDim2,task=tarefa,
},{RunService={Heartbeat=heartbeat}})
local jogador={GetAttribute=function(_,n) return n=="Administrador" and true or nil end}
local nav=carregar("src/client/NavegacaoEstados").new()
local resumo={Dinheiro="100",GanhosPorSegundo="5",Vidas=1,Reencarnacoes=0,Plot=1,Inventario=12,Tempo=60,Instante=123,
	Upgrades={Extracao=0,Fundicao=0,Motores=0,Calibracao=0},Expansao=0,Recordes={}}
local dados={UserId=123,Nome="Jogador",Resumo=resumo,Online=true,Local=true,Inventario={Esteira2x2=10},
	Plot={{Id="peca",MaquinaId="Esteira2x2",Posicao={0,0,0},Rotacao={1,0,0,0,1,0,0,0,1}}},
	Historico={Amostras={resumo},Eventos={},Alteracoes={}}}
local pedido,consultas,confirmou
local pausarLista=false
local falharLista=false
local rede={fetch=function(_,metodo,id,p)
	if metodo=="Listar" then
		if pausarLista then coroutine.yield() end
		if falharLista then error("Falha de rede simulada") end
		return {Online={["123"]=resumo},Perfis={123,456},AoVivoDisponivel=true,HistoricoDisponivel=true}
	elseif metodo=="Consultar" then consultas=(consultas or 0)+1; return dados
	elseif metodo=="Alterar" then assert(id==123); pedido=p; return true,"Aplicado","abcdef12-0000" end
end}
local confirmacao={Pedir=function(_,tipo,_,callback,texto)
	assert(tipo=="Administracao" and texto:find("Jogador",1,true))
	confirmou=callback
end}
local painel=carregar("src/client/PainelAdministracao").new(ui.NovaInstancia("ScreenGui"),jogador,nav,rede,confirmacao)
local function botao(nome)
	for _,b in painel._botoes do if b:ObterInstancia().Name==nome then return b:ObterInstancia() end end
	error("Botao ausente: "..nome)
end
local function campo(nome)
	local lista=painel._janela.Conteudo:GetChildren()
	for i=#lista,1,-1 do if lista[i].Name==nome and not lista[i].destruido then return lista[i] end end
	error("Campo ausente: "..nome)
end
nav:Abrir("Administracao"); painel:Atualizar(); tarefa.wait()
assert(painel._grupo.Visible and botao("Player_123") and botao("Salvo_456"))
botao("Player_123").Activated:Fire()
assert(consultas==1 and painel._dados.UserId==123)
botao("Editar").Activated:Fire()
local gigante="1"..string.rep("0",308)
campo("Valor").Text=gigante; campo("Motivo").Text="Ajuste de teste"
botao("Aplicar").Activated:Fire()
assert(confirmou and not pedido,"A revisao nao pode enviar a edicao antes de confirmar.")
confirmou()
assert(pedido.Tipo=="Dinheiro" and pedido.Valor==gigante and pedido.Esperado=="100" and pedido.Motivo=="Ajuste de teste")
assert(painel._mensagem:find("abcdef12",1,true))
botao("Plot").Activated:Fire()
for _,acao in {"Adicionar","Reposicionar","Recolher","Remover"} do assert(botao("Plot_"..acao).Active) end
botao("Plot_Reposicionar").Activated:Fire()
botao("Peca").Activated:Fire(); botao("Escolha_peca").Activated:Fire()
campo("Posicao").Text="2, 1, 4"; campo("Giro").Text="45, 90, 0"; campo("Motivo").Text="Reposicionar teste"
botao("Aplicar").Activated:Fire(); confirmou()
assert(pedido.PecaId=="peca" and pedido.Posicao[1]==2 and pedido.Posicao[2]==1 and pedido.Giro[1]==45)
botao("Editar").Activated:Fire(); campo("Valor").Text="abc"; campo("Motivo").Text="Invalidar"
local antigo=pedido
botao("Aplicar").Activated:Fire(); assert(pedido==antigo and painel._mensagem:find("dígitos",1,true))
botao("Histórico").Activated:Fire(); assert(botao("Medidas"))
botao("Registro").Activated:Fire()
dados.Historico.Alteracoes={{Id="eb84b89b-teste",Instante=123,Autor=123,Tipo="Dinheiro",Motivo="sim",
	Sucesso=false,Mensagem="O progresso mudou. Atualize antes de editar novamente.",Antes={},Depois={}}}
for _,aba in {"Registro","Histórico","Editar","Plot"} do
	botao("Progresso").Activated:Fire()
	pausarLista=true
	falharLista=aba=="Editar"
	local atualizacao=coroutine.create(function() painel:Listar(true) end)
	assert(coroutine.resume(atualizacao))
	assert(painel._ocupado and coroutine.status(atualizacao)=="suspended")
	botao(aba).Activated:Fire()
	assert(painel._aba==aba)
	local antes=consultas
	painel:Consultar(123)
	assert(consultas==antes,"A navegacao ativa nao pode liberar pedidos simultaneos.")
	assert(coroutine.resume(atualizacao))
	pausarLista=false
	falharLista=false
	assert(not painel._ocupado and coroutine.status(atualizacao)=="dead")
	assert(botao("Progresso").Active,"A atualizacao automatica nao pode deixar os botoes desativados ao trocar de aba.")
	nav:Fechar("Administracao"); painel:Atualizar()
	nav:Abrir("Administracao"); painel:Atualizar()
	botao("Progresso").Activated:Fire()
	assert(painel._aba=="Progresso","Fechar e reabrir deve manter o ADM utilizavel.")
end
botao("ZerarDados").Activated:Fire()
assert(painel._tipo=="Zerar" and campo("ConfirmarUserId"))
local anterior=pedido
campo("ConfirmarUserId").Text="456"; campo("Motivo").Text="Recomeçar teste"
botao("Aplicar").Activated:Fire(); assert(pedido==anterior)
campo("ConfirmarUserId").Text="123"; campo("Motivo").Text="Recomeçar teste"
botao("Aplicar").Activated:Fire()
assert(pedido==anterior,"Zerar deve aguardar a confirmacao final.")
confirmou()
assert(pedido.Tipo=="Zerar" and pedido.Confirmacao=="123" and pedido.Geracao==0)
painel:Destruir()
for _,c in heartbeat.conexoes do assert(not c.ativa) end
print("PAINEL_ADMIN_OK: lista, consulta, edicao, registro preenchido durante atualizacao, falha de rede, retorno entre abas, reabertura e limpeza.")
