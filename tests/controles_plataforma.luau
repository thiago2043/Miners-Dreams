local r=require("@lune/roblox")
local ui=require("./suporte/interface")
local tarefa=require("@lune/task")
local tipo=r.Enum.UserInputType.Keyboard
local input={LastInputTypeChanged=ui.Sinal(),TouchTapInWorld=ui.Sinal(),WindowFocusReleased=ui.Sinal(),WindowFocused=ui.Sinal()}
local teclas,focado={},false
function input:GetLastInputType() return tipo end
function input:GetMouseLocation() return r.Vector2.new(100,200) end
function input:IsKeyDown(k) return teclas[k.Name]==true end
function input:GetFocusedTextBox() return focado and {} or nil end
local render,acoes={},{}
local run={BindToRenderStep=function(_,nome,_,fn) render[nome]=fn end,UnbindFromRenderStep=function(_,nome) render[nome]=nil end}
local cas={BindAction=function(_,nome,fn) acoes[nome]=fn end,UnbindAction=function(_,nome) acoes[nome]=nil end}
local gui={mudou=ui.Sinal(),GetPropertyChangedSignal=function(self) return self.mudou end}
local camera={ViewportSize=r.Vector2.new(800,600)}
local function novo(classe)
	local objeto=ui.NovaInstancia(classe)
	local attrs={}
	function objeto:SetAttribute(k,v) attrs[k]=v end
	function objeto:GetAttribute(k) return attrs[k] end
	return objeto
