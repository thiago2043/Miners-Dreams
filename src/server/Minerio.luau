local ServerScriptService = game:GetService("ServerScriptService")
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))

local Minerio = {}
Minerio.__index = Minerio

function Minerio.new(parte)
	assert(parte:IsA("BasePart") and parte.Name == "Minerio", "Parte nao representa um minerio.")
	return setmetatable({ _parte = parte }, Minerio)
end

function Minerio.Criar(definicao, cframe, terreno)
	local parte = Instance.new("Part")
	parte.Name = "Minerio"
	local self = Minerio.new(parte)
	assert(self:DefinirValor(definicao.Valor), "Valor inicial de minerio invalido.")
	assert(self:DefinirTamanho(Vector3.new(table.unpack(definicao.Tamanho))), "Tamanho inicial de minerio invalido.")
	parte.CFrame = cframe
	parte.Color = Color3.fromRGB(140, 100, 65)
	parte.Anchored = false
	parte.CanCollide = true
	parte.CanTouch = true
	parte:SetAttribute("DonoUserId", terreno:GetAttribute("DonoUserId"))
	parte:SetAttribute("TerrenoId", terreno:GetAttribute("TerrenoId"))
	parte.Parent = terreno:FindFirstChild("Minerios")
	return self
end

function Minerio:ObterParte() return self._parte end
function Minerio:ObterValor() return self._parte:GetAttribute("Valor") end
function Minerio:ObterTamanho() return self._parte.Size end

function Minerio:DefinirValor(valor)
	if not InteiroGrande.eValido(valor) then return false end
	self._parte:SetAttribute("Valor", valor)
	return true
end

function Minerio:DefinirTamanho(tamanho)
	if typeof(tamanho) ~= "Vector3" then return false end
	for _, valor in { tamanho.X, tamanho.Y, tamanho.Z } do
		if not (valor > 0 and valor < math.huge) then return false end
	end
	self._parte.Size = tamanho
	return true
end

function Minerio:EstaDisponivel(terreno)
	return self._parte.Parent == terreno:FindFirstChild("Minerios")
		and self._parte:GetAttribute("Processado") ~= true
		and self._parte:GetAttribute("DonoUserId") == terreno:GetAttribute("DonoUserId")
		and self._parte:GetAttribute("TerrenoId") == terreno:GetAttribute("TerrenoId")
end

function Minerio:CalcularValor(multiplicador, bonus)
	local valor = self:ObterValor()
	if not InteiroGrande.eValido(valor) then return nil end
	return InteiroGrande.somar(InteiroGrande.multiplicar(valor, multiplicador or "1"), bonus or "0")
end

function Minerio:Consumir()
	self._parte:SetAttribute("Processado", true)
	self._parte:Destroy()
end

return Minerio
