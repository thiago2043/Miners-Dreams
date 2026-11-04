local r=require("./suporte/modelos")
local sinal=require("./suporte/interface").Sinal
local removidos={}
r.implementProperty("Instance","DescendantRemoving",function(o) removidos[o]=removidos[o] or sinal(); return removidos[o] end)
local I=r.Instance
local mundo=I.new("Workspace")
local pasta=I.new("Folder"); pasta.Name,pasta.Parent="Maquinas",mundo
local modelo=I.new("Model"); modelo.Name,modelo.Parent="PrensaMinerio",pasta
local neon=I.new("Part"); neon.Material,neon.Color,neon.Parent=r.Enum.Material.Neon,r.Color3.fromRGB(30,180,255),modelo
local cor=neon.Color
local luz=I.new("PointLight"); luz.Enabled,luz.Brightness,luz.Parent=true,2,neon
local jato=I.new("ParticleEmitter"); jato.Enabled,jato.Rate,jato.Parent=true,40,neon
local atributos,sinais={},{}
local gui=I.new("Folder")
local jogador={GetAttribute=function(_,id) return atributos[id] end,WaitForChild=function() return gui end}
function jogador:GetAttributeChangedSignal(id) sinais[id]=sinais[id] or sinal(); return sinais[id] end
local animacoes={}
local carregar=require("./suporte/carregador")({workspace=mundo,Instance=I,Enum=r.Enum,Color3=r.Color3,
	TweenInfo={new=function(t) return {Time=t} end}},
	{Lighting={GetDescendants=function() return {} end,DescendantAdded=sinal(),DescendantRemoving=sinal()},
	TweenService={Create=function(_,objeto,info,destino)
		local t={Objeto=objeto,Info=info,Destino=destino,Cancelado=false}
		function t:Play() for k,v in destino do objeto[k]=v end end
		function t:Cancel() self.Cancelado=true end
		table.insert(animacoes,t); return t
	end}})
local visual=carregar("src/client/PreferenciasVisuais").new(jogador)
assert(luz.Enabled and jato.Enabled and neon.Color==cor)
modelo:SetAttribute("ModificadorAtivo",false); modelo:GetAttributeChangedSignal("ModificadorAtivo"):Fire()
assert(#animacoes==1 and animacoes[1].Info.Time==.25 and neon.Color~=cor and not luz.Enabled and not jato.Enabled)
modelo:SetAttribute("ModificadorAtivo",true); modelo:GetAttributeChangedSignal("ModificadorAtivo"):Fire()
assert(neon.Color==cor and luz.Enabled and jato.Enabled and animacoes[1].Cancelado)
atributos.EfeitosMaquinas="Oculto"; jogador:GetAttributeChangedSignal("EfeitosMaquinas"):Fire()
assert(not luz.Enabled and not jato.Enabled)
modelo:SetAttribute("ModificadorAtivo",false); modelo:GetAttributeChangedSignal("ModificadorAtivo"):Fire()
visual:Destruir()
assert(neon.Color==cor and luz.Enabled and luz.Brightness==2 and jato.Enabled and jato.Rate==40)
for _,s in sinais do for _,c in s.conexoes do assert(not c.ativa) end end
mundo:Destroy(); gui:Destroy()
print("DESLIGAMENTO_VISUAL_OK: tween de 0,25s, luz/jato, reativação, preferência de efeitos e limpeza; objetos simulados, sem renderização.")
