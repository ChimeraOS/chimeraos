-- HDMI Passthrough Script Loader for WirePlumber
-- Author: D.A.Pelasgus

print("Loading HDMI passthrough script from /etc/wireplumber/scripts/hdmi_passthrough.lua")

table.insert(package.loaders, function(modname)
    local modfile = "/etc/wireplumber/scripts/" .. modname .. ".lua"
    local f = io.open(modfile, "r")
    if f then
        io.close(f)
        return loadfile(modfile)
    end
end)

-- Load the HDMI passthrough script
require("hdmi_passthrough")
