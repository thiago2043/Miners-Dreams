local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local Permitir=require(script.Parent.PermissaoAdministracao)
local Dados=require(script.Parent.Data.DataManager)
local Store=require(script.Parent.Data.ArmazenamentoPerfis)
local Historico=require(script.Parent.HistoricoProgresso)
local Edicao=require(script.Parent.EdicaoProgresso)
local Construcao=require(script.Parent.Construcao)
local Classificacao=require(script.Parent.ClassificacaoGlobal)
local nome=Run:IsStudio() and "Test" or "Live"
local Chaves=game:GetService("DataStoreService"):GetDataStore(nome)
local Recuperacao=game:GetService("DataStoreService"):GetDataStore("Recuperacao_"..nome.."_v1")
local AoVivo=game:GetService("MemoryStoreService"):GetSortedMap("Progresso_"..nome.."_v1")
local Admin={_sessoes={},_limites={}}

local function copiar(t) return Http:JSONDecode(Http:JSONEncode(t)) end
local function userId(id) return type(id)=="number" and id>0 and id%1==0 and id<2^53 end

function Admin:Permissao(jogador)
	return jogador.Parent==Players and Permitir(jogador)
end
function Admin:_PermitirPedido(jogador,intervalo,chave)
	if not self:Permissao(jogador) then return false end
	local agora=os.clock()
	local limites=self._limites[jogador] or {}; self._limites[jogador]=limites
	chave=chave or "Consulta"
	if agora<(limites[chave] or 0) then return false end
	limites[chave]=agora+(intervalo or .8)
	return true
end
function Admin:_Amostrar(jogador,perfil,forcar)
	local sessao=self._sessoes[jogador]
	if not sessao then return end
	if not Dados.ObterDados(jogador) then return end
	local agora=os.clock()
	if not forcar and agora-sessao.Amostrou<60 then return end
	Historico.Amostrar(perfil.Data,jogador:GetAttribute("GanhosPorSegundo"),math.floor(agora-sessao.Amostrou),os.time())
	sessao.Amostrou=agora
