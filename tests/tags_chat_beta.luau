local jogadores = {}
local chat = {}
function chat:WaitForChild(nome)
	assert(nome == "ChatWindowConfiguration")
	return {DeriveNewMessageProperties = function() return {} end}
end
local carregar = require("./suporte/carregador")({}, {
	Players = {GetPlayerByUserId = function(_, id) return jogadores[id] end},
	TextChatService = chat,
})
local beta = carregar("src/shared/RecompensasBeta")
carregar("src/client/TagsChatBeta.client")
local atributo = {TemaBeta = beta.Participacao}
jogadores[1] = {GetAttribute = function(_, nome) return atributo[nome] end}

local prefixo = '<font color="#00FFFF">Nome:</font>'
local mensagem = {TextSource = {UserId = 1}, PrefixText = prefixo, Text = "Mensagem filtrada"}
assert(chat.OnChatWindowAdded(mensagem) == nil)
assert(chat.OnChatWindowAdded({PrefixText = "Sistema"}) == nil)
assert(chat.OnChatWindowAdded({TextSource = {UserId = 2}, PrefixText = "Outro:"}) == nil)

atributo.EmblemaBetaTester = true
local propriedades = chat.OnChatWindowAdded(mensagem)
assert(propriedades.PrefixText == '<font color="#FFC556">[TESTE BETA]</font> ' .. prefixo)
assert(propriedades.Text == nil and mensagem.PrefixText == prefixo and mensagem.Text == "Mensagem filtrada")

atributo.TemaBeta = beta.E308
assert(chat.OnChatWindowAdded(mensagem) == nil)
atributo.EmblemaBetaE308 = true
assert(chat.OnChatWindowAdded(mensagem).PrefixText == '<font color="#C289FF">[E308 • TESTE BETA]</font> ' .. prefixo)
atributo.TemaBeta = beta.Padrao
assert(chat.OnChatWindowAdded(mensagem) == nil)
print("TAGS_CHAT_BETA_OK: cores, troca de tema, posse do emblema e prefixo nativo preservado.")
