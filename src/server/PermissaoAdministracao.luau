local dono
local consultado=0
return function(jogador)
	if not dono or (game.CreatorType==Enum.CreatorType.Group and os.clock()-consultado>60) then
		if game.CreatorType==Enum.CreatorType.User then dono=game.CreatorId
		elseif game.CreatorType==Enum.CreatorType.Group then
			local ok,grupo=pcall(function() return game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId) end)
			if not ok then return false,"Não foi possível verificar o dono do grupo." end
			dono=grupo.Owner and grupo.Owner.Id or 0
			consultado=os.clock()
		end
	end
	return dono~=nil and dono>0 and jogador.UserId==dono,"O autor não é o dono da experiência."
end
