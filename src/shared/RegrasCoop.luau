local HttpService = game:GetService("HttpService")

local RegrasCoop = {
LimiteMinimo = 0,
LimiteMaximo = 8,
LimitePadrao = 4,
}

RegrasCoop.OrdemPermissoes = {
{ Chave = "Colocar", Nome = "Colocar e mover peças na plot", Padrao = true },
{ Chave = "Retirar", Nome = "Retirar peças da plot", Padrao = true },
{ Chave = "RetirarTudo", Nome = "└ Usar botão Limpar plot (retirar tudo)", Padrao = true, Pai = "Retirar" },
{ Chave = "Comprar", Nome = "Comprar peças na loja", Padrao = true },
{ Chave = "Vender", Nome = "Vender peças (inventário e plot)", Padrao = true },
{ Chave = "Upgrades", Nome = "Comprar upgrades e ajustar motores", Padrao = true },
{ Chave = "Craftar", Nome = "Craftar máquinas", Padrao = false },
{ Chave = "Prestigio", Nome = "Usar opções de Prestígio", Padrao = false },
{ Chave = "Reencarnar", Nome = "└ Fazer Renascimento (Reencarnar)", Padrao = false, Pai = "Prestigio" },
{ Chave = "Ascender", Nome = "└ Fazer Ascensão (Ascender)", Padrao = false, Pai = "Prestigio" },
{ Chave = "Blueprint", Nome = "Usar Blueprints do dono da plot", Padrao = false },
{ Chave = "ColocarBlueprint", Nome = "└ Colocar blueprint na plot", Padrao = false, Pai = "Blueprint" },
{ Chave = "CriarBlueprint", Nome = "└ Criar novo blueprint", Padrao = false, Pai = "Blueprint" },
{ Chave = "EditarBlueprint", Nome = "└ Editar peças/âncora do blueprint", Padrao = false, Pai = "Blueprint" },
{ Chave = "SubstituirBlueprint", Nome = "└ Substituir blueprint na plot", Padrao = false, Pai = "Blueprint" },
{ Chave = "RenomearBlueprint", Nome = "└ Renomear blueprint", Padrao = false, Pai = "Blueprint" },
{ Chave = "ReordenarBlueprint", Nome = "└ Reordenar blueprints (↑/↓)", Padrao = false, Pai = "Blueprint" },
{ Chave = "DeletarBlueprint", Nome = "└ Deletar blueprint", Padrao = false, Pai = "Blueprint" },
}

local mapaMetadados = {}
for _, item in RegrasCoop.OrdemPermissoes do
mapaMetadados[item.Chave] = item
end

function RegrasCoop.PermissoesPadrao()
local p = {}
for _, item in RegrasCoop.OrdemPermissoes do
p[item.Chave] = item.Padrao
end
return p
end

function RegrasCoop.NormalizarPermissoes(entrada)
local p = RegrasCoop.PermissoesPadrao()
if type(entrada) == "table" then
for chave, meta in mapaMetadados do
if type(entrada[chave]) == "boolean" then
p[chave] = entrada[chave]
end
end
end
for _, item in RegrasCoop.OrdemPermissoes do
if item.Pai and not p[item.Pai] then
p[item.Chave] = false
end
end
return p
end

function RegrasCoop.AlterarPermissao(atual, chave, valor)
local meta = mapaMetadados[chave]
if not meta or type(valor) ~= "boolean" then return RegrasCoop.NormalizarPermissoes(atual) end
local p = table.clone(RegrasCoop.NormalizarPermissoes(atual))
p[chave] = valor

if meta.Pai and valor == true then
p[meta.Pai] = true
end

if not meta.Pai then
if valor == false then
for _, sub in RegrasCoop.OrdemPermissoes do
if sub.Pai == chave then
p[sub.Chave] = false
end
end
elseif valor == true then
local algumSubAtivo = false
for _, sub in RegrasCoop.OrdemPermissoes do
if sub.Pai == chave and p[sub.Chave] then
algumSubAtivo = true
break
end
end
if not algumSubAtivo then
for _, sub in RegrasCoop.OrdemPermissoes do
if sub.Pai == chave then
p[sub.Chave] = true
end
end
end
end
end

return RegrasCoop.NormalizarPermissoes(p)
end

function RegrasCoop.Pode(permissoes, acao)
if type(permissoes) ~= "table" then return false end
local meta = mapaMetadados[acao]
if not meta then return false end
if meta.Pai and not permissoes[meta.Pai] then
return false
end
return permissoes[acao] == true
end

local cacheTexto, cacheTabela = nil, nil
function RegrasCoop.JogadorPode(jogador, acao)
if not jogador then return true end
local donoCoop = jogador:GetAttribute("CoopDonoUserId")
if type(donoCoop) ~= "number" or donoCoop == 0 or donoCoop == jogador.UserId then
return true
end
local texto = jogador:GetAttribute("PermissoesCoop")
if type(texto) ~= "string" or texto == "" then
return false
end
if texto ~= cacheTexto then
local ok, decodificado = pcall(HttpService.JSONDecode, HttpService, texto)
if ok and type(decodificado) == "table" then
cacheTexto = texto
cacheTabela = RegrasCoop.NormalizarPermissoes(decodificado)
else
return false
end
end
return cacheTabela ~= nil and RegrasCoop.Pode(cacheTabela, acao)
end

return RegrasCoop