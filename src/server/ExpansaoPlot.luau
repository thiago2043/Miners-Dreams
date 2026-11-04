local U=require(game:GetService("ReplicatedStorage").Shared.Upgrades)
local bloco=require(game:GetService("ReplicatedStorage").Shared.Medidas).Bloco
local E={}
function E.Aplicar(terreno,nivel,permitirReducao)
	local piso=terreno:FindFirstChild("Piso")
	if not piso or not U.Valido(nivel,"Expansao") then return false end
	local lado=U.TamanhosPlot[nivel+1]*bloco
	if not permitirReducao and (lado<piso.Size.X or lado<piso.Size.Z) then return false end
	local dx,dz=lado-piso.Size.X,lado-piso.Size.Z
	if dx==0 and dz==0 then return true end
	-- Mantem o canto usado como origem das coordenadas salvas e da grade.
	piso.CFrame=piso.CFrame*CFrame.new(dx/2,0,dz/2)
	piso.Size=Vector3.new(lado,piso.Size.Y,lado)
	return true
end
return E
