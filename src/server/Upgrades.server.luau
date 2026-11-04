local R=game:GetService("ReplicatedStorage")
local Networker=require(R.Packages.Networker)
local Dados=require(script.Parent.Data.DataManager)
local Expansao=require(script.Parent.ExpansaoPlot)
local Players=game:GetService("Players")
local Servico={}
function Servico:Comprar(jogador,id,nivel,ciclo)
	if jogador.Parent~=Players or type(id)~="string" or type(nivel)~="number" or type(ciclo)~="number" then return false,"Pedido inválido." end
	local dados=Dados.ObterDados(jogador)
	if not dados then return false,"Aguarde seus dados." end
	local terreno
	if id=="Expansao" then
		for _,p in workspace.Terrenos:GetChildren() do if p:GetAttribute("DonoUserId")==jogador.UserId then terreno=p; break end end
		if not terreno then return false,"Terreno indisponível." end
	end
	local ok,msg=dados:ComprarUpgrade(id,nivel,ciclo)
	if ok and terreno then Expansao.Aplicar(terreno,dados:ObterUpgrade("Expansao")) end
	return ok,msg
end
function Servico:Velocidade(jogador,nivel)
	local dados=jogador.Parent==Players and Dados.ObterDados(jogador)
	if not dados then return false,"Aguarde seus dados." end
	return dados:DefinirVelocidadeMotores(nivel)
end
Networker.server.new("Upgrades",Servico,{Servico.Comprar,Servico.Velocidade})
