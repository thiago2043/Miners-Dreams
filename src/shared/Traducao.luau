local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Traducao = {}
local tradutoresPorJogador = setmetatable({}, { __mode = "k" })
local tradutorLocal = nil
local localeLocalAtual = nil
local tabelaRojo = nil

local mapaPorIdioma = {}       -- [lang] = { [sourcePt] = textoTraduzido }
local mapaPorChave = {}        -- [lang] = { [key] = textoTraduzido }
local textosTraduzidos = {}    -- [lang] = { [textoTraduzido] = true }
local entriesCarregadas = false
local observandoUI = false
local aplicandoTexto = setmetatable({}, { __mode = "k" })

local chavesRaridade = {
Comum = "raridade.Comum", Incomum = "raridade.Incomum", Rara = "raridade.Rara",
["Épica"] = "raridade.Epica", ["Lendária"] = "raridade.Lendaria", ["Mítico"] = "raridade.Mitico",
Renascimento = "raridade.Renascimento", ["Exótica"] = "raridade.Exotica", ["Anômala"] = "raridade.Anomala",
Singular = "raridade.Singular", Superior = "raridade.Superior", Elite = "raridade.Elite",
Despertar = "raridade.Despertar", ["Avanço"] = "raridade.Avanco", Apogeu = "raridade.Apogeu",
["Domínio"] = "raridade.Dominio", Meridiano = "raridade.Meridiano", Forjada = "raridade.Forjada",
Composta = "raridade.Composta", ["Núcleo"] = "raridade.Nucleo", Convergente = "raridade.Convergente",
}

local chavesValorConfig = {
Sempre = "config.valor.Sempre", Perto = "config.valor.Perto", Oculto = "config.valor.Oculto",
Completo = "config.valor.Completo", Reduzido = "config.valor.Reduzido", Nunca = "config.valor.Nunca",
["Várias peças"] = "config.valor.VariasPecas", ["Abreviação"] = "config.valor.Abreviacao",
["Científica"] = "config.valor.Cientifica", ["Semicientífica"] = "config.valor.Semicientifica",
["Médio"] = "config.valor.Medio", ["Máximo"] = "config.valor.Maximo",
Desativado = "config.valor.Desativado", Baixo = "config.valor.Baixo",
}

local function normalizarIdioma(locale)
if type(locale) ~= "string" or locale == "" then return "pt" end
local baixo = string.lower(locale)
local base = baixo:match("^([a-z]+)")
return base or "pt"
end

local function obterLocaleAtivo(jogador)
if RunService:IsClient() then
local j = jogador or Players.LocalPlayer
if j and type(j.LocaleId) == "string" and j.LocaleId ~= "" then
return j.LocaleId
end
return LocalizationService.RobloxLocaleId
end
if jogador and type(jogador.LocaleId) == "string" and jogador.LocaleId ~= "" then
return jogador.LocaleId
end
return "pt-br"
end

local function interpolar(texto, params)
if type(texto) ~= "string" then return "" end
if type(params) ~= "table" then return texto end
return (texto:gsub("{([%w_]+)}", function(chave)
local v = params[chave]
return if v ~= nil then tostring(v) else ("{" .. chave .. "}")
end))
end

local function obterTabelaRojo()
if tabelaRojo and tabelaRojo.Parent then return tabelaRojo end
local encontrada = LocalizationService:FindFirstChild("Traducoes")
if encontrada and encontrada:IsA("LocalizationTable") then
tabelaRojo = encontrada
return encontrada
end
return nil
end

local function carregarIndicesTabela()
if entriesCarregadas then return true end
local tabela = obterTabelaRojo()
if not tabela then return false end
local ok, entries = pcall(tabela.GetEntries, tabela)
if not ok or type(entries) ~= "table" then return false end
entriesCarregadas = true

