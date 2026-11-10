local r = require("./suporte/modelos")
local CF,V = r.CFrame,r.Vector3
local function sinal()
	local self={conexoes={}}
	function self:Connect(callback)
		local c={callback=callback,ativa=true}
		function c:Disconnect() self.ativa=false end
		table.insert(self.conexoes,c); return c
	end
	function self:Fire(...) for _, c in self.conexoes do if c.ativa then c.callback(...) end end end
	function self:Contar() local n=0; for _,c in self.conexoes do if c.ativa then n+=1 end end; return n end
	return self
end
local quadro=sinal()
local dispararQuadro=quadro.Fire
function quadro:Fire() dispararQuadro(self,1/60) end
local mundo={DescendantAdded=sinal(),DescendantRemoving=sinal(),partes={},agora=10,lotes=0}
local camera={CFrame=CF.new(0,0,100),FieldOfView=70,ViewportSize=r.Vector2.new(1280,720)}
function camera:GetRenderCFrame() return self.CFrame end
mundo.CurrentCamera=camera
function mundo:GetDescendants() return self.partes end
function mundo:GetServerTimeNow() return self.agora end
function mundo:BulkMoveTo(partes,poses)
	self.lotes+=1; self.ultimoLote=#partes; for i,p in partes do p.CFrame=poses[i] end
end
local function parte(terreno)
	terreno = terreno or {GetAttribute=function() return "[10,10]" end}
	local p={Name="Minerio",Parent={Name="Minerios",Parent=terreno},CFrame=CF.identity,eventos=sinal(),atributos={},
		Size=V.one*.75,LocalTransparencyModifier=0,AncestryChanged=sinal(),tamanho=sinal()}
	function p:IsA(tipo) return tipo=="BasePart" end
	function p:GetAttribute(nome) return self.atributos[nome] end
	function p:GetAttributeChangedSignal() return self.eventos end
	function p:GetPropertyChangedSignal() return self.tamanho end
	function p:SetAttribute(nome,valor) self.atributos[nome]=valor; self.eventos:Fire() end
	return p
end
local function objeto()
	local item={_filhos={}}
	function item:Destroy() self.destruido=true end
	function item:FindFirstChildOfClass() return self._filhos[1] end
	return setmetatable(item,{__newindex=function(self,chave,valor)
		rawset(self,chave,valor)
		if chave=="Parent" and valor and valor._filhos then table.insert(valor._filhos,self) end
	end})
end
local animacoes={}
local carregar=require("./suporte/carregador")({workspace=mundo,CFrame=CF,Vector3=V,Enum=r.Enum,
	Instance={new=objeto},UDim2=r.UDim2,Color3=r.Color3,TweenInfo={new=function(tempo) return tempo end}},
	{RunService={RenderStepped=quadro},TweenService={Create=function(_,parte,tempo,alvo)
		table.insert(animacoes,{Parte=parte,Tempo=tempo,Alvo=alvo}); return {Play=function() end}
	end}})
