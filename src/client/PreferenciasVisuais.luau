local Config=require(game:GetService("ReplicatedStorage").Shared.Configuracoes)
local Lighting=game:GetService("Lighting")
local catalogo=require(game:GetService("ReplicatedStorage").Shared.CatalogoMaquinas)
local tiposModificadores={}
for id,item in catalogo do for _,c in item.Componentes do if c.Tipo=="Modificador" then tiposModificadores[id]=true end end end
local Visuais={}; Visuais.__index=Visuais
function Visuais.new(jogador)
	local self=setmetatable({_jogador=jogador,_efeitos={},_telas={},_conexoes={},_modificadores={}},Visuais)
	local function observar(objeto)
		if objeto:IsA("Model") and tiposModificadores[objeto.Name] and not self._modificadores[objeto] and objeto.Parent and objeto.Parent.Name=="Maquinas" then
			local estado={Cores={},Tweens={}}; self._modificadores[objeto]=estado
			estado.Conexao=objeto:GetAttributeChangedSignal("ModificadorAtivo"):Connect(function() self:_EstadoModificador(objeto) end)
			self:_EstadoModificador(objeto)
		end
		if objeto:IsA("ParticleEmitter") or objeto:IsA("Smoke") or objeto:IsA("Fire") or objeto:IsA("Sparkles") or objeto:IsA("BloomEffect") or objeto:IsA("Light") then
			self._efeitos[objeto]={Enabled=objeto.Enabled,Rate=objeto:IsA("ParticleEmitter") and objeto.Rate or nil,Brightness=objeto:IsA("Light") and objeto.Brightness or nil}
			self:_Efeito(objeto,self._efeitos[objeto])
		end
	end
	for _,raiz in {workspace,Lighting} do
		for _,o in raiz:GetDescendants() do observar(o) end
		table.insert(self._conexoes,raiz.DescendantAdded:Connect(observar))
		table.insert(self._conexoes,raiz.DescendantRemoving:Connect(function(o)
			self._efeitos[o]=nil
			local m=self._modificadores[o]
			if m then m.Conexao:Disconnect(); for _,t in m.Tweens do t:Cancel() end; self._modificadores[o]=nil end
		end))
	end
	local gui=jogador:WaitForChild("PlayerGui")
	local function tela(t)
		if not t:IsA("ScreenGui") or not table.find({"InterfaceJogo","PainelMoedas","MenuContextualPeca","Confirmacao"},t.Name) then return end
		local raiz=Instance.new("Frame"); raiz.Name="EscalaConteudo"; raiz.BackgroundTransparency=1; raiz.Parent=t
		local escala=Instance.new("UIScale"); escala.Parent=raiz
		local function mover(filho) if filho~=raiz and filho:IsA("GuiObject") then filho.Parent=raiz end end
		for _,filho in t:GetChildren() do mover(filho) end
		self._telas[t]={Raiz=raiz,Escala=escala}
		table.insert(self._conexoes,t.ChildAdded:Connect(mover)); self:_Escala()
	end
	for _,t in gui:GetChildren() do tela(t) end
	table.insert(self._conexoes,gui.ChildAdded:Connect(tela))
	table.insert(self._conexoes,gui.ChildRemoved:Connect(function(t) self._telas[t]=nil end))
	table.insert(self._conexoes,jogador:GetAttributeChangedSignal("EfeitosMaquinas"):Connect(function()
		for o,salvo in self._efeitos do self:_Efeito(o,salvo) end
	end))
	table.insert(self._conexoes,jogador:GetAttributeChangedSignal("EscalaInterface"):Connect(function() self:_Escala() end))
	return self
end
function Visuais:_Efeito(objeto,salvo)
	local modo=Config.Obter(self._jogador,"EfeitosMaquinas")
	local ativo=true
	local pai=objeto.Parent
	while pai do
		if self._modificadores[pai] then ativo=pai:GetAttribute("ModificadorAtivo")~=false; break end
		pai=pai.Parent
	end
	objeto.Enabled=salvo.Enabled and ativo and modo~="Oculto" and (modo=="Completo" or objeto:IsA("ParticleEmitter") or objeto:IsA("Light"))
	if salvo.Rate then objeto.Rate=salvo.Rate*(modo=="Reduzido" and .25 or 1) end
	if salvo.Brightness then objeto.Brightness=salvo.Brightness*(modo=="Reduzido" and .25 or 1) end
end
function Visuais:_EstadoModificador(modelo)
	local estado=self._modificadores[modelo]
	local ativo=modelo:GetAttribute("ModificadorAtivo")~=false
	for _,p in modelo:GetDescendants() do
		if p:IsA("BasePart") and p.Material==Enum.Material.Neon and p.Transparency<1 then
			estado.Cores[p]=estado.Cores[p] or p.Color
			if estado.Tweens[p] then estado.Tweens[p]:Cancel(); estado.Tweens[p]=nil end
			local cor=ativo and estado.Cores[p] or estado.Cores[p]:Lerp(Color3.fromRGB(20,24,28),.92)
			if p.Color~=cor then
				local t=game:GetService("TweenService"):Create(p,TweenInfo.new(.25),{Color=cor})
				estado.Tweens[p]=t; t:Play()
			end
		end
		if self._efeitos[p] then self:_Efeito(p,self._efeitos[p]) end
	end
end
function Visuais:_Escala()
	local valor=Config.Obter(self._jogador,"EscalaInterface")
	for _,t in self._telas do t.Escala.Scale=valor; t.Raiz.Size=UDim2.fromScale(1/valor,1/valor) end
end
function Visuais:Destruir()
	for _,c in self._conexoes do c:Disconnect() end
	for _,m in self._modificadores do
		m.Conexao:Disconnect()
		for _,t in m.Tweens do t:Cancel() end
		for p,cor in m.Cores do if p.Parent then p.Color=cor end end
	end
	table.clear(self._modificadores)
	for o,s in self._efeitos do if o.Parent then o.Enabled=s.Enabled; if s.Rate then o.Rate=s.Rate end; if s.Brightness then o.Brightness=s.Brightness end end end
	for tela,t in self._telas do
		if tela.Parent then for _,filho in t.Raiz:GetChildren() do if filho:IsA("GuiObject") then filho.Parent=tela end end end
		t.Raiz:Destroy()
	end
	table.clear(self._efeitos); table.clear(self._telas)
end
return Visuais
