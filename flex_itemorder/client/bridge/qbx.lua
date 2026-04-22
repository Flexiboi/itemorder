if GetResourceState('qbx_core') ~= 'started' then return end

function GetPlayerData()
    return exports.qbx_core:GetPlayerData()
end

function onPlayerLoaded()
    return "QBCore:Client:OnPlayerLoaded"
end

function onPlayerUnLoaded()
    return "QBCore:Client:OnPlayerUnload"
end