for _, entry in entries do
local src = entry.Source
local key = entry.Key
local values = entry.Values
if type(values) == "table" then
for localeKey, traduzido in values do
if type(traduzido) == "string" and traduzido ~= "" then
local lang = normalizarIdioma(localeKey)
mapaPorIdioma[lang] = mapaPorIdioma[lang] or {}
mapaPorChave[lang] = mapaPorChave[lang] or {}
textosTraduzidos[lang] = textosTraduzidos[lang] or {}
if type(src) == "string" and src ~= "" then
mapaPorIdioma[lang][src] = traduzido
end
if type(key) == "string" and key ~= "" then
mapaPorChave[lang][key] = traduzido
end
textosTraduzidos[lang][traduzido] = true
end
end
end
end
return true
end

local function obterTradutor(jogador)
local locale = obterLocaleAtivo(jogador)
if RunService:IsClient() then
if tradutorLocal and localeLocalAtual == locale then
return tradutorLocal
end
localeLocalAtual = locale
local tabela = obterTabelaRojo()
if tabela then
local ok, tr = pcall(tabela.GetTranslator, tabela, locale)
if ok and tr then
tradutorLocal = tr
return tr
end
end
local ok, tr = pcall(LocalizationService.GetTranslatorForPlayer, LocalizationService, Players.LocalPlayer)
if ok and tr then
tradutorLocal = tr
return tr
end
return nil
end

if not jogador then return nil end
local cache = tradutoresPorJogador[jogador]
if cache ~= nil then return cache or nil end
local tabela = obterTabelaRojo()
if tabela then
local ok, tr = pcall(tabela.GetTranslator, tabela, locale)
if ok and tr then
tradutoresPorJogador[jogador] = tr
return tr
end
end
return nil
end

function Traducao.T(chave, fallbackPt, params, jogador)
local locale = obterLocaleAtivo(jogador)
local lang = normalizarIdioma(locale)
if lang == "pt" then
return interpolar(fallbackPt or chave, params)
end
carregarIndicesTabela()
local porChave = mapaPorChave[lang]
if porChave and porChave[chave] then
return interpolar(porChave[chave], params)
end
local tradutor = obterTradutor(jogador)
if tradutor and type(chave) == "string" then
local ok, resultado = pcall(function()
return tradutor:FormatByKey(chave, params)
end)
if ok and type(resultado) == "string" and resultado ~= "" then
return resultado
end
end
return interpolar(fallbackPt or chave, params)
end

function Traducao.NomeMaquina(id, nomePt, jogador)
if type(id) ~= "string" then return nomePt or "" end
return Traducao.T("maquina." .. id, nomePt or id, nil, jogador)
end

function Traducao.NomeRaridade(nomePt, jogador)
local chave = chavesRaridade[nomePt]
if not chave then return nomePt or "" end
return Traducao.T(chave, nomePt, nil, jogador)
end

function Traducao.ValorConfig(valor, jogador)
if type(valor) ~= "string" then return tostring(valor) end
local chave = chavesValorConfig[valor]
if not chave then return valor end
return Traducao.T(chave, valor, nil, jogador)
end

function Traducao.Obtencao(obtencao, jogador)
if obtencao == "Renascimento" then return Traducao.T("obtencao.Renascimento", "Renascimento", nil, jogador)
elseif obtencao == "Craft" then return Traducao.T("obtencao.Craft", "Craft", nil, jogador)
elseif obtencao == "Ascensão" then return Traducao.T("obtencao.Ascensao", "Ascensão", nil, jogador) end
return obtencao
end

local function traduzirFraseEn(texto, exato)
if exato[texto] then return exato[texto] end

local a, b, c, d

-- Cabeçalhos com atalho
a = texto:match("^Loja %[(.+)%]$"); if a then return "Shop [" .. a .. "]" end
a = texto:match("^Inventário %[(.+)%]$"); if a then return "Inventory [" .. a .. "]" end
a = texto:match("^Prestígio %[(.+)%]$"); if a then return "Prestige [" .. a .. "]" end
a = texto:match("^Área de transferência %[(.+)%]$"); if a then return "Clipboard [" .. a .. "]" end