end
local carregar=require("./suporte/carregador")({
	Instance={new=novo},Enum=r.Enum,Color3=r.Color3,UDim=r.UDim,UDim2=r.UDim2,Vector2=r.Vector2,Vector3=r.Vector3,
	typeof=function(v) return if type(v)=="table" and v.ClassName then "Instance" else typeof(v) end,
	workspace={CurrentCamera=camera},task=tarefa,
},{UserInputService=input,RunService=run,GuiService=gui,ContextActionService=cas})
local atributos={}
local p={PlayerGui=ui.NovaInstancia("ScreenGui")}
function p:GetAttribute(k) return atributos[k] end
function p:WaitForChild(n) return self[n] end
function p:Move(v,relativa) self.Movimento=v; assert(relativa) end
local nav=carregar("src/client/NavegacaoEstados").new()
local c={Navegacao=nav,cliques=0,finais=0}
function c:_EncontrarTerreno() return true end
function c:_MaquinaSobMouse() return self.maquinaSobToque end
function c:ProcessarEntrada() self.cliques+=1; self._arrasteSelecao=self._modoSelecao and {} or nil end
function c:FinalizarEntrada() self.finais+=1; self._arrasteSelecao=nil; self._arrasteColocacao=nil end
function c:_AtualizarArrasteSelecao(posicao) self.areaAtualizada=true; self.fimArea=posicao end
function c:Atualizar() self.atualizou=true end
function c:Girar(eixo) self.eixo=eixo end
function c:_ColocacaoSomenteVertical() return self.vertical == true end
function c:_AjustarAlturaSelecao(n) self.alturaSelecao=n end
function c:Cancelar() self.cancelou=true; nav:Voltar() end
local interface={_interface=ui.NovaInstancia("ScreenGui"),_paineisProgressao={},_paineis={}}
interface._menuAbas=ui.NovaInstancia("Frame"); interface._menuAbas.Parent=interface._interface
interface._botoesAbas={Inventario=carregar("src/client/Botao").new(interface._menuAbas,"Inventario",function() end)}
interface._botoesAbas.Inventario:DefinirDisponivel(true)
local C=carregar("src/shared/Configuracoes")
local controle=carregar("src/client/ControlesPlataforma").new(p,c,interface)
assert(controle:Ponteiro()==r.Vector2.new(100,200) and not controle._barra.Visible)
assert(not C.ValidarTecla(p,"W","S") and C.ValidarTecla(p,"W","Up"))
atributos.Atalho_W="Up"; atributos.Atalho_Q="K"
assert(C.ValidarTecla(p,"R","Q") and not C.ValidarTecla(p,"R","Up"))
assert(C.ResolverTecla(p,r.Enum.KeyCode.K).Name=="Q" and C.ResolverTecla(p,r.Enum.KeyCode.Q).Name=="Unknown")
teclas.Up=true
render.Fabrica_TeclasMovimento()
assert(p.Movimento==r.Vector3.new(0,0,-1))
teclas.D=true; render.Fabrica_TeclasMovimento(); assert(math.abs(p.Movimento.Magnitude-1)<.001)
focado=true; render.Fabrica_TeclasMovimento(); assert(p.Movimento==r.Vector3.zero); focado=false
input.WindowFocusReleased:Fire(); render.Fabrica_TeclasMovimento(); assert(p.Movimento==r.Vector3.zero); input.WindowFocused:Fire()
input.LastInputTypeChanged:Fire(r.Enum.UserInputType.Touch)
input.TouchTapInWorld:Fire(r.Vector2.new(250,120),true); assert(c.cliques==0)
c._modoSelecao="Selecao"
input.TouchTapInWorld:Fire(r.Vector2.new(250,120),false)
assert(c.cliques==1 and c.finais==0 and c._arrasteSelecao.PorComando,"Tocar o chao inicia uma area, sem abrir acoes de uma peca.")
assert(controle._instrucao.Visible and not controle._botoes["Girar X"]:ObterInstancia().Visible)
assert(controle:Ponteiro()==r.Vector2.new(250,120))
input.TouchTapInWorld:Fire(r.Vector2.new(350,220),false)
assert(c.cliques==1 and c.finais==0 and c.fimArea==r.Vector2.new(350,220))
assert(controle._botoes["Linha / área"]:ObterInstancia().Text=="Concluir área")
controle:Acao("Confirmar"); assert(c.finais==1 and not c._arrasteSelecao)
c.maquinaSobToque=true
input.TouchTapInWorld:Fire(r.Vector2.new(200,180),false)
assert(c.cliques==2 and c.finais==2,"Um toque numa peca continua permitindo abrir suas acoes.")
c.maquinaSobToque=nil; c._modoSelecao=nil
c._previa={}; nav:Abrir("Colocacao")
assert(controle._barra.Visible)
camera.ViewportSize=r.Vector2.new(360,700); render.Fabrica_TeclasMovimento()
assert(controle._barra.Size.X.Offset<=336 and controle._barra.Position.Y.Offset==-160)
camera.ViewportSize=r.Vector2.new(800,360); render.Fabrica_TeclasMovimento()
assert(controle._barra.Position.Y.Offset==-36,"A barra em paisagem deve ficar abaixo da mira central.")
input.TouchTapInWorld:Fire(r.Vector2.new(280,130),false); assert(c.cliques==2,"Um toque de posicionamento nao deve colocar sem confirmar.")
assert(controle:Acao("Girar X") and c.eixo=="X")
c.vertical=true; controle:Atualizar()
assert(not controle._botoes["Girar X"]:ObterInstancia().Visible and controle._botoes["Girar Y"]:ObterInstancia().Visible)
c.vertical=false
c._alvoColocacao={minimo=r.Vector3.zero}
controle:Acao("Subir"); assert(c._travamentoAltura.altura==3)
c._previa=nil; c._modoSelecao="Selecao"
controle:Acao("Linha / área")
assert(c._arrasteSelecao.PorComando and c.areaAtualizada,"Area por mira fixa deve iniciar sem depender do movimento do ponteiro em pixels.")
controle:Acao("Subir"); assert(c.alturaSelecao==1)
controle:Acao("Confirmar"); assert(not c._arrasteSelecao)
input.LastInputTypeChanged:Fire(r.Enum.UserInputType.Gamepad1)
assert(controle:Ponteiro()==r.Vector2.new(400,180) and controle._mira.Visible)
gui.SelectedObject=interface._botoesAbas.Inventario:ObterInstancia()
local n=c.cliques
acoes.Fabrica_Confirmar(nil,r.Enum.UserInputState.Begin)
assert(c.cliques==n,"O gatilho de construcao nao pode operar enquanto o foco esta na GUI.")
gui.SelectedObject=nil
acoes["Fabrica_Girar X"](nil,r.Enum.UserInputState.Begin)
nav:Fechar("Colocacao"); c._modoSelecao=nil
controle:AlternarFoco(); assert(gui.SelectedObject)
controle:AlternarFoco(); assert(not gui.SelectedObject)
controle:Destruir()
assert(next(render)==nil and next(acoes)==nil and c._ponteiro==nil)
for _,s in {input.LastInputTypeChanged,input.TouchTapInWorld,input.WindowFocusReleased,input.WindowFocused} do
	for _,conexao in s.conexoes do assert(not conexao.ativa) end
end
print("CONTROLES_PLATAFORMA_OK: remapeamento, foco, direcoes normalizadas, toque, confirmacao, area 3D por mira, controle e limpeza.")
