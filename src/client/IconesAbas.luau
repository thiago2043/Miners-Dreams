-- Formas nativas mantem os icones nitidos e disponiveis pelo Rojo, sem depender de imagens publicadas.
local IconesAbas = {}
local fundo = Color3.fromRGB(17, 22, 26)
local cores = {
	Inventario = Color3.fromRGB(255, 51, 137), Loja = Color3.fromRGB(40, 238, 146),
	Upgrades = Color3.fromRGB(147, 93, 255), Prestigio = Color3.fromRGB(255, 181, 63),
	Blueprints = Color3.fromRGB(49, 211, 240), Configuracoes = Color3.fromRGB(255, 214, 78),
	Classificacao = Color3.fromRGB(255, 190, 86),
	Administracao = Color3.fromRGB(112,198,255),
	Tutorial = Color3.fromRGB(101,228,196),
}

-- Coordenadas de desenho usam uma placa de 56 unidades; Scale acompanha o tamanho real do botao.
-- x/y indicam o canto superior esquerdo; raio arredonda os cantos e giro e medido em graus.
local function retangulo(pai, cor, x, y, largura, altura, raio, giro)
	local forma = Instance.new("Frame")
	forma.Name = "Forma"
	forma.Position, forma.Size = UDim2.fromScale(x / 56, y / 56), UDim2.fromScale(largura / 56, altura / 56)
	forma.BackgroundColor3, forma.BorderSizePixel = cor, 0
	forma.Rotation, forma.ZIndex, forma.Parent = giro or 0, pai.ZIndex + 1, pai
	if raio then
		local canto = Instance.new("UICorner")
		canto.CornerRadius, canto.Parent = UDim.new(0, raio), forma
	end
	return forma
end

-- Desenha o segmento entre dois pontos: Pitagoras fornece o comprimento e atan2 fornece a inclinacao.
-- O retangulo fica ancorado no centro para girar sem deslocar as extremidades.
local function linha(pai, cor, x1, y1, x2, y2, espessura)
	local dx, dy = x2 - x1, y2 - y1
	local forma = retangulo(pai, cor, (x1 + x2) / 2, (y1 + y2) / 2,
		math.sqrt(dx * dx + dy * dy), espessura, espessura / 2, math.deg(math.atan2(dy, dx)))
	forma.AnchorPoint = Vector2.new(0.5, 0.5)
	return forma
end

local desenhos = {
	Tutorial = function(pai, cor)
		for _, x in { 9, 29 } do
			retangulo(pai, cor, x, 13, 18, 29, 2)
			retangulo(pai, fundo, x + 3, 16, 12, 23, 1)
			for _, y in { 21, 27, 33 } do retangulo(pai, cor, x + 5, y, 8, 2, 1) end
		end
		retangulo(pai, cor, 26, 16, 4, 29, 1)
	end,
	Classificacao = function(pai, cor)
		retangulo(pai, cor, 9, 31, 11, 15, 2)
		retangulo(pai, cor, 23, 20, 11, 26, 2)
		retangulo(pai, cor, 37, 35, 11, 11, 2)
		retangulo(pai, cor, 26, 9, 6, 6, 1, 45)
	end,
	-- Prancheta: recorta o encaixe superior e as tres linhas usando a cor do fundo.
	Inventario = function(pai, cor)
		retangulo(pai, cor, 13, 12, 30, 33, 4)
		retangulo(pai, fundo, 22, 12, 12, 4, 1)
		for _, y in { 21, 29, 37 } do
			retangulo(pai, fundo, 18, y, 4, 4, 1)
			retangulo(pai, fundo, 25, y, 13, 4, 1)
		end
	end,
	-- Carrinho: segmentos formam cabo/cesto, e dois retangulos arredondados formam as rodas.
	Loja = function(pai, cor)
		linha(pai, cor, 10, 12, 16, 12, 4)
		linha(pai, cor, 16, 12, 22, 35, 4)
		linha(pai, cor, 18, 18, 43, 18, 4)
		linha(pai, cor, 43, 18, 39, 29, 4)
		linha(pai, cor, 21, 29, 39, 29, 4)
		linha(pai, cor, 22, 35, 40, 35, 4)
		retangulo(pai, cor, 20, 39, 7, 7, 4)
		retangulo(pai, cor, 34, 39, 7, 7, 4)
	end,
	-- Duas setas para cima compartilham o mesmo desenho, deslocado verticalmente.
	Upgrades = function(pai, cor)
		for _, y in { 14, 27 } do
			linha(pai, cor, 15, y + 13, 28, y, 5)
			linha(pai, cor, 28, y, 41, y + 13, 5)
		end
	end,
	-- Coroa com tres pontas; os quadrados inclinados representam os detalhes acima delas.
	Prestigio = function(pai, cor)
		linha(pai, cor, 14, 20, 19, 35, 5)
		linha(pai, cor, 19, 35, 28, 18, 5)
		linha(pai, cor, 28, 18, 37, 35, 5)
		linha(pai, cor, 37, 35, 42, 20, 5)
		retangulo(pai, cor, 17, 34, 22, 8, 2)
		for _, ponto in { { 11, 14 }, { 25, 10 }, { 39, 14 } } do
			retangulo(pai, cor, ponto[1], ponto[2], 6, 6, 1, 45)
		end
		retangulo(pai, fundo, 21, 36, 14, 2, 1)
	end,
	-- Folha inclinada com moldura e linhas internas; o giro do pai acompanha todas as suas formas.
	Blueprints = function(pai, cor)
		pai.Rotation = -10
		retangulo(pai, cor, 14, 12, 28, 32, 3)
		retangulo(pai, fundo, 18, 16, 20, 24, 1)
		retangulo(pai, cor, 22, 21, 12, 3, 1)
		retangulo(pai, cor, 22, 28, 9, 3, 1)
		retangulo(pai, cor, 18, 36, 20, 3, 1)
	end,
	-- Dentes distribuidos num circulo a cada 45 graus, com um recorte central da cor do fundo.
	Configuracoes = function(pai, cor)
		for indice = 0, 7 do
			local angulo = indice * math.pi / 4
			retangulo(pai, cor, 28 + math.cos(angulo) * 15 - 3,
				28 + math.sin(angulo) * 15 - 5, 6, 10, 1, math.deg(angulo) + 90)
		end
		retangulo(pai, cor, 15, 15, 26, 26, 13)
		retangulo(pai, fundo, 22, 22, 12, 12, 6)
	end,
}