-- Filtros / Prioridade / Modo Coop Abas
a = texto:match("^Filtros %((%d+)%)$"); if a then return "Filters (" .. a .. ")" end
a = texto:match("^Prioridade %((%d+)%)$"); if a then return "Priority (" .. a .. ")" end
a = texto:match("^Solicitações %((%d+)%)$"); if a then return "Requests (" .. a .. ")" end
a = texto:match("^Membros %((%d+)%)$"); if a then return "Members (" .. a .. ")" end
a = texto:match("^Banidos %((%d+)%)$"); if a then return "Banned (" .. a .. ")" end
a = texto:match("^Eixo ([XYZ])$"); if a then return a .. " Axis" end

-- Ficha / Inventário / Loja
a = texto:match("^No inventário: (.+)$"); if a then return "In inventory: " .. a end
a = texto:match("^Na plot: (.+)$"); if a then return "On plot: " .. a end
a = texto:match("^Comprar: (.+)$"); if a then return "Buy: " .. a end
a = texto:match("^Vender: (.+) %(100%%%)$"); if a then return "Sell: " .. a .. " (100%)" end
a = texto:match("^Vender: (.+)$"); if a then return "Sell: " .. a end
a = texto:match("^(.+) %(cópia%)$"); if a then return (exato[a] or a) .. " (copy)" end
a = texto:match("^Peça de referência: (.+)$"); if a then return "Reference part: " .. (exato[a] or a) end
a = texto:match("^(%d+) selecionadas$"); if a then return a .. " selected" end
a = texto:match("^Tamanho do minério: (.+) studs$"); if a then return "Ore size: " .. a .. " studs" end
a = texto:match("^Transporte: (.+) blocos/s$"); if a then return "Speed: " .. a .. " blocks/s" end
a, b = texto:match("^Cálculo: %((.+)%) → ×(.+)$"); if a then return "Calc: (" .. a .. ") → ×" .. b end

-- Dicas e listas da GradePecas
a, b, c = texto:match("^(.+) • Na plot: (.+) • Estoque: (.+)$")
if a then return (exato[a] or a) .. " • On plot: " .. b .. " • Stock: " .. c end
a, b, c = texto:match("^(.+) • Estoque: (.+) • (.+)$")
if a then
local cTr = c:gsub("^Loja: ", "Shop: ")
return (exato[a] or a) .. " • Stock: " .. b .. " • " .. (exato[cTr] or cTr)
end
a, b, c = texto:match("^(.+) %((%d+×%d+×%d+) bl(.*)%)$")
if a then
local resto = (c or ""):gsub(" • Usos: ", " • Uses: ")
return (exato[a] or a) .. " (" .. b .. " bl" .. resto .. ")"
end

-- Upgrades
a, b, c = texto:match("^(%d+) × (%d+) × (%d+) blocos • Permanente$")
if a then return string.format("%s × %s × %s blocks • Permanent", a, b, c) end
a, b, c = texto:match("^Nível (%d+)/(%d+) • %+(%d+)%%$")
if a then return string.format("Level %s/%s • +%s%%", a, b, c) end
a = texto:match("^Requer (%d+) renascimento%(s%)$"); if a then return "Requires " .. a .. " rebirth(s)" end
a, b, c, d = texto:match("^Expandir: (%d+) × (%d+) × (%d+) • (.+)$")
if a then return string.format("Expand: %s × %s × %s • %s", a, b, c, d) end
a = texto:match("^Comprar • (.+)$"); if a then return "Buy • " .. a end
a = texto:match("^Velocidade das esteiras: (%d+)%% • alternar$")
if a then return "Conveyor speed: " .. a .. "% • toggle" end

