local Botao = {}
Botao.__index = Botao

local gerenciadorJanelas = nil
local function obterGerenciador()
if gerenciadorJanelas ~= nil then return gerenciadorJanelas end
local modulo = script.Parent:FindFirstChild("GerenciadorJanelas")
if modulo then
local ok, g = pcall(require, modulo)
if ok then gerenciadorJanelas = g; return g end
end
gerenciadorJanelas = false
return false
end

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

local self = setmetatable({ _instancia = instancia, _destruido = false }, Botao)
self._conexao = instancia.Activated:Connect(function()
if self._destruido or not instancia.Active then return end
local ger = obterGerenciador()
if ger and ger.PodeInteragir and not ger.PodeInteragir(instancia) then
return
end
aoAtivar()
end)
return self
end

function Botao:ObterInstancia()
return self._instancia
end

function Botao:DefinirDisponivel(disponivel)
assert(type(disponivel) == "boolean", "Disponibilidade deve ser booleana.")
if self._destruido then return end
self._instancia:SetAttribute("BotaoDisponivel", disponivel)
self._instancia.Active = disponivel
end

function Botao:Destruir()
if self._destruido then return end
self._destruido = true
self._conexao:Disconnect()
self._instancia:Destroy()
end

return Botao