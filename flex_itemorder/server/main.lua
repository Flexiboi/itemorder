local orders, activeOrders, stashIds = {}, {}, {}
local function SendWebhook(title, description)
    if SV_Config.WEBHOOK == "" or SV_Config.WEBHOOK == nil then return end

    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["type"] = "rich",
            ["color"] = 3066993,
            ["footer"] = {
                ["text"] = "VOS ITEM ORDER",
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(SV_Config.WEBHOOK, function(err, text, headers) end, 'POST', json.encode({
        username = "VOS",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

lib.callback.register("flex_itemorder:server:AddToOrder", function(source, job, item, amount, price, coords)
    if activeOrders[job] then
        return not activeOrders[job].ordered
    end
    local src = source
    if not job then return false end
    if not coords then return false end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 10.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    local player = GetPlayer(src)
    if not player then return false end
    local citizen = player.PlayerData.citizenid
    if not citizen then return false end
    if job == ('unemployed' or 'gang') then job = citizen end
    if not orders[job] then
        orders[job] = {}
    end
    for k, v in pairs(orders[job]) do
        if v.item and v.item == item then
            v.amount += amount
            return true
        end
    end
    table.insert(orders[job], {item = item, amount = amount, price = price})
    return true
end)

lib.callback.register("flex_itemorder:server:RemoveFromOrder", function(source, job, item, amount, coords)
    if activeOrders[job] then
        return not activeOrders[job].ordered
    end
    local src = source
    if not job then return false end
    if not coords then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 10.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    local player = GetPlayer(src)
    if not player then return false end
    local citizen = player.PlayerData.citizenid
    if not citizen then return false end
    if job == ('unemployed' or 'gang') then job = citizen end
    if not orders[job] then
        orders[job] = {}
    end
    for k, v in pairs(orders[job]) do
        if v.item and v.item == item and v.amount and v.amount >= 0 then
            if (v.amount - amount) <= 0 then
                table.remove(orders[job], k)
            else
                v.amount -= amount
            end
            return true
        elseif  v.item and v.item == item then
            table.remove(orders[job], k)
            return true
        end
    end
    return false
end)

lib.callback.register("flex_itemorder:server:GetCurrentOrder", function(source, job, coords)
    local src = source
    if not job then return false end
    if not coords then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 10.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    local player = GetPlayer(src)
    if not player then return false end
    local citizen = player.PlayerData.citizenid
    if not citizen then return false end
    if job == ('unemployed' or 'gang') then job = citizen end
    if not orders[job] then
        orders[job] = {}
    end
    return orders[job] or {}
end)

lib.callback.register("flex_itemorder:server:ConfirmOrder", function(source, job, coords, weight)
    local src = source
    if not job then return false end
    if not coords then return false end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 10.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    local player = GetPlayer(src)
    if not player then return false end
    local citizen = player.PlayerData.citizenid
    if not citizen then return false end
    if job == ('unemployed' or 'gang') then job = citizen end
    if not orders[job] then
        orders[job] = {}
    end
    if not activeOrders[job] then
        activeOrders[job] = {}
    end
    if not orders[job] or #orders[job] <= 0 or (activeOrders[job] and activeOrders[job].ordered) then return false end
    local totalPrice = 0
    for k, v in pairs(orders[job]) do
        totalPrice += v.price and (v.price * v.amount or 1) or 0
    end
    if totalPrice <= 0 then return false end
    local canPay = PayOrder(src, job, totalPrice)
    if not canPay then return false end
    SendWebhook(locale('discord.order_payed_title'), locale('discord.order_payed_desc', totalPrice, json.encode(orders[job])))
    activeOrders[job].ordered = true
    return activeOrders[job].ordered
end)

lib.callback.register("flex_itemorder:server:RegisterStash", function(source, job, coords, weight)
    local src = source
    if not job then return false end
    if not coords then return false end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 10.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    local player = GetPlayer(src)
    if not player then return false end
    local citizen = player.PlayerData.citizenid
    if not citizen then return false end
    local items = {}
    for k, v in pairs(orders[job]) do
        items[k] = {
            v.item,
            v.amount,
            {metadata = SV_Config.Metadata[v.item] or nil}
        }
    end
    local stashId = RegisterTempStash(job..'_order', #orders[job], weight, coords, job ~= citizen and job, items)
    if not stashId then return false end
    stashIds[job] = stashId
    if activeOrders[job] then
        activeOrders[job] = nil
    end
    orders[job] = {}
    TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stashIds[job])
    return true
end)