-- Verificacao manual opcional no cliente do Studio; apenas clona e mede a interface.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Use a aba Cliente durante um teste do Studio.")
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local original = playerGui:WaitForChild("InterfaceJogo")
-- Listas e fichas tem molduras fixas e areas internas rolaveis; as acoes das fichas nao rolam.
local function areaRolavel(painel)
	return painel:IsA("ScrollingFrame") and painel or painel:FindFirstChild("Informacoes") or painel:FindFirstChild("Pecas")
end
local function conteudoDe(painel)
	local area = assert(areaRolavel(painel), "Area rolavel ausente.")
	return assert(area:FindFirstChild("Conteudo") or area:FindFirstChild("Grade"))
end
local function estatisticasDe(grupo)
	local conteudo = conteudoDe(grupo.Ficha)
	return conteudo:FindFirstChild("Estatisticas") or conteudo.QuadroEstatisticas.Estatisticas
end
local teste = Instance.new("ScreenGui")
teste.Name, teste.DisplayOrder, teste.Parent = "VerificacaoPaineisTemporaria", 100, playerGui
local sucesso, mensagem = pcall(function()
	for _, tamanho in { Vector2.new(1366, 768), Vector2.new(320, 568), Vector2.new(568, 320) } do
		local quadro = Instance.new("Frame")
		quadro.Size, quadro.BackgroundTransparency, quadro.Parent = UDim2.fromOffset(tamanho.X, tamanho.Y), 1, teste
		local grupos, paineis = {}, {}
		for _, aba in { "Inventario", "Loja" } do
			local grupo = original[aba]:Clone()
			grupo.Parent = quadro
			grupos[aba] = grupo
			for _, nome in { "Lista", "Ficha" } do
				local painel = grupo[nome]
				painel.Visible = true
				table.insert(paineis, painel)
			end
			estatisticasDe(grupo).Text = "Peça de teste\nValor: 1" .. string.rep("0", 100)
				.. "\nTransporte: 13 studs/s\nIntervalo: 2 s"
		end
		for _, escala in { 1, 2 } do
			for _, grupo in grupos do estatisticasDe(grupo).TextSize = 16 * escala end
			for _ = 1, 4 do RunService.RenderStepped:Wait() end
			for _, painel in paineis do
				local conteudo = conteudoDe(painel)
				local layout = conteudo:FindFirstChildWhichIsA("UIListLayout") or conteudo:FindFirstChildWhichIsA("UIGridLayout")
				areaRolavel(painel).CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 16)
				assert(painel.AbsolutePosition.X >= quadro.AbsolutePosition.X
					and painel.AbsolutePosition.X + painel.AbsoluteSize.X <= quadro.AbsolutePosition.X + tamanho.X + 1,
					"Painel fora da tela.")
				local itens = {}
				for _, item in conteudo:GetChildren() do
					if item:IsA("GuiObject") and item.Visible then
						table.insert(itens, item)
						if item:IsA("TextLabel") or item:IsA("TextButton") then assert(item.TextFits, "Texto cortado: " .. item:GetFullName()) end
					end
				end
				if layout:IsA("UIListLayout") then
					table.sort(itens, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
					for i = 2, #itens do
						assert(itens[i].AbsolutePosition.Y >= itens[i - 1].AbsolutePosition.Y + itens[i - 1].AbsoluteSize.Y - 1, "Itens sobrepostos.")
					end
				end
			end
			local ordem = { grupos.Inventario.Lista, grupos.Inventario.Ficha, grupos.Loja.Ficha, grupos.Loja.Lista }
			for i = 2, #ordem do
				assert(ordem[i].AbsolutePosition.X >= ordem[i - 1].AbsolutePosition.X + ordem[i - 1].AbsoluteSize.X, "Paineis sobrepostos.")
			end
		end
		quadro:Destroy()
	end
end)
teste:Destroy()
assert(sucesso, mensagem)
print("PAINEIS_LAYOUT_PASS: quatro paineis simultaneos, tres resolucoes e estatisticas com fonte a 100%/200%.")
