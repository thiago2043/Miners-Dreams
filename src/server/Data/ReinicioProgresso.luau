local ReinicioProgresso = {}
ReinicioProgresso.__index = ReinicioProgresso

local function copiar(valor)
	if type(valor) ~= "table" then return valor end
	local novo = {}
	for chave, item in valor do novo[chave] = copiar(item) end
	return novo
end

-- Cada politica escolhe explicitamente o que sobrevive ao reinicio. Outra mecanica pode omitir
-- RecompensasReencarnacao para apaga-las; nao ha excecoes permanentes escondidas nesta classe.
function ReinicioProgresso.new(inicial, preservados)
	return setmetatable({ _inicial = copiar(inicial), _preservados = table.clone(preservados) }, ReinicioProgresso)
end

-- Prepara dados novos sem tocar nos atuais. Campos nao preservados voltam ao estado inicial,
-- incluindo o kit basico; o chamador so substitui o perfil depois de validar a operacao inteira.
function ReinicioProgresso:Preparar(dados)
	local novo = copiar(self._inicial)
	for _, campo in self._preservados do
		if dados[campo] ~= nil then novo[campo] = copiar(dados[campo]) end
	end
	return novo
end

return ReinicioProgresso
