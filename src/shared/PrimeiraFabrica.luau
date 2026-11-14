local Inteiro = require(script.Parent.InteiroGrande)
local catalogo = require(script.Parent.CatalogoMaquinas)

local Guia = {
	PrimeiroModificador = "CamaraFissao",
	Etapas = {Venda = 0, Modificador = 1, Concluido = 5},
}

function Guia.TemSaldo(saldo, preco)
	return Inteiro.eValido(saldo) and not Inteiro.menor(saldo, preco)
end

function Guia.TipoPeca(id)
	local peca = catalogo[id]
	if not peca then return end
	for _, componente in peca.Componentes do
		if componente.Tipo ~= "Transportador" then return componente.Tipo end
	end
	if #peca.Componentes > 0 then return "Transportador" end
end

return Guia