-- Prestígio (Renascimento & Ascensão)
a = texto:match("^Vida (.+)$"); if a then return "Life " .. a end
a = texto:match("^Reencarnações: (.+)$"); if a then return "Rebirths: " .. a end
a = texto:match("^Requisito: (.+)$"); if a then return "Requirement: " .. a end
a = texto:match("^Saldo disponível: (.+)$"); if a then return "Available cash: " .. a end
a, b, c = texto:match("^%+(.-) vida%(s%) · (.-) pulada%(s%) · destino: vida (.+)$")
if a then return string.format("+%s life(s) · %s skipped · target: life %s", a, b, c) end
a, b = texto:match("^Reencarnar · (.-) peça%(s%) · %+(.-) vida%(s%)$")
if a then return string.format("Rebirth · %s part(s) · +%s life(s)", a, b) end
a = texto:match("^Transições: (.+)$"); if a then return "Transitions: " .. a end
a = texto:match("^Ascensões: (.+)$"); if a then return "Ascensions: " .. a end
a = texto:match("^Ascender · %+(.-) transiç.+"); if a then return "Ascend · +" .. a .. (if a == "1" then " transition" else " transitions") end
a, b = texto:match("^Próxima transição em (.-) · Após ascender: (.+)$")
if a then return "Next transition at " .. a .. " · After ascending: " .. b end
a, b = texto:match("^Transições extras exigem %+(.-) no expoente · Após ascender: (.+)$")
if a then return "Extra transitions require +" .. a .. " exponent · After ascending: " .. b end

-- Craft
a, b, c = texto:match("^([A-Z0-9]+) · (.-)  •  (%d+/%d+)$")
if a then return a .. " · " .. (exato[b] or b) .. "  •  " .. c end
a, b = texto:match("^([A-Z0-9]+) · (.+)$")
if a then return a .. " · " .. (exato[b] or b) end
a = texto:match("^› (.+)$"); if a then return "› " .. (exato[a] or a) end
a, b = texto:match("^(.+) no estoque / 1 · (.+)$")
if a then
local orig = b:gsub("^Loja · ", "Shop · "):gsub(" · variante$", " · variant")
return a .. " in stock / 1 · " .. (exato[orig] or orig)
end
a = texto:match("^Fabricar (.+)%?$"); if a then return "Craft " .. (exato[a] or a) .. "?" end
a = texto:match("^As (%d+) peças da receita serão consumidas%.$")
if a then return "All " .. a .. " recipe parts will be consumed." end
a = texto:match("^Variantes incluídas: (%d+)%.$"); if a then return "Variants included: " .. a .. "." end
a = texto:match("^(.+) fabricada e enviada ao inventário%.$")
if a then return (exato[a] or a) .. " crafted and sent to inventory." end
a = texto:match("^Falta: (.+)%.$"); if a then return "Missing: " .. (exato[a] or a) .. "." end

-- Blueprints & Auto-Blueprint
a = texto:match("^(%d+) salvo%(s%)$"); if a then return a .. " saved" end
a, b = texto:match("^(%d+) peça%(s%) • Tamanho %(L×C×A%): (.+) blocos$")
if a then return a .. " part(s) • Size (W×L×H): " .. b .. " blocks" end
a, b = texto:match("^Tamanho %(L×C×A%): (.+) blocos • (%d+) peça%(s%)$")
if a then return "Size (W×L×H): " .. a .. " blocks • " .. b .. " part(s)" end
a = texto:match("^Custo total: (.+)$")
if a then
local res = a:gsub("%(%+(%d+) renasc%.%)", "(+%1 rebirth)"):gsub("%(%+(%d+) craft%)", "(+%1 craft)")
return "Total cost: " .. res
end
a, b = texto:match("^⚡ Auto: Custo %((.-)%)(.*)$")
if a then return "⚡ Auto: Cost (" .. a .. ")" .. b:gsub("%(Pausado%)", "(Paused)") end
a, b = texto:match("^⚡ Auto: (%$[^%s]+)(.*)$")
if a then return "⚡ Auto: " .. a .. b:gsub("%(Pausado%)", "(Paused)") end
a = texto:match("^★ Ao Renascer: Sim(.*)$")
if a then return "★ On Rebirth: Yes" .. a:gsub("%(Pausado%)", "(Paused)") end
a = texto:match("^Pelo Custo %((.-)%)$"); if a then return "By Cost (" .. a .. ")" end
a = texto:match("^Escolha o Custo %((.-)%) ou digite um valor %(ex: 25K, 1,5M, 1e18%):$")
if a then return "Pick Cost (" .. a .. ") or enter a value (e.g. 25K, 1.5M, 1e18):" end
a = texto:match("^Vazio = usar custo %((.-)%) ou digite valor$")
if a then return "Empty = use cost (" .. a .. ") or type value" end
a, b = texto:match("^Peças do conjunto %((%d+) de (%d+) selecionadas%)$")
if a then return string.format("Blueprint parts (%s of %s selected)", a, b) end
a, b = texto:match('^Deletar o blueprint "(.+)" %((%d+) peça%(s%)%)%?$')
if a then return string.format('Delete blueprint "%s" (%s part(s))?', a, b) end
if texto == "Esta ação removerá o conjunto salvo da sua lista." then
return "This will permanently remove it from your list."
end

