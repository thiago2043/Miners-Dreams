local InteiroGrande = require(script.Parent.InteiroGrande)

local sufixos = { "", "K", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "O", "N" }
local unidades = { "", "U", "D", "T", "Qa", "Qi", "Sx", "Sp", "O", "N" }
local dezenas = { "De", "Vi", "Tg", "Qag", "Qig", "Sxg", "Spg", "Og", "Ng", "Ce" }

for indice = 10, 101 do
local unidade = unidades[indice % 10 + 1]
local dezena = dezenas[math.floor(indice / 10)]
sufixos[indice + 2] = unidade .. dezena
end

local mapaExpoentes = {}
for idx, s in sufixos do
if s ~= "" then
mapaExpoentes[string.lower(s)] = (idx - 1) * 3
end
end

local function montarComExpoente(parteInt, parteFrac, exp)
local digitos = parteInt .. parteFrac
local zerosFaltam = exp - #parteFrac
local resultado
if zerosFaltam >= 0 then
if #digitos + zerosFaltam > 309 then
return nil, "O valor máximo suportado tem até 309 dígitos."
end
resultado = (digitos .. string.rep("0", zerosFaltam)):gsub("^0+", "")
else
local corte = #digitos + zerosFaltam
resultado = if corte > 0 then digitos:sub(1, corte):gsub("^0+", "") else ""
end
if resultado == "" then
return nil, "O valor deve ser maior que zero."
end
if #resultado > 309 or not InteiroGrande.eValido(resultado) then
return nil, "O valor máximo suportado tem até 309 dígitos."
end
return resultado, nil
end

return function(entrada)
if entrada == nil then return nil, nil end
if type(entrada) == "number" then
if entrada ~= entrada or entrada <= 0 or entrada >= math.huge then
return nil, "Informe um valor maior que zero."
end
entrada = string.format("%.0f", math.floor(entrada))
end
if type(entrada) ~= "string" then
return nil, "Valor inválido."
end

local limpo = entrada:gsub("%s+", ""):gsub("^%$", "")
if limpo == "" then
return nil, nil
end

local _, qtdVirgulas = limpo:gsub(",", "")
local _, qtdPontos = limpo:gsub("%.", "")
if qtdVirgulas == 1 and qtdPontos == 0 then
limpo = limpo:gsub(",", ".")
elseif qtdVirgulas > 0 then
return nil, "Use apenas uma vírgula ou ponto para casas decimais (ex: 1,5M ou 2.5B)."
end

if limpo:match("^%d+$") then
local res = limpo:gsub("^0+", "")
if res == "" then return nil, "Informe um valor maior que zero." end
if #res > 309 then return nil, "O valor máximo suportado tem até 309 dígitos." end
return res, nil
end

local intSci, fracSci, expSci = limpo:match("^(%d+)%.?(%d*)[eE]%+?(%d+)$")
if intSci and expSci then
local exp = tonumber(expSci)
if not exp or exp > 308 then
return nil, "Expoente máximo permitido é 308."
end
return montarComExpoente(intSci, fracSci or "", exp)
end

local intSuf, fracSuf, sufixo = limpo:match("^(%d+)%.?(%d*)([a-zA-Z]+)$")
if intSuf and sufixo then
local exp = mapaExpoentes[string.lower(sufixo)]
if not exp then
return nil, "Sufixo desconhecido ('" .. sufixo .. "'). Exemplos: 25K, 1,5M, 10B, 1Qd, 1e18."
end
return montarComExpoente(intSuf, fracSuf or "", exp)
end

return nil, "Formato inválido. Exemplos: 50000, 25K, 1,5M, 10B, 1Qd ou 1e18."
end