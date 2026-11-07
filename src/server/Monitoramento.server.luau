local Admin=require(script.Parent.Administracao)
local Dados=require(script.Parent.Data.DataManager)
local Players=game:GetService("Players")
local Networker=require(game:GetService("ReplicatedStorage").Packages.Networker)
Networker.server.new("Administracao",Admin,{Admin.Permissao,Admin.Listar,Admin.Consultar,Admin.Alterar,Admin.Recursos})
local function permissao(p) p:SetAttribute("Administrador",Admin:Permissao(p)) end
Players.PlayerAdded:Connect(permissao)
for _,p in Players:GetPlayers() do task.spawn(permissao,p) end
while true do
	for p,perfil in Dados.Profiles do
		if perfil:IsActive() then
			permissao(p)
			Admin:_Amostrar(p,perfil,false)
			Admin:_Publicar(p,perfil)
		end
	end
	task.wait(10)
end
