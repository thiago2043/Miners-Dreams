local Shared = game:GetService("ReplicatedStorage").Shared
local Catalogo = require(Shared.CatalogoMaquinas)
local Rotacao = require(Shared.RotacaoConstrucao)
local passo = require(Shared.Medidas).Bloco
local Template = require(script.Parent.Template)
local Premios = require(script.Parent.PremiosRenascimento)
local PremiosAscensao = require(script.Parent.PremiosAscensao)
local Migracao = {}

local function copiar(valor)
if type(valor) ~= "table" then return valor end
local novo = {}
for chave, item in valor do novo[chave] = copiar(item) end
return novo
end

local function limparModificacoesEsteira(maquinaId, mods)
if type(mods) ~= "table" then return nil end
local def = Catalogo[maquinaId]
if def and Rotacao.PermiteInclinar(def) then
mods.Partes = nil
end
return if next(mods) ~= nil then mods else nil
end

local function filtrarPecas(pecas, ajustarPosicao)
if pecas == nil then return end
assert(type(pecas) == "table", "Lista de pecas invalida.")
for i = #pecas, 1, -1 do
local reg = pecas[i]
assert(type(reg) == "table", "Registro de peca invalido.")
local def = Catalogo[reg.MaquinaId]
if not def then
table.remove(pecas, i)
else
if reg.Modificacoes ~= nil then
reg.Modificacoes = limparModificacoesEsteira(reg.MaquinaId, reg.Modificacoes)
end
if ajustarPosicao and type(reg.Posicao) == "table" and #reg.Posicao == 3 then
for e = 1, 3 do
if type(reg.Posicao[e]) == "number" then
reg.Posicao[e] = math.round(reg.Posicao[e] / passo) * passo
end
end
end
end
end
end

local function limpar(dados)
for _, campo in { "Inventory", "InventarioPersonalizado" } do
local inventario = dados[campo]
if inventario ~= nil then
assert(type(inventario) == "table", "Inventario invalido.")
for id, valor in inventario do
if not Catalogo[id] then
inventario[id] = nil
elseif campo == "InventarioPersonalizado" and type(valor) == "table" then
if Rotacao.PermiteInclinar(Catalogo[id]) then
for idx = #valor, 1, -1 do
local limpo = limparModificacoesEsteira(id, valor[idx])
if limpo then valor[idx] = limpo else table.remove(valor, idx) end
end
if #valor == 0 then inventario[id] = nil end
end
end
end
end
end
filtrarPecas(dados.MaquinasColocadas, true)
if dados.Blueprints ~= nil then
assert(type(dados.Blueprints) == "table", "Blueprints invalidos.")
for i = #dados.Blueprints, 1, -1 do
local blueprint = dados.Blueprints[i]
assert(type(blueprint) == "table" and type(blueprint.Pecas) == "table", "Blueprint invalido.")
filtrarPecas(blueprint.Pecas, false)
if #blueprint.Pecas == 0 then table.remove(dados.Blueprints, i) end
end
end
end

function Migracao.Preparar(dados)
assert(type(dados) == "table", "Perfil invalido.")
local novo = {}
for chave, valor in dados do
if Template[chave] ~= nil or chave == "BackupGrade4" or chave == "BackupHitboxes" or chave == "BackupHitboxesV2" or chave == "BackupHitboxesV3" or chave == "BackupHitboxesV4" then
novo[chave] = copiar(valor)
end
end
limpar(novo)
Premios.Migrar(novo)
PremiosAscensao.Entregar(novo)
if novo.BackupGrade4 ~= nil then
assert(type(novo.BackupGrade4) == "table", "Backup de grade invalido.")
limpar(novo.BackupGrade4)
end
return novo
end

return Migracao