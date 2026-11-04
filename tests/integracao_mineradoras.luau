-- Usa os assets mapeados no Rojo e os servicos reais; perfil, rede e consulta espacial sao locais.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local r = require("./suporte/modelos")
local I, V, CF = r.Instance, r.Vector3, r.CFrame
local mundo = I.new("Workspace")
local modelos = require("./suporte/catalogo_modelos")()
local replicado = { ModelosMaquinas = modelos }
function replicado:WaitForChild(nome) return assert(self[nome]) end
r.implementMethod("Workspace", "GetPartBoundsInBox", function(_, cf, tamanho, consulta)
	local encontrados = {}
	for _, raiz in (if consulta.FilterType==r.Enum.RaycastFilterType.Exclude then {mundo} else consulta.FilterDescendantsInstances) do
		for _, parte in raiz:IsA("BasePart") and { raiz } or raiz:GetDescendants() do
			if parte:IsA("BasePart") and (if consulta.RespectCanCollide then parte.CanCollide else parte.CanQuery)
				and (parte.CFrame.Position - cf.Position).Magnitude <= (parte.Size.Magnitude + tamanho.Magnitude) / 2 then
				table.insert(encontrados, parte)
			end
		end
	end
	return encontrados
end)
local Players = {}
local jogador = { Name = "Integracao", UserId = 123, Parent = Players, atributos = { TerrenoId = 1 } }
function jogador:SetAttribute(k, v) self.atributos[k] = v end
function jogador:GetAttribute(k) return self.atributos[k] end
function Players:GetPlayerByUserId(id) return id == 123 and jogador or nil end
local tempo = 0
local carregar, no = require("./suporte/carregador")({
	workspace = mundo, Instance = I, Vector3 = V, CFrame = CF, Color3 = r.Color3, Enum = r.Enum,
	typeof = r.typeof, OverlapParams = { new = function() return {} end },
	os = { clock = function() return tempo end },
}, { Players = Players, ReplicatedStorage = replicado })
replicado.Shared = no("src/shared")
local Catalogo = carregar("src/shared/CatalogoMaquinas")
local Template = carregar("src/server/Data/Template")
local Manager = carregar("src/server/Data/DataManager")
local Construcao = carregar("src/server/ServicoConstrucao")
local Geometria = carregar("src/shared/GeometriaColocacao")
local Personalizacao = carregar("src/shared/PersonalizacaoMaquina")
local Previa = carregar("src/client/PreviaConstrucao")
local Inteiro = carregar("src/server/InteiroGrande")
local Fabrica = carregar("src/server/Fabrica")
local terrenos = I.new("Folder")
terrenos.Name, terrenos.Parent = "Terrenos", mundo
local terreno = I.new("Model")
terreno.Parent = terrenos
terreno:SetAttribute("DonoUserId", 123); terreno:SetAttribute("TerrenoId", 1)
local piso = I.new("Part")
piso.Name, piso.Size, piso.CFrame, piso.Anchored, piso.Parent = "Piso", V.new(128, 1, 128), CF.new(64, -.5, 64), true, terreno
for _, nome in { "Maquinas", "Minerios" } do
	local pasta = I.new("Folder")
	pasta.Name, pasta.Parent = nome, terreno
end
local perfil = { Data = serde.decode("json", serde.encode("json", Template)) }
function perfil:IsActive() return true end
perfil.Data.Dinheiro = "1" .. string.rep("0", 30)
for id in perfil.Data.Inventory do perfil.Data.Inventory[id] = 0 end
local dados = Manager.RegistrarPerfil(jogador, perfil)
local servico = Construcao.new()
local manifesto = serde.decode("json", fs.readFile("modelos/mineradoras/geometria.json"))
local precos = {"100", "1500", "100000", "10000000", "750000000", "50000000000", "2000000000000",
	"100000000000000", "5000000000000000", "250000000000000000", "25000000000000000000",
	"2500000000000000000000", "500000000000000000000000"}
local valores = {"5", "15", "45", "150", "1200", "6000", "18000", "75000", "350000", "2000000", "15000000", "90000000", "500000000"}
local intervalos = {2, 1.5, 1.2, 1, 1.5, 1.2, 1.5, 1, 1.25, 1.5, 1.2, 1, 1.25}
local rotacoes = {}
for x = 0, 3 do for y = 0, 3 do for z = 0, 3 do
	local cf = CF.Angles(x * math.pi / 2, y * math.pi / 2, z * math.pi / 2)
	local repetida = false
	for _, outra in rotacoes do
		if (cf.RightVector - outra.RightVector).Magnitude < .001 and (cf.UpVector - outra.UpVector).Magnitude < .001 then repetida = true end
	end
	if not repetida then table.insert(rotacoes, cf) end
