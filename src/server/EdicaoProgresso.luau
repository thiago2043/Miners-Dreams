local R=game:GetService("ReplicatedStorage")
local Catalogo=require(R.Shared.CatalogoMaquinas)
local Upgrades=require(R.Shared.Upgrades)
local Inteiro=require(R.Shared.InteiroGrande)
local bloco=require(R.Shared.Medidas).Bloco
local Elevador=require(R.Shared.ElevadorVertical)
local E={}
local campos={Tipo=true,Motivo=true,Valor=true,Esperado=true,Chave=true,MaquinaId=true,PecaId=true,PosicaoAnterior=true,Posicao=true,Giro=true,Geracao=true,Confirmacao=true,Rotacao=true,Elevador=true}
local function inteiro(n,minimo,maximo)
	return type(n)=="number" and n%1==0 and n>=minimo and n<=maximo
end
local function tripla(t,minimo,maximo,passo)
	if type(t)~="table" or #t~=3 then return false end
	for k in t do if not inteiro(k,1,3) then return false end end
	for i=1,3 do if not inteiro(t[i],minimo,maximo) or t[i]%passo~=0 then return false end end
	return true
end
function E.Validar(p)
	if type(p)~="table" or type(p.Motivo)~="string" or #p.Motivo<3 or #p.Motivo>160 or p.Motivo:find("%c") then return false,"Informe um motivo de 3 a 160 caracteres." end
	for k in p do if not campos[k] then return false,"Campo desconhecido no pedido." end end
	if p.Geracao~=nil and not inteiro(p.Geracao,0,2^53-2) then return false,"Versão de progresso inválida." end
	if p.Confirmacao~=nil and (type(p.Confirmacao)~="string" or #p.Confirmacao>16) then return false,"Confirmação inválida." end
	for _,k in {"Chave","MaquinaId","PecaId"} do
		if p[k]~=nil and (type(p[k])~="string" or #p[k]>64) then return false,"Identificador inválido." end
	end
	for _,k in {"Valor","Esperado"} do
		if p[k]~=nil and not ((type(p[k])=="string" and #p[k]<=309) or (type(p[k])=="number" and p[k]==p[k] and math.abs(p[k])<math.huge)) then return false,"Valor inválido." end
	end
	for _,k in {"Posicao","PosicaoAnterior","Giro"} do
		if p[k]~=nil and not tripla(p[k],-10000,10000,1) then return false,"Coordenadas inválidas." end
	end
	if p.Rotacao~=nil then
		if p.Tipo~="Adicionar" or p.Giro~=nil or type(p.Rotacao)~="table" or #p.Rotacao~=9 then return false,"Rotação inválida." end
		for k in p.Rotacao do if not inteiro(k,1,9) then return false,"Rotação inválida." end end
		for i=1,9 do
			local v=p.Rotacao[i]
			if type(v)~="number" or not (math.abs(v)<=1.0001) then return false,"Rotação inválida." end
		end
	end
	if p.Elevador~=nil then
		local c=p.Elevador
		if p.Tipo~="Adicionar" or p.MaquinaId~="ElevadorVertical" or type(c)~="table" or #c~=4
			or not Elevador.Validar(c[1],c[2],c[3],c[4]) then return false,"Configuração de elevador inválida." end
		for k in c do if not inteiro(k,1,4) then return false,"Configuração de elevador inválida." end end
	end
	if p.Tipo=="Zerar" then
		if not p.Confirmacao or not p.Confirmacao:match("^[1-9]%d*$") then return false,"Digite o UserId do jogador para confirmar a limpeza." end
	elseif p.Tipo=="Dinheiro" then
		if not Inteiro.eValido(p.Valor) or #p.Valor>309 or not Inteiro.eValido(p.Esperado) or #p.Esperado>309 then return false,"Use o dinheiro inteiro em dígitos, até 309 caracteres." end
	elseif p.Tipo=="Vidas" then
		if not inteiro(p.Valor,1,2^53-1) or not inteiro(p.Esperado,1,2^53-1) then return false,"Quantidade de vidas inválida." end
	elseif p.Tipo=="Upgrade" then
		if not Upgrades.Item(p.Chave) or not Upgrades.Valido(p.Valor,p.Chave) or not Upgrades.Valido(p.Esperado,p.Chave) then return false,"Upgrade ou nível inválido." end
	elseif p.Tipo=="Inventario" then
		if not Catalogo[p.Chave] or not inteiro(p.Valor,0,2^53-1) or not inteiro(p.Esperado,0,2^53-1) then return false,"Peça ou quantidade inválida." end
	elseif p.Tipo=="Adicionar" or p.Tipo=="Reposicionar" or p.Tipo=="Recolher" or p.Tipo=="Remover" then
		if p.Tipo=="Adicionar" then
			if not Catalogo[p.MaquinaId] then return false,"Peça inválida." end
		elseif type(p.PecaId)~="string" or #p.PecaId>64 or not tripla(p.PosicaoAnterior,0,32*bloco,bloco) then return false,"Peça da plot inválida. Atualize o painel." end
		if p.Tipo=="Adicionar" or p.Tipo=="Reposicionar" then
			if not tripla(p.Posicao,0,32,1) or (not p.Rotacao and
				(not tripla(p.Giro,-360,360,45) or p.Giro[2]%90~=0 or p.Giro[3]%90~=0)) then return false,"Posição em blocos e rotação inválidas." end
		end
	else return false,"Operação desconhecida." end
	return true
end

function E.Aplicar(dados,p,construcao,jogador)
	local valido,erro=E.Validar(p)
	if not valido then return false,erro end
	if not dados:EstaAtivo() then return false,"Perfil indisponível." end
	local d=dados._perfil.Data
	if (p.Geracao or 0)~=(d.GeracaoProgresso or 0) then return false,"Os dados foram reiniciados. Atualize o painel." end
	if p.Tipo=="Zerar" then return false,"A limpeza exige cópia de recuperação no serviço administrativo." end
	local antes
	if p.Tipo=="Dinheiro" then antes=d.Dinheiro
	elseif p.Tipo=="Vidas" then antes=d.Vidas
	elseif p.Tipo=="Upgrade" then antes=dados:ObterUpgrade(p.Chave)
	elseif p.Tipo=="Inventario" then antes=dados:ObterQuantidade(p.Chave)
	else return construcao.Administrar(jogador,p) end
	if antes~=p.Esperado then return false,"O progresso mudou. Atualize antes de editar novamente." end
	local mensagem="Progresso alterado."
	local efeitos
	if p.Tipo=="Dinheiro" then dados:_DefinirSaldo(Inteiro.somar("0",p.Valor))
	elseif p.Tipo=="Vidas" then d.Vidas=p.Valor
	elseif p.Tipo=="Inventario" then
		if p.Valor<#dados:_ObterVariantes(p.Chave) then return false,"A quantidade não pode excluir variantes personalizadas. Recolha ou remova essas unidades primeiro." end
		dados:_DefinirQuantidade(p.Chave,p.Valor)
	elseif p.Tipo=="Upgrade" then
		if p.Chave=="Expansao" then
			local ok,msg,devolvidas=construcao.RedimensionarAdministrativo(jogador,p.Valor)
			if not ok then return false,msg end
			efeitos={Devolvidas=devolvidas}
			d.ExpansaoPlot=p.Valor; mensagem=msg
		else
			d.Upgrades[p.Chave]=p.Valor
			if p.Chave=="Motores" then d.VelocidadeMotores=math.min(d.VelocidadeMotores or 0,p.Valor) end
		end
	end
	dados:Sincronizar()
	return true,mensagem,antes,p.Valor,efeitos
end
return E
