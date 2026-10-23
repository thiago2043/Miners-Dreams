-- Verifica o desenho real do controlador com tipos locais; a orientacao do canvas foi medida no Studio.
local roblox = require("@lune/roblox")
local function sinal()
	local s = { callbacks = {} }
	function s:Connect(callback)
		table.insert(self.callbacks, callback)
		return { Disconnect = function() end }
	end
	function s:Fire(dt) for _, callback in self.callbacks do callback(dt) end end
	return s
end
local render, heartbeat = sinal(), sinal()
local mundo = { CurrentCamera = { CFrame = roblox.CFrame.new(50, 50, 50) } }
local carregar = require("./suporte/carregador")({
	workspace = mundo,
	Instance = roblox.Instance, Enum = roblox.Enum, Color3 = roblox.Color3,
	Vector2 = roblox.Vector2, Vector3 = roblox.Vector3, CFrame = roblox.CFrame,
	UDim2 = roblox.UDim2, ColorSequence = roblox.ColorSequence,
	ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
}, {
	RunService = { RenderStepped = render, Heartbeat = heartbeat },
	UserInputService = { InputBegan = sinal(), InputChanged = sinal(), InputEnded = sinal(), WindowFocusReleased = sinal() },
	ContextActionService = {},
}, {
	["Packages/Networker"] = {},
})
local Controlador = carregar("src/client/ControladorConstrucao")
local controlador = setmetatable({ _modoSelecao = "Blueprint" }, Controlador)
controlador:_CriarCaixaSelecao()

