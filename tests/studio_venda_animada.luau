-- Executar na barra de comandos do Studio; carteira e cena isoladas.
task.spawn(function()
	local S = game.ServerScriptService
	local C = game.StarterPlayer.StarterPlayerScripts.Client
	local function novo(modulo)
		local clone = modulo:Clone()
		clone.Name, clone.Parent = "__Teste_" .. modulo.Name, modulo.Parent
		local resultado = require(clone)
		clone:Destroy()
		return resultado
	end
	local raiz = Instance.new("Model", workspace)
	raiz.Name = "TesteVendaAnimada"
	raiz:SetAttribute("DonoUserId", 987654)
	raiz:SetAttribute("TerrenoId", 987654)
	local pasta = Instance.new("Folder", raiz); pasta.Name = "Minerios"
	local hud, vendedor
	local ok, erro = xpcall(function()
		local ficha = novo(C.FichaMaquina).Descrever(require(game.ReplicatedStorage.Shared.CatalogoMaquinas).PrensaMinerio)
		assert(ficha:find("Modificação: ×2", 1, true) and ficha:find("Limite: $100", 1, true))
		assert(not ficha:find("passagem") and not ficha:find("valor"))
		local jogador = {SetAttribute = function(self, k, v) self[k] = v end}
		local perfil = {Data = {Dinheiro = "0"}, IsActive = function() return true end}
		local dados = novo(S.Data.DadosJogador).new(jogador, perfil)
		local minerio = novo(S.Minerio).Criar({Valor="25", Tamanho={.75,.75,.75}}, workspace.CurrentCamera.CFrame*CFrame.new(0,0,-10), raiz)
		local modelo = Instance.new("Model", raiz)
		local maquina = {ObterModelo=function() return modelo end, EstaNoTerreno=function() return true end,
			ObterTerreno=function() return raiz end, ObterDadosDono=function() return dados end, ObterSimulacao=function() return nil end}
		vendedor = novo(S.Componentes.VendedorMinerio).new(maquina, {Sensor="Sensor", Multiplicador="2"})
		vendedor:Receber(minerio); vendedor:Receber(minerio)
		local parte = minerio:ObterParte()
		assert(perfil.Data.Dinheiro=="50" and parte.Parent and parte:GetAttribute("Vendido"))
		local sim = novo(S.SimulacaoMinerios).new()
		sim:RegistrarMinerio(minerio,nil,{})
		sim:Avancar(1/120)
		assert(#sim._minerios==0 and parte.Parent and perfil.Data.Dinheiro=="50")
		local visual = setmetatable({_vendas={},_movimentos={},_grupos={},_ocultos={},_etiquetas={}},novo(C.MineriosVisuais))
		visual:_AnimarVenda(parte); visual:_AnimarVenda(parte)
		local efeito = assert(workspace:FindFirstChild("VendaMinerio"))
		task.wait(.1)
		assert(efeito.Size.X<.75 and efeito.Transparency>0 and efeito.Transparency<1,"Tween nao progrediu")
		dados:PublicarGanhosPorSegundo(1)
		assert(jogador.GanhosPorSegundo=="50")
		hud = novo(C.PainelMoedas).new(game:GetService("CoreGui"))
		hud:AtualizarDinheiro("250000000000000000000000000000000000"); hud:AtualizarTaxa("12500")
		assert(hud._valores.Dinheiro.Text=="250De" and hud._taxa.Text=="+$12,5K/s")
		task.wait(.4)
		assert(not efeito.Parent and not parte.Parent)
		print("VENDA_ANIMADA_STUDIO_OK", "ficha, credito unico, remocao da fisica, Tween, limpeza, saldo e receita")
	end,debug.traceback)
	if hud then hud:Destruir() end
	if vendedor then vendedor:Destruir() end
	raiz:Destroy()
	assert(ok,erro)
end)
