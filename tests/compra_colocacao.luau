-- Executar com Lune; perfis, rede e metodos de Model sao simulados.
local serde = require("@lune/serde")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("./suporte/modelos")
local Instance, CFrame, Vector3 = roblox.Instance, roblox.CFrame, roblox.Vector3

local mundo = Instance.new("Workspace")
local catalogo = luau.load(fs.readFile("src/shared/CatalogoMaquinas.luau"))()
for maquinaId in catalogo do
	local modelo = roblox.deserializeModel(fs.readFile("modelos/rojo/" .. maquinaId .. ".rbxm"))[1]
	modelo.Parent = mundo
end

local terrenos = Instance.new("Folder")
terrenos.Name = "Terrenos"
terrenos.Parent = mundo
local terreno = Instance.new("Model")
terreno:SetAttribute("DonoUserId", 123)
terreno:SetAttribute("TerrenoId", 1)
terreno.Parent = terrenos
local piso = Instance.new("Part")
piso.Name = "Piso"
piso.Size = Vector3.new(64, 1, 64)
piso.Parent = terreno
local maquinas = Instance.new("Folder")
maquinas.Name = "Maquinas"
maquinas.Parent = terreno

local Players = { PlayerRemoving = { Connect = function() end } }
local atributos = { TerrenoId = 1 }
local jogador = { Parent = Players, UserId = 123, Name = "Teste" }
function jogador:GetAttribute(nome) return atributos[nome] end
function jogador:SetAttribute(nome, valor) atributos[nome] = valor end
local profile = {
	Data = { Dinheiro = "300", Inventory = { MineradoraBasica = 2, EsteiraBasica = 0, FornalhaBasica = 0 }, MaquinasColocadas = {} },
}
function profile:IsActive() return true end

local tempo = 0
local carregar = require("./suporte/carregador")({
	workspace = mundo, CFrame = CFrame, Vector3 = Vector3, typeof = roblox.typeof,
	os = { clock = function() return tempo end },
}, { Players = Players, Debris = { AddItem = function() end } }, {
	["Packages/Networker"] = { server = { new = function(_, moduloServidor, acesso)
		assert(#acesso == 2 and acesso[1] == moduloServidor.Colocar
			and acesso[2] == moduloServidor.Recolher)
	end } },
})
local inteiro = carregar("src/server/InteiroGrande")
local manager = carregar("src/server/Data/DataManager")
manager.RegistrarPerfil(jogador, profile)
local geometria = carregar("src/shared/GeometriaColocacao")
local construcao = carregar("src/server/Construcao")

local function colocar(posicao, rotacao)
	tempo += 1
	return construcao:Colocar(jogador, "MineradoraBasica", posicao, rotacao or CFrame.identity)
