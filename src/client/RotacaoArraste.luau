-- Converte o movimento do cursor em passos de 90 graus, mantendo o eixo durante pequenas oscilacoes do gesto.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RotacaoConstrucao = require(ReplicatedStorage.Shared.RotacaoConstrucao)

local RotacaoArraste = {}
RotacaoArraste.__index = RotacaoArraste
local pixelsParaIniciar = 48
local pixelsParaRepetir = 96
local mesmaDirecao = math.cos(math.rad(25))

-- Recebe a posicao inicial do mouse, a orientacao da camera no terreno, a rotacao atual e a esfera projetada
-- na tela. Inicializa os acumuladores do gesto sem aplicar nenhum giro.
function RotacaoArraste.new(mouse, cameraNoTerreno, rotacao, centroTela, raioTela)
	-- Guarda a camera no inicio do gesto, a posicao anterior do cursor e acumuladores: um confirma mudanca de
	-- direcao, outro determina quantos giros completos foram pedidos.
	local self = setmetatable({
		_camera = cameraNoTerreno,
		_centroTela = centroTela, _raioTela = raioTela,
		_rotacao = rotacao, _mouseAnterior = mouse,
		_movimentoDirecao = Vector2.zero,
		_pixelsRepeticao = 0, _pixelsPendentes = 0,
	}, RotacaoArraste)
	return self
end

-- Converte um deslocamento na tela em eixo e sentido da grade, levando a camera em conta. Enquanto o movimento
-- permanece na faixa ja confirmada, conserva o eixo; antes de confirmar uma nova direcao pode devolver nil.
function RotacaoArraste:_EixoDoMovimento(mouse, movimento)
	-- O produto escalar compara a nova direcao com a confirmada. Um movimento quase paralelo conserva o eixo;
	-- sinal negativo inverte so o sentido desse giro.
	local alinhamento = self._direcaoGesto and self._direcaoGesto:Dot(movimento.Unit)
	if alinhamento and math.abs(alinhamento) >= mesmaDirecao then
		self._movimentoDirecao, self._origemDirecao = Vector2.zero, nil
		return self._eixoGesto * math.sign(alinhamento), movimento.Magnitude
	end
	-- Uma correcao pequena nao pode redefinir o eixo usado na volta do mouse.
	self._origemDirecao = self._origemDirecao or mouse
	self._movimentoDirecao += movimento
	local distancia = self._movimentoDirecao.Magnitude
	if distancia < pixelsParaIniciar then return nil end
	movimento = self._movimentoDirecao
	alinhamento = self._direcaoGesto and self._direcaoGesto:Dot(movimento.Unit)
	if alinhamento and math.abs(alinhamento) >= mesmaDirecao then
		self._movimentoDirecao, self._origemDirecao = Vector2.zero, nil
		return self._eixoGesto * math.sign(alinhamento), distancia
	end
	-- Normaliza o ponto em uma esfera virtual centrada na previa. O produto vetorial entre sua normal e o
	-- movimento fornece um eixo, depois convertido da camera para a plot.
	local ponto = (self._origemDirecao - self._centroTela) / self._raioTela
	local distancia2 = ponto:Dot(ponto)
	-- A extensao hiperbolica evita perder a inclinacao quando o cursor sai da esfera.
	local z = if distancia2 <= 0.5 then math.sqrt(1 - distancia2) else 0.5 / math.sqrt(distancia2)
	local normal = Vector3.new(ponto.X, -ponto.Y, z).Unit
	local direcao = self._camera:VectorToWorldSpace(normal:Cross(Vector3.new(movimento.X, -movimento.Y, 0))).Unit
	-- Escolhe so o componente dominante para manter X, Y ou Z. A direcao confirmada fica guardada para pequenas
	-- oscilacoes nao trocarem o eixo no meio do movimento.
	local x, y, zEixo = math.abs(direcao.X), math.abs(direcao.Y), math.abs(direcao.Z)
	self._eixoGesto = if x >= y and x >= zEixo then Vector3.new(math.sign(direcao.X), 0, 0)
		elseif y >= zEixo then Vector3.new(0, math.sign(direcao.Y), 0)
		else Vector3.new(0, 0, math.sign(direcao.Z))
	self._direcaoGesto = movimento.Unit
	self._movimentoDirecao, self._origemDirecao = Vector2.zero, nil
	return self._eixoGesto, distancia
end

-- Recebe a nova posicao do mouse e devolve a orientacao resultante. Acumula pixels ate atingir os limiares de
-- inicio/repeticao, aplica os passos inteiros e devolve a orientacao anterior quando ainda nao houve movimento
-- suficiente.
function RotacaoArraste:Atualizar(mouse)
	local deslocamento = mouse - self._mouseAnterior
	local anterior = self._mouseAnterior
	self._mouseAnterior = mouse
	if deslocamento.Magnitude < 0.000001 then return self._rotacao end
	local eixo, distancia = self:_EixoDoMovimento(anterior, deslocamento)
	if not eixo then return self._rotacao end
	local passos
	-- No eixo confirmado, cada 96 pixels acrescenta um passo. Ao trocar de eixo/sentido, exige primeiro 48
	-- pixels de confirmacao para nao girar por um tremor curto.
	if eixo == self._eixo then
		self._eixoPendente, self._pixelsPendentes = nil, 0
		self._pixelsRepeticao += distancia
		passos = math.floor(self._pixelsRepeticao / pixelsParaRepetir)
		self._pixelsRepeticao -= passos * pixelsParaRepetir
	else
		if self._eixo and eixo == -self._eixo then
			self._pixelsRepeticao = math.max(0, self._pixelsRepeticao - distancia)
		end
		if eixo ~= self._eixoPendente then self._eixoPendente, self._pixelsPendentes = eixo, 0 end
		self._pixelsPendentes += distancia
		if self._pixelsPendentes < pixelsParaIniciar then return self._rotacao end
		self._eixo = eixo
		self._pixelsRepeticao = self._pixelsPendentes - pixelsParaIniciar
		self._eixoPendente, self._pixelsPendentes = nil, 0
		passos = 1 + math.floor(self._pixelsRepeticao / pixelsParaRepetir)
		self._pixelsRepeticao -= (passos - 1) * pixelsParaRepetir
	end
	-- Aplica os quartos de volta completos em uma matriz, preservando os pixels restantes. A validacao mantem a
	-- orientacao exatamente na grade de 90 graus.
	if passos > 0 then
		self._rotacao = assert(RotacaoConstrucao.ValidarNaGrade(
			CFrame.fromAxisAngle(self._eixo, passos * RotacaoConstrucao.Passo) * self._rotacao
		))
	end
	return self._rotacao
end

return RotacaoArraste