-- Coop
a, b, c = texto:match("^Limite da sua plot: (%d+) jogador%(es%) %(Ocupado: (%d+)/(%d+)%)$")
if a then return string.format("Your plot limit: %s player(s) (Used: %s/%s)", a, b, c) end
a, b = texto:match("^(.+)  •  Vagas na plot: (%d+/%d+)$")
if a then return a .. "  •  Plot slots: " .. b end
a = texto:match("^(.+)  •  Coop Fechado %(Limite 0%)$"); if a then return a .. "  •  Co-op Closed (Limit 0)" end
a = texto:match("^(.+)  •  Acesso bloqueado %(Banido%)$"); if a then return a .. "  •  Access blocked (Banned)" end
a = texto:match("^(.+)  •  Visitando outra plot$"); if a then return a .. "  •  Visiting another plot" end
a = texto:match("^(.+) quer ajudar na sua plot$"); if a then return a .. " wants to help on your plot" end
a = texto:match("^Você está no Coop de (.+)$"); if a then return "You are in " .. a .. "'s Co-op" end
if texto == "Sua própria plot continua funcionando e gerando dinheiro normalmente!" then
return "Your own plot keeps running and earning cash normally!"
end
a = texto:match("^Permissões na plot para: (.+)$"); if a then return "Plot permissions for: " .. a end
a = texto:match("^(%d+) pedido$"); if a then return a .. " request" end
a = texto:match("^(%d+) pedidos$"); if a then return a .. " requests" end

-- Elevador & Placas 3D
a = texto:match("^(%d+) blocos$"); if a then return a .. " blocks" end
a = texto:match("^LOTE (%d+)$"); if a then return "PLOT " .. a end

-- Tutorial
a, b = texto:match("^(%d+) de (%d+) capítulos • escolha um tema ou siga a sequência$")
if a then return a .. " of " .. b .. " chapters • pick a topic or follow in order" end
a, b, c = texto:match("^Capítulo (%d+) de (%d+) • (.+)$")
if a then return string.format("Chapter %s of %s • %s", a, b, exato[c] or c) end
a, b = texto:match("^(%d+) • (.+)$")
if a and exato[b] then return a .. " • " .. exato[b] end

-- Área de transferência / Histórico de Cópia
a, b, c, d = texto:match("^Copiar: %[(.-)%] • Colar: %[(.-)%] • Desfazer: %[(.-)%] • Refazer: %[(.-)%]$")
if a then return string.format("Copy: [%s] • Paste: [%s] • Undo: [%s] • Redo: [%s]", a, b, c, d) end
a = texto:match("^Aponte ou selecione peças na plot e pressione %[(.-)%]%.$")
if a then return "Point or select parts on your plot and press [" .. a .. "]." end
a, b = texto:match("^(%d+) peça%(s%) • (.*)$"); if a then return a .. " part(s) • " .. b end
a, b = texto:match("^(.+) %+ (%d+) peça%(s%)$"); if a then return (exato[a] or a) .. " + " .. b .. " part(s)" end