end
local function recusar(posicao, rotacao)
	local antes = serde.encode("json", profile.Data)
	local quantidade = #maquinas:GetChildren()
	assert(colocar(posicao, rotacao) == false)
	assert(serde.encode("json", profile.Data) == antes)
	assert(#maquinas:GetChildren() == quantidade)
end

for i, x in { 0, 12, 24, 36, 48 } do
	assert(colocar(Vector3.new(x, 0, 0)))
	assert(profile.Data.Inventory.MineradoraBasica == math.max(0, 2 - i))
	assert(profile.Data.Dinheiro == tostring(300 - math.max(0, i - 2) * 100))
	assert(#maquinas:GetChildren() == i and #profile.Data.MaquinasColocadas == i)
	recusar(Vector3.new(x, 0, 0))
end
assert(profile.Data.Dinheiro == "0")
recusar(Vector3.new(0, 0, 16))
profile.Data.Dinheiro = "99"
recusar(Vector3.new(0, 0, 16))
profile.Data.Dinheiro = "100"
recusar(Vector3.new(-4, 0, 16))
recusar(Vector3.new(1, 0, 16))
recusar(Vector3.new(60, 0, 16))
recusar(Vector3.new(0, -4, 16))
recusar(Vector3.new(0, 0, 16), CFrame.Angles(0, math.pi / 4, 0))
terreno:SetAttribute("DonoUserId", 999)
recusar(Vector3.new(0, 0, 16))
terreno:SetAttribute("DonoUserId", 123)
for _, quantidade in { -1, 0.5, 2 ^ 53 } do
	profile.Data.Inventory.MineradoraBasica = quantidade
	recusar(Vector3.new(0, 0, 16))
end
profile.Data.Inventory.MineradoraBasica = 0
profile.Data.Dinheiro = "0"
tempo += 1
assert(construcao:Recolher(jogador, maquinas:GetChildren()[1]))
assert(profile.Data.Inventory.MineradoraBasica == 1 and profile.Data.Dinheiro == "0")
assert(colocar(Vector3.new(0, 0, 16)))
assert(profile.Data.Inventory.MineradoraBasica == 0 and profile.Data.Dinheiro == "0")

local dadosSalvos = serde.decode("json", serde.encode("json", profile.Data))
for _, maquina in maquinas:GetChildren() do maquina:Destroy() end
profile = { Data = dadosSalvos }
function profile:IsActive() return true end
manager.Profiles[jogador] = profile
assert(construcao.Restaurar(jogador))
assert(#maquinas:GetChildren() == 5 and profile.Data.Dinheiro == "0")
assert(profile.Data.Inventory.MineradoraBasica == 0)
print("PASS: inventario tem prioridade; estoque vazio compra e coloca por 100.")
print("PASS: sobreposicao, saldo, limites, grade, rotacao, dono e quantidade invalidos nao alteram dados.")
print("PASS: recolher/recolocar e restaurar nao cobram novamente.")

local template = carregar("src/server/Data/Template")
for maquinaId in catalogo do assert(template.Inventory[maquinaId] == 0) end
profile.Data.Dinheiro = "100000"
local saldoEsperado = profile.Data.Dinheiro
local tipos = { "MineradoraBasica", "EsteiraBasica", "FornalhaBasica" }
local testadas = 0
for _, maquinaId in tipos do
	local rotacoes = {}
	for x = 0, 3 do
		for y = 0, 3 do
			for z = 0, 3 do
				local rotacao = CFrame.Angles(x * math.pi / 2, y * math.pi / 2, z * math.pi / 2)
				local r, u = rotacao.RightVector, rotacao.UpVector
				local chave = string.format("%.0f,%.0f,%.0f/%.0f,%.0f,%.0f", r.X + 0, r.Y + 0, r.Z + 0, u.X + 0, u.Y + 0, u.Z + 0):gsub("-0", "0")
				if rotacoes[chave] then continue end
				rotacoes[chave] = true
				testadas += 1
				local posicao = Vector3.new(0, testadas * 32, 0)
				local antes = #profile.Data.MaquinasColocadas
				tempo += 1
				assert(construcao:Colocar(jogador, maquinaId, posicao, rotacao))
				saldoEsperado = inteiro.subtrair(saldoEsperado, catalogo[maquinaId].Preco)
				assert(profile.Data.Dinheiro == saldoEsperado and profile.Data.Inventory[maquinaId] == 0)
				assert(#profile.Data.MaquinasColocadas == antes + 1)
				local criada = maquinas:GetChildren()[#maquinas:GetChildren()]
				assert(criada.Name == maquinaId and criada:GetAttribute("PodeRecolher") == true)
				local minimo = geometria.VolumeDoModelo(criada, geometria.Origem(piso))
				assert((minimo - posicao).Magnitude < 0.001)
				local caixaReal, tamanhoReal = criada:GetBoundingBox()
				local caixaLocal = geometria.Origem(piso):ToObjectSpace(caixaReal)
				local extensaoReal = geometria.CalcularVolume(caixaLocal, tamanhoReal)
				local minimoReal = caixaLocal.Position - extensaoReal
				for _, eixo in { "X", "Y", "Z" } do
					assert(math.abs(math.floor(minimoReal[eixo] / 4 + geometria.Tolerancia) * 4 - posicao[eixo]) < 0.001)
				end
				local snapshot = serde.encode("json", profile.Data)
				tempo += 1
				assert(construcao:Colocar(jogador, maquinaId, posicao, rotacao) == false)
				assert(serde.encode("json", profile.Data) == snapshot)
				if x == 0 and y == 0 and z == 0 then
					tempo += 1
					assert(construcao:Recolher(jogador, criada))
					assert(profile.Data.Inventory[maquinaId] == 1 and profile.Data.Dinheiro == saldoEsperado)
					tempo += 1
					assert(construcao:Colocar(jogador, maquinaId, posicao, rotacao))
					assert(profile.Data.Inventory[maquinaId] == 0 and profile.Data.Dinheiro == saldoEsperado)
				end
			end
		end
	end
end
assert(testadas == 72)
local salvos = serde.decode("json", serde.encode("json", profile.Data))
local quantidadeAntes = #maquinas:GetChildren()
for _, maquina in maquinas:GetChildren() do maquina:Destroy() end
profile = { Data = salvos }
function profile:IsActive() return true end
manager.Profiles[jogador] = profile
assert(construcao.Restaurar(jogador))
assert(#maquinas:GetChildren() == quantidadeAntes and profile.Data.Dinheiro == saldoEsperado)
assert(construcao.Restaurar(jogador) and #maquinas:GetChildren() == quantidadeAntes)
tempo += 1
assert(construcao:Colocar(jogador, "Inexistente", Vector3.zero, CFrame.identity) == false)
print("PASS: modelos reais dos tres tipos, 24 rotacoes cada, precos, sobreposicao e recolhimento correto por tipo.")
print("PASS: registros antigos e novos restaurados juntos, sem duplicacao ou nova cobranca.")

local dados = manager.ObterDados(jogador)
assert(dados == manager.ObterDados(jogador))
local outroJogador = { Name = "Outro", SetAttribute = function() end }
local outroPerfil = { Data = { Dinheiro = "50", Inventory = { EsteiraBasica = 0 } } }
function outroPerfil:IsActive() return true end
local outrosDados = manager.RegistrarPerfil(outroJogador, outroPerfil)
assert(outrosDados ~= dados)
assert(outrosDados:ComprarMaquina("EsteiraBasica"))
assert(outroPerfil.Data.Dinheiro == "25" and profile.Data.Dinheiro == saldoEsperado)
local copia = dados:ObterConstrucoes()
table.clear(copia)
assert(#dados:ObterConstrucoes() == quantidadeAntes)
profile.Data.Inventory.MineradoraBasica = 2 ^ 53 - 1
local snapshot = serde.encode("json", profile.Data)
assert(dados:ComprarMaquina("MineradoraBasica") == false)
assert(serde.encode("json", profile.Data) == snapshot)
manager.RemoverPerfil(jogador)
assert(manager.ObterDados(jogador) == nil)
print("PASS: dados por jogador, copia da lista e limite seguro do inventario.")

local Volume = carregar("src/shared/VolumeConstrucao")
local volume = Volume.new(Vector3.new(5, 6, 7), { 4, 3, 2 })
assert(volume:ObterBlocos() == Vector3.new(4, 3, 2))
assert(volume:ObterBlocos(CFrame.Angles(0, math.pi / 2, 0)) == Vector3.new(2, 3, 4))
assert(not pcall(Volume.new, Vector3.new(9, 1, 1), { 2, 1, 1 }))
local copiaModelo = mundo.MineradoraBasica:Clone()
copiaModelo.Name = "MineradoraGrande"
copiaModelo.Parent = mundo
catalogo.MineradoraGrande = table.clone(catalogo.MineradoraBasica)
catalogo.MineradoraGrande.Blocos = { 4, 3, 4 }
carregar("src/shared/CatalogoMaquinas").MineradoraGrande = catalogo.MineradoraGrande
local carregarTemplate = require("./suporte/carregador")({}, {}, {
	["src/shared/CatalogoMaquinas"] = catalogo,
})
assert(carregarTemplate("src/server/Data/Template").Inventory.MineradoraGrande == 0)
local jogador2 = { Name = "Construtor2", UserId = 456, Parent = Players }
function jogador2:GetAttribute() return 2 end
function jogador2:SetAttribute() end
local terreno2 = Instance.new("Model")
terreno2:SetAttribute("DonoUserId", 456)
terreno2:SetAttribute("TerrenoId", 2)
terreno2.Parent = terrenos
local piso2 = piso:Clone()
piso2.Parent = terreno2
local maquinas2 = Instance.new("Folder")
maquinas2.Name, maquinas2.Parent = "Maquinas", terreno2
local perfil2 = { Data = { Dinheiro = "100", Inventory = { MineradoraGrande = 0 }, MaquinasColocadas = {} } }
function perfil2:IsActive() return true end
manager.RegistrarPerfil(jogador2, perfil2)
local novoServico = carregar("src/server/ServicoConstrucao").new()
assert(novoServico:Colocar(jogador2, "MineradoraGrande", Vector3.zero, CFrame.identity))
local construida = maquinas2:GetChildren()[1]
local a, b = geometria.VolumeDoModelo(construida, geometria.Origem(piso2))
assert(a == Vector3.zero and b == Vector3.new(16, 12, 16))
local Maquina = carregar("src/server/Maquinas/Maquina")
local definicaoAssimetrica = table.clone(catalogo.MineradoraGrande)
definicaoAssimetrica.Blocos = { 5, 3, 4 }
-- O objeto usa dimensoes de criacao, mesmo quando a caixa atual troca seus eixos.
local caixaOriginal, tamanhoOriginal = copiaModelo:GetBoundingBox()
local modeloGirado = copiaModelo:Clone()
modeloGirado:PivotTo(CFrame.Angles(0, math.pi / 2, 0) * caixaOriginal)
modeloGirado:SetAttribute("TamanhoConstrucao", tamanhoOriginal)
local objeto = Maquina.new(modeloGirado, terreno2, definicaoAssimetrica)
assert(objeto:ObterVolume():ObterBlocos() == Vector3.new(5, 3, 4))
objeto:Destruir()
local saldoAntes = perfil2.Data.Dinheiro
assert(not novoServico:Colocar(jogador2, "MineradoraGrande", Vector3.new(12, 0, 0), CFrame.identity))
assert(perfil2.Data.Dinheiro == saldoAntes)
print("PASS: classe de volume, rotacao dos blocos declarados e bloqueio pelo volume configurado.")
