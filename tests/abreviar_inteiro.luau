local abreviar = require("./suporte/carregador")({}, {})("src/shared/AbreviarInteiro")
for _, caso in {
	{ "0", "0" }, { "000001", "1" }, { "999", "999" }, { "1000", "1K" },
	{ "1500", "1,5K" }, { "12999", "12,99K" }, { "50000000000", "50B" },
	{ "250000000000000000", "250Qd" }, { "25000000000000000000", "25Qn" },
	{ "2500000000000000000000", "2,5Sx" }, { "500000000000000000000000", "500Sx" },
	{ "250000000000000000000000000000000000", "250De" },
	{ 1000, "1K" }, { 1234567, "1,23M" }, { 2 ^ 53 - 1, "9Qd" },
	{ "1" .. string.rep("0", 100) .. "1", "100DTg" },
	{ "1" .. string.rep("0", 36), "1UDe" },
	{ "1" .. string.rep("0", 39), "1DDe" },
	{ "1" .. string.rep("0", 63), "1Vi" },
	{ "1" .. string.rep("0", 66), "1UVi" },
	{ "1" .. string.rep("0", 138), "1QiQag" },
	{ "1" .. string.rep("0", 201), "1SxSxg" },
	{ "1" .. string.rep("0", 303), "1Ce" },
	{ "1" .. string.rep("0", 308), "100UCe" },
	{ string.rep("9", 309), "999,99UCe" },
	{ "1" .. string.rep("0", 309), "1e309" },
} do assert(abreviar(caso[1]) == caso[2], caso[1]) end
local vistos = {}
for grupo = 1, 102 do
	local texto = abreviar("1" .. string.rep("0", grupo * 3))
	assert(not texto:find("e%d") and not vistos[texto], texto)
	vistos[texto] = true
end
assert(not pcall(abreviar, "1e9") and not pcall(abreviar, -1))
assert(not pcall(abreviar, 1.5) and not pcall(abreviar, 2 ^ 53))
assert(abreviar("100001", true) == "100,001K" and abreviar("100002", true) == "100,002K")
print("PASS: abreviacao visual de precos pequenos e grandes sem converter inteiros para number.")
