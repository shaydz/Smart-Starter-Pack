script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    local force = player.force
    local active_mods = script.active_mods
    local has_k2 = active_mods["Krastorio2"] or active_mods["Krastorio2-spaced-out"]

    -- Attempt to find the player's character entity.
    -- (Accessing inventory via player.get_inventory() fails here because the
    -- character body may not be fully registered yet — go through the entity instead.)
    local character = player.character or player.cutscene_character
    if not character then
        log("Smart Starter Pack: no character found for player '" .. player.name .. "', skipping starter items.")
        return
    end

    -- Get main inventory via character entity
    local inventory = character.get_main_inventory()
    if not inventory then
        log("Smart Starter Pack: could not get main inventory for player '" .. player.name .. "'.")
        return
    end

    -- ===============================================
    -- UNIVERSAL ITEMS (always given regardless of mods)
    -- ===============================================
    if settings.global["ssp-enable-universal"].value then
        local repair_count = settings.global["ssp-repair-pack-count"].value
        if repair_count > 0 then
            inventory.insert({name = "repair-pack", count = repair_count})
        end
    end

    -- ===============================================
    -- MOD: Mining Drones Remastered
    -- ===============================================
    if active_mods["Mining_Drones_Remastered"] and settings.global["ssp-enable-mining-drones"].value then
        -- Unlock the technology
        if force.technologies["mining-drone"] then
            force.technologies["mining-drone"].researched = true
        else
            log("Smart Starter Pack: warning — mining-drone technology not found.")
        end

        -- Insert starting items
        local drone_count = settings.global["ssp-mining-drone-count"].value
        local depot_count = settings.global["ssp-mining-depot-count"].value
        if drone_count > 0 then
            inventory.insert({name = "mining-drone", count = drone_count})
        end
        if depot_count > 0 then
            inventory.insert({name = "mining-depot", count = depot_count})
        end
    end

    -- ===============================================
    -- MOD: AAI Loaders
    -- ===============================================
    if active_mods["aai-loaders"] and settings.global["ssp-enable-aai-loaders"].value then
        local loader_count = settings.global["ssp-aai-loader-count"].value
        if loader_count > 0 then
            inventory.insert({name = "aai-loader", count = loader_count})
        end
    end

    -- ===============================================
    -- MOD: Krastorio 2
    -- ===============================================
    if has_k2 and settings.global["ssp-enable-k2"].value then
        -- Give construction robots to main inventory
        local robot_count = settings.global["ssp-k2-robot-count"].value
        if robot_count > 0 then
            inventory.insert({name = "construction-robot", count = robot_count})
        end

        -- Equip power armor and pre-fill its grid
        if settings.global["ssp-give-armor"].value then
            local k2_armor_inv = character.get_inventory(defines.inventory.character_armor)
            if k2_armor_inv then
                k2_armor_inv.insert({name = "power-armor", count = 1})
                local k2_armor_stack = k2_armor_inv[1]
                if k2_armor_stack and k2_armor_stack.valid_for_read then
                    local grid = k2_armor_stack.grid
                    if grid then
                        -- Place largest items first to avoid grid fragmentation
                        -- Generators: 3x (2x2 each = 12 tiles)
                        for _ = 1, 3 do
                            grid.put({name = "kr-small-portable-generator-equipment"})
                        end
                        -- Personal roboports: 2x (2x2 each = 8 tiles)
                        for _ = 1, 2 do
                            grid.put({name = "personal-roboport-equipment"})
                        end
                        -- Batteries: 4x (1x2 each = 8 tiles)
                        for _ = 1, 4 do
                            grid.put({name = "battery-equipment"})
                        end
                        -- Solar panels: 8x (1x1 each = 8 tiles)
                        for _ = 1, 8 do
                            grid.put({name = "solar-panel-equipment"})
                        end
                    end
                end
            end
        end
    end

    -- ===============================================
    -- VANILLA ARMOR KIT (skipped if Krastorio 2 is active,
    -- as K2 overhauls progression and provides its own gear)
    -- ===============================================
    if not has_k2 and settings.global["ssp-enable-vanilla-armor"].value then
        -- Construction robots go in the main inventory (used by the roboport)
        local robot_count = settings.global["ssp-vanilla-robot-count"].value
        if robot_count > 0 then
            inventory.insert({name = "construction-robot", count = robot_count})
        end

        -- Get armor inventory via character entity
        if settings.global["ssp-give-armor"].value then
            local armor_inv = character.get_inventory(defines.inventory.character_armor)
            if armor_inv then
                armor_inv.insert({name = "modular-armor", count = 1})

                -- Pre-fill the armor's equipment grid (fits perfectly: 4+8+13 = 25 tiles)
                local armor_stack = armor_inv[1]
                if armor_stack and armor_stack.valid_for_read then
                    local grid = armor_stack.grid
                    if grid then
                        -- Personal roboport: 2x2 = 4 tiles
                        grid.put({name = "personal-roboport-equipment"})
                        -- Batteries: 4 x (1x2) = 8 tiles
                        for _ = 1, 4 do
                            grid.put({name = "battery-equipment"})
                        end
                        -- Solar panels: 13 x (1x1) = 13 tiles
                        for _ = 1, 13 do
                            grid.put({name = "solar-panel-equipment"})
                        end
                    end
                end
            end
        end
    end

    inventory.sort_and_merge()
end)
