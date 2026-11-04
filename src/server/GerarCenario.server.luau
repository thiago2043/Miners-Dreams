local Mapa = require(game:GetService("ReplicatedStorage").Shared.Mapa)
local terrenos = workspace:WaitForChild("Terrenos")
local baseplate = workspace:WaitForChild("Baseplate")
while #terrenos:GetChildren() < Mapa.QuantidadePlots do terrenos.ChildAdded:Wait() end
local Cenario = require(script.Parent.Cenario)
Cenario.Criar(baseplate, terrenos, workspace)
Cenario.Iluminar()
