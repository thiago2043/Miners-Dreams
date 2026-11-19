local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local function separadorDecimal()
local j = Players.LocalPlayer
local locale = (j and j.LocaleId ~= "" and j.LocaleId) or LocalizationService.RobloxLocaleId or "pt-br"
return if string.lower(locale):match("^([a-z]+)") == "pt" then "," else "."
end
local Traducao = require(ReplicatedStorage.Shared.Traducao)
local AbreviarInteiro = require(script.Parent.FormatarNumero).Inteiro
local Efeitos = require(ReplicatedStorage.Shared.EfeitosUpgrades)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Inteiro = require(ReplicatedStorage.Shared.InteiroGrande)
local bloco = require(ReplicatedStorage.Shared.Medidas).Bloco

local FichaMaquina = {}

local origens = { Renascimento = "RN", ["Ascensão"] = "AS", Ascensao = "AS" }

function FichaMaquina.RotuloCatalogo(item)
if item.Preco and (item.Preco ~= "0" or not item.Obtencao) then
return "$" .. AbreviarInteiro(item.Preco)
end
return origens[item.Obtencao] or item.Obtencao or Traducao.T("comum.sem_preco", "Sem preço")
end

local function numero(valor)
if type(valor) == "number" and valor >= 0 and valor < 2 ^ 53 and valor % 1 == 0 then
return AbreviarInteiro(valor)
end
if type(valor) == "string" and valor:match("^%d+$") then
return AbreviarInteiro(valor)
end
if type(valor) == "number" then
return ((string.format("%.6f", valor):gsub("0+$", ""):gsub("%.$", "")):gsub("%.", separadorDecimal()))
end
return (tostring(valor):gsub("%.", separadorDecimal()))
end

function FichaMaquina.FormatarMultiplicador(valor)
if type(valor) == "number" then
local texto = tostring(valor)
valor = if Inteiro.eDecimalValido(texto) then texto else string.format("%.2f", valor)
end
if Inteiro.eValido(valor) then
return AbreviarInteiro(valor)
end

local centesimos = "00" .. Inteiro.multiplicarArredondado("100", valor)
local inteiro = centesimos:sub(1, -3):gsub("^0+", "")
local fracao = centesimos:sub(-2):gsub("0+$", "")
if inteiro == "" then inteiro = "0" end
if #inteiro > 3 or fracao == "" then
return AbreviarInteiro(inteiro)
end
return inteiro .. separadorDecimal() .. fracao
end

local function efeito(configuracao)
local bonus = configuracao.Bonus and configuracao.Bonus ~= "0"
local multiplicador = configuracao.Multiplicador or "1"
local texto = bonus and multiplicador == "1" and "" or "×" .. FichaMaquina.FormatarMultiplicador(multiplicador)
if bonus then
texto ..= (texto == "" and "+" or " + ") .. numero(configuracao.Bonus)
end
return texto
end

function FichaMaquina.Descrever(definicao, jogador)
local linhas = {}
if definicao.Blocos then
local b = definicao.Blocos
table.insert(linhas, Traducao.T("stats.tamanho", "Tamanho (L×C×A): {l} × {c} × {a} blocos", {
l = numero(b[1]),
c = numero(b[3]),
a = numero(b[2]),
}, jogador))
end

local transportes, vendedor = {}, false
for _, c in definicao.Componentes or {} do
if c.Tipo == "Vendedor" then vendedor = true end
end

if definicao.Obtencao then
table.insert(linhas, Traducao.T("stats.obtencao_permanente", "{origem} • Permanente", {
origem = Traducao.Obtencao(definicao.Obtencao, jogador),
}, jogador))
end

for _, componente in definicao.Componentes or {} do
if componente.Tipo == "Soltador" then
local minerio = componente.Minerio
table.insert(linhas, Traducao.T("stats.minerio", "Minério: ${valor}", {
valor = AbreviarInteiro(Efeitos.Extracao(minerio.Valor, Efeitos.Nivel(jogador, "Extracao"))),
}, jogador))
table.insert(linhas, Traducao.T("stats.intervalo", "Intervalo de geração: {tempo} s", {
tempo = numero(componente.Intervalo),
}, jogador))
table.insert(linhas, Traducao.T("stats.tamanho_minerio", "Tamanho do minério: {tam} studs", {
tam = table.concat({ numero(minerio.Tamanho[1]), numero(minerio.Tamanho[2]), numero(minerio.Tamanho[3]) }, " × "),
}, jogador))
elseif componente.Tipo == "Transportador" then
local selecionado = jogador and jogador:GetAttribute("VelocidadeMotores") or 0
local nivel = Upgrades.Valido(selecionado) and math.min(selecionado, Efeitos.Nivel(jogador, "Motores")) or 0
local texto = Traducao.T("stats.transporte", "Transporte: {vel} blocos/s", {
vel = numero(Efeitos.Velocidade(componente.Velocidade, nivel) / bloco),
}, jogador)
if not vendedor and not transportes[texto] then
table.insert(linhas, texto)
transportes[texto] = true
end
elseif componente.Tipo == "Elevador" then
table.insert(linhas, Traducao.T("stats.elevador", "Altura ajustável · entrada e saída nas quatro faces", nil, jogador))
elseif componente.Tipo == "Modificador" then
table.insert(linhas, Traducao.T("stats.modificacao", "Modificação: ×{mult}", {
mult = FichaMaquina.FormatarMultiplicador(Efeitos.MultiplicadorTotalModificador(componente)),
}, jogador))
if componente.Renascimento then
table.insert(linhas, Traducao.T("stats.copias", "Cópias: +50% por unidade adicional", nil, jogador))
end
local limite = Efeitos.UsosModificador(componente.LimiteUsos, Efeitos.Nivel(jogador, "Calibracao"))
table.insert(linhas, Traducao.T("stats.limite", "Limite: {limite}", {
limite = limite and numero(limite) or "inf",
}, jogador))
elseif componente.Tipo == "Vendedor" then
local nivel = Efeitos.Nivel(jogador, "Fundicao")
local venda = efeito(componente)
if nivel > 0 then
local fator = Upgrades.Fator(nivel)
local base = venda
venda = efeito({
Multiplicador = Inteiro.multiplicarDecimal(componente.Multiplicador or "1", fator),
Bonus = Inteiro.multiplicarDecimal(componente.Bonus or "0", fator),
})
if (componente.Multiplicador or "1"):find("%.") then
venda = "≈" .. venda .. "\n" .. Traducao.T("stats.calculo", "Cálculo: ({base}) → ×{fator}", {
base = base,
fator = FichaMaquina.FormatarMultiplicador(fator),
}, jogador)
end
end
table.insert(linhas, Traducao.T("stats.venda", "Venda: {valor}", { valor = venda }, jogador))
end
end

return table.concat(linhas, "\n")
end

return FichaMaquina