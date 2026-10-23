local MiniaturaPeca = {}
-- As miniaturas compartilham metodos, mas cada objeto guarda seu proprio ViewportFrame e seus descendentes.
MiniaturaPeca.__index = MiniaturaPeca

-- Uma camera e um clone estatico por cartao. A personalizacao opcional adapta o retrato da ficha
-- a unidade selecionada; os cartoes do catalogo continuam usando o modelo original.
function MiniaturaPeca.new(pai, original, personalizacao)
	local self = setmetatable({}, MiniaturaPeca)
	-- ViewportFrame desenha o modelo dentro do cartao, independentemente da camera do jogador.
	self._viewport = Instance.new("ViewportFrame")
	self._viewport.Name, self._viewport.BackgroundTransparency = "Miniatura", 1
	self._viewport.Position, self._viewport.Size = UDim2.fromOffset(3, 3), UDim2.new(1, -6, 1, -6)
	-- Luz ambiente preenche as sombras; LightDirection acrescenta contraste para mostrar o formato da peca.
	self._viewport.Ambient, self._viewport.LightColor = Color3.fromRGB(170, 170, 180), Color3.new(1, 1, 1)
	self._viewport.LightDirection = Vector3.new(-1, -1, -1)
	self._viewport.ZIndex, self._viewport.Parent = pai.ZIndex + 1, pai
	-- O WorldModel agrupa apenas o clone visual. O modelo original da fabrica permanece intacto.
	local mundo = Instance.new("WorldModel")
	mundo.Parent = self._viewport
	local modelo = original:Clone()
	-- O clone e apenas visual: nenhum script do modelo deve acompanhar a miniatura.
	for _, objeto in modelo:GetDescendants() do
		if objeto:IsA("LuaSourceContainer") then objeto:Destroy()
		elseif objeto:IsA("BasePart") then
			objeto.Anchored, objeto.CanCollide, objeto.CanTouch, objeto.CanQuery = true, false, false, false
		end
	end
	modelo.Parent = mundo
	if personalizacao then
		-- Uma variante invalida nao pode deixar camera/modelo orfaos. Aplicar atua somente sobre o clone.
		local sucesso, erro = pcall(function() personalizacao:Aplicar(modelo) end)
		if not sucesso then self:Destruir(); error(erro) end
	end
	local caixa, tamanho = modelo:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	-- A esfera envolvente cabe na imagem quadrada mesmo para modelos altos ou compridos.
	local distancia = math.max(tamanho.Magnitude / 2, 0.1) / math.sin(math.rad(camera.FieldOfView / 2)) * 1.06
	-- A vista diagonal mostra frente, lateral e topo; lookAt aponta para o centro do modelo, nao para o pivot.
	camera.CFrame = CFrame.lookAt(caixa.Position + Vector3.new(1, 0.8, 1).Unit * distancia, caixa.Position)
	-- CurrentCamera conecta esta camera ao cartao. Como ambos sao filhos do viewport, a limpeza e conjunta.
	camera.Parent, self._viewport.CurrentCamera = self._viewport, camera
	return self
end

-- Remove o viewport, o clone e a camera de uma vez. A guarda permite chamadas repetidas durante a limpeza.
function MiniaturaPeca:Destruir()
	if self._destruido then return end
	self._destruido = true
	self._viewport:Destroy()
end

return MiniaturaPeca
