-- Carrega os modulos reais em um ambiente de teste; game, script e servicos sao fornecidos por cada caso.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")

-- Simula apenas require/script/GetService; cada teste fornece os recursos do Roblox usados.
-- Monta um carregador local dos arquivos reais. ambiente fornece tipos/objetos, servicos substitui
-- GetService e substituicoes permite controlar dependencias; devolve carregar e o criador de nos de script.
local function criarCarregador(ambiente, servicos, substituicoes)
	local nos, cache, carregando = {}, {}, {}
	-- Cria ou reutiliza um objeto que representa um caminho de ModuleScript. A metatabela traduz Parent e
	-- WaitForChild em caminhos, sem criar instancias reais no Studio.
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
	-- Os testes recebem somente os servicos necessarios. HttpService usa JSON do runtime local e as raizes de
	-- scripts apontam para arquivos da pasta do projeto.
	local raizes = {
		HttpService = {
			JSONEncode = function(_, valor) return serde.encode("json", valor) end,
			JSONDecode = function(_, valor) return serde.decode("json", valor) end,
		},
		ServerScriptService = no("src/server"),
		ReplicatedStorage = { Shared = no("src/shared"), Packages = no("Packages") },
	}
	local jogo = { GetService = function(_, nome)
		return assert(servicos[nome] or raizes[nome], "Servico nao simulado: " .. nome)
	end }
	local carregar
	-- Executa um modulo uma vez e guarda seu retorno no cache, como require. A marca carregando reconhece
	-- dependencias circulares antes de entrar em recursao infinita.
	carregar = function(caminho)
		caminho = caminho:gsub("%.luau$", "")
		if substituicoes and substituicoes[caminho] then return substituicoes[caminho] end
		if cache[caminho] ~= nil then return cache[caminho] end
		assert(not carregando[caminho], "Dependencia circular: " .. caminho)
		carregando[caminho] = true
		-- Cada modulo recebe game, script e require proprios neste ambiente isolado. A funcao compilada e executada
		-- apenas com esses recursos simulados, sem entrar no servidor Roblox.
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
