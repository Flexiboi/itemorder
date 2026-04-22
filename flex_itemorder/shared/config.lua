Config = {}

Config.Debug = false
Config.CoreName = {
    qb = 'qb-core',
    esx = 'es_extended',
    ox = 'ox_core',
    ox_inv = 'ox_inventory',
    qbx = 'qbx_core',
}

Config.Notify = {
    client = function(msg, type, time)
        lib.notify({
            title = msg,
            type = type,
            time = time or 5000,
        })
    end,
    server = function(src, msg, type, time)
        lib.notify(src, {
            title = msg,
            type = type,
            time = time or 5000,
        })
    end,
}

Config.scenarios = { "WORLD_HUMAN_VALET", "WORLD_HUMAN_AA_COFFEE", "WORLD_HUMAN_GUARD_STAND_CASINO", "WORLD_HUMAN_GUARD_PATROL", "PROP_HUMAN_STAND_IMPATIENT", }
Config.Peds = {
    -- [1] = {coords = vector4(-346.65759277344, -130.06365966797, 39.009910583496, 252.41314697266), ped = 's_m_y_armymech_01', job = 'gang'}, -- Location to order based on gang / anyone can order here
    -- [1] = {coords = vector4(-346.65759277344, -130.06365966797, 39.009910583496, 252.41314697266), ped = 's_m_y_armymech_01', }, -- Location to take order but anyone can take their order here
    [1] = {coords = vector4(-346.65759277344, -130.06365966797, 39.009910583496, 252.41314697266), ped = 's_m_y_armymech_01', job = 'vcr'}, -- Location to order based on job
    [2] = {coords = vector4(858.63061523438, -3203.0212402344, 5.9949960708618, 171.02101135254), ped = 's_m_y_dockwork_01', canTake = {'vcr'}}, -- Location to take order if your job or gang allows it
}

Config.Jobs = {
    vcr = { -- VCR JOB
        grade = 3, -- Min grade to order / open menu
        items = { -- Itemlist they can order and price
            nitrous_bottle = 2100,
            nitrous_install_kit = 170,
            repair_kit = 200,
            engine_oil = 50,
            tyre_replacement = 200,
            tyre_replacement = 200,
            clutch_replacement = 50,
            air_filter = 50,
            spark_plug = 45,
            suspension_parts = 50,
            turbocharger = 7500,
            ev_motor = 50,
            ev_coolant = 50,
            ev_battery = 50,
            stancing_kit = 150,
            cosmetic_part = 200,
            respray_kit = 200,
            vehicle_wheels = 200,
            extras_kit = 200,
            performance_part = 6200,
        }
    },
    -- gang = { -- gang / global / for anyone
    --     grade = 0, -- Min grade to order / open menu
    --     items = { -- Itemlist they can order and price
    --         i4_engine = 100,
    --         v6_engine = 200,
    --         v8_engine = 300,
    --         awd_drivetrain = 500,
    --     }
    -- },
}