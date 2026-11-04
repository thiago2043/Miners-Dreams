local HttpService = game:GetService("HttpService")
local MovimentoMinerio = {}

function MovimentoMinerio.DecodificarRelogio(texto)
	if type(texto)~="string" then return nil end
	local ok,dados=pcall(HttpService.JSONDecode,HttpService,texto)
	if not ok or type(dados)~="table" or (#dados~=2 and #dados~=3) then return nil end
	for _,v in dados do if type(v)~="number" or v~=v or math.abs(v)==math.huge then return nil end end
	if dados[3] and (dados[3]<0 or dados[3]>4) then return nil end
	return dados
end

function MovimentoMinerio.TempoVisual(estado,dados,agora)
	if not dados[3] then return dados[2]+math.max(0,agora-dados[1]) end
	-- Atraso de rede nao permite adiantar indefinidamente nem fazer o relogio visual voltar.
	if estado.Amostra and dados[1]<estado.Amostra[1] then dados=estado.Amostra end
	estado.Amostra=dados
	local alvo=dados[2]+math.min(.15,math.clamp(agora-dados[1],0,.25)*dados[3])
	local exibido=estado.Exibido
	if not exibido then exibido=alvo
	else
		local erro=math.max(0,alvo-exibido)
		local velocidade=math.clamp(dados[3]+erro*8,0,math.max(1,dados[3])*2)
		exibido+=math.min(erro,math.max(0,agora-estado.Agora)*velocidade)
	end
	estado.Exibido,estado.Agora=exibido,agora
	return exibido
end

function MovimentoMinerio.Codificar(pose: CFrame, velocidade: Vector3, inicio: number, aceleracao, angular, duracao)
	local valores = {pose:GetComponents()}
	table.insert(valores,velocidade.X); table.insert(valores,velocidade.Y); table.insert(valores,velocidade.Z)
	table.insert(valores,inicio)
	if aceleracao then
		for _,v in {aceleracao,angular} do
			table.insert(valores,v.X); table.insert(valores,v.Y); table.insert(valores,v.Z)
		end
		table.insert(valores,duracao)
	end
	return HttpService:JSONEncode(valores)
end

function MovimentoMinerio.Decodificar(texto)
	if type(texto)~="string" then return nil end
	local ok, valores = pcall(HttpService.JSONDecode,HttpService,texto)
	if not ok or type(valores)~="table" or (#valores~=16 and #valores~=23) then return nil end
	for _, valor in valores do if type(valor)~="number" or valor~=valor or math.abs(valor)==math.huge then return nil end end
	if #valores==23 and valores[23]<0 then return nil end
	return {Origem=CFrame.new(table.unpack(valores,1,12)),Velocidade=Vector3.new(valores[13],valores[14],valores[15]),Inicio=valores[16],
		Aceleracao=if #valores==23 then Vector3.new(valores[17],valores[18],valores[19]) else Vector3.zero,
		Angular=if #valores==23 then Vector3.new(valores[20],valores[21],valores[22]) else Vector3.zero,
		Duracao=if #valores==23 then valores[23] else 0, Suave=#valores==23}
end

function MovimentoMinerio.Avaliar(movimento, tempo)
	local t=math.max(0,tempo-movimento.Inicio)
	if movimento.Duracao>0 then t=math.min(t,movimento.Duracao) end
	local pose=movimento.Origem+movimento.Velocidade*t
	local velocidade=movimento.Velocidade
	if movimento.Aceleracao~=Vector3.zero then
		pose+=movimento.Aceleracao*(t*t/2)
		velocidade+=movimento.Aceleracao*t
	end
	if movimento.Angular~=Vector3.zero then
		local a=movimento.Angular
		pose=CFrame.fromAxisAngle(a.Unit,a.Magnitude*t)*movimento.Origem.Rotation+pose.Position
	end
	return pose,velocidade
end

return MovimentoMinerio
