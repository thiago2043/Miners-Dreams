local carregar=require("./suporte/carregador")({}, {})
local T=carregar("src/server/Data/Template")
local Reinicio=carregar("src/server/Data/ReinicioProgresso").new(T,{"RecompensasReencarnacao"})
local P=carregar("src/server/Data/PremiosRenascimento")
local premios=carregar("src/shared/RecompensasRenascimento")
for _,lotes in {{9},{2,3,4},{1,1,1,1,1,1,1,1,1},{5,7}} do
 local atual=Reinicio:Preparar({})
 local total=0
 for _,q in lotes do
  local novo=Reinicio:Preparar(atual)
  P.Aplicar(novo,atual,q); total+=q
  local recebidos=0
  for _,item in premios do
   local n=novo.Inventory[item.Id]
   recebidos+=n
   if total<=9 then assert(n<=1,"Repeticao antes de completar as nove") else assert(n>=1) end
  end
  assert(recebidos==total)
  atual=novo
 end
end
local antigo=Reinicio:Preparar({})
antigo.RecompensasReencarnacao[premios[1].Id]={Quantidade=8}
local novo=Reinicio:Preparar(antigo)
P.Aplicar(novo,antigo,8)
assert(novo.Inventory[premios[1].Id]==8)
for _,p in premios do assert(novo.Inventory[p.Id]>=1) end
print("SORTEIO_RENASCIMENTO_OK: nove distintos em um salto ou varios ciclos; repeticao apos completar; progresso antigo preservado.")
