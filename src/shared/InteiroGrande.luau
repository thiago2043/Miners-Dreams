--!native
local InteiroGrande = {}

local function normalizar(valor: string): string
  if valor:sub(1, 1) ~= "0" then return valor end
  local limpo = valor:gsub("^0+", "")
  return if limpo == "" then "0" else limpo
end

function InteiroGrande.eValido(valor)
  return type(valor) == "string" and valor:match("^[0-9]+$") ~= nil
end

function InteiroGrande.menor(a: string, b: string): boolean
  assert(InteiroGrande.eValido(a), "O primeiro valor deve conter apenas digitos.")
  assert(InteiroGrande.eValido(b), "O segundo valor deve conter apenas digitos.")
  a = normalizar(a)
  b = normalizar(b)
  return #a < #b or (#a == #b and a < b)
end

function InteiroGrande.somar(a, b)
  assert(InteiroGrande.eValido(a), "O primeiro valor deve conter apenas digitos.")
  assert(InteiroGrande.eValido(b), "O segundo valor deve conter apenas digitos.")
  if b == "0" then return normalizar(a) end
  if a == "0" then return normalizar(b) end

  local posicaoA = #a
  local posicaoB = #b
  local vaiUm = 0
  local digitos = {}

  while posicaoA > 0 or posicaoB > 0 or vaiUm > 0 do
    local digitoA = if posicaoA > 0 then string.byte(a, posicaoA) - 48 else 0
    local digitoB = if posicaoB > 0 then string.byte(b, posicaoB) - 48 else 0
    local soma = digitoA + digitoB + vaiUm
    table.insert(digitos, tostring(soma % 10))
    vaiUm = math.floor(soma / 10)
    posicaoA -= 1
    posicaoB -= 1
  end

  return normalizar(string.reverse(table.concat(digitos)))
end

function InteiroGrande.subtrair(a, b)
  assert(InteiroGrande.eValido(a), "O primeiro valor deve conter apenas digitos.")
  assert(InteiroGrande.eValido(b), "O segundo valor deve conter apenas digitos.")

  a = normalizar(a)
  b = normalizar(b)
  if b == "0" then return a end
  if a == b then return "0" end
  if #a < #b or (#a == #b and a < b) then return nil end

  local posicaoA = #a
  local posicaoB = #b
  local emprestimo = 0
  local digitos = {}

  while posicaoA > 0 do
    local digitoA = string.byte(a, posicaoA) - 48
    local digitoB = if posicaoB > 0 then string.byte(b, posicaoB) - 48 else 0
    local diferenca = digitoA - digitoB - emprestimo
    if diferenca < 0 then
      diferenca += 10
      emprestimo = 1
    else
      emprestimo = 0
    end
    table.insert(digitos, tostring(diferenca))
    posicaoA -= 1
    posicaoB -= 1
  end

  return normalizar(string.reverse(table.concat(digitos)))
end

function InteiroGrande.multiplicar(a, b)
  assert(InteiroGrande.eValido(a) and InteiroGrande.eValido(b), "Os valores devem conter apenas digitos.")
  if a == "0" or b == "0" then return "0" end
  if a == "1" then return normalizar(b) end
  if b == "1" then return normalizar(a) end

  local digitos = table.create(#a + #b, 0)
  for i = #a, 1, -1 do
    for j = #b, 1, -1 do
      local posicao = #a - i + #b - j + 1
      digitos[posicao] += (string.byte(a, i) - 48) * (string.byte(b, j) - 48)
    end
  end
  for i = 1, #digitos - 1 do
    digitos[i + 1] += math.floor(digitos[i] / 10)
    digitos[i] %= 10
  end
  while #digitos > 1 and digitos[#digitos] == 0 do table.remove(digitos) end
  for i, digito in digitos do digitos[i] = tostring(digito) end
  return string.reverse(table.concat(digitos))
end

function InteiroGrande.eDecimalValido(valor)
  return type(valor) == "string" and (valor:match("^[0-9]+$") ~= nil or valor:match("^[0-9]+%.[0-9]+$") ~= nil)
end

function InteiroGrande.multiplicarDecimal(a, b)
  assert(InteiroGrande.eDecimalValido(a) and InteiroGrande.eDecimalValido(b), "Decimal invalido.")
  local fa, fb = a:match("%.(%d+)$") or "", b:match("%.(%d+)$") or ""
  local da, db = a:gsub("%.", ""), b:gsub("%.", "")
  local produto = InteiroGrande.multiplicar(da, db)
  local casas = #fa + #fb
  if casas == 0 then return produto end
  if #produto <= casas then produto = string.rep("0", casas + 1 - #produto) .. produto end
  local corte = #produto - casas
  return (produto:sub(1, corte) .. "." .. produto:sub(corte + 1)):gsub("0+$", ""):gsub("%.$", "")
end

function InteiroGrande.multiplicarArredondado(valor, multiplicador)
  assert(InteiroGrande.eValido(valor) and InteiroGrande.eDecimalValido(multiplicador), "Valor ou multiplicador invalido.")
  if multiplicador == "1" then return normalizar(valor) end
  local inteiro, fracao = multiplicador:match("^([0-9]+)%.([0-9]+)$")
  if not inteiro then return InteiroGrande.multiplicar(valor, multiplicador) end
  local produto = InteiroGrande.multiplicar(valor, inteiro .. fracao)
  if #produto <= #fracao then produto = string.rep("0", #fracao + 1 - #produto) .. produto end
  local corte = #produto - #fracao
  local resultado = produto:sub(1, corte)
  if produto:sub(corte + 1, corte + 1) >= "5" then resultado = InteiroGrande.somar(resultado, "1") end
  return resultado
end

return InteiroGrande