-- Decora o TextButton existente; a acao e o ciclo de vida continuam pertencendo ao objeto Botao.
function IconesAbas.Criar(botao, aba)
	local cor = assert(cores[aba], "Icone de aba nao definido: " .. tostring(aba))
	local canto = Instance.new("UICorner")
	canto.CornerRadius, canto.Parent = UDim.new(0, 8), botao
	botao.ClipsDescendants = true
	local icone = Instance.new("Frame")
	icone.Name, icone.Size, icone.BackgroundTransparency = "Icone", UDim2.fromScale(1, 1), 1
	icone.ZIndex, icone.Parent = botao.ZIndex + 1, botao
	retangulo(icone, cor:Lerp(fundo, 0.94), 3, 3, 50, 50, 6)
	-- Pequenas marcas nos cantos repetem o aspecto de placa industrial da referencia.
	for _, ponto in { { 7, 7 }, { 49, 7 }, { 7, 49 }, { 49, 49 } } do
		local marca = retangulo(icone, cor, ponto[1] - 4, ponto[2] - 1, 8, 3, 1, 45)
		marca.BackgroundTransparency = 0.75
	end
	local simbolo = Instance.new("Frame")
	simbolo.Name, simbolo.Size, simbolo.BackgroundTransparency = "Simbolo", UDim2.fromScale(1, 1), 1
	simbolo.ZIndex, simbolo.Parent = icone.ZIndex + 2, icone
	if aba=="Administracao" then
		local rotulo=Instance.new("TextLabel")
		rotulo.Size,rotulo.BackgroundTransparency=UDim2.fromScale(1,1),1
		rotulo.Text,rotulo.TextColor3,rotulo.TextSize,rotulo.Font="ADM",cor,20,Enum.Font.SourceSansBold
		rotulo.ZIndex,rotulo.Parent=simbolo.ZIndex+1,simbolo
	else desenhos[aba](simbolo, cor) end
	return icone
end

-- As categorias da loja usam silhuetas sem placa propria: GradePecas controla o fundo e recolore
-- as formas ao trocar o filtro. O retorno e um elemento visual, nao outro controlador de botao.
function IconesAbas.CriarCategoria(botao, categoria)
  local icone = Instance.new("Frame")
  icone.Name, icone.BackgroundTransparency = "IconeCategoria", 1
  icone.AnchorPoint, icone.Position, icone.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1)
  icone.ZIndex, icone.Parent = botao.ZIndex + 1, botao
  local proporcao = Instance.new("UIAspectRatioConstraint")
  proporcao.AspectRatio = 1
  proporcao.AspectType = Enum.AspectType.FitWithinMaxSize
  proporcao.Parent = icone
	local cor = Color3.fromRGB(128, 142, 138)
	if categoria == "Todos" then
		-- Quatro quadrados representam a visao completa do catalogo.
		for _, x in { 13, 31 } do
			for _, y in { 13, 31 } do retangulo(icone, cor, x, y, 12, 12, 2) end
		end
	elseif categoria == "Soltador" then
		-- Base, suporte e cabeca de uma mineradora, com saida voltada para baixo.
		retangulo(icone, cor, 9, 39, 38, 6, 2)
		retangulo(icone, cor, 13, 14, 7, 26, 1)
		retangulo(icone, cor, 16, 12, 27, 10, 2)
		retangulo(icone, cor, 32, 20, 8, 13, 1)
	elseif categoria == "Transportador" then
		-- Correia com pes de apoio e tres marcas que indicam a superficie de transporte.
		retangulo(icone, cor, 7, 23, 42, 12, 5)
		for _, x in { 13, 25, 37 } do retangulo(icone, cor, x, 16, 5, 5, 1) end
		retangulo(icone, cor, 13, 34, 5, 8, 1)
		retangulo(icone, cor, 38, 34, 5, 8, 1)
	elseif categoria == "Modificador" then
		-- Portal sobre a correia: a peca modifica o minerio que passa por dentro.
		retangulo(icone, cor, 8, 39, 40, 6, 2)
		retangulo(icone, cor, 14, 13, 6, 27, 1)
		retangulo(icone, cor, 36, 13, 6, 27, 1)
		retangulo(icone, cor, 19, 12, 18, 7, 1)
		retangulo(icone, cor, 25, 27, 7, 7, 1, 45)
	elseif categoria == "Vendedor" then
		-- Fornalha: duas paredes, teto e chamine deixam a abertura central aparente.
		retangulo(icone, cor, 9, 40, 38, 6, 2)
		retangulo(icone, cor, 12, 22, 8, 18, 1)
		retangulo(icone, cor, 36, 22, 8, 18, 1)
		retangulo(icone, cor, 12, 18, 32, 7, 2)
		retangulo(icone, cor, 31, 8, 9, 11, 1)
	else
		error("Icone de categoria nao definido: " .. tostring(categoria))
	end
	return icone
end

return IconesAbas
