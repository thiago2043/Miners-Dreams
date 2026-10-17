-- Guarda as selecoes das duas listas; as consultas devolvem dados que o chamador nao pode alterar.
export type Copia = {
	MaquinaId: string, Token: number, Rotacao: CFrame,
	Modificacoes: { [string]: unknown }?,
}
export type Selecao = { Id: number, MaquinaId: string, Rotacao: CFrame, Copia: Copia? }

local SelecaoPecas = {}
SelecaoPecas.__index = SelecaoPecas

-- O mapa privado nao pertence a tabela publica da instancia; a chave fraca permite libera-la da memoria.
local estados = setmetatable({}, { __mode = "k" })

-- Percorre cada tabela e congela uma copia independente, incluindo os niveis internos. Valores como strings e
-- CFrames sao reutilizados; o limite de profundidade interrompe tabelas ciclicas ou grandes demais.
local function copiarCongelando(valor, profundidade)
	if type(valor) ~= "table" then return valor end
	assert((profundidade or 0) < 20, "Selecao profunda demais ou ciclica.")
	local copia = {}
	for chave, item in valor do copia[chave] = copiarCongelando(item, (profundidade or 0) + 1) end
	-- Congelar cada nivel impede que uma ficha altere por referencia a configuracao usada por outra. Como ha
	-- subtabelas, congelar so a tabela externa nao seria suficiente.
	return table.freeze(copia)
end

-- Cria a instancia publica e, no mapa privado do modulo, suas escolhas por aba e o contador de identidades. A
-- tabela devolvida nao entrega esse armazenamento ao chamador.
function SelecaoPecas.new()
	local self = setmetatable({}, SelecaoPecas)
	estados[self] = { itens = {}, proximoId = 0 }
	return self
end

-- Recebe uma aba e devolve a visao congelada da escolha atual, ou nil. A mesma visao pode ser lida por varios
-- paineis sem permitir escrita nos dados internos.
function SelecaoPecas:Obter(aba: string): Selecao?
	return estados[self].itens[aba]
end

-- Cria uma identidade nova para a escolha recebida e copia/congela seus dados, inclusive a personalizacao da
-- copia. Devolve a visao que ficou registrada, sem manter tabelas mutaveis do argumento original.
function SelecaoPecas:Definir(aba: string, maquinaId: string, rotacao: CFrame, copia: Copia?): Selecao
	assert(aba == "Inventario" or aba == "Loja", "Aba de selecao invalida.")
	local estado = estados[self]
	-- O Id identifica esta escolha, mesmo ao selecionar novamente o mesmo tipo. Respostas antigas da rede podem
	-- comparar esse numero para nao agir sobre a ficha nova.
	estado.proximoId += 1
	local selecao = copiarCongelando({ Id = estado.proximoId, MaquinaId = maquinaId, Rotacao = rotacao, Copia = copia })
	estado.itens[aba] = selecao
	return selecao
end

-- Descarta somente a escolha da aba informada. Nao recria uma selecao padrao nem modifica a escolha existente
-- no outro painel.
function SelecaoPecas:Remover(aba: string)
	estados[self].itens[aba] = nil
end

-- Troca a visao imutavel, mas conserva o Id: girar nao significa selecionar outra unidade.
-- Recebe a aba, a identidade esperada e a nova matriz de orientacao. Atualiza apenas a escolha que ainda tem
-- esse Id; uma colocacao antiga ou uma ficha fechada nao deve recuperar uma selecao descartada.
function SelecaoPecas:GuardarRotacao(aba: string, id: number, rotacao: CFrame)
	local selecao = self:Obter(aba)
	-- O fim de uma colocacao antiga nao pode alterar a selecao que a substituiu, nem reabrir uma ficha.
	if not selecao or selecao.Id ~= id then return end
	-- A visao anterior ja foi congelada, entao o giro produz outra tabela. O Id permanece igual porque a
	-- escolha continua a mesma; apenas sua orientacao muda.
	local atualizada = table.clone(selecao)
	atualizada.Rotacao = rotacao
	estados[self].itens[aba] = table.freeze(atualizada)
end

return SelecaoPecas
