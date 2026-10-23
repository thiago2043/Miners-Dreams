local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("./modelos")
local projeto = serde.decode("json", fs.readFile("default.project.json"))

-- Os testes carregam os mesmos recursos que o build do Rojo.
return function(pasta)
	pasta = pasta or roblox.Instance.new("Folder")
	for id, entrada in projeto.tree.ReplicatedStorage.ModelosMaquinas do
		if id:sub(1, 1) == "$" then continue end
		local modelo = roblox.deserializeModel(fs.readFile(entrada["$path"]))[1]
		assert(modelo.Name == id, "Nome do modelo diverge do projeto: " .. id)
		for _, saida in modelo:GetDescendants() do
			if saida:IsA("Attachment") and saida.Parent:IsA("BasePart") then
				saida.WorldCFrame = saida.Parent.CFrame * saida.CFrame
			end
		end
		modelo.Parent = pasta
	end
	return pasta
end