local Movimento=carregar("src/shared/MovimentoMinerio")
local Visuais=carregar("src/client/MineriosVisuais")
local ouvintesDoMonitor=quadro:Contar()
assert(not Movimento.Decodificar(nil) and not Movimento.Decodificar("x") and not Movimento.Decodificar("[]"))
local a=parte(); table.insert(mundo.partes,a)
local origem=CF.new(1,2,3)*CF.Angles(.1,.2,.3)
a:SetAttribute("MovimentoMinerio",Movimento.Codificar(origem,V.new(0,0,6),10))
local visual=Visuais.new()
a:SetAttribute("Valor","2500000")
assert(visual._etiquetas[a]._filhos[1].Text=="$2,5M")
a:SetAttribute("Valor","5000000")
assert(visual._etiquetas[a]._filhos[1].Text=="$5M")
visual:_Ocultar(a,true); assert(not visual._etiquetas[a].Enabled)
visual:_Ocultar(a,false); assert(visual._etiquetas[a].Enabled)
mundo.agora=12; quadro:Fire()
assert((a.CFrame.Position-(origem.Position+V.new(0,0,12))).Magnitude<.00001)
assert(a.CFrame.Rotation==origem.Rotation and mundo.lotes==1)
a:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(20,2,3),V.new(-6,0,0),12))
mundo.agora=12.5; quadro:Fire(); assert(a.CFrame.Position==V.new(17,2,3))
-- Uma publicacao futura nao deve fazer o cliente retroceder antes da origem.
mundo.agora=11; quadro:Fire(); assert(a.CFrame.Position==V.new(20,2,3))
a:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(30,0,0),V.zero,12.5))
quadro:Fire(); assert(a.CFrame.Position==V.new(30,0,0) and not visual._movimentos[a])
a:SetAttribute("MovimentoMinerio",nil)
a.CFrame=CF.new(99,0,0); quadro:Fire(); assert(a.CFrame.Position.X==99)
local b=parte(); b.CFrame=CF.new(50,0,0)
b:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(40,0,0),V.zero,10))
mundo.DescendantAdded:Fire(b); quadro:Fire()
assert(b.eventos:Contar()==3 and b.CFrame.Position.X==50,"Entrada tardia deve preservar a pose dinamica mais recente.")
mundo.DescendantRemoving:Fire(a); assert(a.eventos:Contar()==0 and not visual._observados[a])
visual:Destruir()
assert(b.eventos:Contar()==0 and quadro:Contar()==ouvintesDoMonitor and mundo.DescendantAdded:Contar()==0 and mundo.DescendantRemoving:Contar()==0)
print("PASS: movimento visual sincronizado, troca de direcao, parada, entrada/saida e limpeza das conexoes.")

table.clear(mundo.partes)
camera.CFrame=CF.identity
local frente={GetAttribute=function() return "[10,10]" end}
local tras={GetAttribute=function() return "[10,10]" end}
for _, terreno in {frente,tras} do
	for i=1,2500 do
		local p=parte(terreno)
		local z=terreno==frente and -30 or 30
		p:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new((i%10)*.01,0,z),V.new(.1,0,0),10))
		table.insert(mundo.partes,p)
	end
end
visual=Visuais.new()
mundo.agora=10; quadro:Fire()
assert(mundo.ultimoLote==2500 and #visual._partes==2500,"So a plot enquadrada deve entrar no lote.")
local suspenso=mundo.partes[2501]
assert(suspenso.LocalTransparencyModifier==1,"Poses antigas de plots suspensas nao podem aparecer como minerios congelados.")
local grupo=visual._grupos[tras]
local limites=grupo.Minimo
local calculos=0
for _=1,120 do mundo.agora+=1/60; quadro:Fire(); calculos+=#visual._poses end
assert(calculos==300000 and grupo.Minimo==limites,"120 quadros devem calcular 2500 poses, sem refazer os limites estaveis.")
camera.CFrame=CF.Angles(0,math.pi,0)
quadro:Fire()
assert(#visual._partes==2500 and suspenso.LocalTransparencyModifier==0)
assert((suspenso.CFrame.Position-V.new(.21,0,30)).Magnitude<.00001,"Retomar deve usar o tempo atual, sem reproduzir quadros atrasados.")
assert(mundo.partes[1].LocalTransparencyModifier==1)
suspenso:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(2,0,30),V.zero,mundo.agora))
assert(suspenso.CFrame.Position==V.new(2,0,30) and not visual._movimentos[suspenso] and suspenso.LocalTransparencyModifier==0)
local removido=mundo.partes[1]
removido.LocalTransparencyModifier=1
mundo.DescendantRemoving:Fire(removido)
assert(removido.LocalTransparencyModifier==0 and removido.AncestryChanged:Contar()==0 and removido.tamanho:Contar()==0)
visual:Destruir()
assert(not next(visual._grupos) and not next(visual._ocultos))
for _, p in mundo.partes do assert(p.LocalTransparencyModifier==0 and p.eventos:Contar()==0 and p.tamanho:Contar()==0 and p.AncestryChanged:Contar()==0) end
print("PASS: 5000 minerios/duas plots: 2500 poses por quadro; 300000 em 120 quadros contra 600000; retomada, parada oculta e limpeza.")

