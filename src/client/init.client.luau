local Players = game:GetService("Players")
local ControladorConstrucao = require(script.ControladorConstrucao)
local InterfaceJogo = require(script.InterfaceJogo)

local construcao = ControladorConstrucao.new(Players.LocalPlayer)
local interface = InterfaceJogo.new(Players.LocalPlayer)
construcao:Iniciar()

script.Destroying:Connect(function()
	construcao:Destruir()
	interface:Destruir()
end)
