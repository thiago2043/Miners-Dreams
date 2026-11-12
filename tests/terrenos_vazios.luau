-- Executa o bootstrap real com tarefas adiadas e jogadores simulados, sem modelos no Workspace.
local roblox = require("./suporte/modelos")
local Instance, CFrame, Vector3 = roblox.Instance, roblox.CFrame, roblox.Vector3
local function sinal()
	local callbacks = {}
	return {
		Connect = function(_, callback)
			local conexao = {Callback = callback, Ativa = true}
			function conexao:Disconnect() self.Ativa = false end
			table.insert(callbacks, conexao)
			return conexao
		end,
		Fire = function(_, ...)
			for _, conexao in callbacks do if conexao.Ativa then conexao.Callback(...) end end
		end,
	}
end
local function avancar(tarefa)
	local ok, erro = coroutine.resume(tarefa, 1 / 60)
	assert(ok, erro)
end
local function iniciar(funcao)
	local tarefa = coroutine.create(funcao)
	avancar(tarefa)
	return tarefa
end
local mundo = Instance.new("Workspace")
local baseplate = Instance.new("Part")
baseplate.Name, baseplate.Size, baseplate.Position = "Baseplate", Vector3.new(256, 1, 256), Vector3.zero
baseplate.Parent = mundo
local players = { MaxPlayers = 2, PlayerAdded = sinal(), PlayerRemoving = sinal() }
local function jogador(id)
	local p = { UserId = id, Name = "Jogador" .. id, Parent = players, atributos = {}, CharacterAdded = sinal() }
	function p:GetAttribute(nome) return self.atributos[nome] end
	function p:SetAttribute(nome, valor) self.atributos[nome] = valor end
	return p
end
local p1, p2, p3 = jogador(123), jogador(456), jogador(789)
local personagem = Instance.new("Model")
local raiz = Instance.new("Part")
raiz.Name, raiz.Parent = "HumanoidRootPart", personagem
personagem.Parent, p2.Character = mundo, personagem
function players:GetPlayers() return { p1, p2 } end
local tarefas, restaurados, consultas = {}, {}, 0
local carregar = require("./suporte/carregador")({
	workspace = mundo, Instance = Instance, CFrame = CFrame, Vector3 = Vector3,
	Color3 = roblox.Color3, Enum = roblox.Enum, print = function() end, warn = error,
	task = { spawn = function(funcao) table.insert(tarefas, funcao) end },
}, { Players = players, RunService = {Heartbeat = {Wait = coroutine.yield}} }, setmetatable({}, { __index = function(_, caminho)
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
assert(p1.RespawnLocation == mundo.Terrenos.Terreno_1.Spawn and p2.RespawnLocation == mundo.Terrenos.Terreno_2.Spawn)
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
assert(p1.RespawnLocation == nil)
assert(not mundo.Terrenos.Terreno_1.Spawn.Enabled)
players.PlayerAdded:Fire(p3)
assert(p3:GetAttribute("TerrenoId") == 1)
assert(p3.RespawnLocation == mundo.Terrenos.Terreno_1.Spawn)
for _, funcao in tarefas do
	local tarefa = iniciar(funcao)
	if coroutine.status(tarefa) == "suspended" then avancar(tarefa) end
	assert(coroutine.status(tarefa) == "dead")
end
assert((personagem:GetPivot().Position - (p2.RespawnLocation.CFrame.Position + Vector3.yAxis*4)).Magnitude < .001)
assert(not table.find(restaurados, p1), "Uma tarefa antiga nao pode restaurar no terreno entregue a outro jogador.")
assert(table.find(restaurados, p2) and table.find(restaurados, p3))

local destino = p3.RespawnLocation.CFrame * CFrame.new(0, 4, 0)
for _ = 1, 2 do
	local avatar = personagem:Clone()
	p3.Character = avatar
	local tarefa = iniciar(function() p3.CharacterAdded:Fire(avatar) end)
	assert(coroutine.status(tarefa) == "suspended" and not avatar.Parent)
	avatar.Parent = mundo
	avancar(tarefa)
	assert(coroutine.status(tarefa) == "suspended")
	avatar:PivotTo(mundo.Terrenos.Terreno_1.Piso.CFrame * CFrame.new(0, 4, 0))
	avancar(tarefa)
	assert(coroutine.status(tarefa) == "dead" and (avatar:GetPivot().Position - destino.Position).Magnitude < .001)
end

local atrasado = personagem:Clone()
p3.Character = atrasado
local tarefa = iniciar(function() p3.CharacterAdded:Fire(atrasado) end)
players.PlayerRemoving:Fire(p3)
atrasado.Parent = mundo
local antes = atrasado:GetPivot()
avancar(tarefa)
assert(coroutine.status(tarefa) == "suspended")
avancar(tarefa)
assert(coroutine.status(tarefa) == "dead" and atrasado:GetPivot() == antes)
for _, terreno in mundo.Terrenos:GetChildren() do assert(#terreno.Maquinas:GetChildren() == 0) end
local template = carregar("src/server/Data/Template")
assert(template.Dinheiro == "0" and #template.MaquinasColocadas == 0)
assert(template.Inventory.MineradoraBasica == 1 and template.Inventory.Esteira2x2 == 10
	and template.Inventory.FornalhaBasica == 1 and template.Inventory.PrensaMinerio == 0)
print("PASS: plots criadas e atribuidas vazias sem modelos no Workspace nem dependencia sincrona de Construcao.")
print("PASS: saida/reutilizacao do terreno e restauracao adiada respeitam o dono atual.")
print("PASS: primeiro nascimento e respawn sao posicionados apos o motor; tarefa atrasada nao move personagem de ex-dono.")
print("PASS: perfil novo recebe uma mineradora, dez esteiras 2x2 e uma fornalha, sem construcoes iniciais.")
