local Botao = {}
Botao.__index = Botao

function Botao.new(pai, nome, aoAtivar)
	local instancia = Instance.new("TextButton")
	instancia.Name = nome
	instancia.Parent = pai
	local self = setmetatable({ _instancia = instancia, _destruido = false }, Botao)
	self._conexao = instancia.Activated:Connect(function()
		if not self._destruido and instancia.Active then aoAtivar() end
	end)
	return self
end

function Botao:ObterInstancia() return self._instancia end

function Botao:DefinirDisponivel(disponivel)
	self._instancia.Active = disponivel
	self._instancia.AutoButtonColor = disponivel
end

function Botao:Destruir()
	if self._destruido then return end
	self._destruido = true
	self._conexao:Disconnect()
	self._instancia:Destroy()
end

return Botao
