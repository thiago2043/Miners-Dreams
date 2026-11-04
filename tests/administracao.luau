local r=require("./suporte/modelos")
local serde=require("@lune/serde")
local sinais=require("./suporte/interface")
local tarefa=require("@lune/task")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo=I.new("Workspace")
local modelos=I.new("Folder")
require("./suporte/catalogo_modelos")(modelos)
local replicado={ModelosMaquinas=modelos}; function replicado:WaitForChild(n) return self[n] end
local players={PlayerRemoving=sinais.Sinal()}
local function jogador(id)
	local p={UserId=id,Name="Jogador"..id,Parent=players,atributos={}}
	function p:GetAttribute(k) return self.atributos[k] end
	function p:SetAttribute(k,v) self.atributos[k]=v end
	return p
end
local p,outro=jogador(123),jogador(456)
function players:GetPlayerByUserId(id) return id==p.UserId and p or nil end
function players:GetUserIdFromNameAsync(nome) assert(nome==p.Name); return p.UserId end
local tempo=100
local salvos,mensagens,memoria={}, {}, {}
local store={}
function store:GetAsync(chave) return salvos[chave] end
function store:MessageAsync(chave,m) table.insert(mensagens,{Chave=chave,Mensagem=m}); return true end
local mapa={}
function mapa:SetAsync(k,v,ttl) assert(ttl==40); memoria[k]=v end
function mapa:GetAsync(k) return memoria[k] end
function mapa:RemoveAsync(k) memoria[k]=nil end
function mapa:GetRangeAsync() local lista={} for k,v in memoria do table.insert(lista,{key=k,value=v}) end return lista end
local raw={ListKeysAsync=function() return {IsFinished=true,GetCurrentPage=function() return {{KeyName="Player_123"},{KeyName="Player_789"}} end} end}
local backups,falharBackup,duranteBackup={},false,nil
local recuperacao={UpdateAsync=function(_,k,fn)
	if duranteBackup then duranteBackup() end
	if falharBackup then error("Falha de copia simulada") end
	backups[k]=fn(backups[k]); return backups[k]
end}
local geracaoClassificada
local construcao
local carregar,no=require("./suporte/carregador")({
	game={CreatorType=r.Enum.CreatorType.User,CreatorId=123,JobId="teste"},
	workspace=mundo,Instance=I,Enum=r.Enum,Vector3=V,CFrame=CF,Color3=r.Color3,typeof=r.typeof,
	os={clock=function() return tempo end},task=tarefa,
},{Players=players,ReplicatedStorage=replicado,RunService={IsStudio=function() return true end},
	DataStoreService={GetDataStore=function(_,nome) if nome=="Recuperacao_Test_v1" then return recuperacao end; assert(nome=="Test"); return raw end},
	MemoryStoreService={GetSortedMap=function() return mapa end},
},{["src/server/Data/ArmazenamentoPerfis"]=store,["src/server/Construcao"]={
	Administrar=function(j,pedido) return construcao:Administrar(j,pedido) end,
	RedimensionarAdministrativo=function(j,n) return construcao:RedimensionarAdministrativo(j,n) end,
	Sincronizar=function(j) return construcao:Sincronizar(j) end,
	ReiniciarProgresso=function(j,fn) return construcao:ReiniciarProgresso(j,fn) end,
},["src/server/ClassificacaoGlobal"]={
	Registrar=function(_,_,recordes,geracao) assert(recordes.Dinheiro=="0"); geracaoClassificada=geracao end,
}})
replicado.Shared=no("src/shared")
local Manager=carregar("src/server/Data/DataManager")
local Template=carregar("src/server/Data/Template")
local perfil={Data=serde.decode("json",serde.encode("json",Template)),OnSave=sinais.Sinal(),OnLastSave=sinais.Sinal(),salvamentos=0}
function perfil:IsActive() return true end
function perfil:Save() self.salvamentos+=1 end
function perfil:MessageHandler(callback) self.handler=callback end
local dados=Manager.RegistrarPerfil(p,perfil)
local terrenos=I.new("Folder"); terrenos.Name,terrenos.Parent="Terrenos",mundo
local terreno=I.new("Model"); terreno.Parent=terrenos; terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1); p:SetAttribute("TerrenoId",1)
local piso=I.new("Part"); piso.Name,piso.Size,piso.CFrame,piso.Parent="Piso",V.new(36,1,36),CF.new(18,-.5,18),terreno
for _,n in {"Maquinas","Minerios"} do local f=I.new("Folder"); f.Name,f.Parent=n,terreno end
construcao=carregar("src/server/ServicoConstrucao").new()
local Admin=carregar("src/server/Administracao")
local H=carregar("src/server/HistoricoProgresso")
local E=carregar("src/server/EdicaoProgresso")
assert(Admin:Permissao(p) and not Admin:Permissao(outro))
assert(Admin:Listar(outro)==nil and Admin:Consultar(outro,123)==nil)
assert(not Admin:Alterar(outro,123,{Tipo="Vidas",Valor=9,Esperado=1,Motivo="Teste"}))
Admin:Registrar(p,perfil)
Admin:_Publicar(p,perfil)
assert(memoria["123"].Nome==p.Name)
local function alterar(pedido)
	tempo+=3; pedido.Motivo=pedido.Motivo or "Teste de balanceamento"
	return Admin:Alterar(p,123,pedido)