-- Confirmações e Mensagens do Servidor
a = texto:match("^Vender (%d+) peça%(s%)%?$"); if a then return "Sell " .. a .. " part(s)?" end
if texto == "As peças selecionadas serão removidas da plot ou do inventário." then
return "The selected parts will be removed from your plot or inventory."
end
a = texto:match("^Peca vendida por (.+)%.$"); if a then return "Part sold for " .. a .. "." end
a = texto:match("^Peça vendida por (.+)%.$"); if a then return "Part sold for " .. a .. "." end
a = texto:match("^Pecas vendidas por (.+)%.$"); if a then return "Parts sold for " .. a .. "." end
a = texto:match("^Peças vendidas por (.+)%.$"); if a then return "Parts sold for " .. a .. "." end
a, b = texto:match("^(%d+) de (%d+) pecas colocadas%.$"); if a then return a .. " of " .. b .. " parts placed." end
a = texto:match("^Reencarnou: %+(.-) vida%(s%)%.(.*)$")
if a then return "Rebirthed: +" .. a .. " life(s)." end
a = texto:match("^Trocar tema · (.+)$"); if a then return "Switch theme · " .. (exato[a] or a) end
a = texto:match("^(.+) por segundo$"); if a then return a .. " per second" end
a = texto:match("^(.+) para girar a entrada • Clique para fixar$")
if a then return a .. " to rotate input • Click to lock" end
a = texto:match("^(.+) para girar a saída • Mouse ↑/↓ para a altura • Clique para colocar$")
if a then return a .. " to rotate output • Mouse ↑/↓ for height • Click to place" end
a = texto:match("^(.+) colocada ✓$"); if a then return (exato[a] or a) .. " placed ✓" end

-- Controles com prefixo de botão do Gamepad ("R2 • Colocar")
a, b = texto:match("^([A-Z0-9↑↓]+) • (.+)$")
if a and exato[b] then return a .. " • " .. exato[b] end

-- Editor de Blueprints ("1. Mineradora básica [Âncora]" / "Pos: (...) bl • Renascimento")
a, b = texto:match("^(%d+%. )(.+) %[Âncora%]$")
if a then return a .. (exato[b] or b) .. " [Anchor]" end
a, b = texto:match("^(%d+%. )(.+)$")
if a and exato[b] then return a .. exato[b] end
if texto:sub(1, 5) == "Pos: " then
local posTr = texto:gsub("Renascimento", "Rebirth"):gsub("Ascensão", "Ascension")
if posTr ~= texto then return posTr end
end

-- Composição de peças em Blueprints / Histórico ("Mineradora básica ×2 • Esteira 2×2 (1 inclinada)")
if texto:find(" • ", 1, true) or texto:find(" inclinada", 1, true) then
local corpo, sufixoInc = texto:match("^(.-)( %(%d+ inclinadas?%))$")
local base = corpo or texto
local itens = string.split(base, " • ")
local mudouComp = false
for i, item in itens do
local nomeP, multP = item:match("^(.-)( ×%d+)$")
local chaveNome = nomeP or item
if exato[chaveNome] then
itens[i] = exato[chaveNome] .. (multP or "")
mudouComp = true
end
end
if mudouComp or sufixoInc then
local sufTr = if sufixoInc then sufixoInc:gsub("inclinadas?", "tilted") else ""
return table.concat(itens, " • ") .. sufTr
end
end

return texto
end

function Traducao.TraduzirTexto(texto, jogador)
if type(texto) ~= "string" or texto == "" then return texto end
local lang = normalizarIdioma(obterLocaleAtivo(jogador))
if lang == "pt" then return texto end
if not carregarIndicesTabela() then return texto end

local exato = mapaPorIdioma[lang]
if not exato then return texto end
if textosTraduzidos[lang] and textosTraduzidos[lang][texto] then return texto end

