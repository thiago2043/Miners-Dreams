local r=require('@lune/roblox')
local s=require('./suporte/interface')
local eventos={InputBegan=s.Sinal(),InputChanged=s.Sinal(),InputEnded=s.Sinal(),WindowFocusReleased=s.Sinal()}
local carregar=require('./suporte/carregador')({Instance={new=s.NovaInstancia},UDim2=r.UDim2,Vector2=r.Vector2,Color3=r.Color3,Enum=r.Enum},{UserInputService=eventos})
local Controle=carregar('src/client/ControleDeslizante')
local pai=s.NovaInstancia('ScrollingFrame'); pai.ScrollingEnabled=true
local controle,recebido
controle=Controle.new(pai,'Quantidade',{0,100,200},r.Color3.new(0,1,1),function(valor) recebido=valor; controle:DefinirValor(valor,tostring(valor)) end)
controle:DefinirValor(100,'100')
controle._trilho.AbsolutePosition=r.Vector2.new(100,0); controle._trilho.AbsoluteSize=r.Vector2.new(200,4)
local captura=controle:ObterInstancia():FindFirstChild('Ajustar')
local mouse={UserInputType=r.Enum.UserInputType.MouseButton1,Position=r.Vector3.new(500,0,0)}
captura.InputBegan:Fire(mouse); assert(recebido==200 and not pai.ScrollingEnabled)
eventos.InputChanged:Fire({UserInputType=r.Enum.UserInputType.MouseMovement,Position=r.Vector3.new(0,0,0)})
assert(recebido==0)
eventos.InputEnded:Fire(mouse); assert(pai.ScrollingEnabled)
captura.SelectionGained:Fire(); eventos.InputBegan:Fire({KeyCode=r.Enum.KeyCode.Right}); assert(recebido==100)
local touch={UserInputType=r.Enum.UserInputType.Touch,Position=r.Vector3.new(300,0,0)}
captura.InputBegan:Fire(touch); assert(recebido==200)
eventos.WindowFocusReleased:Fire(); assert(pai.ScrollingEnabled)
controle:Destruir()
for _,e in eventos do for _,c in e.conexoes do assert(not c.ativa) end end
print('DESLIZANTES_OK: mouse, toque, teclado, limites e limpeza.')
