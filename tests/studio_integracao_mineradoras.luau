-- Command Bar da aba Servidor durante Play. Usa clones temporarios, sem comprar ou alterar perfis.
do
	local RunService = game:GetService("RunService")
	assert(RunService:IsStudio() and RunService:IsServer(), "Execute no servidor local do Studio durante Play.")
	local jogador = assert(game:GetService("Players"):GetPlayers()[1], "Jogador de teste ausente.")
	local servidor = game:GetService("ServerScriptService")
	local replicado = game:GetService("ReplicatedStorage")
	local catalogo = require(replicado.Shared.CatalogoMaquinas)
	local geometria = require(replicado.Shared.GeometriaColocacao)
	local Fabrica = require(servidor.Fabrica)
	local Maquina = require(servidor.Maquinas.Maquina)
	local pasta = Instance.new("Folder")
	pasta.Name, pasta.Parent = "VerificacaoMineradorasTemporaria", workspace
	local fabrica
	local sucesso, erro = pcall(function()
		local terreno = Instance.new("Model")
		terreno.Parent = pasta
		terreno:SetAttribute("DonoUserId", jogador.UserId); terreno:SetAttribute("TerrenoId", -1)
		for _, nome in { "Maquinas", "Minerios" } do
			local f = Instance.new("Folder")
			f.Name, f.Parent = nome, terreno
		end
		local modelos, geracoes, total = {}, {}, 0
		for id, definicao in catalogo do
			if not definicao.Componentes[1] or definicao.Componentes[1].Tipo ~= "Soltador" then continue end
			total += 1
			local modelo = replicado.ModelosMaquinas[id]:Clone()
			local caixa, tamanho = geometria.CaixaDeConstrucao(modelo)
			assert(tamanho == Vector3.new(table.unpack(definicao.Blocos)) * 3)
			modelo:PivotTo(CFrame.new(total * 80, 500, 500) * caixa:ToObjectSpace(modelo:GetPivot()))
			modelo:SetAttribute("DonoUserId", jogador.UserId); modelo:SetAttribute("TerrenoId", -1)
			modelo.Parent, modelos[id], geracoes[id] = terreno.Maquinas, modelo, {}
		end
		assert(total == 13 and #replicado.ModelosMaquinas:GetChildren() == 91)
		fabrica = Fabrica.new(pasta)
		for id, modelo in modelos do
			local maquina = Maquina.new(modelo, terreno, catalogo[id], fabrica._simulacao)
			-- A Command Bar testa a emissao com dono local, sem depender da sessao do ProfileStore.
			function maquina:ObterDadosDono() return {} end
			fabrica._maquinas[modelo] = maquina
		end
		-- Isola a emissao da queda: o registro e observado e o minerio de teste e consumido imediatamente.
		fabrica._simulacao.RegistrarMinerio = function(simulacao, minerio, vida, configuracao)
			local parte, encontrado = minerio:ObterParte(), false
			for id, modelo in modelos do
				local saida = modelo:FindFirstChild("SaidaMinerio", true)
				if (parte.CFrame.Position - saida.WorldCFrame.Position).Magnitude > .001 then continue end
				assert(parte:GetAttribute("Valor") == catalogo[id].Componentes[1].Minerio.Valor)
				assert(configuracao.Valor == parte:GetAttribute("Valor") and vida == nil)
				table.insert(geracoes[id], simulacao._tempo)
				encontrado = true
				break
			end
			assert(encontrado, "Minerio fora das saidas nativas.")
			minerio:Consumir()
		end
		for _ = 1, 360 do fabrica:Avancar(1 / 120) end
		local emissoes = 0
		for id, instantes in geracoes do
			local intervalo = catalogo[id].Componentes[1].Intervalo
			assert(#instantes == math.ceil((3 - 1 / 120) / intervalo), id .. ": quantidade incorreta")
			for i = 2, #instantes do assert(math.abs(instantes[i] - instantes[i - 1] - intervalo) < .00001) end
			emissoes += #instantes
		end
		print("STUDIO_13_MINERADORAS_OK", total, emissoes, "modelos, hitboxes, Attachments, valores e intervalos nativos")
	end)
	if fabrica then fabrica:Destruir() end
	pasta:Destroy()
	assert(sucesso, erro)
end
