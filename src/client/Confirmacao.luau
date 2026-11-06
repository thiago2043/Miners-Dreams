local Config=require(game:GetService("ReplicatedStorage").Shared.Configuracoes)
local Botao=require(script.Parent.Botao)
local AnimacaoInterface=require(script.Parent.AnimacaoInterface)
local Confirmacao={}; Confirmacao.__index=Confirmacao
function Confirmacao.new(pai,jogador,nav)
	local self=setmetatable({_jogador=jogador,_nav=nav},Confirmacao)
	local gui=Instance.new("ScreenGui"); gui.Name="Confirmacao"; gui.ResetOnSpawn=false; gui.DisplayOrder=100; gui.Parent=pai; self._gui=gui
	local fundo=Instance.new("Frame"); fundo.Size=UDim2.fromScale(1,1); fundo.BackgroundColor3=Color3.new(0,0,0); fundo.BackgroundTransparency=.45; fundo.Active=true; fundo.Visible=false; fundo.Parent=gui; self._fundo=fundo
	local caixa=Instance.new("Frame"); caixa.AnchorPoint=Vector2.new(.5,.5); caixa.Position=UDim2.fromScale(.5,.5); caixa.Size=UDim2.new(1,-32,0,220); caixa.BackgroundColor3=Color3.fromRGB(22,23,29); caixa.BorderSizePixel=0; caixa.Parent=fundo; self._caixa=caixa
	local max=Instance.new("UISizeConstraint"); max.MaxSize=Vector2.new(440,320); max.Parent=caixa
	local canto=Instance.new("UICorner"); canto.CornerRadius=UDim.new(0,12); canto.Parent=caixa
	local texto=Instance.new("TextLabel"); texto.Position=UDim2.fromOffset(18,12); texto.Size=UDim2.new(1,-36,0,132); texto.BackgroundTransparency=1; texto.Font=Enum.Font.SourceSansBold; texto.TextSize=19; texto.TextColor3=Color3.fromRGB(240,243,250); texto.TextWrapped=true; texto.Parent=caixa; self._texto=texto
	self._sim=Botao.new(caixa,"Confirmar",function()
		local callback=self._callback; self._callback=nil; nav:Fechar("Confirmacao"); if callback then callback() end
	end)
	self._nao=Botao.new(caixa,"Cancelar",function() nav:Fechar("Confirmacao") end)
	for i,b in {self._nao,self._sim} do
		local o=b:ObterInstancia(); o.Text=i==1 and "Cancelar" or "Confirmar"; o.Position=UDim2.new((i-1)*.5,18-(i-1)*9,1,-60); o.Size=UDim2.new(.5,-27,0,40); o.BackgroundColor3=i==1 and Color3.fromRGB(48,51,62) or Color3.fromRGB(255,182,90); o.TextColor3=i==1 and Color3.new(1,1,1) or Color3.fromRGB(22,23,29); o.Font=Enum.Font.SourceSansBold; o.TextSize=18; o.Selectable=true; b:DefinirDisponivel(true)
	end
	return self
end
function Confirmacao:Pedir(tipo,quantidade,callback,mensagem)
	local modo=Config.Obter(self._jogador,"ConfirmarVenda")
	local pedir=if tipo=="Administracao" or tipo=="LimparPlot" then true elseif tipo=="Renascimento" then Config.Obter(self._jogador,"ConfirmarRenascimento") else modo=="Sempre" or (modo=="Várias peças" and quantidade>1)
	if not pedir then return callback() end
	if self._callback then return false end
self._callback=callback; self._fundo.Visible=true
  self._caixa.Size=UDim2.new(1,-32,0,tipo=="Administracao" and 320 or 220)
  self._texto.Size=UDim2.new(1,-36,1,-88)
  self._texto.TextSize=tipo=="Administracao" and 16 or 19
  self._texto.Text=mensagem or (if tipo=="Renascimento" then "Confirmar renascimento?\n\nDinheiro e upgrades do ciclo serão reiniciados. Recompensas e expansão permanecem." else "Vender "..quantidade.." peça(s)?\n\nAs peças selecionadas serão removidas da plot ou do inventário.")
AnimacaoInterface.DefinirVisivel(self._caixa, true, "Centro")
  self._nav:Abrir("Confirmacao",function()
    self._callback=nil
    AnimacaoInterface.DefinirVisivel(self._caixa, false, "Centro", function()
      if not AnimacaoInterface.EstaVisivel(self._caixa) then
        self._fundo.Visible = false
      end
    end)
  end)
  return true
end
function Confirmacao:Destruir()
	self._nav:Fechar("Confirmacao"); self._sim:Destruir(); self._nao:Destruir(); self._gui:Destroy()
end
return Confirmacao
