-- Completa os objetos do runtime local com os metodos usados nos testes; nao reproduz o motor fisico do Studio.
local roblox = require("@lune/roblox")
local Instance, CFrame, Vector3 = roblox.Instance, roblox.CFrame, roblox.Vector3
local sinal = require("./interface").Sinal
local sinais = {}
local function obterSinal(objeto, nome)
	sinais[objeto] = sinais[objeto] or {}
	sinais[objeto][nome] = sinais[objeto][nome] or sinal()
	return sinais[objeto][nome]
end
-- O Lune nao emite eventos de arvore/propriedades; testes de invalidacao os disparam explicitamente.
for _, nome in { "ChildAdded", "ChildRemoved", "DescendantAdded", "DescendantRemoving" } do
	roblox.implementProperty("Instance", nome, function(objeto) return obterSinal(objeto, nome) end)
end
roblox.implementMethod("Instance", "GetPropertyChangedSignal", function(objeto, nome) return obterSinal(objeto,"Propriedade:"..nome) end)
roblox.implementMethod("Instance", "GetAttributeChangedSignal", function(objeto, nome) return obterSinal(objeto,"Atributo:"..nome) end)
roblox.implementMethod("Workspace", "GetServerTimeNow", function(mundo) return mundo:GetAttribute("TempoServidorTeste") or 0 end)
roblox.implementMethod("Workspace", "BulkMoveTo", function(mundo, partes, poses)
	mundo:SetAttribute("LotesMovimentoTeste", (mundo:GetAttribute("LotesMovimentoTeste") or 0) + 1)
	for i, parte in partes do parte.CFrame = poses[i] end
end)

-- O runtime de testes nao aguarda replicacao. Esta versao exige que o filho ja exista e falha por assert se
-- o cenario esqueceu de cria-lo.
roblox.implementMethod("Instance", "WaitForChild", function(objeto, nome)
	return assert(objeto:FindFirstChild(nome))
end)
local pivos = {}
-- Calcula a caixa de todas as BaseParts do modelo nos eixos recebidos. Projeta os oito cantos de cada
-- parte, acumula extremos e devolve CFrame central e dimensoes.
local function caixa(modelo, orientacao)
	local minimo = Vector3.new(math.huge, math.huge, math.huge)
	local maximo = -minimo
	for _, parte in modelo:GetDescendants() do
		if not parte:IsA("BasePart") then continue end
		for _, x in { -1, 1 } do
			for _, y in { -1, 1 } do
				for _, z in { -1, 1 } do
					local canto = parte.CFrame:PointToWorldSpace(parte.Size * Vector3.new(x, y, z) / 2)
					local p = orientacao:PointToObjectSpace(canto)
					minimo = Vector3.new(math.min(minimo.X, p.X), math.min(minimo.Y, p.Y), math.min(minimo.Z, p.Z))
					maximo = Vector3.new(math.max(maximo.X, p.X), math.max(maximo.Y, p.Y), math.max(maximo.Z, p.Z))
				end
			end
		end
	end
	return orientacao * CFrame.new((minimo + maximo) / 2), maximo - minimo
end
-- Os metodos abaixo completam a geometria que os testes precisam. O mapa pivos conserva a pose definida por
-- PivotTo; isto nao simula contatos nem renderizacao do Studio.
roblox.implementMethod("Model", "GetBoundingBox", function(modelo)
	return caixa(modelo, pivos[modelo] and pivos[modelo].Rotation or CFrame.identity)
end)
roblox.implementMethod("Model", "GetPivot", function(modelo)
	local primaria = modelo.PrimaryPart
	if primaria and (modelo:GetAttribute("AlturaBlocos") or modelo.Name == "Carro" or modelo.Name == "MesaGiratória") then
		return primaria.CFrame * primaria.PivotOffset
	end
	if pivos[modelo] then return pivos[modelo] end
	local cf = caixa(modelo, CFrame.identity)
	return cf
end)
roblox.implementMethod("Model", "PivotTo", function(modelo, destino)
	-- delta transforma a pose antiga na nova. Aplicar essa mesma transformacao a cada parte preserva suas
	-- distancias e orientacoes relativas dentro do modelo.
	local delta = destino * modelo:GetPivot():Inverse()
	for _, parte in modelo:GetDescendants() do
		if parte:IsA("BasePart") then parte.CFrame = delta * parte.CFrame end
	end
	-- O Lune armazena WorldCFrame, mas nao o recalcula ao mover o pai.
	for _, saida in modelo:GetDescendants() do
		if saida:IsA("Attachment") and saida.Parent:IsA("BasePart") then
			saida.WorldCFrame = saida.Parent.CFrame * saida.CFrame
		end
	end
	pivos[modelo] = destino
end)

return roblox
