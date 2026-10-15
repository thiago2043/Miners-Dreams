local ServerScriptService = game:GetService("ServerScriptService")
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))
local ContatoMinerio = require(script.Parent.ContatoMinerio)
local VendedorMinerio = setmetatable({}, { __index = ContatoMinerio })
VendedorMinerio.__index = VendedorMinerio

function VendedorMinerio.new(maquina, configuracao)
	local self = setmetatable(ContatoMinerio.new(maquina, configuracao), VendedorMinerio)
	local modelo = maquina:ObterModelo()
	if modelo:GetAttribute("TotalRecebido") == nil then modelo:SetAttribute("TotalRecebido", "0") end
	return self
end

function VendedorMinerio:AoTocar(minerio)
	local valor = minerio:CalcularValor(self._configuracao.Multiplicador, self._configuracao.Bonus)
	local modelo = self._maquina:ObterModelo()
	local total = modelo:GetAttribute("TotalRecebido")
	if not valor or not InteiroGrande.eValido(total) then
		warn("Valor do minerio ou TotalRecebido invalido em " .. modelo:GetFullName())
		return
	end
	local dados = self._maquina:ObterDadosDono()
	if not dados or not dados:AdicionarDinheiro(valor) then return end
	local novoTotal = InteiroGrande.somar(total, valor)
	minerio:Consumir()
	modelo:SetAttribute("TotalRecebido", novoTotal)
	print(self._maquina:ObterTerreno().Name .. " | Minerio processado: " .. valor .. " | Total: " .. novoTotal)
end

return VendedorMinerio
