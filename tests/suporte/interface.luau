-- Simula a arvore e os sinais da GUI; nao desenha pixels nem substitui os tipos geometricos do Roblox.
local roblox = require("@lune/roblox")
local function sinal()
	local s = { conexoes = {} }
	function s:Connect(callback)
		local c = { ativa = true, callback = callback }
		function c:Disconnect() self.ativa = false end
		table.insert(self.conexoes,c)
		return c
	end
	function s:Fire(...) for _, c in self.conexoes do if c.ativa then c.callback(...) end end end
	return s
end
local function novaInstancia(classe)
	if classe == "BindableEvent" then
		local e = { Event = sinal() }
		function e:Fire(...) self.Event:Fire(...) end
		function e:Destroy() for _, c in self.Event.conexoes do c:Disconnect() end end
		return e
	end
	local objeto = { ClassName=classe, _filhos={}, _sinais={}, Visible=true, ZIndex=1,
		AbsoluteSize=roblox.Vector2.new(256,400), AbsoluteContentSize=roblox.Vector2.zero }
	for _, nome in { "Activated", "MouseEnter", "MouseLeave", "SelectionGained", "SelectionLost" } do objeto[nome]=sinal() end
	function objeto:GetChildren() return self._filhos end
	function objeto:FindFirstChild(nome) for _, f in self._filhos do if f.Name==nome then return f end end end
	function objeto:FindFirstChildOfClass(nome) for _, f in self._filhos do if f.ClassName==nome then return f end end end
	function objeto:GetPropertyChangedSignal(nome)
		self._sinais[nome] = self._sinais[nome] or sinal()
		return self._sinais[nome]
	end
	function objeto:Destroy()
		if self.destruido then return end
		self.destruido=true
		for _, f in self._filhos do f:Destroy() end
	end
	return setmetatable(objeto,{ __newindex=function(self,chave,valor)
		rawset(self,chave,valor)
		if chave=="Parent" and valor then table.insert(valor._filhos,self) end
	end })
end
return { Sinal=sinal, NovaInstancia=novaInstancia }