end
local gigante="1"..string.rep("0",308)
assert(alterar({Tipo="Dinheiro",Esperado="0",Valor=gigante}))
assert(perfil.Data.Dinheiro==gigante and perfil.salvamentos==1)
assert(not alterar({Tipo="Dinheiro",Esperado="0",Valor="5"}) and perfil.Data.Dinheiro==gigante)
assert(alterar({Tipo="Vidas",Esperado=1,Valor=10}) and p:GetAttribute("Vidas")==10)
assert(alterar({Tipo="Upgrade",Chave="Motores",Esperado=0,Valor=5}))
assert(not alterar({Tipo="Upgrade",Chave="Motores",Esperado=5,Valor=6}))
assert(alterar({Tipo="Inventario",Chave="Esteira2x2",Esperado=10,Valor=25}))
assert(not alterar({Tipo="Inventario",Chave="Esteira2x2",Esperado=10,Valor=30}))
assert(not E.Validar({Tipo="Dinheiro",Valor="3",Esperado="0",Motivo="Teste",Posicao={1,2,{}}}))
assert(not E.Validar({Tipo="Inventario",Chave={},Valor=0,Esperado=0,Motivo="Teste"}))
local saldo=perfil.Data.Dinheiro
assert(alterar({Tipo="Adicionar",MaquinaId="Esteira2x2",Posicao={0,0,0},Giro={0,0,0}}))
local r1=perfil.Data.MaquinasColocadas[1]
assert(r1.Id and #terreno.Maquinas:GetChildren()==1 and dados:ObterQuantidade("Esteira2x2")==25)
assert(not alterar({Tipo="Adicionar",MaquinaId="Esteira2x2",Posicao={0,0,0},Giro={0,0,0}}))
assert(alterar({Tipo="Reposicionar",PecaId=r1.Id,PosicaoAnterior=r1.Posicao,Posicao={3,0,0},Giro={45,0,0}}))
local r2=perfil.Data.MaquinasColocadas[1]
assert(r2.Id==r1.Id and r2.Posicao[1]==9 and #terreno.Maquinas:GetChildren()==1)
assert(not alterar({Tipo="Remover",PecaId=r1.Id,PosicaoAnterior=r1.Posicao}))
assert(alterar({Tipo="Recolher",PecaId=r2.Id,PosicaoAnterior=r2.Posicao}))
assert(#perfil.Data.MaquinasColocadas==0 and #terreno.Maquinas:GetChildren()==0 and dados:ObterQuantidade("Esteira2x2")==26)
assert(alterar({Tipo="Adicionar",MaquinaId="Parede1x1",Posicao={0,0,0},Giro={0,0,0}}))
r1=perfil.Data.MaquinasColocadas[1]
assert(alterar({Tipo="Remover",PecaId=r1.Id,PosicaoAnterior=r1.Posicao}))
assert(perfil.Data.Dinheiro==saldo and dados:ObterQuantidade("Parede1x1")==0)
assert(alterar({Tipo="Upgrade",Chave="Expansao",Esperado=0,Valor=5}))
assert(piso.Size.X==96)
assert(alterar({Tipo="Adicionar",MaquinaId="Parede1x1",Posicao={30,0,0},Giro={0,0,0}}))
assert(alterar({Tipo="Upgrade",Chave="Expansao",Esperado=5,Valor=0}))
assert(piso.Size.X==36 and #terreno.Maquinas:GetChildren()==0 and dados:ObterQuantidade("Parede1x1")==1)
assert(#H.Obter(perfil.Data).Alteracoes[#H.Obter(perfil.Data).Alteracoes].Efeitos.Devolvidas==1)
tempo+=2; local consulta=Admin:Consultar(p,123)
assert(consulta.UserId==123 and consulta.Local and #consulta.Historico.Alteracoes>8)
local ultima=consulta.Historico.Alteracoes[#consulta.Historico.Alteracoes]
assert(ultima.Autor==123 and ultima.Motivo=="Teste de balanceamento" and ultima.Sucesso)
local offline={Data=serde.decode("json",serde.encode("json",perfil.Data))}
salvos.Player_789=offline
tempo+=3
assert(Admin:Alterar(p,789,{Tipo="Vidas",Esperado=10,Valor=20,Motivo="Ajuste offline"}))
assert(#mensagens==1 and offline.Data.Vidas==10,"Edicao offline nao pode escrever ignorando a sessao.")
local m=mensagens[1].Mensagem
local processados=0
perfil.handler(m,function() processados+=1 end)
assert(processados==1 and perfil.Data.Vidas==20)
perfil.handler(m,function() processados+=1 end)
assert(processados==2 and perfil.Data.Vidas==20,"Uma mensagem repetida nao pode reaplicar a alteracao.")
local antigo={Tipo=m.Tipo,Id="expirada",Autor=123,Instante=os.time()-90000,Pedido={Tipo="Vidas",Esperado=20,Valor=30,Motivo="Pedido antigo"}}
perfil.handler(antigo,function() end)
assert(perfil.Data.Vidas==20 and not H.Obter(perfil.Data).Alteracoes[#H.Obter(perfil.Data).Alteracoes].Sucesso)
assert(H.Obter(perfil.Data).Tempo>0)
local anterior=#H.Obter(perfil.Data).Alteracoes
perfil.Data.Dinheiro="1"..string.rep("0",100)
assert(dados:Reencarnar(0))
assert(#H.Obter(perfil.Data).Alteracoes==anterior and #H.Obter(perfil.Data).Eventos>=2)
for i=1,1500 do H.Amostrar(perfil.Data,"5",1,i) end
assert(#H.Obter(perfil.Data).Amostras<=1440)
assert(#serde.encode("json",H.Obter(perfil.Data))<1600000)
local migrado=carregar("src/server/Data/MigracaoCatalogo").Preparar(perfil.Data)
assert(#migrado.Monitoramento.Alteracoes==anterior and migrado.NomeJogador==p.Name,"A migracao de carregamento deve preservar historico e auditoria.")
local carregarGrupo=require("./suporte/carregador")({Enum=r.Enum,game={CreatorType=r.Enum.CreatorType.Group,CreatorId=999}},
	{GroupService={GetGroupInfoAsync=function(_,id) assert(id==999); return {Owner={Id=123}} end}})
local permitirGrupo=carregarGrupo("src/server/PermissaoAdministracao")
assert(permitirGrupo(p) and not permitirGrupo(outro))
assert(alterar({Tipo="Upgrade",Chave="Expansao",Esperado=0,Valor=5}))
assert(alterar({Tipo="Adicionar",MaquinaId="Parede1x1",Posicao={30,0,0},Giro={0,0,0}}))
perfil.Data.Blueprints={{Id="anterior",Pecas={}}}
perfil.Data.RecompensasReencarnacao={MineradoraBasica=9}
perfil.Data.Inventory.Parede1x1=42
perfil.Data.Dinheiro=gigante
local reset={Tipo="Zerar",Confirmacao="123",Motivo="Limpeza completa de teste",Geracao=0}
local quantidadeAntes=#perfil.Data.MaquinasColocadas
duranteBackup=function()
	assert(not dados:EstaAtivo() and Manager.ObterDados(p)==nil)
	assert(not dados:AdicionarDinheiro("10"),"Uma copia em andamento nao pode receber alteracoes de progresso.")
end
falharBackup=true
assert(not alterar(reset))
assert(perfil.Data.Dinheiro==gigante and #perfil.Data.MaquinasColocadas==quantidadeAntes and dados:EstaAtivo())
falharBackup=false
assert(not alterar({Tipo="Zerar",Confirmacao="456",Motivo="Usuario incorreto"}))
local ok,msg,idReset=alterar(reset)
assert(ok,msg)
assert(perfil.Data.Dinheiro=="0" and perfil.Data.Vidas==1 and perfil.Data.Reencarnacoes==0)
assert(perfil.Data.ExpansaoPlot==0 and perfil.Data.GeracaoProgresso==1 and geracaoClassificada==1)
assert(#perfil.Data.MaquinasColocadas==0 and #terreno.Maquinas:GetChildren()==0 and piso.Size.X==36)
assert(#perfil.Data.Blueprints==0 and next(perfil.Data.RecompensasReencarnacao)==nil)
assert(perfil.Data.Inventory.Esteira2x2==10 and perfil.Data.Inventory.MineradoraBasica==1 and perfil.Data.Inventory.FornalhaBasica==1)
assert(perfil.Data.Inventory.Parede1x1==0 and perfil.Data.Recordes.Dinheiro=="0" and p:GetAttribute("GanhosPorSegundo")=="0")
local chaveBackup="123_"..idReset:gsub("%-","")
local copia=backups[chaveBackup]
assert(copia and copia.Dados.Inventory.Parede1x1==42 and #copia.Dados.MaquinasColocadas==quantidadeAntes)
assert(copia.Dados.Dinheiro==gigante and copia.Dados.Blueprints[1].Id=="anterior")
local audit=H.Obter(perfil.Data).Alteracoes
assert(#audit==1 and audit[1].Tipo=="Zerar" and audit[1].Sucesso and audit[1].Efeitos.Backup==chaveBackup)
perfil.handler({Tipo="EdicaoAdministrativaV1",Id=idReset,Autor=123,Instante=os.time(),Pedido=reset},function() end)
assert(#H.Obter(perfil.Data).Alteracoes==1 and perfil.Data.GeracaoProgresso==1)
assert(not alterar({Tipo="Vidas",Esperado=1,Valor=100,Motivo="Pedido anterior",Geracao=0}))
assert(perfil.Data.Vidas==1,"Uma edicao anterior ao reset nao pode modificar o novo progresso.")
perfil.Data.Dinheiro=gigante
assert(dados:Reencarnar(0) and perfil.Data.GeracaoProgresso==1,"Renascimento nao pode devolver a versao de progresso anterior ao reset.")
print("ADMINISTRACAO_OK: acesso exclusivo, inteiros ate 1e308, conflitos, auditoria, fila e repeticao, historico preservado, plot real, rotacao, limites e devolucao.")
