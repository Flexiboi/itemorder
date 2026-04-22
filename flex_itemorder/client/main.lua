local points = {}
local peds, orderPed = {}, nil

local function canInteract(job)
    local data = QBX.PlayerData or {}
    if data.job.name ~= 'unemployed' then
        if Config.Jobs[job] then
            local grade = Config.Jobs[job].grade
            return data.job.grade.level >= grade
        else
            return false
        end
    elseif data.gang.name ~= 'none' then
        if Config.Jobs[job] then
            local grade = Config.Jobs[job].grade
            return data.gang.grade.level >= grade
        else
            if job == 'gang' and Config.Jobs['gang'] then
                local grade = Config.Jobs['gang'].grade
                return true
            else
                return false
            end
        end
    else
        return false
    end
end

local function addToOrder(job, coords)
     local data = QBX.PlayerData or {}
    if (data and data.job.name == job and data.job.onduty) or data.gang.name == job or not data or not job then
        local items = Config.Jobs[job or (not job or not data) and 'unemployed'].items
        local inv = exports.ox_inventory:Items()
        local menu = {}
        for k, v in pairs(items) do
            if inv[k] then
                local item = inv[k]
                menu[#menu + 1] = {
                    title = locale('menu.title_addtoorder', item.label),
                    description = locale('menu.description_addtoorder', v),
                    image = string.format("nui://ox_inventory/web/images/%s", (item.client and item.client.image) and item.client.image or (k .. ".png")),
                    order = k,
                    onSelect = function()
                        local input = lib.inputDialog(locale('menu.how_much_order'), {
                            { type = 'number', label = locale('menu.amount') },
                        })
                        if input and input[1] and tonumber(input[1]) > 0 then
                            lib.callback('flex_itemorder:server:AddToOrder', 1000, function(added)
                                if added then
                                    Config.Notify.client(locale('success.order_added'), 'success')
                                else
                                    Config.Notify.client(locale('error.cant_add_to_order'), 'error')
                                end
                                addToOrder(job, coords)
                            end, job or ((not job or not data) and 'unemployed'), k, tonumber(input[1]), v, coords)
                        end
                    end
                }
            end
        end
        lib.registerContext({
            id = locale('menu.title_order')..'_flex_itemorder',
            title = locale('menu.title_order'),
            options = menu
        })
        lib.showContext(locale('menu.title_order')..'_flex_itemorder')
    end
end

local function checkOrder(job, coords)
    local data = QBX.PlayerData or {}
    if (data and data.job.name == job and data.job.onduty) or data.gang.name == job or not data or not job then
        local inv = exports.ox_inventory:Items()
        local items = Config.Jobs[job or (not job or not data) and 'unemployed'].items
        local menu = {}
        local totalPrice = 0
        lib.callback('flex_itemorder:server:GetCurrentOrder', 1000, function(order)
            if order then
                for k, v in pairs(order) do
                    if inv[v.item] then
                        local item = inv[v.item]
                        totalPrice += (items[v.item] * v.amount)
                        menu[#menu + 1] = {
                            title = locale('menu.check_title', item.label, v.amount),
                            description = locale('menu.remove'),
                            image = string.format("nui://ox_inventory/web/images/%s", (item.client and item.client.image) and item.client.image or (v.item .. ".png")),
                            order = k,
                            onSelect = function()
                                local input = lib.inputDialog(locale('menu.how_much_remove'), {
                                    { type = 'number', label = locale('menu.amount') },
                                })
                                if input and input[1] and tonumber(input[1]) > 0 then
                                    lib.callback('flex_itemorder:server:RemoveFromOrder', 1000, function(removed)
                                        if removed then
                                            Config.Notify.client(locale('success.order_removed'), 'success')
                                        else
                                            Config.Notify.client(locale('error.cant_add_to_order'), 'error')
                                        end
                                        checkOrder(job, coords)
                                    end, job or ((not job or not data) and 'unemployed'), v.item, tonumber(input[1]), coords)
                                end
                            end
                        }
                    end
                end
            end
            lib.registerContext({
                id = locale('menu.title_checkorder')..'_flex_itemorder',
                title = locale('menu.title_checkorder', math.floor(totalPrice)),
                options = menu
            })
            lib.showContext(locale('menu.title_checkorder')..'_flex_itemorder')
        end, job or ((not job or not data) and 'unemployed'), coords)
    end
end

local function confirmOrder(job, coords)
    local data = QBX.PlayerData or {}
    if (data and data.job.name == job and data.job.onduty) or data.gang.name == job or not data or not job then
        local inv = exports.ox_inventory:Items()
        local items = Config.Jobs[job or (not job or not data) and 'unemployed'].items
        local menu = {}
        local totalPrice = 0
        local weight = 0
        lib.callback('flex_itemorder:server:GetCurrentOrder', 1000, function(order)
            if order then
                for k, v in pairs(order) do
                    if inv[v.item] then
                        local item = inv[v.item]
                        totalPrice += (items[v.item] * v.amount)
                        weight += math.floor(item.weight * v.amount)
                    end
                end
                menu[#menu + 1] = {
                    title = locale('menu.confirm'),
                    description = locale('menu.total_to_pay', totalPrice),
                    onSelect = function()
                        lib.callback('flex_itemorder:server:ConfirmOrder', 1000, function(confirmed)
                            if confirmed then
                                Config.Notify.client(locale('success.order_confirmed'), 'success')
                            else
                                Config.Notify.client(locale('error.not_enough_balance'), 'error')
                            end
                        end, job, coords, weight)
                    end
                }
            end
            lib.registerContext({
                id = locale('menu.title_confirmorder')..'_flex_itemorder',
                title = locale('menu.title_confirmorder'),
                options = menu
            })
            lib.showContext(locale('menu.title_confirmorder')..'_flex_itemorder')
        end, job or (not job or not data) and 'unemployed', coords)
    end