-- Fast path: números puros, saldos, multiplicadores, @usuários
if texto:match("^[%$%+%-%d%.,×x/sKMBTQdQnSxSpONeE%s—•★↑↓←→×]+$") or texto:sub(1, 1) == "@" or texto:match("^%d+%.  @") then
return texto
end

if exato[texto] then return exato[texto] end

-- Textos multilinhas são divididos antes do pattern-matching para (.+)$ não engolir as linhas seguintes
if texto:find("\n", 1, true) then
local partes = string.split(texto, "\n")
local mudou = false
for i, linha in partes do
if linha ~= "" then
local nova = traduzirFraseEn(linha, exato)
if nova ~= linha then
partes[i] = nova
mudou = true
end
end
end
return if mudou then table.concat(partes, "\n") else texto
end

return traduzirFraseEn(texto, exato)
end

local function processarObjetoUI(obj)
if not obj or not obj.Parent then return end
if obj:IsA("ScreenGui") then
obj.AutoLocalize = false
return
end
if obj:IsA("TextLabel") or obj:IsA("TextButton") then
local function aplicar()
if aplicandoTexto[obj] then return end
local atual = obj.Text
if atual == "" then return end
local traduzido = Traducao.TraduzirTexto(atual)
if traduzido ~= atual then
aplicandoTexto[obj] = true
obj.Text = traduzido
aplicandoTexto[obj] = nil
end
end
aplicar()
obj:GetPropertyChangedSignal("Text"):Connect(aplicar)
elseif obj:IsA("TextBox") then
local function aplicarPh()
if aplicandoTexto[obj] then return end
local atual = obj.PlaceholderText
if atual == "" then return end
local traduzido = Traducao.TraduzirTexto(atual)
if traduzido ~= atual then
aplicandoTexto[obj] = true
obj.PlaceholderText = traduzido
aplicandoTexto[obj] = nil
end
end
aplicarPh()
obj:GetPropertyChangedSignal("PlaceholderText"):Connect(aplicarPh)
end
end

function Traducao.IniciarObservadorUI()
if observandoUI or not RunService:IsClient() then return end
observandoUI = true

task.spawn(function()
local jogador = Players.LocalPlayer
if not jogador then return end
LocalizationService:WaitForChild("Traducoes", 10)
carregarIndicesTabela()

local playerGui = jogador:WaitForChild("PlayerGui", 10)
if playerGui then
for _, desc in playerGui:GetDescendants() do
processarObjetoUI(desc)
end
playerGui.DescendantAdded:Connect(processarObjetoUI)
end

-- Observar também as placas dos lotes em workspace.Cenario.Sinalizacao
local cenario = workspace:WaitForChild("Cenario", 10)
local sinais = cenario and cenario:WaitForChild("Sinalizacao", 10)
if sinais then
for _, desc in sinais:GetDescendants() do
if desc:IsA("TextLabel") then processarObjetoUI(desc) end
end
sinais.DescendantAdded:Connect(function(desc)
if desc:IsA("TextLabel") then processarObjetoUI(desc) end
end)
end

local function aoMudarLocale()
tradutorLocal = nil
localeLocalAtual = nil
if playerGui then
for _, desc in playerGui:GetDescendants() do
if desc:IsA("TextLabel") or desc:IsA("TextButton") then
local t = Traducao.TraduzirTexto(desc.Text)
if t ~= desc.Text then
aplicandoTexto[desc] = true
desc.Text = t
aplicandoTexto[desc] = nil
end
elseif desc:IsA("TextBox") then
local p = Traducao.TraduzirTexto(desc.PlaceholderText)
if p ~= desc.PlaceholderText then
aplicandoTexto[desc] = true
desc.PlaceholderText = p
aplicandoTexto[desc] = nil
end
end
end
end
end
jogador:GetPropertyChangedSignal("LocaleId"):Connect(aoMudarLocale)
LocalizationService:GetPropertyChangedSignal("RobloxLocaleId"):Connect(aoMudarLocale)
end)
end

if RunService:IsClient() then
Traducao.IniciarObservadorUI()
end

return Traducao