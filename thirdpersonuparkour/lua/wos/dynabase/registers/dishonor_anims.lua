wOS.DynaBase:RegisterSource({
    Name = "Quick Dishonored animation",
    Type = WOS_DYNABASE.EXTENSION,

    -- model paths per gender:
    Shared = "models/avault/Dishonored.mdl",      -- default or neutral model
    Female = "models/avault/Dishonored_f.mdl",    -- female-specific model (optional)
    Male   = "models/avault/Dishonored_m.mdl"     -- optional if you have a male version
})

hook.Add("PreLoadAnimations", "wOS.DynaBase.MountDishonor", function(gender)
    if gender == WOS_DYNABASE.SHARED then
        IncludeModel("models/avault/Dishonored.mdl")
    elseif gender == WOS_DYNABASE.FEMALE then
        IncludeModel("models/avault/Dishonored_f.mdl")
    elseif gender == WOS_DYNABASE.MALE then
        IncludeModel("models/avault/Dishonored_m.mdl")
    end
end)
