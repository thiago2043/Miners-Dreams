local fs=require("@lune/fs")
local r=require("./suporte/modelos")
local V,CF,I=r.Vector3,r.CFrame,r.Instance
local mundo=I.new("Workspace")
local modelos=I.new("Folder")
require("./suporte/catalogo_modelos")(modelos)
local replicado={ModelosMaquinas=modelos}
function replicado:WaitForChild(nome) return assert(self[nome]) end
local Players={PlayerRemoving={Connect=function() end}}
local tempo=0
local carregar,no=require("./suporte/carregador")({
	workspace=mundo,Instance=I,Vector3=V,Vector2=r.Vector2,CFrame=CF,Color3=r.Color3,Enum=r.Enum,typeof=r.typeof,
	os={clock=function() tempo+=1; return tempo end},
},{Players=Players,ReplicatedStorage=replicado})
replicado.Shared=no("src/shared")
local Catalogo=carregar("src/shared/CatalogoMaquinas")
local Rotacao=carregar("src/shared/RotacaoConstrucao")
local Adaptar=carregar("src/shared/EsteiraInclinada")
local Personalizacao=carregar("src/shared/PersonalizacaoMaquina")
local Volume=carregar("src/shared/VolumeConstrucao")
local Corpo=carregar("src/shared/CorpoRigido")
local Arraste=carregar("src/client/RotacaoArraste")
local definicao=Catalogo.Esteira2x2
for _,angulo in {-math.pi/4,math.pi/4} do for giro=0,3 do
	local rot=CF.Angles(0,giro*math.pi/2,0)*CF.Angles(angulo,0,0)
	assert(Rotacao.ValidarNaGrade(rot,definicao))
	assert(not Rotacao.ValidarNaGrade(rot,Catalogo.MineradoraBasica))
	assert(not Rotacao.ValidarNaGrade(rot,Catalogo.PrensaMinerio))
	local base,a=Rotacao.DecomporEsteira(rot,definicao)
	assert(math.abs(a-angulo)<.001 and base.UpVector.Y==1)
end end
assert(not Rotacao.ValidarNaGrade(CF.Angles(0,math.pi/4,0),definicao))
assert(not Rotacao.ValidarNaGrade(CF.Angles(math.pi/8,0,0),definicao))
local gesto=Arraste.new(r.Vector2.zero,CF.identity,CF.identity,r.Vector2.zero,100,definicao)
gesto:Atualizar(r.Vector2.new(0,48))
local rotGesto=gesto:Atualizar(r.Vector2.new(0,49))
assert(math.abs(rotGesto.UpVector.Y-math.sqrt(.5))<.001)

local arquivos={"Esteira1x1","Esteira2x2","Centralizadora1x1","Centralizadora2x2"}
for _,id in arquivos do
	local original=modelos[id]
	local hitbox=original.HitboxConstrucao
	local def=Catalogo[id]
	for _,angulo in {-math.pi/4,math.pi/4} do
		local modelo=original:Clone()
		Adaptar.Aplicar(modelo,def,CF.Angles(angulo,0,0))
		assert(next(Personalizacao.new():Capturar(modelo,original):ObterDados())==nil,"A inclinacao nao e uma personalizacao permanente.")
		local caixa=modelo.HitboxConstrucao
		local esperado=V.new(hitbox.Size.X,hitbox.Size.Y+hitbox.Size.Z,hitbox.Size.Z)
		assert(caixa.Size==esperado)
		local _,ocupado=Volume.new(hitbox.Size,def.Blocos,def):Calcular(CF.Angles(angulo,0,0))
		assert(ocupado==esperado)
		for _,p in modelo:GetDescendants() do
			if not p:IsA("BasePart") or p==caixa then continue end
			for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
				local v=p.CFrame:PointToWorldSpace(p.Size*V.new(x,y,z)/2)
				assert(math.abs(v.X)<=esperado.X/2+.001 and math.abs(v.Z)<=esperado.Z/2+.001
					and v.Y>=-.001 and v.Y<=esperado.Y+.001,"Geometria fora da reserva: " .. id .. "/" .. p.Name .. " / " .. tostring(v))
			end end end
		end
		modelo:Destroy()
	end
