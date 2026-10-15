local roblox = require("@lune/roblox")
local Instance, CFrame, Vector3 = roblox.Instance, roblox.CFrame, roblox.Vector3

roblox.implementMethod("Instance", "WaitForChild", function(objeto, nome)
	return assert(objeto:FindFirstChild(nome))
end)
local pivos = {}
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
roblox.implementMethod("Model", "GetBoundingBox", function(modelo)
	return caixa(modelo, pivos[modelo] and pivos[modelo].Rotation or CFrame.identity)
end)
roblox.implementMethod("Model", "GetPivot", function(modelo)
	if pivos[modelo] then return pivos[modelo] end
	local cf = caixa(modelo, CFrame.identity)
	return cf
end)
roblox.implementMethod("Model", "PivotTo", function(modelo, destino)
	local delta = destino * modelo:GetPivot():Inverse()
	for _, parte in modelo:GetDescendants() do
		if parte:IsA("BasePart") then parte.CFrame = delta * parte.CFrame end
	end
	pivos[modelo] = destino
end)

return roblox