end

local function getTargetOptions(job, coords)
    local targetOptions = {
        {
            name = locale('target.order')..'_flex_itemorder',
            label = locale('target.order'),
            icon = "fa-solid fa-question",
            distance = 2.0,
            canInteract = function()
                return canInteract(job)
            end,
            onSelect = function()
               addToOrder(job, coords)
            end
        },
        {
            name = locale('target.check')..'_flex_itemorder',
            label = locale('target.check'),
            icon = "fa-solid fa-question",
            distance = 2.0,
            canInteract = function()
                return canInteract(job)
            end,
            onSelect = function()
                checkOrder(job, coords)
            end
        },
        {
            name = locale('target.submit')..'_flex_itemorder',
            label = locale('target.submit'),
            icon = "fa-solid fa-question",
            distance = 2.0,
            canInteract = function()
                return canInteract(job)
            end,
            onSelect = function()
                confirmOrder(job, coords)
            end
        },
    }
    return targetOptions
end

local function load()
    for k, v in pairs(Config.Peds) do
        
        local point = lib.points.new(v.coords.xyz, 10)
        points[k] = point
        function point:onEnter()
            if IsModelAPed(v.ped) then
                function createEntity()
                    local orderPed = CreatePed(0, v.ped, v.coords.x, v.coords.y, v.coords.z - 1.0, v.coords.w, false, false)
                    SetEntityInvincible(orderPed, true)
                    SetEntityNoCollisionEntity(orderPed, cache.ped, false)
                    TaskStartScenarioInPlace(orderPed, Config.scenarios[math.random(1, #Config.scenarios)], -1, true)
                    SetBlockingOfNonTemporaryEvents(orderPed, true)
                    SetEntityNoCollisionEntity(orderPed, cache.ped, false)
                    FreezeEntityPosition(orderPed, true)
                    peds[k] = orderPed
                end
    
                function deleteEntity()
                    DeletePed(peds[k])
                    peds[k] = nil
                end
            end
            if not peds[k] or (peds[k] and not DoesEntityExist(peds[k])) then
                while not HasModelLoaded(v.ped) do
                    pcall(function()
                        lib.requestModel(v.ped)
                    end)
                end
                createEntity()
            end

            if v.job then
                exports.ox_target:addLocalEntity(peds[k], getTargetOptions(v.job or nil, v.coords.xyz))
            else
                local data = QBX.PlayerData or {}
                exports.ox_target:addLocalEntity(peds[k], {
                    {
                        name = locale('target.grab_order')..'_flex_itemorder',
                        label = locale('target.grab_order'),
                        icon = "fa-solid fa-question",
                        distance = 2.0,
                        canInteract = function()
                            return not v.canTake or v.canTake and lib.table.contains(v.canTake, data.job.name) or v.canTake and lib.table.contains(v.canTake, data.gang.name)
                        end,
                        onSelect = function()
                            local stashId = (data.job.name ~= 'unemployed' and Config.Jobs[data.job.name] and data.job.name) or (data.gang.name ~= 'none' and Config.Jobs[data.gang.name] and data.gang.name) or data.citizenid
                            lib.callback('flex_itemorder:server:GetCurrentOrder', 1000, function(order)
                                if order then
                                    local inv = exports.ox_inventory:Items()
                                    local items = Config.Jobs[stashId].items
                                    local menu = {}
                                    local weight = 0
                                    TriggerServerEvent("InteractSound_SV:PlayOnSource", "StashOpen", 0.4)
                                    if not exports.ox_inventory:openInventory('stash', stashId..'_order') then
                                        for k, v in pairs(order) do
                                            if inv[v.item] then
                                                local item = inv[v.item]
                                                weight += math.floor(item.weight * v.amount)
                                            end
                                        end
                                        lib.callback('flex_itemorder:server:RegisterStash', 1000, function(success)
                                            if success then
                                            end
                                        end, stashId, v.coords.xyz, weight)
                                    end
                                end
                            end, stashId, v.coords.xyz)
                        end
                    },
                })
            end
        end

        function point:onExit()
            deleteEntity()
            exports.ox_target:removeLocalEntity(peds[k])
        end

    end
end

-- Player load event
RegisterNetEvent(onPlayerLoaded(), function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(1000)
    end
    load()
end)

-- Resource start event
AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        while not LocalPlayer.state.isLoggedIn do
            Wait(1000)
        end
        load()
    end
end)

-- Player unload event
RegisterNetEvent(onPlayerUnLoaded(), function()
    for k, v in pairs(peds) do
        exports.ox_target:removeLocalEntity(v)
        DeletePed(v)
    end
end)

-- Resource stop event
AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for k, v in pairs(peds) do
            exports.ox_target:removeLocalEntity(v)
            DeletePed(v)
        end
    end
end)