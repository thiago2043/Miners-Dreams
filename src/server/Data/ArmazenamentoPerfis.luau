local ProfileStore=require(script.Parent.Parent.Libraries.ProfileStore)
local nome=game:GetService("RunService"):IsStudio() and "Test" or "Live"
return ProfileStore.New(nome,require(script.Parent.Template))
