local abreviar = require("./suporte/carregador")({}, {})("src/shared/AbreviarInteiro")
for _, caso in {
	{ "0", "0" }, { "000001", "1" }, { "999", "999" }, { "1000", "1K" },
	{ "1500", "1,5K" }, { "12999", "12,99K" }, { "50000000000", "50B" },
	{ "250000000000000000", "250qd" }, { "25000000000000000000", "25qn" },
	{ "2500000000000000000000", "2,5sx" }, { "500000000000000000000000", "500sx" },
	{ "1" .. string.rep("0", 100) .. "1", "100e99" },
} do assert(abreviar(caso[1]) == caso[2], caso[1]) end
assert(not pcall(abreviar, "1e9") and not pcall(abreviar, -1))
print("PASS: abreviacao visual de precos pequenos e grandes sem converter inteiros para number.")
