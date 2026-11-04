-- Mapear temporariamente no StarterPlayerScripts junto do teste de carga do servidor.
local raiz = workspace:WaitForChild("TesteCargaMinerios", 30)
assert(raiz, "O teste de carga do servidor nao iniciou.")
while raiz.Parent and not raiz:GetAttribute("Medindo") do task.wait() end
assert(raiz.Parent, "A cena terminou antes da medicao do cliente.")
local camera = workspace.CurrentCamera
local tipo, pose = camera.CameraType, camera.CFrame
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.lookAt(Vector3.new(0, 1030, 32), Vector3.new(0, 1000, -5))
local duracao, quadros, maior = 0, 0, 0
local Movimento = require(game.ReplicatedStorage.Shared.MovimentoMinerio)
local estadoRelogio = {}
local terreno = raiz:FindFirstChildWhichIsA("Model")
local amostra = terreno.Minerios:GetChildren()[1]
local desvio, medidas = 0, 0
while raiz.Parent and raiz:GetAttribute("Medindo") do
	local delta = game:GetService("RunService").RenderStepped:Wait()
	duracao += delta; quadros += 1; maior = math.max(maior, delta)
	if duracao>1 and amostra.Parent then
		local movimento = Movimento.Decodificar(amostra:GetAttribute("MovimentoMinerio"))
		local relogio = Movimento.DecodificarRelogio(terreno:GetAttribute("RelogioMinerios"))
		if movimento and relogio then
			local tempo = Movimento.TempoVisual(estadoRelogio,relogio,workspace:GetServerTimeNow())
			local esperado = Movimento.Avaliar(movimento,tempo)
			desvio = math.max(desvio,(esperado.Position-amostra.Position).Magnitude); medidas += 1
		end
	end
end
camera.CameraType, camera.CFrame = tipo, pose
assert(quadros > 0)
print("CARGA_CLIENTE",quadros/duracao,"quadros_s",maior*1000,"pico_quadro_ms")
assert(medidas>0 and desvio<1,"O desenho local nao acompanhou a trajetoria publicada pelo servidor.")
print("CARGA_CLIENTE_TRAJETORIA",medidas,"amostras",desvio,"desvio_max_studs")
script:Destroy()