end
print("PASS: quatro modelos inclinam nos dois sentidos, encaixam nas faces e voltam sem criar variantes.")

local terrenos=I.new("Folder"); terrenos.Name="Terrenos"; terrenos.Parent=mundo
local terreno=I.new("Model"); terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1); terreno.Parent=terrenos
local piso=I.new("Part"); piso.Name="Piso"; piso.Size=V.new(128,1,128); piso.Parent=terreno
local maquinas=I.new("Folder"); maquinas.Name="Maquinas"; maquinas.Parent=terreno
local jogador={Parent=Players,UserId=123,Name="Teste"}
function Players:GetPlayerByUserId(id) return id==jogador.UserId and jogador or nil end
local atributos={TerrenoId=1}
function jogador:GetAttribute(nome) return atributos[nome] end
function jogador:SetAttribute(nome,valor) atributos[nome]=valor end
local perfil={Data={Dinheiro="100000",Inventory={},MaquinasColocadas={},Blueprints={}}}
for id in Catalogo do perfil.Data.Inventory[id]=0 end
perfil.Data.Inventory.Esteira2x2=20
function perfil:IsActive() return true end
local manager=carregar("src/server/Data/DataManager")
manager.RegistrarPerfil(jogador,perfil)
local servico=carregar("src/server/ServicoConstrucao").new()
for _,angulo in {-math.pi/4,math.pi/4} do
	local pos=V.new(if angulo<0 then 0 else 15,0,0)
	assert(servico:Colocar(jogador,"Esteira2x2",pos,CF.Angles(angulo,0,0)))
