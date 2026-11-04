local carregar=require('./suporte/carregador')({}, {})
local T=carregar('src/server/Data/Template')
local R=carregar('src/server/Data/ReinicioProgresso')
local D=carregar('src/server/Data/DadosJogador')
local atributos={}; local p={UserId=1,Name='Teste',SetAttribute=function(_,k,v) atributos[k]=v end}
local perfil={Data=R.new(T,{}):Preparar({}),IsActive=function() return true end}
local d=D.new(p,perfil)
for i=1,10 do assert(d:AdicionarDinheiro('200')); d:PublicarGanhosPorSegundo(2); assert(atributos.GanhosPorSegundo=='100') end
for i=1,10 do d:PublicarGanhosPorSegundo(2); assert(atributos.GanhosPorSegundo==tostring(100-i*10)) end
assert(perfil.Data.Dinheiro=='2000' and perfil.Data.Recordes.DinheiroPorSegundo=='100' and #d._amostrasGanhos==10)
assert(not pcall(d.PublicarGanhosPorSegundo,d,0))
print('GANHOS_ESTAVEIS_OK: media de 20s, queda gradual, saldo e recorde preservados.')