end end end
assert(#rotacoes == 24 and #modelos:GetChildren() == 91)
for n, entrada in manifesto do
	local id, def = entrada.id, Catalogo[entrada.id]
	assert(def.Preco == precos[n] and def.Componentes[1].Minerio.Valor == valores[n] and def.Componentes[1].Intervalo == intervalos[n])
	assert(Template.Inventory[id] == (n == 1 and 1 or 0))
	local esperado = V.new(def.Blocos[1], def.Blocos[2], def.Blocos[3]) * 3
	assert(modelos[id].HitboxConstrucao.Size == esperado)
	for _, rotacao in rotacoes do
		tempo += 1
		local saldo = perfil.Data.Dinheiro
		assert(servico:Colocar(jogador, id, V.zero, rotacao))
		assert(perfil.Data.Dinheiro == Inteiro.subtrair(saldo, def.Preco))
		local colocada = terreno.Maquinas:GetChildren()[1]
		local hitbox, tamanho = Geometria.CaixaDeConstrucao(colocada)
		local extensao, ocupado = Geometria.CalcularVolume(rotacao, esperado)
		assert((tamanho - esperado).Magnitude < .001)
		assert((hitbox.Position - ocupado / 2).Magnitude < .001)
		assert((hitbox.RightVector - rotacao.RightVector).Magnitude < .001)
		assert((hitbox.UpVector - rotacao.UpVector).Magnitude < .001)
		assert((colocada:GetAttribute("VolumeOcupado") - ocupado).Magnitude < .001)
		local originalSaida = modelos[id]:FindFirstChild("SaidaMinerio", true)
		local saida = colocada:FindFirstChild("SaidaMinerio", true)
		local pose = saida.Parent.CFrame * saida.CFrame
		local localOriginal = modelos[id].HitboxConstrucao.CFrame:ToObjectSpace(originalSaida.Parent.CFrame * originalSaida.CFrame)
		assert((hitbox:ToObjectSpace(pose).Position - localOriginal.Position).Magnitude < .001)
		local previa = Previa.new(modelos[id], Personalizacao.new(), def, terreno.Maquinas)
		local alvo = { caixaDestino = CF.new(ocupado / 2) * rotacao }
		local clone = previa:ObterModelo()
		clone:PivotTo(previa:CalcularPivoAlvo(alvo))
		assert((clone.HitboxConstrucao.CFrame.Position - hitbox.Position).Magnitude < .001)
		assert((clone:FindFirstChild("SaidaMinerio", true).Parent.CFrame.Position - saida.Parent.CFrame.Position).Magnitude < .001)
		previa:Destruir()
		tempo += 1
		assert(servico:Recolher(jogador, colocada))
		assert(dados:ObterQuantidade(id) == 1)
		-- Volta ao mesmo estado para verificar o preco da proxima orientacao tambem.
		assert(dados:VenderMaquina(id, jogador:GetAttribute("ConfiguracaoInventario_" .. id)))
	end
	print("PASS: " .. id .. ": preco exato, emissao relativa e mesma hitbox na previa/servidor em 24 rotacoes.")
end

-- Restaura todos os tipos num perfil serializado, preservando tambem o blueprint salvo.
for n, entrada in manifesto do
	tempo += 1
	assert(servico:Colocar(jogador, entrada.id, V.new((n-1)%4*27, 0, math.floor((n-1)/4)*27), CF.identity))
end
tempo += 1
local criou, mensagem = servico:CriarBlueprint(jogador, "Mineradoras", terreno.Maquinas:GetChildren())
assert(criou, mensagem)
local salvo = serde.encode("json", perfil.Data)
terreno.Maquinas:ClearAllChildren()
perfil.Data = serde.decode("json", salvo)
servico = Construcao.new()
assert(servico:Restaurar(jogador) and #terreno.Maquinas:GetChildren() == 13)
assert(serde.encode("json", perfil.Data) == salvo, "Restauracao nao deve cobrar nem alterar dados.")
tempo += 1
local preparou, erro, copia = servico:PrepararBlueprint(jogador, perfil.Data.Blueprints[1].Id)
assert(preparou and #copia.Pecas == 13, erro)
print("PASS: 13 tipos salvos/restaurados e blueprint com seus 13 modelos.")

-- Gera com a Fabrica real para medir intervalos fracionarios em diferentes Heartbeats.
for _, fps in {30, 144} do
	for n, entrada in manifesto do
		terreno.Maquinas:ClearAllChildren(); terreno.Minerios:ClearAllChildren()
		local modelo = modelos[entrada.id]:Clone()
		modelo:SetAttribute("DonoUserId", 123); modelo:SetAttribute("TerrenoId", 1)
		modelo.Parent = terreno.Maquinas
		local fabrica = Fabrica.new(terrenos)
		local instantes = {}
		fabrica._simulacao.RegistrarMinerio = function(sim, minerio, vida, configuracao)
			local parte = minerio:ObterParte()
			local saida = modelo:FindFirstChild("SaidaMinerio", true)
			assert((parte.CFrame.Position - (saida.Parent.CFrame * saida.CFrame).Position).Magnitude < .001)
			assert(parte:GetAttribute("Valor") == valores[n])
			assert(vida == nil and configuracao.Valor == valores[n])
			table.insert(instantes, sim._tempo)
			-- O teste mede a emissao; queda, transporte e venda sao exercitados nos testes de fisica.
			minerio:Consumir()
		end
		for _ = 1, fps * 6 do fabrica:Avancar(1 / fps) end
		assert(#instantes == math.ceil((6 - 1 / 120) / intervalos[n]), entrada.id .. ": quantidade incorreta")
		for i = 2, #instantes do assert(math.abs(instantes[i] - instantes[i - 1] - intervalos[n]) < .00001) end
		fabrica:Destruir()
	end
end
print("PASS: geracao real dos 13 modelos em 30/144 FPS, inclusive intervalos de 1,2/1,25/1,5 s.")