table.clear(mundo.partes)
local p=parte(frente)
p.LocalTransparencyModifier=.35
p:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(12,0,-10),V.new(-1.5,0,0),10))
table.insert(mundo.partes,p)
visual=Visuais.new(); mundo.agora=10
camera.CFrame=CF.identity; camera.FieldOfView=90; camera.ViewportSize=r.Vector2.new(100,100)
quadro:Fire(); assert(#visual._partes==0 and p.LocalTransparencyModifier==1)
mundo.agora=12; quadro:Fire()
assert(#visual._partes==1 and p.CFrame.Position==V.new(9,0,-10) and p.LocalTransparencyModifier==.35,"Movimento de uma plot oculta pode entrar na camera sem mudar o atributo.")
p:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(10.4,0,-10),V.new(.01,0,0),12))
quadro:Fire(); assert(#visual._partes==1,"Intersecao parcial na borda deve permanecer visivel.")
p:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(0,10.4,-10),V.new(.01,0,0),12))
quadro:Fire(); assert(#visual._partes==1,"Borda vertical tambem deve considerar o tamanho.")
camera.ViewportSize=r.Vector2.new(100,50); camera.FieldOfView=60
quadro:Fire(); assert(#visual._partes==0)
p.Size=V.one*20; p.tamanho:Fire()
quadro:Fire(); assert(p.LocalTransparencyModifier==.35,"Redimensionar o minerio deve invalidar os limites.")
p.Size=V.one*.75; p.tamanho:Fire()
p:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(0,0,0),V.new(.01,0,0),12))
quadro:Fire(); assert(#visual._partes==1,"Camera dentro do volume nao pode descartar o grupo.")
p:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(0,0,10),V.new(.01,0,0),12))
quadro:Fire(); assert(#visual._partes==0)
p.Parent={Name="Minerios",Parent=tras}; p.AncestryChanged:Fire()
assert(not visual._grupos[frente] and visual._grupos[tras],"Trocar de plot deve retirar o grupo antigo.")
camera.CFrame=CF.Angles(0,math.pi,0)
quadro:Fire(); assert(#visual._partes==1 and p.LocalTransparencyModifier==.35)
p:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(0,0,10),V.new(1,0,0),20))
mundo.agora=15; quadro:Fire(); assert(p.CFrame.Position==V.new(0,0,10))
mundo.agora=21; quadro:Fire(); assert(p.CFrame.Position==V.new(1,0,10))
mundo.agora=11; quadro:Fire(); assert(p.CFrame.Position==V.new(0,0,10),"Recuo do relogio deve reconstruir os limites.")
mundo.CurrentCamera=nil; quadro:Fire(); assert(#visual._partes==0)
mundo.CurrentCamera=camera; camera.ViewportSize=r.Vector2.zero; quadro:Fire(); assert(#visual._partes==0)
camera.ViewportSize=r.Vector2.new(50,100); quadro:Fire()
assert(p.LocalTransparencyModifier==.35,"Recuperar o viewport mantém o minério visível sem reenviar a mesma pose.")
camera.CFrame=CF.identity; quadro:Fire(); assert(p.LocalTransparencyModifier==1)
p:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(0,0,12),V.zero,12))
assert(p.CFrame.Position==V.new(0,0,12) and p.LocalTransparencyModifier==.35)
p:SetAttribute("Vendido",true)
assert(#animacoes==1 and animacoes[1].Tempo==.25 and animacoes[1].Alvo.Transparency==1 and p.LocalTransparencyModifier==1)
p:SetAttribute("Vendido",true); assert(#animacoes==1,"A venda nao deve animar duas vezes.")
visual:Destruir()
assert(not next(visual._movimentos) and not next(visual._observados) and not next(visual._etiquetas))
print("PASS: bordas, tamanho, entrada automatica no campo de visao, transferencia, camera ausente, viewport, relogio futuro/regressivo e transparencia preservada.")

table.clear(mundo.partes)
local preferencias,eventos={},{}
local jogador={}
function jogador:GetAttribute(id) return preferencias[id] end
function jogador:GetAttributeChangedSignal(id) eventos[id]=eventos[id] or sinal(); return eventos[id] end
function jogador:SetAttribute(id,valor) preferencias[id]=valor; self:GetAttributeChangedSignal(id):Fire() end
local primeiro=parte(); table.insert(mundo.partes,primeiro)
visual=Visuais.new(jogador)
jogador:SetAttribute("TamanhoValores",24)
assert(visual._etiquetas[primeiro].Size.X.Offset==168 and visual._etiquetas[primeiro].Size.Y.Offset==32)
jogador:SetAttribute("MostrarValoresMinerios",false)
visual:_Ocultar(primeiro,false); assert(not visual._etiquetas[primeiro].Enabled)
local segundo=parte(); mundo.DescendantAdded:Fire(segundo)
assert(not visual._etiquetas[segundo].Enabled,"Novos minerios devem respeitar a preferencia.")
visual:_Ocultar(primeiro,true)
jogador:SetAttribute("MostrarValoresMinerios",true)
assert(not visual._etiquetas[primeiro].Enabled and visual._etiquetas[segundo].Enabled)
jogador:SetAttribute("AnimarVendaMinerios",false)
local antes=#animacoes
segundo:SetAttribute("Vendido",true)
assert(#animacoes==antes and segundo.LocalTransparencyModifier==1)
jogador:SetAttribute("AnimarVendaMinerios",true)
local terceiro=parte(); mundo.DescendantAdded:Fire(terceiro); terceiro:SetAttribute("Vendido",true)
assert(#animacoes==antes+1)
visual:Destruir()
for _,evento in eventos do assert(evento:Contar()==0) end
print("PASS: preferencias locais afetam etiquetas atuais/novas, respeitam ocultacao e ligam/desligam a animacao sem alterar a venda.")
local sinaisJogador={}
local atributosJogador={LimiteMineriosVisiveis=100}
local jogador={UserId=42}
function jogador:GetAttribute(id) return atributosJogador[id] end
function jogador:GetAttributeChangedSignal(id) sinaisJogador[id]=sinaisJogador[id] or sinal(); return sinaisJogador[id] end
function jogador:SetAttribute(id,v) atributosJogador[id]=v; self:GetAttributeChangedSignal(id):Fire() end
local terrenoA={GetAttribute=function(_,id) return id=='DonoUserId' and 42 or '[10,10]' end}
local terrenoB={GetAttribute=function(_,id) return id=='DonoUserId' and 99 or '[10,10]' end}
mundo.partes={}
for i=1,102 do local p=parte(i<=101 and terrenoA or terrenoB); p.atributos.Valor='10'; table.insert(mundo.partes,p) end
local limite=Visuais.new(jogador)
assert(mundo.partes[100].LocalTransparencyModifier==0 and mundo.partes[101].LocalTransparencyModifier==1 and mundo.partes[102].LocalTransparencyModifier==0)
jogador:SetAttribute('LimiteMineriosVisiveis',0)
for _,p in mundo.partes do assert(p.LocalTransparencyModifier==1 and not limite._etiquetas[p].Enabled and p.atributos.Valor=='10') end
jogador:SetAttribute('LimiteMineriosVisiveis',5000)
for _,p in mundo.partes do assert(p.LocalTransparencyModifier==0 and p.atributos.Valor=='10') end
jogador:SetAttribute('LimiteMineriosVisiveis',100)
local p=mundo.partes[1]; p.Parent=nil; limite:_Remover(p)
assert(mundo.partes[101].LocalTransparencyModifier==0,'Uma vaga liberada deve mostrar outro minerio')
limite:Destruir()
for _,e in sinaisJogador do assert(e:Contar()==0) end
print('LIMITE_VISUAL_OK: limite por plot, zero, restauracao, reposicao de vaga e valor dos minerios preservado.')

do
	local plot = r.Instance.new("Model")
	local piso = r.Instance.new("Part")
	piso.CFrame, piso.Parent = CF.new(0,0,-400), plot
	plot:SetAttribute("DonoUserId", 99)
	plot:SetAttribute("RelogioMinerios", "[10,10,1]")
	local comSombra, semSombra = parte(plot), parte(plot)
	comSombra.CastShadow, semSombra.CastShadow = true, false
	comSombra:SetAttribute("MovimentoMinerio",Movimento.Codificar(CF.new(0,0,-400),V.xAxis,10))
	mundo.partes = {comSombra, semSombra}
	camera.CFrame = CF.identity
	jogador:SetAttribute("MineriosOutrasPlots",true)
	jogador:SetAttribute("LimiteMineriosVisiveis",100)
	jogador:SetAttribute("MostrarValoresMinerios","Oculto")
	jogador:SetAttribute("LODPlots","Máximo")
	local lod = Visuais.new(jogador)
	mundo.agora=10.1
	quadro:Fire()
	local etiqueta = lod._etiquetas[comSombra]
	assert(not etiqueta.Enabled and not comSombra.CastShadow)
	assert(lod._terrenoAtivoNoQuadro[plot]==false and lod._grupos[plot].EstadoRelogio.Exibido==10.1,
		"O relógio precisa avançar mesmo nos quadros em que o LOD pula o movimento.")
	jogador:SetAttribute("MostrarValoresMinerios","Perto")
	jogador:SetAttribute("DistanciaValores",15)
	quadro:Fire()
	assert(not etiqueta.Enabled, "O perfil máximo suprime etiquetas da plot distante.")
	camera.CFrame = CF.new(0,0,-390)
	quadro:Fire()
	assert(etiqueta.Enabled and etiqueta.MaxDistance==15, "O LOD não pode aumentar a distância escolhida.")
	jogador:SetAttribute("MostrarValoresMinerios","Oculto")
	jogador:SetAttribute("LODPlots","Desativado")
	quadro:Fire()
	assert(not etiqueta.Enabled and comSombra.CastShadow and not semSombra.CastShadow,
		"Desativar LOD restaura somente as sombras que ele suprimiu, sem reativar etiquetas ocultas.")
	jogador:SetAttribute("MostrarValoresMinerios","Perto")
	assert(etiqueta.Enabled and etiqueta.MaxDistance==15)
	jogador:SetAttribute("MineriosOutrasPlots",false)
	quadro:Fire()
	assert(not etiqueta.Enabled and comSombra.LocalTransparencyModifier==1)
	lod:Destruir()
	plot:Destroy()
end
print("LOD_OK: preferências, distância, visibilidade de vizinhos e sombras preservadas.")

table.clear(mundo.partes)
mundo.agora=10
camera.CFrame=CF.new(0,0,40); camera.FieldOfView=90; camera.ViewportSize=r.Vector2.new(100,100)
local dinamico=parte(frente)
dinamico.CFrame=CF.new(0,8,-10)
local queda=Movimento.Codificar(dinamico.CFrame,V.new(0,-2,6),10,V.new(0,-196.2,0),V.new(0,2,0),.25)
dinamico:SetAttribute('MovimentoMinerio',queda)
table.insert(mundo.partes,dinamico)
visual=Visuais.new(); quadro:Fire()
for i=1,5 do
	mundo.agora=10+i/60; quadro:Fire()
	local esperado=Movimento.Avaliar(Movimento.Decodificar(queda),mundo.agora)
	assert((dinamico.CFrame.Position-esperado.Position).Magnitude<.00001)
	assert(dinamico.CFrame.LookVector:Dot(esperado.LookVector)>.99999)
end
local antes=dinamico.CFrame
local estado=Movimento.Decodificar(queda)
local _,velocidade=Movimento.Avaliar(estado,mundo.agora)
local nova=antes+V.new(.2,.1,0)
-- A CFrame replicada pode chegar antes do atributo; o ultimo quadro exibido deve ser conservado.
dinamico.CFrame=nova
dinamico:SetAttribute('MovimentoMinerio',Movimento.Codificar(nova,velocidade,mundo.agora,V.zero,V.new(0,2,0),.25))
dinamico:SetAttribute('MovimentoMinerio',Movimento.Codificar(nova,velocidade,mundo.agora,V.zero,V.new(0,2,0),.25))
quadro:Fire()
assert((dinamico.CFrame.Position-antes.Position).Magnitude<.00001,'Nao pode saltar ao receber uma correcao nem perder o ultimo quadro em atualizacoes agrupadas.')
local inicio=mundo.agora
for i=1,8 do mundo.agora=inicio+i/60; quadro:Fire() end
local previsto=Movimento.Avaliar(visual._movimentos[dinamico],mundo.agora)
assert((dinamico.CFrame.Position-previsto.Position).Magnitude<.00001,'A correcao visual precisa convergir ao estado autorizado.')
local limitado=Movimento.Decodificar(queda)
assert(Movimento.Avaliar(limitado,11)==Movimento.Avaliar(limitado,10.25),'Queda sem novas amostras nao pode ser prevista indefinidamente.')
assert(not Movimento.Decodificar(Movimento.Codificar(CF.identity,V.zero,0,V.zero,V.zero,-1)))
visual:Destruir()

table.clear(mundo.partes); mundo.agora=10; camera.CFrame=CF.identity
local entrando=parte(frente)
entrando:SetAttribute('MovimentoMinerio',Movimento.Codificar(CF.new(0,14,-10),V.zero,10,V.new(0,-196.2,0),V.zero,.25))
table.insert(mundo.partes,entrando)
visual=Visuais.new(); quadro:Fire()
assert(entrando.LocalTransparencyModifier==1)
mundo.agora=10.2; quadro:Fire()
assert(#visual._partes==1 and entrando.LocalTransparencyModifier==0,'Queda deve entrar no enquadramento mesmo sem receber outro atributo.')
visual:Destruir()
print('TRANSICOES_VISUAIS_OK: queda e giro por quadro, correcoes agrupadas sem salto, convergencia, previsao limitada e enquadramento de trajetoria acelerada.')

table.clear(mundo.partes); mundo.agora=10; camera.CFrame=CF.identity
local relogio='[10,10,1]'
local plotLenta={GetAttribute=function() return relogio end}
local continuo=parte(plotLenta)
continuo:SetAttribute('MovimentoMinerio',Movimento.Codificar(CF.new(0,0,-30),V.new(6,0,0),10))
table.insert(mundo.partes,continuo)
visual=Visuais.new(); quadro:Fire()
local x=continuo.CFrame.Position.X
local grupoContinuo=visual._grupos[plotLenta]
for i=1,120 do
	mundo.agora=10+i/60
	local amostra=math.floor(i/12)*.2
	relogio=string.format('[%f,%f,0.5]',10+amostra,10+amostra*.5)
	quadro:Fire()
	assert(continuo.CFrame.Position.X>=x-.000001,'Atualizar o relogio de uma plot lenta nao pode recuar seus minerios.')
	x=continuo.CFrame.Position.X
end
continuo:SetAttribute('MovimentoMinerio',Movimento.Codificar(CF.new(6,0,-30),V.new(6,0,0),11,V.zero,V.zero,0))
assert(visual._grupos[plotLenta]==grupoContinuo,'Atualizar o unico minerio da plot deve preservar o relogio visual.')
local avaliar=Movimento.Avaliar
local avaliacoes=0
Movimento.Avaliar=function(...) avaliacoes+=1; return avaliar(...) end
quadro:Fire()
assert(avaliacoes==1,'Limites e desenho devem compartilhar a pose calculada no mesmo quadro.')
Movimento.Avaliar=avaliar
for i=1,240 do mundo.agora=12+i/60; quadro:Fire() end
assert(continuo.CFrame.Position.X<=6.9+.000001,'Sem amostras recentes a previsao precisa parar, sem atravessar a fabrica inteira.')
visual:Destruir()
print('ROLLBACK_VISUAL_OK: renderer real, servidor a meia velocidade e atualizacoes atrasadas; movimento monotono e previsao limitada.')
