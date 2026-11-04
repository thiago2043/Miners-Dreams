-- Command Bar do servidor no Play: jogador em tabela e carteira isolada, sem ProfileStore ou dados reais.
local Servico=require(game.ServerScriptService.ServicoConstrucao)
local Manager=require(game.ServerScriptService.Data.DataManager)
local jogador={Name="TesteColocacaoParcial",UserId=-20261028,Parent=game.Players,Atributos={TerrenoId=-20261028}}
function jogador:GetAttribute(nome) return self.Atributos[nome] end
function jogador:SetAttribute(nome,valor) self.Atributos[nome]=valor end
local perfil={Data={}}
function perfil:IsActive() return true end
Manager.RegistrarPerfil(jogador,perfil)
local plot=Instance.new("Model"); plot.Name="TesteColocacaoParcial"
plot:SetAttribute("DonoUserId",jogador.UserId); plot:SetAttribute("TerrenoId",jogador:GetAttribute("TerrenoId"))
local piso=Instance.new("Part"); piso.Name,piso.Size,piso.CFrame,piso.Anchored,piso.Parent="Piso",Vector3.new(48,1,48),CFrame.new(0,2000,0),true,plot
local maquinas=Instance.new("Folder"); maquinas.Name,maquinas.Parent="Maquinas",plot
plot.Parent=workspace.Terrenos
local servico
local ok,erro=xpcall(function()
	local function limpar(estoque,saldo)
		maquinas:ClearAllChildren()
		perfil.Data={Dinheiro=saldo or "0",Inventory={Parede1x1=estoque},InventarioPersonalizado={},MaquinasColocadas={},Blueprints={}}
		servico=Servico.new()
	end
	local function pedidos(...)
		local lista={}
		for _,x in {...} do table.insert(lista,{Minimo=Vector3.new(x,0,9),Rotacao=CFrame.identity}) end
		return lista
	end
	local function unidade(x)
		local sucesso,msg=servico:Colocar(jogador,"Parede1x1",Vector3.new(x,0,9),CFrame.identity)
		assert(sucesso,msg)
		for _,m in maquinas:GetChildren() do if m:GetAttribute("VolumeMinimo")==Vector3.new(x,0,9) then return m end end
	end
	limpar(1,"25")
	local sucesso,msg,criadas=servico:ColocarMultiplos(jogador,"Parede1x1",pedidos(9,12,15))
	assert(sucesso,msg); assert(#criadas==2 and perfil.Data.Dinheiro=="0" and perfil.Data.Inventory.Parede1x1==0)
	limpar(4)
	unidade(12)
	sucesso,msg,criadas=servico:ColocarMultiplos(jogador,"Parede1x1",pedidos(9,12,15))
	assert(sucesso,msg); assert(#criadas==2 and #perfil.Data.MaquinasColocadas==3 and perfil.Data.Inventory.Parede1x1==1)
	limpar(7)
	local fontes={unidade(0),unidade(3),unidade(6)}
	unidade(15)
	local capturou,_,captura=servico:CopiarGrupo(jogador,fontes); assert(capturou)
	sucesso,msg,criadas=servico:ColocarGrupoCopia(jogador,captura.Token,pedidos(12,15,18))
	assert(sucesso,msg); assert(#criadas==2)
	local salvou,_,blueprint=servico:CriarBlueprint(jogador,"Teste",fontes); assert(salvou)
	local preparou,_,pronto=servico:PrepararBlueprint(jogador,blueprint.Id); assert(preparou)
	sucesso,msg,criadas=servico:ColocarGrupoCopia(jogador,pronto.Token,pedidos(24,27,30))
	assert(sucesso,msg); assert(#criadas==1 and perfil.Data.Inventory.Parede1x1==0)
	limpar(0,"100")
	local fonte=unidade(0)
	local mudou,_,personalizada=servico:Personalizar(jogador,fonte,{Dados={Nivel=7}}); assert(mudou)
	local capturouUma,_,capturaUma=servico:CopiarGrupo(jogador,{personalizada}); assert(capturouUma)
	sucesso,msg,criadas=servico:ColocarMultiplos(jogador,"Parede1x1",pedidos(9,12,15),capturaUma.Token)
	assert(sucesso,msg); assert(#criadas==3 and perfil.Data.Dinheiro=="0" and personalizada.Parent==maquinas)
	local Personalizacao=require(game.ReplicatedStorage.Shared.PersonalizacaoMaquina)
	for _,m in criadas do assert(Personalizacao.DoModelo(m):ObterDados().Dados.Nivel==7) end
	limpar(4)
	fontes={unidade(0),unidade(3),unidade(6)}
	local iniciou,_,token=servico:IniciarMovimento(jogador,fontes); assert(iniciou)
	unidade(12)
	sucesso,msg,criadas=servico:MoverGrupo(jogador,token,pedidos(9,12,15))
	assert(sucesso,msg)
	assert(#criadas==2 and perfil.Data.Inventory.Parede1x1==1 and #perfil.Data.MaquinasColocadas==3 and not servico._movimentosPendentes[jogador])
	print("COLOCACAO_PARCIAL_STUDIO_OK","linha, estoque/saldo, obstaculo intermediario, copia, blueprint e movimento com devolucao; carteira isolada e modelos nativos.")
end,debug.traceback)
if servico then servico:LimparJogador(jogador) end
Manager.RemoverPerfil(jogador); plot:Destroy()
assert(ok,erro)