end
function Admin:_Resumo(jogador,perfil)
	local r=Historico.Resumo(perfil.Data,jogador:GetAttribute("GanhosPorSegundo"))
	r.UserId,r.Nome,r.Servidor=jogador.UserId,jogador.Name,game.JobId
	local a=Historico.Obter(perfil.Data).Alteracoes[#Historico.Obter(perfil.Data).Alteracoes]
	r.UltimaAlteracao=a and {Id=a.Id,Instante=a.Instante,Sucesso=a.Sucesso,Mensagem=a.Mensagem} or nil
	return r
end
function Admin:_Publicar(jogador,perfil)
	local ok,erro=pcall(function() AoVivo:SetAsync(tostring(jogador.UserId),self:_Resumo(jogador,perfil),40,os.time()) end)
	if not ok then
		if not self._avisouMemoria then warn("Monitoramento ao vivo indisponível: "..tostring(erro)); self._avisouMemoria=true end
	else self._avisouMemoria=false end
end
function Admin:_Aplicar(jogador,perfil,mensagem,recusa)
	if not perfil:IsActive() then return end
	local dados=Dados.ObterDados(jogador)
	if not dados then return false,"Aguarde a operação atual no perfil." end
	local d=perfil.Data
	if Historico.Registrou(d,mensagem.Id) then return true,"Alteração já processada." end
	local ok,msg,antes,depois,efeitos
	if recusa then ok,msg=false,recusa
	elseif os.time()-mensagem.Instante>86400 then ok,msg=false,"Pedido expirou após 24 horas."
	elseif mensagem.Pedido.Tipo=="Zerar" then ok,msg,antes,depois,efeitos=self:_Zerar(jogador,dados,mensagem)
	else ok,msg,antes,depois,efeitos=Edicao.Aplicar(dados,mensagem.Pedido,Construcao,jogador) end
	if not perfil:IsActive() then return false,msg or "O jogador saiu; a alteração não foi concluída." end
	Historico.Alteracao(perfil.Data,{Id=mensagem.Id,Instante=os.time(),SolicitadoEm=mensagem.Instante,Autor=mensagem.Autor,
		Tipo=mensagem.Pedido.Tipo,Chave=mensagem.Pedido.Chave,Motivo=mensagem.Pedido.Motivo,
		Sucesso=ok==true,Mensagem=msg,Antes=copiar(antes or {}),Depois=copiar(depois or {}),Efeitos=efeitos and copiar(efeitos)})
	self:_Amostrar(jogador,perfil,true)
	perfil:Save()
	return ok,msg
end

function Admin:_Zerar(jogador,dados,mensagem)
	local perfil,pedido=dados._perfil,mensagem.Pedido
	if pedido.Confirmacao~=tostring(jogador.UserId) then return false,"O UserId de confirmação não corresponde ao jogador." end
	if (pedido.Geracao or 0)~=(perfil.Data.GeracaoProgresso or 0) then return false,"Os dados já foram reiniciados. Atualize o painel." end
	Construcao.Sincronizar(jogador)
	local antes=Historico.Resumo(perfil.Data,jogador:GetAttribute("GanhosPorSegundo"))
	local chave=tostring(jogador.UserId).."_"..mensagem.Id:gsub("%-","")
	dados._suspenso=true
	local salvou,erro=pcall(function()
		local copia={UserId=jogador.UserId,Autor=mensagem.Autor,Instante=os.time(),Motivo=pedido.Motivo,Dados=copiar(perfil.Data)}
		local gravado=Recuperacao:UpdateAsync(chave,function(anterior) return anterior or copia, {jogador.UserId} end)
		assert(type(gravado)=="table" and gravado.UserId==jogador.UserId and type(gravado.Dados)=="table","A cópia de recuperação não foi confirmada.")
	end)
	dados._suspenso=false
	if not salvou then warn("Cópia de recuperação indisponível: "..tostring(erro)); return false,"Não foi possível criar a cópia de recuperação. Nenhum dado foi zerado." end
	if not perfil:IsActive() or jogador.Parent~=Players then return false,"O jogador saiu antes da limpeza; os dados foram preservados." end
	local ok,msg=Construcao.ReiniciarProgresso(jogador,function(d) return d:ZerarProgresso() end)
	if not ok then return false,msg end
	self._sessoes[jogador].Amostrou=os.clock()
	Classificacao:Registrar(jogador,dados:ObterRecordes())
	return true,msg,antes,Historico.Resumo(perfil.Data,"0"),{Backup=chave}
end
function Admin:Registrar(jogador,perfil)
	if self._sessoes[jogador] then return end
	self._sessoes[jogador]={Amostrou=os.clock()}
	Historico.Evento(perfil.Data,"Entrada",{Nome=jogador.Name})
	perfil.Data.NomeJogador=jogador.Name
	self:_Amostrar(jogador,perfil,true)
	perfil.OnSave:Connect(function() self:_Amostrar(jogador,perfil,true) end)
	perfil.OnLastSave:Connect(function()
		Historico.Evento(perfil.Data,"Saida",{})
		self:_Amostrar(jogador,perfil,true)
		self._sessoes[jogador]=nil; self._limites[jogador]=nil
		task.spawn(function() pcall(function() AoVivo:RemoveAsync(tostring(jogador.UserId)) end) end)
	end)
	perfil:MessageHandler(function(mensagem,processado)
		if type(mensagem)~="table" or mensagem.Tipo~="EdicaoAdministrativaV1" then return end
		if type(mensagem.Id)~="string" or type(mensagem.Instante)~="number" or not Edicao.Validar(mensagem.Pedido)
			or not userId(mensagem.Autor) then processado(); return end
		local autorizado,erro=Permitir({UserId=mensagem.Autor})
		if not perfil:IsActive() then return end
		self:_Aplicar(jogador,perfil,mensagem,not autorizado and erro or nil); processado()
		self:_Publicar(jogador,perfil)
	end)
end
function Admin:Listar(jogador,cursor,apenasOnline)
	if not self:_PermitirPedido(jogador,.8,"Lista") then return nil,"Sem acesso ou aguarde um instante." end
	if cursor~=nil and (type(cursor)~="string" or #cursor>1024) then return nil,"Página inválida." end
	if apenasOnline~=nil and type(apenasOnline)~="boolean" then return nil,"Pedido inválido." end
	local online,disponivel={},true
	-- shortcut: lista online limitada aos 100 mais recentes; paginar quando houver mais jogadores simultaneos. A busca individual continua disponivel.
	local ok,linhas=pcall(function() return AoVivo:GetRangeAsync(Enum.SortDirection.Descending,100) end)
	if ok then for _,l in linhas do online[tostring(l.value.UserId)]=l.value end else disponivel=false end
	for p,perfil in Dados.Profiles do if perfil:IsActive() then online[tostring(p.UserId)]=self:_Resumo(p,perfil) end end
	local ids,proxima={},nil
	local leu,pagina=true,nil
	if not apenasOnline then leu,pagina=pcall(function() return Chaves:ListKeysAsync("Player_",40,cursor or "",true) end) end
	if pagina then
		for _,chave in pagina:GetCurrentPage() do
			local id=tonumber(chave.KeyName:match("^Player_(%d+)$")); if id then table.insert(ids,id) end
		end
		if not pagina.IsFinished then proxima=pagina.Cursor end
	end
	return {Online=online,Perfis=ids,Proxima=proxima,AoVivoDisponivel=disponivel,HistoricoDisponivel=leu}
end
function Admin:Consultar(jogador,id)
	if not self:_PermitirPedido(jogador) then return nil,"Sem acesso ou aguarde um instante." end
	if type(id)=="string" and #id<=21 then
		local nomeUsuario=id:gsub("^@","")
		if nomeUsuario:match("^%d+$") then id=tonumber(nomeUsuario)
		elseif nomeUsuario:match("^[%w_]+$") then
			local ok,resultado=pcall(function() return Players:GetUserIdFromNameAsync(nomeUsuario) end)
			id=ok and resultado or nil
		end
	end
	if not userId(id) then return nil,"Nome de usuário ou UserId inválido." end
	local alvo=Players:GetPlayerByUserId(id)
	local perfil=alvo and Dados.Profiles[alvo]
	local localAtivo=perfil and perfil:IsActive()
	if not localAtivo then
		local ok,p=pcall(function() return Store:GetAsync("Player_"..id) end)
		if not ok then return nil,"Não foi possível consultar o perfil salvo." end
		perfil=p
	end
	if not perfil then return nil,"Nenhum perfil salvo para esse UserId." end
	local d=perfil.Data
	local h=Historico.Obter(d)
	local nomeJogador=d.NomeJogador
	if not nomeJogador or nomeJogador=="" then
		local achou,usuario=pcall(function() return Players:GetNameFromUserIdAsync(id) end)
		nomeJogador=achou and usuario or tostring(id)
	end
	local resumo=localAtivo and self:_Resumo(alvo,perfil) or h.Amostras[#h.Amostras] or Historico.Resumo(d,"0",0)
	local ok,resultado=pcall(function() return AoVivo:GetAsync(tostring(id)) end)
	local vivo=ok and resultado or nil
	if not localAtivo and vivo then resumo=vivo end
	return copiar({UserId=id,Nome=nomeJogador,Resumo=resumo,
		Inventario=d.Inventory,Plot=d.MaquinasColocadas,Historico=h,
		Local=localAtivo==true,Online=localAtivo==true or vivo~=nil,
		SalvoEm=perfil.KeyInfo and perfil.KeyInfo.UpdatedTime or nil})
end
function Admin:Alterar(jogador,id,pedido)
	if not self:_PermitirPedido(jogador,2,"Edicao") or not userId(id) then return false,"Sem acesso, jogador inválido ou aguarde um instante." end
	local valido,erro=Edicao.Validar(pedido)
	if not valido then return false,erro end
	if pedido.Tipo=="Zerar" and pedido.Confirmacao~=tostring(id) then return false,"Digite exatamente o UserId do jogador selecionado." end
	local mensagem={Tipo="EdicaoAdministrativaV1",Id=Http:GenerateGUID(false),Autor=jogador.UserId,Instante=os.time(),Pedido=copiar(pedido)}
	local alvo=Players:GetPlayerByUserId(id)
	local perfil=alvo and Dados.Profiles[alvo]
	if perfil and perfil:IsActive() then
		local ok,msg=self:_Aplicar(alvo,perfil,mensagem)
		return ok,msg,mensagem.Id
	end
	local leu,p=pcall(function() return Store:GetAsync("Player_"..id) end)
	if not leu or not p then return false,"Perfil não encontrado ou indisponível; nenhum pedido enviado." end
	local ok,enviou=pcall(function() return Store:MessageAsync("Player_"..id,mensagem) end)
	return ok and enviou==true,ok and enviou and "Pedido enviado. Será validado no servidor do jogador ou na próxima entrada; confira o registro de alterações." or "Falha ao enviar a alteração.",mensagem.Id
end
return Admin
