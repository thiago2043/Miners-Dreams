local Fabrica = require(script.Parent.Fabrica)
local fabrica = Fabrica.new(workspace:WaitForChild("Terrenos"))

while true do
	fabrica:Atualizar(os.clock())
	task.wait(1)
end