end
assert(#maquinas:GetChildren()==2 and #perfil.Data.MaquinasColocadas==2)
local peca=maquinas:GetChildren()[1]
local ok,_,copia=servico:Copiar(jogador,peca)
assert(ok and next(copia.Modificacoes)==nil and Rotacao.ValidarNaGrade(copia.Rotacao,definicao))
assert(servico:Colocar(jogador,"Esteira2x2",V.new(30,0,0),copia.Rotacao,copia.Token))
local salvo=perfil.Data.MaquinasColocadas[1].Rotacao
assert(math.abs(CF.new(0,0,0,table.unpack(salvo)).UpVector.Y-math.sqrt(.5))<.001)
local movimentoOk,_,mov=servico:IniciarMovimento(jogador,{peca})
assert(movimentoOk)
assert(servico:Mover(jogador,mov,V.new(45,0,0),copia.Rotacao))
servico:Sincronizar(jogador)
for _,m in maquinas:GetChildren() do m:Destroy() end
local matriz={CF.Angles(-math.pi/4,0,0):GetComponents()}
table.insert(perfil.Data.MaquinasColocadas,{MaquinaId="Esteira2x2",Posicao={75,0,75},Rotacao={table.unpack(matriz,4,12)}})
local restaurado=carregar("src/server/ServicoConstrucao").new()
assert(restaurado:Restaurar(jogador) and #maquinas:GetChildren()==4)
local antigas=0
for _,m in maquinas:GetChildren() do
	if not m:GetAttribute("InclinacaoEsteira") then
		antigas+=1
		assert(m:GetAttribute("OrientacaoEsteiraLegada") and m.Correia.Size==modelos.Esteira2x2.Correia.Size)
	end
end
assert(antigas==1,"A geometria antiga precisa ser restaurada sem adaptacao automatica.")
local selecao={}
for _,m in maquinas:GetChildren() do if m:GetAttribute("InclinacaoEsteira") and #selecao<2 then table.insert(selecao,m) end end
local criou,mensagem,bp=restaurado:CriarBlueprint(jogador,"Esteiras inclinadas",selecao)
assert(criou,mensagem)
local preparou,_,grupo=restaurado:PrepararBlueprint(jogador,bp.Id)
assert(preparou)
assert(restaurado:ColocarGrupoCopia(jogador,grupo.Token,{
	{Minimo=V.new(0,30,30),Rotacao=grupo.Pecas[1].RotacaoInicial},
	{Minimo=V.new(15,30,30),Rotacao=grupo.Pecas[2].RotacaoInicial},
}))
local quantidade=#maquinas:GetChildren()
assert(restaurado:Recolher(jogador,selecao[1]) and #maquinas:GetChildren()==quantidade-1)
print("PASS: servidor coloca, copia, move, salva e restaura a esteira inclinada com dados reais dos servicos, fora do Studio.")

local Simulacao=carregar("src/server/SimulacaoMinerios")
local Maquina=carregar("src/server/Maquinas/Maquina")
local percursos=0
for _,id in arquivos do
	for _,angulo in {0,-math.pi/4,math.pi/4} do
		local modelo=modelos[id]:Clone()
		local tamanho=modelo.HitboxConstrucao.Size
		local def=Catalogo[id]
		Adaptar.Aplicar(modelo,def,CF.Angles(angulo,0,0))
		modelo.Parent=maquinas
		modelo:SetAttribute("DonoUserId",123); modelo:SetAttribute("TerrenoId",1)
		local sim=Simulacao.new()
		local maquina=Maquina.new(modelo,terreno,def,sim)
		maquina:Atualizar(0)
		local obstaculos={}
		for _,p in modelo:GetDescendants() do
			if p:IsA("BasePart") and p.CanCollide then
				local reg=sim._transportadores[p]
				table.insert(obstaculos,{CFrame=p.CFrame,Tamanho=p.Size,
					Velocidade=if reg then reg.Velocidade else V.zero,Atrito=if reg then reg.Atrito else nil,
					PriorizarTopo=reg and reg.PriorizarTopo,Centralizacao=reg and reg.Centralizacao})
			end
		end
		local h0=.9375+(if angulo>0 then tamanho.Z else 0)
		local h1=.9375+(if angulo<0 then tamanho.Z else 0)
		for _,v in {{-tamanho.Z/2-2,h0},{tamanho.Z/2+2,h1}} do
			table.insert(obstaculos,{CFrame=CF.new(0,v[2]-.125,v[1]),Tamanho=V.new(tamanho.X,.25,4),Velocidade=V.zAxis*6})
		end
		for _,x in (if id:find("Centralizadora") then {-.825,0,.825} else {0}) do
			local corpo=Corpo.new(CF.new(x,h0+.375,-tamanho.Z/2-.75),V.one*.75)
			local passou=false
			for passo=1,2400 do
				local candidatos={}
				for _,o in obstaculos do
					local p=o.CFrame:PointToObjectSpace(corpo.CFrame.Position)
					local h=o.Tamanho/2
					local proximo=V.new(math.clamp(p.X,-h.X,h.X),math.clamp(p.Y,-h.Y,h.Y),math.clamp(p.Z,-h.Z,h.Z))
					if (p-proximo).Magnitude<1.1 then table.insert(candidatos,o) end
				end
				corpo:Avancar(1/240,V.new(0,-196.2,0),candidatos)
				assert(corpo.CFrame.Position.Y>.5,"Perdeu apoio: " .. id .. " / " .. tostring(corpo.CFrame.Position))
				if corpo.CFrame.Position.Z>tamanho.Z/2+1 then
					local apoio=(math.abs(corpo.CFrame.RightVector.Y)+math.abs(corpo.CFrame.UpVector.Y)+math.abs(corpo.CFrame.LookVector.Y))*.375
					assert(math.abs(corpo.CFrame.Position.Y-h1-apoio)<.2,"Altura de saida: " .. id .. " / " .. tostring(corpo.CFrame.Position))
					-- O bloco pode tombar na juncao; o centro deve sair a menos de 0,1 bloco do eixo.
					if id:find("Centralizadora") then assert(math.abs(corpo.CFrame.Position.X)<.3,"Nao centralizou: " .. id .. " angulo=" .. angulo .. " inicio=" .. x .. " / " .. tostring(corpo.CFrame.Position)) end
					passou=true; break
				end
			end
			assert(passou,"Nao atravessou a inclinacao: " .. id .. " / " .. tostring(corpo.CFrame.Position))
			percursos+=1
		end
		maquina:Destruir(); modelo:Destroy()
	end
end
print("ESTEIRAS_INCLINADAS_OK",percursos,"percursos planos e entre inclinadas, com transporte real e solver local.")