-- Os modos lisos usam a mesma camada sem iluminacao do blueprint, em vez do material ForceField.
for modo, cor in {
	Copia = roblox.Color3.fromRGB(40,125,255), Venda = roblox.Color3.fromRGB(35,190,95),
	Movimentacao = roblox.Color3.fromRGB(255,185,0), Recolhimento = roblox.Color3.fromRGB(255,65,65),
} do
	local c = setmetatable({ _modoSelecao = modo }, Controlador)
	c:_CriarCaixaSelecao()
	assert(c._caixaSelecao.Transparency == 1 and c._caixaSelecao.ContornoSelecao.Visible)
	assert(#c._faixasSelecao.faces == 6 and #c._faixasSelecao.bordas == 0)
	for _, tamanho in { roblox.Vector3.new(32,8,12), roblox.Vector3.new(12,8,32) } do
		c._caixaSelecao.Size = tamanho
		c:_AtualizarListrasSelecao(tamanho)
		local visiveis = 0
		for _, face in c._faixasSelecao.faces do
			local f = assert(face.Preenchimento)
			assert(f.BackgroundColor3 == cor and math.abs(f.BackgroundTransparency - 0.7) < 1e-6)
			assert(f.Size == roblox.UDim2.fromScale(1,1) and not f:FindFirstChildOfClass("UIGradient"))
			assert(face.Superficie.LightInfluence == 0 and not face.Superficie.AlwaysOnTop)
			assert(#face.Faixas == 0, "O preenchimento liso nao deve criar listras.")
			if face.Superficie.Enabled then visiveis += 1 end
		end
		assert(visiveis == 3, "As faces opostas nao devem acumular opacidade.")
	end
	c._caixaSelecao:Destroy()
end

local function canvasEsperado(tamanho, lado)
	if lado == roblox.Enum.NormalId.Front or lado == roblox.Enum.NormalId.Back then
		return tamanho.X * 24, tamanho.Y * 24
	elseif lado == roblox.Enum.NormalId.Left or lado == roblox.Enum.NormalId.Right then
		return tamanho.Z * 24, tamanho.Y * 24
	end
	-- Em Top/Bottom, o eixo horizontal do SurfaceGui acompanha Z e o vertical acompanha X.
	return tamanho.Z * 24, tamanho.X * 24
end

local eixos = {
 Front = {-roblox.Vector3.xAxis, -roblox.Vector3.yAxis, -roblox.Vector3.zAxis},
 Back = {roblox.Vector3.xAxis, -roblox.Vector3.yAxis, roblox.Vector3.zAxis},
 Left = {roblox.Vector3.zAxis, -roblox.Vector3.yAxis, -roblox.Vector3.xAxis},
 Right = {-roblox.Vector3.zAxis, -roblox.Vector3.yAxis, roblox.Vector3.xAxis},
 -- Calibracao visual independente: Top ORIGEM=(-X,+Z); Bottom ORIGEM=(+X,+Z).
 Top = {-roblox.Vector3.zAxis, roblox.Vector3.xAxis, roblox.Vector3.yAxis},
 Bottom = {-roblox.Vector3.zAxis, -roblox.Vector3.xAxis, -roblox.Vector3.yAxis},
}
local function faseNoPonto(face, ponto, tamanho)
	local uv = eixos[face.Superficie.Face.Name]
	local px = (ponto:Dot(uv[1]) + (uv[1] * tamanho).Magnitude / 2) * 24
	local py = (ponto:Dot(uv[2]) + (uv[2] * tamanho).Magnitude / 2) * 24
	local fase
	for _, faixa in face.Faixas do
		local f = faixa.Instancia
		local dx, dy = px - f.Position.X.Offset, py - f.Position.Y.Offset
		if f.Visible and dx >= 0 and dy >= 0 and dx <= f.Size.X.Offset and dy <= f.Size.Y.Offset then
			local g = f:FindFirstChildOfClass("UIGradient")
			local a = math.rad(g.Rotation)
			local projecao = (dx - f.Size.X.Offset/2)*math.cos(a) + (dy - f.Size.Y.Offset/2)*math.sin(a)
			fase = (4*(0.5 + projecao/(f.Size.X.Offset*math.sqrt(2)))) % 2
		end
	end
	return assert(fase, "A aresta compartilhada deve estar coberta.")
end
local casos = 0
local arestas = 0
for _, tamanho in {
	roblox.Vector3.new(32, 12, 8), roblox.Vector3.new(8, 12, 32),
	roblox.Vector3.new(4, 4, 4), roblox.Vector3.new(64, 4, 16),
	roblox.Vector3.new(11.5, 7.25, 23.75),
} do
	for _, fase in { 0, 4 * math.sqrt(2), 8 * math.sqrt(2) - 1e-4 } do
		controlador._faixasSelecao.deslocamento = fase
		controlador._caixaSelecao.Size = tamanho
		controlador:_AtualizarListrasSelecao(tamanho)
		controlador:_AtualizarBordasListradas(controlador._caixaSelecao)
		for _, face in controlador._faixasSelecao.faces do
			local largura, altura = canvasEsperado(tamanho, face.Superficie.Face)
            assert(face.Superficie.SizingMode == roblox.Enum.SurfaceGuiSizingMode.FixedSize)
            assert((face.Superficie.CanvasSize - roblox.Vector2.new(largura, altura)).Magnitude < 0.01,
                "O canvas deve acompanhar o tamanho atual no mesmo chamado, sem esperar outro quadro.")
            local uv = eixos[face.Superficie.Face.Name]
			assert(math.abs(face.Largura * 24 - largura) < 0.01
				and math.abs(face.Altura * 24 - altura) < 0.01,
				"Dimensoes invertidas no canvas " .. face.Superficie.Face.Name)
			for _, x in { 0, 0.125, 0.5, 0.875, 1 } do
				for _, y in { 0, 0.125, 0.5, 0.875, 1 } do
					local coberto = false
                    local faseRenderizada
					for _, faixa in face.Faixas do
						local f = faixa.Instancia
						if not f.Visible then continue end
						assert(f.Rotation == 0, "Frames girados reproduzem a falha de recorte no Studio.")
						local esperado = math.ceil(8 * math.sqrt(2) * 24) + 1
						assert(f.Size.X.Offset == esperado and f.Size.Y.Offset == esperado,
							"O padrao deve ter escala fixa, com apenas um pixel de sobreposicao.")
						local g = assert(f:FindFirstChildOfClass("UIGradient"))
						assert(#g.Color.Keypoints == 8)
						local px, py = 0.5 + x * (largura - 1), 0.5 + y * (altura - 1)
						local dx, dy = px - f.Position.X.Offset, py - f.Position.Y.Offset
						if dx >= 0 and dx <= f.Size.X.Offset
							and dy >= 0 and dy <= f.Size.Y.Offset then
                            coberto = true
                            local angulo = math.rad(g.Rotation)
                            local projecao = (dx - f.Size.X.Offset/2) * math.cos(angulo)
                                + (dy - f.Size.Y.Offset/2) * math.sin(angulo)
                            faseRenderizada = (4 * (0.5 + projecao / (f.Size.X.Offset * math.sqrt(2)))) % 2
						end
					end
					assert(coberto, string.format("Ponto descoberto em %s, tamanho %s, fase %.5f, ponto %.3f/%.3f",
						face.Superficie.Face.Name, tostring(tamanho), fase, x, y))
                    local ponto = uv[3] * tamanho / 2
                        + uv[1] * ((0.5 + x*(largura-1))/24 - largura/48)
                        + uv[2] * ((0.5 + y*(altura-1))/24 - altura/48)
                    local esperada = ((ponto.X+ponto.Y+ponto.Z-fase)/(4*math.sqrt(2))) % 2
                    local erro = math.abs(faseRenderizada - esperada)
                    assert(math.min(erro, 2-erro) < 0.04,
                        "A fase deve corresponder ao mesmo ponto 3D em todas as faces: "..face.Superficie.Face.Name)
				end
			end
			casos += 1
		end
		local faces = {}
		for _, face in controlador._faixasSelecao.faces do faces[face.Superficie.Face.Name] = face end
		for _, nome in { "Top", "Bottom" } do
			for _, lateral in { "Front", "Back", "Left", "Right" } do
				local normal = eixos[lateral][3]
				for _, t in { -0.43, -0.21, 0.13, 0.41 } do
					local ponto = (eixos[nome][3] + normal) * tamanho / 2
						+ eixos[lateral][1] * tamanho * t
					local erro = math.abs(faseNoPonto(faces[nome], ponto, tamanho)
						- faseNoPonto(faces[lateral], ponto, tamanho))
					assert(math.min(erro, 2-erro) < 0.04, nome .. " deve continuar a listra de " .. lateral)
					arestas += 1
				end
			end
		end
        for _, borda in controlador._faixasSelecao.bordas do
            for _, segmento in borda.Segmentos do
                if segmento.Transparency >= 1 then continue end
                local p = segmento.CFrame.Position
                local indice = (p.X+p.Y+p.Z-fase)/(4*math.sqrt(2))
                if math.abs(indice-math.round(indice)) < 1e-4 then continue end
                local cor = math.floor(indice)%2 == 0 and roblox.Color3.fromRGB(115,205,255)
                    or roblox.Color3.fromRGB(25,85,190)
                assert(segmento.Color == cor, "As arestas devem acompanhar a fase das faces.")
            end
        end
    end
end
-- Uma vista externa mostra somente as faces voltadas para a camera; de dentro, preserva as paredes internas.
for _, posicao in { roblox.Vector3.new(50,50,50), roblox.Vector3.new(-50,-50,-50), roblox.Vector3.zero } do
	mundo.CurrentCamera.CFrame = roblox.CFrame.new(posicao)
	controlador:_AtualizarListrasSelecao(roblox.Vector3.new(8,8,8))
	local visiveis = 0
	for _, face in controlador._faixasSelecao.faces do
		if face.Superficie.Enabled then visiveis += 1 end
	end
	assert(visiveis == (posicao.Magnitude == 0 and 6 or 3), "Faces opostas nao devem se sobrepor na vista externa.")
end
-- O tamanho do volume deve mudar no Heartbeat; ler AbsoluteSize nao comprova o recorte desenhado no cliente.
controlador._conexoes = {}
controlador._jogador = { GetAttributeChangedSignal = function() return sinal() end }
controlador._AtualizarDestaqueHover = function() end
controlador._AtualizarSelecaoTerreno = function() end
controlador._piso = roblox.Instance.new("Part")
controlador._piso.Size = roblox.Vector3.new(64, 1, 64)
local caixa = controlador._caixaSelecao
local antes = caixa.Size
controlador._arrasteSelecao = { AlvoVisual = { CFrame = caixa.CFrame, Size = roblox.Vector3.new(20, 8, 12) } }
controlador:Iniciar()
render:Fire(0.05)
assert(caixa.Size == antes, "RenderStepped nao deve redimensionar a superficie depois da preparacao da GUI.")
heartbeat:Fire(0.05)
assert((caixa.Size - antes).Magnitude > 0.1, "Heartbeat deve animar o volume junto com as listras.")
for _, conexao in controlador._conexoes do conexao:Disconnect() end
controlador._piso:Destroy()
caixa:Destroy()
print("PASS: 4 modos com preenchimento SurfaceGui; " .. casos .. " faces/fases, " .. arestas .. " pontos compartilhados, cobertura e Heartbeat.")

