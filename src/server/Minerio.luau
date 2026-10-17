-- Representa a parte do minerio e oferece operacoes validadas sobre valor, dimensoes, propriedade e consumo.
local ServerScriptService = game:GetService("ServerScriptService")
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))

local Minerio = {}
Minerio.__index = Minerio

-- Recebe uma BasePart chamada Minerio e cria o objeto de operacoes sobre ela. Nao clona nem posiciona a parte;
-- Criar e a funcao que monta uma unidade nova.
function Minerio.new(parte)
	assert(parte:IsA("BasePart") and parte.Name == "Minerio", "Parte nao representa um minerio.")
	return setmetatable({ _parte = parte }, Minerio)
end

-- Confere valor decimal, tres dimensoes positivas e, quando fornecidos, atrito e elasticidade entre zero e um.
-- Devolve um booleano para o soltador recusar configuracoes invalidas.
function Minerio.DefinicaoValida(definicao)
	if type(definicao) ~= "table" or not InteiroGrande.eValido(definicao.Valor)
		or type(definicao.Tamanho) ~= "table" or #definicao.Tamanho ~= 3
	then return false end
	for _, valor in definicao.Tamanho do
		if type(valor) ~= "number" or not (valor > 0 and valor < math.huge) then return false end
	end
	for _, nome in { "Atrito", "Elasticidade" } do
		local valor = definicao[nome]
		if valor ~= nil and (type(valor) ~= "number" or not (valor >= 0 and valor <= 1)) then return false end
	end
	return true
end

-- Recebe a definicao, o CFrame de saida e o terreno dono. Cria a Part ancorada com valor/tamanho validados e
-- atributos de propriedade, insere na pasta Minerios e devolve o objeto Minerio.
function Minerio.Criar(definicao, cframe, terreno)
	assert(Minerio.DefinicaoValida(definicao), "Definicao de minerio invalida.")
	local parte = Instance.new("Part")
	parte.Name = "Minerio"
	-- O objeto envolve a Part recem-criada e aplica valor/tamanho pelos mesmos metodos validados usados depois.
	-- O atributo Valor e texto decimal; Size e um Vector3 em studs.
	local self = Minerio.new(parte)
	assert(self:DefinirValor(definicao.Valor), "Valor inicial de minerio invalido.")
	assert(self:DefinirTamanho(Vector3.new(table.unpack(definicao.Tamanho))), "Tamanho inicial de minerio invalido.")
	parte.CFrame = cframe
	parte.Color = Color3.fromRGB(140, 100, 65)
	-- A simulacao propria controla a pose desta Part. Desligar a fisica nativa, toques e consultas evita que o
	-- Roblox tambem mova o minerio ou o considere obstaculo de outro minerio.
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanTouch = false
	parte.CanQuery = false
	-- Os atributos ligam a unidade a uma plot especifica. Sensores conferem esses dados e a pasta antes de
	-- modificar ou pagar por ela.
	parte:SetAttribute("DonoUserId", terreno:GetAttribute("DonoUserId"))
	parte:SetAttribute("TerrenoId", terreno:GetAttribute("TerrenoId"))
	parte.Parent = terreno:FindFirstChild("Minerios")
	return self
end

-- Devolve a Part real usada como representacao visual. A simulacao atualiza seu CFrame e os componentes podem
-- usa-la como identidade da unidade.
function Minerio:ObterParte() return self._parte end
-- Devolve o atributo Valor como texto decimal. O calculo deve passar por CalcularValor/InteiroGrande, sem
-- converter o saldo completo para number.
function Minerio:ObterValor() return self._parte:GetAttribute("Valor") end
-- Devolve o Size atual da Part, em studs. A simulacao rele essas dimensoes para que o corpo acompanhe uma
-- eventual mudanca de tamanho.
function Minerio:ObterTamanho() return self._parte.Size end

-- Recebe uma string decimal valida e atualiza o atributo Valor. Devolve false sem escrever quando o formato e
-- invalido, ou true depois da alteracao.
function Minerio:DefinirValor(valor)
	if not InteiroGrande.eValido(valor) then return false end
	self._parte:SetAttribute("Valor", valor)
	return true
end

-- Recebe um Vector3 com tres dimensoes positivas e finitas e grava o Size. Devolve true quando aplicado ou
-- false para uma dimensao invalida.
function Minerio:DefinirTamanho(tamanho)
	if typeof(tamanho) ~= "Vector3" then return false end
	for _, valor in { tamanho.X, tamanho.Y, tamanho.Z } do
		if not (valor > 0 and valor < math.huge) then return false end
	end
	self._parte.Size = tamanho
	return true
end

-- Recebe o terreno esperado e confere pasta, dono, identificador e marca Processado. E a barreira usada antes
-- de modificar ou vender uma unidade.
function Minerio:EstaDisponivel(terreno)
	return self._parte.Parent == terreno:FindFirstChild("Minerios")
		and self._parte:GetAttribute("Processado") ~= true
		and self._parte:GetAttribute("DonoUserId") == terreno:GetAttribute("DonoUserId")
		and self._parte:GetAttribute("TerrenoId") == terreno:GetAttribute("TerrenoId")
end

-- Calcula valor atual vezes multiplicador mais bonus usando as strings decimais. Os argumentos omitidos
-- equivalem a 1 e 0; devolve nil se o valor atual estiver invalido e nao grava o resultado automaticamente.
function Minerio:CalcularValor(multiplicador, bonus)
	local valor = self:ObterValor()
	if not InteiroGrande.eValido(valor) then return nil end
	return InteiroGrande.somar(InteiroGrande.multiplicar(valor, multiplicador or "1"), bonus or "0")
end

-- Marca a unidade como processada e destroi sua Part. O vendedor chama esse metodo depois de confirmar o
-- credito, impedindo outro sensor de vender a mesma unidade.
function Minerio:Consumir()
	self._parte:SetAttribute("Processado", true)
	self._parte:Destroy()
end

return Minerio
