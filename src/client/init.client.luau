-- Cria os objetos locais de cada jogador e encerra suas conexoes quando este script e destruido.
local Players = game:GetService("Players")
local ControladorConstrucao = require(script.ControladorConstrucao)
local InterfaceJogo = require(script.InterfaceJogo)
local MineriosVisuais = require(script.MineriosVisuais)
local PreferenciasVisuais = require(script.PreferenciasVisuais)
local ControlesPlataforma = require(script.ControlesPlataforma)

-- Cada cliente cria seus objetos para Players.LocalPlayer. A interface recebe o mesmo controlador,
-- compartilhando sua navegacao sem criar outra selecao independente.
local construcao = ControladorConstrucao.new(Players.LocalPlayer)
local interface = InterfaceJogo.new(Players.LocalPlayer, construcao)
local controles = ControlesPlataforma.new(Players.LocalPlayer, construcao, interface)
local minerios = MineriosVisuais.new(Players.LocalPlayer)
local preferencias = PreferenciasVisuais.new(Players.LocalPlayer)
-- Apos montar a interface, conecta as entradas e a atualizacao por quadro. Construir o controlador sozinho
-- apenas prepara o estado e suas referencias.
construcao:Iniciar()

-- O callback libera eventos, previas e elementos visuais quando o script acaba. Sem essa limpeza, uma
-- conexao poderia continuar tentando usar uma interface encerrada.
script.Destroying:Connect(function()
	controles:Destruir()
	construcao:Destruir()
	interface:Destruir()
	minerios:Destruir()
	preferencias:Destruir()
end)
