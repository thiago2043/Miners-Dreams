-- Execute na Command Bar do servidor durante um teste do Studio.
-- A cena temporaria fica fora das plots; nenhum perfil ou inventario e alterado.
assert(game:GetService("RunService"):IsStudio(), "Use o Roblox Studio.")
assert(game:GetService("RunService"):IsServer(), "Selecione a aba Servidor.")
local Simulacao = require(game.ServerScriptService.SimulacaoMinerios)
local Minerio = require(game.ServerScriptService.Minerio)

local function simular(fps)
	local terreno = Instance.new("Model")
	terreno.Name = "VerificacaoFisicaTemporaria"
	terreno:SetAttribute("DonoUserId", -999)
	terreno:SetAttribute("TerrenoId", -999)
	for _, nome in { "Minerios", "Maquinas" } do
		local pasta = Instance.new("Folder")
		pasta.Name, pasta.Parent = nome, terreno
	end
	local piso = Instance.new("Part")
	piso.Name, piso.Anchored = "Piso", true
	piso.Size, piso.CFrame = Vector3.new(30, 1, 30), CFrame.new(10000, 99.5, 10000)
	piso.Parent, terreno.Parent = terreno, workspace
	local sim = Simulacao.new()
	local sucesso, resultado = pcall(function()
		local inicial = CFrame.new(10000, 107, 10000) * CFrame.Angles(0.2, 0.3, 0.1)
		for _ = 1, 2 do
			local minerio = Minerio.Criar({ Valor = "10", Tamanho = { 1, 1, 1 } }, inicial, terreno)
			sim:RegistrarMinerio(minerio, 12, { Elasticidade = 0.5 })
		end
		local a, b = sim._minerios[1].Corpo, sim._minerios[2].Corpo
		local trajetoria, quicou, girou, repouso = {}, false, false, nil
		for _ = 1, fps * 10 do
			sim:Avancar(1 / fps, function()
				assert(a.CFrame == b.CFrame and a.Velocidade == b.Velocidade
					and a.MomentoAngular == b.MomentoAngular, "Minerios interferiram entre si.")
				local valores = { a.CFrame:GetComponents() }
				for _, vetor in { a.Velocidade, a.MomentoAngular } do
					table.insert(valores, vetor.X); table.insert(valores, vetor.Y); table.insert(valores, vetor.Z)
				end
				table.insert(trajetoria, valores)
				quicou = quicou or a.Velocidade.Y > 1
				girou = girou or a:VelocidadeAngular().Magnitude > 0.1
				if sim._passos == 1080 then repouso = a.CFrame end
			end)
		end
		assert(sim._passos == 1200 and quicou and girou, "Passos, quicada ou giro invalidos.")
		assert(a.Velocidade == Vector3.zero and a.MomentoAngular == Vector3.zero,
			"O minerio continuou se movendo depois de apoiado.")
		assert(a.CFrame == repouso,
			"A pose continuou derivando no ultimo segundo.")
		return trajetoria
	end)
	sim:Destruir()
	terreno:Destroy()
	assert(sucesso, resultado)
	return resultado
end

local referencia = simular(120)
for _, fps in { 30, 60, 144 } do
	local comparacao = simular(fps)
	assert(#referencia == #comparacao)
	for i, etapa in referencia do
		for j, valor in etapa do
			assert(valor == comparacao[i][j], string.format("Divergencia em %d FPS, passo %d, campo %d", fps, i, j))
		end
	end
end
print("FISICA_STUDIO_PASS: 1200 estados identicos em 30/60/120/144 FPS; quicada, giro, repouso e minerios sem colisao entre si.")
