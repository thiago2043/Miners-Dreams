local fs = require("@lune/fs")
local serde = require("@lune/serde")
local r = require("./suporte/modelos")
local V, CF = r.Vector3, r.CFrame
local replicado = {}
local carregar, no = require("./suporte/carregador")({ Vector3=V, CFrame=CF, typeof=r.typeof }, {ReplicatedStorage=replicado})
replicado.Shared = no("src/shared")
local Medidas = carregar("src/shared/Medidas")
local Migracao = carregar("src/server/Data/MigracaoGrade")
local Geometria = carregar("src/shared/GeometriaColocacao")
assert(Medidas.Bloco == 3 and Geometria.Passo == 3)
local function clone(t) return serde.decode("json",serde.encode("json",t)) end
local rotacao = {0,0,1,0,1,0,-1,0,0}
local modificacoes = { Partes={{Tamanho={4,8,12}, CFrame={4,-8,12,table.unpack(rotacao)}, Cor={1,.5,0}}},
	Configuracao={Blocos={2,3,4},Componentes={{Tipo="Soltador",Minerio={Tamanho={1,2,3},Valor="5"},Velocidade=6}}} }
local antigo = { Dinheiro="12345678901234567890", Inventory={Esteira2x2=10},
	MaquinasColocadas={{MaquinaId="Esteira2x2",Posicao={4,8,12},Rotacao=rotacao,InclinacaoGrade=true,Modificacoes=modificacoes}},
	Blueprints={{Id="1",Pecas={{MaquinaId="Esteira2x2",DeslocamentoInicial={-4,8,12},RotacaoInicial=rotacao,Modificacoes=clone(modificacoes)}}}},
	InventarioPersonalizado={Esteira2x2={clone(modificacoes)}} }
local original = serde.encode("json",antigo)
local novo = Migracao.Preparar(antigo)
assert(serde.encode("json",antigo) == original and novo ~= antigo)
assert(novo.TamanhoBloco == 3 and Migracao.Preparar(novo) == novo)
assert(novo.Dinheiro == antigo.Dinheiro and novo.Inventory.Esteira2x2 == 10)
assert(novo.MaquinasColocadas[1].Posicao[1]==3 and novo.MaquinasColocadas[1].Posicao[3]==9)
assert(novo.Blueprints[1].Pecas[1].DeslocamentoInicial[1]==-3)
for _, p in {novo.MaquinasColocadas[1].Modificacoes, novo.Blueprints[1].Pecas[1].Modificacoes, novo.InventarioPersonalizado.Esteira2x2[1]} do
	assert(p.Partes[1].Tamanho[2]==6 and p.Partes[1].CFrame[2]==-6 and p.Partes[1].Cor[2]==.5)
	for i,n in rotacao do assert(p.Partes[1].CFrame[i+3]==n) end
	assert(p.Configuracao.Blocos[2]==3 and p.Configuracao.Componentes[1].Velocidade==6)
	assert(p.Configuracao.Componentes[1].Minerio.Tamanho[1]==.75)
end
for _, campo in {"MaquinasColocadas","Blueprints","InventarioPersonalizado"} do
	assert(serde.encode("json",novo.BackupGrade4[campo])==serde.encode("json",antigo[campo]))
end
local invalido=clone(antigo); invalido.MaquinasColocadas[1].Posicao[2]="invalido"
local antes=serde.encode("json",invalido)
assert(not pcall(Migracao.Preparar,invalido) and serde.encode("json",invalido)==antes)
invalido=clone(antigo); invalido.TamanhoBloco=2
assert(not pcall(Migracao.Preparar,invalido))
invalido=clone(antigo); invalido.BackupGrade4={}
assert(not pcall(Migracao.Preparar,invalido))
assert(Migracao.Preparar({}).TamanhoBloco==3)
print("PASS: migracao atomica e idempotente; backup integral dos campos espaciais; rotacoes, dinheiro e quantidades preservados.")

local Escala = require("../modelos/escala")
local amostra = r.Instance.new("Model")
local parte = r.Instance.new("Part"); parte.Size=V.new(4,8,12); parte.CFrame=CF.new(4,8,12)*CF.Angles(.2,.3,.4); parte.Parent=amostra
parte:SetAttribute("DirecaoTransporte",V.zAxis); parte:SetAttribute("ExtremidadeA",V.new(4,8,12))
local saida=r.Instance.new("Attachment"); saida.CFrame=CF.new(1,2,3); saida.Parent=parte
amostra:SetAttribute("BlocosHorizontais",V.new(2,0,3)); amostra:SetAttribute("AvancoSaidaBlocos",3.5)
Escala.Aplicar(amostra,3)
assert(parte.Size==V.new(3,6,9) and (parte.CFrame.Position-V.new(3,6,9)).Magnitude<.00001)
assert(saida.CFrame.Position==V.new(.75,1.5,2.25))
assert(parte:GetAttribute("DirecaoTransporte")==V.zAxis and parte:GetAttribute("ExtremidadeA")==V.new(3,6,9))
assert(amostra:GetAttribute("BlocosHorizontais")==V.new(2,0,3) and amostra:GetAttribute("AvancoSaidaBlocos")==3.5)
local bytes=r.serializeModel({amostra}); Escala.Aplicar(amostra,3)
assert(r.serializeModel({amostra})==bytes)
print("PASS: exportador escala geometria e bocais; vetores de direcao, contagens de blocos e repeticao preservados.")

local Catalogo=carregar("src/shared/CatalogoMaquinas")
local modelos=require("./suporte/catalogo_modelos")()
local total=0
for id,def in Catalogo do
	local m=assert(modelos:FindFirstChild(id),id)
	assert(m:GetAttribute("GradeStuds")==3,"Escala antiga: "..id)
	local _,tamanho=Geometria.CaixaDeConstrucao(m)
	local Volume=carregar("src/shared/VolumeConstrucao").new(tamanho,def.Blocos,def)
	if def.Blocos then assert((Volume:ObterBlocos()-V.new(table.unpack(def.Blocos))).Magnitude<.001,id) end
	for _,c in def.Componentes do
		if c.Tipo=="Soltador" then assert(c.Minerio.Tamanho[1]==.75) end
	end
	total+=1
end
assert(total==91)
print("ESCALA_3_STUDS_OK",total,"assets e reservas; migracao de perfil e personalizacoes.")
