--[[
Módulo: Botao (LPOO)
Responsabilidade:
Encapsula um elemento interativo TextButton da interface, gerenciando seu estado
de disponibilidade (ativo/inativo), ciclo de vida de conexões e validação de foco
junto ao GerenciadorJanelas (impedindo cliques em janelas cobertas por outras).
]]

local Botao = {}
Botao.__index = Botao

local gerenciadorJanelas = nil

--- Obtém de forma preguiçosa (lazy-load) a referência ao GerenciadorJanelas para evitar dependência circular.
local function obterGerenciador()
if gerenciadorJanelas ~= nil then return gerenciadorJanelas end
local modulo = script.Parent:FindFirstChild("GerenciadorJanelas")
if modulo then
local ok, g = pcall(require, modulo)
if ok then
gerenciadorJanelas = g
return g
end
end
gerenciadorJanelas = false
return false
end

--- Construtor da classe Botao.
--- @param pai Instance -- Contêiner pai onde o botão será inserido
--- @param nome string -- Nome identificador do instância e texto inicial
--- @param aoAtivar () -> () -- Função callback executada quando o botão é clicado
--- @return table -- Nova instância de Botao
function Botao.new(pai, nome, aoAtivar)
assert(typeof(pai) == "Instance", "Pai do botao invalido.")
assert(type(nome) == "string" and #nome > 0, "Nome do botao invalido.")
assert(type(aoAtivar) == "function", "Callback do botao invalido.")

local instancia = Instance.new("TextButton")
instancia.Name = nome
instancia.Text = nome
instancia.Active = false
instancia.AutoButtonColor = false
instancia:SetAttribute("BotaoDisponivel", false)
instancia.Parent = pai

local self = setmetatable({
_instancia = instancia,
_disponivel = false,
_destruido = false,
}, Botao)

self._conexao = instancia.Activated:Connect(function()
if self._destruido or not instancia.Active then return end
-- Verifica no GerenciadorJanelas se a janela dona deste botão está no topo sob o cursor
local ger = obterGerenciador()
if ger and ger.PodeInteragir and not ger.PodeInteragir(instancia) then
return
end
aoAtivar()
end)

return self
end

--- Retorna a instância física do TextButton no Roblox.
--- @return TextButton
function Botao:ObterInstancia()
return self._instancia
end

--- Retorna se o botão está atualmente habilitado para interação.
--- @return boolean
function Botao:EstaDisponivel()
return self._disponivel and not self._destruido
end

--- Altera o estado de disponibilidade lógica e visual do botão.
--- Salva o estado no atributo "BotaoDisponivel" para permitir restauração após inibição por sobreposição de janelas.
--- @param disponivel boolean
function Botao:DefinirDisponivel(disponivel)
assert(type(disponivel) == "boolean", "Disponibilidade deve ser booleana.")
if self._destruido then return end
self._disponivel = disponivel
self._instancia:SetAttribute("BotaoDisponivel", disponivel)
self._instancia.Active = disponivel
end

--- Desconecta eventos e remove a instância da interface.
function Botao:Destruir()
if self._destruido then return end
self._destruido = true
if self._conexao then
self._conexao:Disconnect()
self._conexao = nil
end
self._instancia:Destroy()
end

return Botao