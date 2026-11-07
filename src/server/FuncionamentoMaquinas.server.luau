local MonitorRecursos = require(game:GetService("ReplicatedStorage").Shared.MonitorRecursos)
-- Entrega o tempo do Heartbeat a fabrica; a simulacao transforma esse tempo em passos fixos e atualiza os
-- componentes.
local Fabrica = require(script.Parent.Fabrica)
-- A fabrica observa a pasta criada pelo sistema de terrenos. Ela descobre os modelos que forem colocados e
-- gerencia seus componentes e minerios.
local fabrica = Fabrica.new(workspace:WaitForChild("Terrenos"))
-- Heartbeat fornece o tempo decorrido do servidor. Avancar acumula esse tempo e executa passos fisicos
-- fixos; nao usa diretamente o intervalo variavel para resolver contatos.
local DataManager = require(game:GetService("ServerScriptService").Data.DataManager)
local tempoTaxa = 0
local tempoRecebimentos = 0
local conexao = game:GetService("RunService").Heartbeat:Connect(function(delta)
	fabrica:Avancar(delta)
	tempoRecebimentos+=delta
	if tempoRecebimentos>=1 then local tEco=MonitorRecursos.Iniciar(); DataManager.PublicarRecebimentos(); MonitorRecursos.Finalizar("Economia e Recebimentos (DataManager)", tEco, "Publicação de saldos e ganhos"); tempoRecebimentos=0 end
	tempoTaxa += delta
	if tempoTaxa >= 2 then
		local tTaxa=MonitorRecursos.Iniciar(); DataManager.PublicarGanhosPorSegundo(tempoTaxa); MonitorRecursos.Finalizar("Economia e Recebimentos (DataManager)", tTaxa, "Cálculo de $/s")
		tempoTaxa = 0
	end
end)
-- Desconecta o relogio antes de destruir a fabrica. Isso impede uma atualizacao nova durante a limpeza dos
-- componentes e dos corpos simulados.
script.Destroying:Connect(function()
	conexao:Disconnect()
	fabrica:Destruir()
end)
