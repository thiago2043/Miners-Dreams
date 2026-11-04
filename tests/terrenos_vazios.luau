-- Executa o bootstrap real com tarefas adiadas e jogadores simulados, sem modelos no Workspace.
local roblox = require("./suporte/modelos")
local Instance, CFrame, Vector3 = roblox.Instance, roblox.CFrame, roblox.Vector3
local function sinal()
	local callbacks = {}
	return {
		Connect = function(_, callback) table.insert(callbacks, callback) end,
		Fire = function(_, ...) for _, callback in callbacks do callback(...) end end,
	}
end
local mundo = Instance.new("Workspace")
local baseplate = Instance.new("Part")
baseplate.Name, baseplate.Size, baseplate.Position = "Baseplate", Vector3.new(256, 1, 256), Vector3.zero
baseplate.Parent = mundo
local players = { MaxPlayers = 2, PlayerAdded = sinal(), PlayerRemoving = sinal() }
local function jogador(id)
	local p = { UserId = id, Name = "Jogador" .. id, Parent = players, atributos = {} }
	function p:GetAttribute(nome) return self.atributos[nome] end
	function p:SetAttribute(nome, valor) self.atributos[nome] = valor end
	return p
end
local p1, p2, p3 = jogador(123), jogador(456), jogador(789)
function players:GetPlayers() return { p1, p2 } end
local tarefas, restaurados, consultas = {}, {}, 0
local carregar = require("./suporte/carregador")({
	workspace = mundo, Instance = Instance, CFrame = CFrame, Vector3 = Vector3,
	Color3 = roblox.Color3, Enum = roblox.Enum, print = function() end, warn = error,
	task = { spawn = function(funcao) table.insert(tarefas, funcao) end },
}, { Players = players }, setmetatable({}, { __index = function(_, caminho)
	if caminho ~= "src/server/Construcao" then return nil end
	consultas += 1
	assert(mundo:FindFirstChild("Terrenos") and #mundo.Terrenos:GetChildren() == 8,
		"Criar os terrenos nao pode depender de carregar Construcao ou os modelos.")
	return { Restaurar = function(p)
		table.insert(restaurados, p)
	end }
end }))
carregar("src/server/Terrenos.server")
assert(consultas == 0, "A atribuicao dos terrenos nao deve aguardar Construcao.")
assert(p1:GetAttribute("TerrenoId") == 1 and p2:GetAttribute("TerrenoId") == 2)
for _, terreno in mundo.Terrenos:GetChildren() do
	assert(terreno.Piso.Size==Vector3.new(36,1,36))
	assert(#terreno.Maquinas:GetChildren() == 0 and #terreno.Minerios:GetChildren() == 0)
	assert(terreno.Spawn.Enabled==(terreno:GetAttribute("TerrenoId")<=2))
	assert(terreno.Spawn.Transparency==1 and not terreno.Spawn.CastShadow
		and not terreno.Spawn.CanCollide and not terreno.Spawn.CanTouch and not terreno.Spawn.CanQuery)
	assert(terreno.Piso.Color==roblox.Color3.fromRGB(145,145,145))
end
players.PlayerRemoving:Fire(p1)
assert(p1:GetAttribute("TerrenoId") == nil)
assert(not mundo.Terrenos.Terreno_1.Spawn.Enabled)
players.PlayerAdded:Fire(p3)
assert(p3:GetAttribute("TerrenoId") == 1)
for _, tarefa in tarefas do tarefa() end
assert(not table.find(restaurados, p1), "Uma tarefa antiga nao pode restaurar no terreno entregue a outro jogador.")
assert(table.find(restaurados, p2) and table.find(restaurados, p3))
for _, terreno in mundo.Terrenos:GetChildren() do assert(#terreno.Maquinas:GetChildren() == 0) end
local template = carregar("src/server/Data/Template")
assert(template.Dinheiro == "0" and #template.MaquinasColocadas == 0)
assert(template.Inventory.MineradoraBasica == 1 and template.Inventory.Esteira2x2 == 10
	and template.Inventory.FornalhaBasica == 1 and template.Inventory.PrensaMinerio == 0)
print("PASS: plots criadas e atribuidas vazias sem modelos no Workspace nem dependencia sincrona de Construcao.")
print("PASS: saida/reutilizacao do terreno e restauracao adiada respeitam o dono atual.")
print("PASS: perfil novo recebe uma mineradora, dez esteiras 2x2 e uma fornalha, sem construcoes iniciais.")
