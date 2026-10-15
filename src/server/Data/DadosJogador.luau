local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)

local DadosJogador = {}
DadosJogador.__index = DadosJogador

local function quantidadeValida(quantidade)
	return type(quantidade) == "number" and quantidade >= 0
		and quantidade % 1 == 0 and quantidade < 2 ^ 53
end

function DadosJogador.new(jogador, perfil)
	return setmetatable({ _jogador = jogador, _perfil = perfil }, DadosJogador)
end

function DadosJogador:EstaAtivo()
	return self._perfil:IsActive()
end

function DadosJogador:ObterSaldo()
	return self._perfil.Data.Dinheiro
end

function DadosJogador:ObterQuantidade(maquinaId)
	local inventario = self._perfil.Data.Inventory
	local quantidade = type(inventario) == "table" and inventario[maquinaId]
	return quantidadeValida(quantidade) and quantidade or nil
end

function DadosJogador:ObterConstrucoes()
	local registros = self._perfil.Data.MaquinasColocadas
	-- A lista e uma copia; os registros conservam sua identidade para o recolhimento.
	return type(registros) == "table" and table.clone(registros) or nil
end

function DadosJogador:Sincronizar()
	self._jogador:SetAttribute("Dinheiro", self:ObterSaldo())
	for maquinaId in CatalogoMaquinas do
		self._jogador:SetAttribute("Inventario_" .. maquinaId, self:ObterQuantidade(maquinaId))
	end
end

function DadosJogador:_DefinirQuantidade(maquinaId, quantidade)
	self._perfil.Data.Inventory[maquinaId] = quantidade
	self._jogador:SetAttribute("Inventario_" .. maquinaId, quantidade)
end

function DadosJogador:_DefinirSaldo(saldo)
	self._perfil.Data.Dinheiro = saldo
	self._jogador:SetAttribute("Dinheiro", saldo)
end

function DadosJogador:AdicionarDinheiro(valor)
	if not self:EstaAtivo() or not InteiroGrande.eValido(valor) then return false end
	local saldo = self:ObterSaldo()
	if not InteiroGrande.eValido(saldo) then
		warn("Dinheiro invalido no perfil de " .. self._jogador.Name)
		return false
	end
	self:_DefinirSaldo(InteiroGrande.somar(saldo, valor))
	return true
end

function DadosJogador:ComprarMaquina(maquinaId)
	if type(maquinaId) ~= "string" or #maquinaId > 64 then return false, "Maquina invalida." end
	local item = CatalogoMaquinas[maquinaId]
	if not item then return false, "Maquina nao encontrada na loja." end
	if not self:EstaAtivo() then return false, "Dados ainda nao estao disponiveis." end
	if not InteiroGrande.eValido(self:ObterSaldo()) then return false, "Saldo invalido." end
	if type(self._perfil.Data.Inventory) ~= "table" then return false, "Inventario invalido." end
	local quantidade = self:ObterQuantidade(maquinaId)
	if not quantidade or quantidade >= 2 ^ 53 - 1 then
		return false, "Quantidade invalida no inventario."
	end
	local novoSaldo = InteiroGrande.subtrair(self:ObterSaldo(), item.Preco)
	if novoSaldo == nil then return false, "Dinheiro insuficiente." end
	self:_DefinirSaldo(novoSaldo)
	self:_DefinirQuantidade(maquinaId, quantidade + 1)
	return true, "Maquina comprada."
end

function DadosJogador:RegistrarColocacao(registro)
	if not self:EstaAtivo() then return false, "Dados ainda nao estao disponiveis." end
	local registros = self._perfil.Data.MaquinasColocadas
	local quantidade = self:ObterQuantidade(registro.MaquinaId)
	if type(registros) ~= "table" or not quantidade then
		return false, "Quantidade invalida no inventario."
	end
	local comprou = quantidade == 0
	if comprou then
		local sucesso, mensagem = self:ComprarMaquina(registro.MaquinaId)
		if not sucesso then return false, mensagem end
		quantidade = self:ObterQuantidade(registro.MaquinaId)
	end
	-- Compra, consumo e registro nao podem ceder a execucao entre suas alteracoes.
	table.insert(registros, registro)
	self:_DefinirQuantidade(registro.MaquinaId, quantidade - 1)
	return true, comprou and "Maquina comprada e colocada." or "Maquina colocada."
end

function DadosJogador:RegistrarRecolhimento(registro)
	if not self:EstaAtivo() then return false, "Dados ainda nao estao disponiveis." end
	local registros = self._perfil.Data.MaquinasColocadas
	local indice = type(registros) == "table" and table.find(registros, registro)
	local quantidade = self:ObterQuantidade(registro.MaquinaId)
	if not indice or not quantidade or quantidade >= 2 ^ 53 - 1 then
		return false, "Nao foi possivel atualizar seu inventario."
	end
	table.remove(registros, indice)
	self:_DefinirQuantidade(registro.MaquinaId, quantidade + 1)
	return true, "Maquina devolvida ao inventario."
end

return DadosJogador
