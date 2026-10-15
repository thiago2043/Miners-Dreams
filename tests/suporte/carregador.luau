local fs = require("@lune/fs")
local luau = require("@lune/luau")

-- Simula apenas require/script/GetService; cada teste fornece os recursos do Roblox usados.
local function criarCarregador(ambiente, servicos, substituicoes)
	local nos, cache, carregando = {}, {}, {}
	local function no(caminho)
		if nos[caminho] then return nos[caminho] end
		local objeto = { Caminho = caminho }
		nos[caminho] = objeto
		setmetatable(objeto, { __index = function(_, nome)
			if nome == "WaitForChild" then
				return function(_, filho) return no(caminho .. "/" .. filho) end
			elseif nome == "Parent" then
				return no(caminho:match("^(.*)/[^/]+$"))
			end
			return no(caminho .. "/" .. nome)
		end })
		return objeto
	end
	local raizes = {
		ServerScriptService = no("src/server"),
		ReplicatedStorage = { Shared = no("src/shared"), Packages = no("Packages") },
	}
	local jogo = { GetService = function(_, nome)
		return assert(servicos[nome] or raizes[nome], "Servico nao simulado: " .. nome)
	end }
	local carregar
	carregar = function(caminho)
		caminho = caminho:gsub("%.luau$", "")
		if substituicoes and substituicoes[caminho] then return substituicoes[caminho] end
		if cache[caminho] ~= nil then return cache[caminho] end
		assert(not carregando[caminho], "Dependencia circular: " .. caminho)
		carregando[caminho] = true
		local env = table.clone(ambiente)
		env.game = jogo
		env.script = no(caminho:match("/init%.client$") and "src/client" or caminho)
		env.require = function(modulo) return carregar(modulo.Caminho) end
		local resultado = luau.load(fs.readFile(caminho .. ".luau"), {
			debugName = caminho, environment = env,
		})()
		cache[caminho] = resultado
		carregando[caminho] = nil
		return resultado
	end
	return carregar, no
end

return criarCarregador
