local NoSuicideMSG = {
	"Use of kill bind is disabled.",
}

net.Receive("NoSuicide", function()
    local Randomizer = math.random(1, #NoSuicideMSG)
    chat.AddText(Color(255,100,100), NoSuicideMSG[Randomizer])
end)