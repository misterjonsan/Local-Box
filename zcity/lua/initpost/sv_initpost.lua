

timer.Simple(1, function()
    function GAMEMODE:PlayerSay( ply, text, teamonly ) // commands and shit get called about here

        local txt = {text}
        hook.Run("HG_PlayerSay", ply, txt) // our shit gets called later
        text = isstring(txt[1]) and txt[1] or text // checks to see if shit hits the ceiling

        return text

    end
    
    hook.Add("HG_PlayerSay", "niggamove", function(ply, txt)
        //txt[1] = "huy"
    end)
end)