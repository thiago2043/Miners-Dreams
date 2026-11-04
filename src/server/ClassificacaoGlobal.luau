local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Servico = require(script.Parent.ServicoClassificacao)
return Servico.new(DataStoreService:GetDataStore(if RunService:IsStudio() then "Classificacao_Test_v1" else "Classificacao_Live_v1"))
