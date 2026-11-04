-- Executar na Command Bar em edicao. A cena temporaria nao acessa perfis nem altera as plots.
do
	assert(not game:GetService("RunService"):IsRunning(), "Encerre o Play antes do teste de carga.")
	local S = game:GetService("ServerScriptService")
	local copias = Instance.new("Folder"); copias.Name = "ModulosTesteCarga"; copias.Parent = S
	local corpo = game.ReplicatedStorage.Shared.CorpoRigido:Clone(); corpo.Parent = copias
	local modulo = S.SimulacaoMinerios:Clone(); modulo.Parent = copias
	modulo.Source = modulo.Source:gsub("require%(ReplicatedStorage.Shared.CorpoRigido%)", "require(script.Parent.CorpoRigido)")
	local Simulacao = require(modulo)
	local Minerio = require(S.Minerio)
	local raiz = Instance.new("Folder"); raiz.Name = "TesteCargaMinerios"; raiz.Parent = workspace
	local terreno = Instance.new("Model"); terreno.Parent = raiz
	terreno:SetAttribute("DonoUserId", 987654); terreno:SetAttribute("TerrenoId", 987654)
	for _, nome in { "Maquinas", "Minerios" } do local p = Instance.new("Folder"); p.Name = nome; p.Parent = terreno end
	local correia = Instance.new("Part")
	correia.Name, correia.Size, correia.CFrame = "Correia", Vector3.new(48, 1, 48), CFrame.new(0, 999.5, 0)
	correia.Anchored, correia.Parent = true, terreno.Maquinas
	local sim
	local ok, erro = xpcall(function()
		for _, quantidade in { 100, 1000, 5000 } do
			for _, velocidade in { 0, 6 } do
				sim = Simulacao.new()
				sim:RegistrarTransportador({ EstaAtivo = function() return true end }, correia, Vector3.zAxis * velocidade)
				for i = 1, quantidade do
					local pos = Vector3.new((i % 80) * .5 - 20, 1000.3751, (math.floor(i / 80) % 80) * .5 - 20)
					local m = Minerio.Criar({ Valor = "5", Tamanho = { .75, .75, .75 } }, CFrame.new(pos), terreno)
					sim:RegistrarMinerio(m, 120, {})
					sim._minerios[i].Corpo.Velocidade = Vector3.zAxis * velocidade
				end
				local soma, maior, estabilizado = 0, 0, 0
				for passo = 1, 12 do
					local inicio = os.clock()
					sim:Avancar(1 / 120)
					local custo = os.clock() - inicio
					soma += custo; maior = math.max(maior, custo)
					if passo > 6 then estabilizado += custo end
					task.wait()
				end
				assert(#sim._minerios == quantidade and #terreno.Minerios:GetChildren() == quantidade)
				local apoiados = 0
				for _, r in sim._minerios do if r.Corpo._apoio then apoiados += 1 end end
				print("CARGA_MINERIOS", quantidade, velocidade, "media_ms", soma / 12 * 1000, "max_ms", maior * 1000,
					"estavel_ms", estabilizado/6*1000, "apoiados", apoiados)
				sim:Destruir(); sim = nil
				task.wait()
			end
		end
	end, debug.traceback)
	if sim then sim:Destruir() end
	raiz:Destroy()
	copias:Destroy()
	assert(ok, erro)
	print("CARGA_MINERIOS_CONCLUIDA")
end
