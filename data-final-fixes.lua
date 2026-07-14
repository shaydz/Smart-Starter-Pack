-- data-final-fixes.lua
-- Runs after all other mods (including Krastorio 2) have finished their data stage.
-- Removes Krastorio 2's fuel requirements from personal equipment generators
-- and spidertron power sources, reverting them to vanilla-style free power.
-- Detect Krastorio 2 or Krastorio 2 Spaced Out
local has_k2 = mods["Krastorio2"] or mods["Krastorio2-spaced-out"]

if has_k2 and settings.startup["ssp-k2-remove-fuel-requirement"].value then

  -- =====================================================
  -- Personal equipment generators (generator-equipment)
  -- K2 adds burner-powered generators; remove the burner
  -- so they produce power freely like vanilla equipment.
  -- =====================================================
  if data.raw["generator-equipment"] then
    for name, equipment in pairs(data.raw["generator-equipment"]) do
      if equipment.burner then
        log("Smart Starter Pack: removing fuel requirement from equipment '" .. name .. "'")
        equipment.burner = nil
      end
    end
  end

  -- =====================================================
  -- Spidertrons (spider-vehicle)
  -- K2 changes spidertron energy sources to burner type;
  -- revert them to void (no fuel needed).
  -- =====================================================
  if data.raw["spider-vehicle"] then
    for name, spider in pairs(data.raw["spider-vehicle"]) do
      if spider.energy_source and spider.energy_source.type == "burner" then
        log("Smart Starter Pack: removing fuel requirement from spider vehicle '" .. name .. "'")
        spider.energy_source = {type = "void"}
      end
    end
  end

end

-- =====================================================
-- Revert Krastorio 2's radar power changes to vanilla values.
-- K2 sets energy_usage = "1MW" (vanilla: 300kW) and
-- energy_per_sector = "2MJ" (vanilla: 10MJ).
-- We restore both so the standard radar is no more
-- expensive to run than it is in the base game.
-- =====================================================
if has_k2 then
  local radar = data.raw["radar"]["radar"]
  if radar then
    log("Smart Starter Pack: reverting K2 radar power to vanilla values.")
    radar.energy_usage        = "300kW"
    radar.energy_per_sector   = "10MJ"
    -- energy_per_nearby_scan is already "250kJ" in both vanilla and K2
  end
end
-- =====================================================
-- SPACE EXPLORATION: Landfill Multiplier
-- Some other mods fail to multiply SE's custom landfill recipes.
-- We run in data-final-fixes and dynamically search every recipe
-- to ensure any recipe yielding 'landfill' gets multiplied.
-- =====================================================
if mods["space-exploration"] and settings.startup["ssp-se-multiply-landfill"].value then
  local multiplier = settings.startup["ssp-se-landfill-multiplier"].value
  
  local max_amount = 65535  -- Factorio's 16-bit cap on recipe result amounts

  local function multiply_landfill_results(results_table)
    local modified = false
    for _, result in pairs(results_table) do
      -- Result can be {"landfill", 1} or {name="landfill", amount=1}
      local name = result.name or result[1]
      if name == "landfill" then
        if result.amount then
          result.amount = math.min(result.amount * multiplier, max_amount)
        elseif result[2] then
          result[2] = math.min(result[2] * multiplier, max_amount)
        elseif result.amount_min and result.amount_max then
          result.amount_min = math.min(result.amount_min * multiplier, max_amount)
          result.amount_max = math.min(result.amount_max * multiplier, max_amount)
        end
        modified = true
      end
    end
    return modified
  end

  local function check_recipe_block(block)
    local modified = false
    if block.results then
      modified = multiply_landfill_results(block.results) or modified
    elseif block.result == "landfill" then
      -- Convert shorthand `result="landfill"` to robust `results` table
      local count = block.result_count or 1
      block.results = {{type="item", name="landfill", amount=math.min(count * multiplier, max_amount)}}
      block.result = nil
      block.result_count = nil
      modified = true
    end
    return modified
  end

  if data.raw.recipe then
    for _, recipe in pairs(data.raw.recipe) do
      local modified = check_recipe_block(recipe)
      if recipe.normal then
        modified = check_recipe_block(recipe.normal) or modified
      end
      if recipe.expensive then
        modified = check_recipe_block(recipe.expensive) or modified
      end
      
      if modified then
        log("Smart Starter Pack: Multiplied landfill yield for recipe '" .. recipe.name .. "' by " .. multiplier)
      end
    end
  end
end

-- =====================================================
-- SPACE EXPLORATION + KRASTORIO 2: Wood Recipe Revert
-- SE heavily nerfs or alters the K2 greenhouse wood recipes.
-- This block forcefully restores them to the K2 defaults.
-- =====================================================
if mods["space-exploration"] and has_k2 and settings.startup["ssp-se-k2-revert-wood"].value then
  log("Smart Starter Pack: Reverting K2 greenhouse wood recipes to defaults.")
  
  -- 1. Standard Wood (200 water -> 40 wood over 60s)
  local wood_recipe = data.raw.recipe["wood"]
  if wood_recipe and wood_recipe.category == "kr-growing" then
    wood_recipe.energy_required = 60
    wood_recipe.ingredients = {
      { type = "fluid", name = "water", amount = 200 }
    }
    wood_recipe.results = {
      { type = "item", name = "wood", amount = 40 }
    }
    wood_recipe.result = nil
    wood_recipe.result_count = nil
  end

  -- 2. Wood with Fertilizer (200 water + 1 fertilizer -> 80 wood over 60s)
  local fert_recipe = data.raw.recipe["kr-wood-with-fertilizer"]
  if fert_recipe then
    fert_recipe.energy_required = 60
    fert_recipe.ingredients = {
      { type = "fluid", name = "water", amount = 200 },
      { type = "item", name = "kr-fertilizer", amount = 1 }
    }
    fert_recipe.results = {
      { type = "item", name = "wood", amount = 80 }
    }
    fert_recipe.result = nil
    fert_recipe.result_count = nil
  end
end

-- =====================================================
-- TRANSPORT DRONES (CONTINUED): Streamline Technologies
-- Moves depot unlocks into the core transport techs and 
-- hides the redundant intermediate technologies.
-- =====================================================
if mods["Transport_Drones_Continued"] and settings.startup["ssp-td-streamline-techs"].value then
  log("Smart Starter Pack: Streamlining Transport Drones tech tree.")

  local function move_unlock(recipe_name, from_tech_name, to_tech_name)
    local from_tech = data.raw.technology[from_tech_name]
    local to_tech = data.raw.technology[to_tech_name]

    if from_tech and to_tech and from_tech.effects and to_tech.effects then
      for i, effect in ipairs(from_tech.effects) do
        if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
          table.remove(from_tech.effects, i)
          table.insert(to_tech.effects, {type="unlock-recipe", recipe=recipe_name})
          log("Smart Starter Pack: Moved " .. recipe_name .. " from " .. from_tech_name .. " to " .. to_tech_name)
          break
        end
      end
    end
  end

  local function replace_prerequisite(old_req, new_req)
    for _, tech in pairs(data.raw.technology) do
      if tech.prerequisites then
        local has_new = false
        local old_idx = nil
        for i, req in ipairs(tech.prerequisites) do
          if req == new_req then has_new = true end
          if req == old_req then old_idx = i end
        end
        if old_idx then
          if has_new then
            table.remove(tech.prerequisites, old_idx)
          else
            tech.prerequisites[old_idx] = new_req
          end
        end
      end
    end
  end

  local function disable_tech(tech_name)
    local tech = data.raw.technology[tech_name]
    if tech then
      tech.hidden = true
      tech.enabled = false
      log("Smart Starter Pack: Disabled redundant technology " .. tech_name)
    end
  end

  -- Move recipes
  move_unlock("fluid-depot", "transport-fluids", "transport-system")
  move_unlock("buffer-depot", "transport-buffering", "transport-logistics")
  move_unlock("active-depot", "transport-active-supply", "transport-logistics")
  move_unlock("storage-depot", "transport-active-supply", "transport-logistics")

  -- Reroute prerequisites
  replace_prerequisite("transport-fluids", "transport-system")
  replace_prerequisite("transport-buffering", "transport-logistics")
  replace_prerequisite("transport-active-supply", "transport-logistics")

  -- Disable empty techs
  disable_tech("transport-fluids")
  disable_tech("transport-buffering")
  disable_tech("transport-active-supply")
end

-- =====================================================
-- SPACE EXPLORATION + KRASTORIO 2: Nerf Reverts
-- Reverts various nerfs applied to K2 by SE.
-- =====================================================
if mods["space-exploration"] and has_k2 then
  
  local all_effects = { "consumption", "speed", "productivity", "pollution", "quality" }
  
  -- 1. Electrolysis Plant Power
  if settings.startup["ssp-se-k2-revert-electrolysis-power"].value then
    local ep = data.raw["assembling-machine"]["kr-electrolysis-plant"]
    if ep then
      ep.energy_usage = "375kW"
      ep.allowed_effects = all_effects
    end
    local eps = data.raw["assembling-machine"]["kr-electrolysis-plant-spaced"]
    if eps then
      eps.energy_usage = "375kW"
      eps.allowed_effects = all_effects
    end
  end
  
  -- 2. Robot Stats
  if settings.startup["ssp-se-k2-revert-robot-stats"].value then
    local logi = data.raw["logistic-robot"]["logistic-robot"]
    if logi then
      logi.speed = 0.0694
      logi.max_energy = "3MJ"
      logi.max_payload_size = 7
    end
    local cons = data.raw["construction-robot"]["construction-robot"]
    if cons then
      cons.speed = 0.09257
      cons.max_energy = "3MJ"
      cons.max_payload_size = 2
    end
  end
  
  -- 3. Fuel Refinery
  if settings.startup["ssp-se-k2-revert-fuel-refinery"].value then
    local fr = data.raw["assembling-machine"]["kr-fuel-refinery"]
    if fr then
      fr.crafting_speed = 1
      fr.energy_usage = "250kW"
      fr.allowed_effects = all_effects
    end
    local frs = data.raw["assembling-machine"]["kr-fuel-refinery-spaced"]
    if frs then
      frs.crafting_speed = 1
      frs.energy_usage = "250kW"
      frs.allowed_effects = all_effects
    end
  end
  

  
  -- 5. Atmospheric Condenser
  if settings.startup["ssp-se-k2-revert-condenser"].value then
    local ac = data.raw["assembling-machine"]["kr-atmospheric-condenser"]
    if ac then
      ac.energy_usage = "250kW"
      ac.allowed_effects = all_effects
    end
  end
  
  -- 6. Water Recipes
  if settings.startup["ssp-se-k2-revert-water-recipes"].value then
    local we = data.raw.recipe["kr-water-electrolysis"]
    if we then
      we.energy_required = 3
      if we.results then
        for _, res in pairs(we.results) do
          if res.name == "kr-hydrogen" then res.amount = 30 end
        end
      end
    end
    local ws = data.raw.recipe["kr-water-separation"]
    if ws then
      ws.energy_required = 3
      if ws.ingredients then
        for _, ing in pairs(ws.ingredients) do
          if ing.name == "water" then ing.amount = 50 end
        end
      end
    end
  end
  
  -- 7. Advanced Buildings
  if settings.startup["ssp-se-k2-revert-advanced-buildings"].value then
    local af = data.raw["assembling-machine"]["kr-advanced-furnace"]
    if af then
      af.energy_usage = "2MW"
      af.crafting_speed = 12
    end
    local aam = data.raw["assembling-machine"]["kr-advanced-assembling-machine"]
    if aam then
      aam.energy_usage = "0.925MW"
      aam.crafting_speed = 5
    end
    local acp = data.raw["assembling-machine"]["kr-advanced-chemical-plant"]
    if acp then
      acp.energy_usage = "1.75MW"
      acp.crafting_speed = 8
    end
    local rs = data.raw["lab"]["kr-research-server"]
    if rs then
      rs.energy_usage = "250kW"
      rs.allowed_effects = all_effects
    end
    local qc = data.raw["lab"]["kr-quantum-computer"]
    if qc then
      qc.energy_usage = "1MW"
      qc.allowed_effects = all_effects
    end
  end
  
  -- 8. Void Crushing Recipes
  if settings.startup["ssp-se-k2-revert-void-crushing"].value then
    for name, recipe in pairs(data.raw.recipe) do
      if name:find("^kr%-crush%-") then
        recipe.energy_required = 1
      end
    end
  end
  
  -- 9. Stack Sizes
  if settings.startup["ssp-se-k2-revert-stack-sizes"].value then
    local kr_stack_size_value = 200
    
    local target_subgroups = {
      ["raw-resource"] = true,
      ["raw-material"] = true,
      ["intermediate-product"] = true,
      ["plates"] = true,
      ["science-pack"] = true,
      ["ammo"] = true,
      ["capsule"] = true,
      ["terrain"] = true,
    }
    
    for _, category in ipairs({"item", "ammo", "tool", "capsule"}) do
      if data.raw[category] then
        for name, item in pairs(data.raw[category]) do
          -- Exclude space exploration's critical fuels to prevent crashes
          if name ~= "rocket-fuel" and name ~= "nuclear-fuel" then
            -- If it's a known intermediate/resource subgroup, or if it was one of the explicitly hardcoded ones
            if (item.subgroup and target_subgroups[item.subgroup]) or string.match(name, "^kr%-") then
               -- We also boost all Krastorio 2 intermediate items that begin with kr- (excluding machines, belts, etc)
               -- Wait, K2 prefixes machines with kr- too. Let's strictly rely on subgroup.
               if item.subgroup and target_subgroups[item.subgroup] then
                 if not item.stack_size or item.stack_size < kr_stack_size_value then
                   item.stack_size = kr_stack_size_value
                 end
               end
            end
          end
        end
      end
    end
    
    -- And just manually cover a few specific stragglers that K2 explicitly touched (like plates, barrels, vanilla ores if subgroups changed)
    local function set_stack(cat, name, size)
      if data.raw[cat] and data.raw[cat][name] then
        if not data.raw[cat][name].stack_size or data.raw[cat][name].stack_size < size then
          data.raw[cat][name].stack_size = size
        end
      end
    end
    
    -- Vanilla
    set_stack("ammo", "artillery-shell", 25)
    set_stack("capsule", "cliff-explosives", kr_stack_size_value)
    set_stack("capsule", "raw-fish", 50)
    set_stack("item", "barrel", 10)
    set_stack("item", "battery", kr_stack_size_value)
    set_stack("item", "coal", kr_stack_size_value)
    set_stack("item", "coke", kr_stack_size_value)
    set_stack("item", "concrete", kr_stack_size_value)
    set_stack("item", "copper-ore", kr_stack_size_value)
    set_stack("item", "copper-plate", kr_stack_size_value)
    set_stack("item", "depleted-uranium-fuel-cell", 10)
    set_stack("item", "hazard-concrete", kr_stack_size_value)
    set_stack("item", "iron-gear-wheel", kr_stack_size_value)
    set_stack("item", "iron-ore", kr_stack_size_value)
    set_stack("item", "iron-plate", kr_stack_size_value)
    set_stack("item", "iron-stick", kr_stack_size_value)
    set_stack("item", "landfill", kr_stack_size_value)
    set_stack("item", "low-density-structure", kr_stack_size_value * 0.5)
    set_stack("item", "nuclear-fuel", 10)
    set_stack("item", "plastic-bar", kr_stack_size_value)
    set_stack("item", "processing-unit", kr_stack_size_value)
    set_stack("item", "refined-concrete", kr_stack_size_value)
    set_stack("item", "refined-hazard-concrete", kr_stack_size_value)
    set_stack("item", "steel-plate", kr_stack_size_value)
    set_stack("item", "stone-brick", kr_stack_size_value)
    set_stack("item", "stone", kr_stack_size_value)
    set_stack("item", "stone-wall", kr_stack_size_value)
    set_stack("item", "sulfur", kr_stack_size_value)
    set_stack("item", "uranium-235", kr_stack_size_value)
    set_stack("item", "uranium-238", kr_stack_size_value)
    set_stack("item", "uranium-fuel-cell", 10)
    set_stack("item", "uranium-ore", kr_stack_size_value)
    set_stack("item", "wood", kr_stack_size_value)

    -- K2 explicit overrides just in case subgroup failed
    set_stack("item", "kr-silicon", kr_stack_size_value)
    set_stack("item", "kr-quartz", kr_stack_size_value)
    set_stack("item", "kr-glass", kr_stack_size_value)
    set_stack("item", "kr-sand", kr_stack_size_value)
    set_stack("item", "kr-imersite", kr_stack_size_value)
    set_stack("item", "kr-raw-imersite", kr_stack_size_value)
    set_stack("item", "kr-enriched-iron", kr_stack_size_value)
    set_stack("item", "kr-enriched-copper", kr_stack_size_value)
    set_stack("item", "kr-rare-metals", kr_stack_size_value)
    set_stack("item", "kr-enriched-rare-metals", kr_stack_size_value)
    set_stack("item", "kr-lithium-chloride", kr_stack_size_value)
    set_stack("item", "kr-lithium", kr_stack_size_value)
    set_stack("item", "kr-lithium-sulfur-battery", kr_stack_size_value)
    set_stack("item", "kr-tritium", kr_stack_size_value)
    set_stack("item", "kr-fuel", kr_stack_size_value)
    set_stack("item", "kr-biofuel", kr_stack_size_value)
    set_stack("item", "kr-advanced-fuel", kr_stack_size_value)
    set_stack("item", "kr-coke", kr_stack_size_value)
    set_stack("item", "kr-biomass", kr_stack_size_value)
    set_stack("item", "kr-fertilizer", kr_stack_size_value)
    set_stack("item", "kr-space-research-data", 1000)
    set_stack("item", "kr-matter-research-data", 200)
    set_stack("item", "kr-biter-research-data", 200)

    set_stack("item", "kr-advanced-fuel", kr_stack_size_value)
    set_stack("item", "kr-ai-core", kr_stack_size_value)
    set_stack("item", "kr-automation-core", kr_stack_size_value)
    set_stack("item", "kr-blank-tech-card", 200)
    set_stack("item", "kr-charged-matter-stabilizer", kr_stack_size_value * 0.5)
    set_stack("item", "kr-electronic-components", kr_stack_size_value)
    set_stack("item", "kr-energy-control-unit", kr_stack_size_value * 0.5)
    set_stack("item", "kr-imersite-crystal", kr_stack_size_value * 0.5)
    set_stack("item", "kr-imersite-powder", kr_stack_size_value)
    set_stack("item", "kr-imersium-beam", kr_stack_size_value)
    set_stack("item", "kr-imersium-gear-wheel", kr_stack_size_value)
    set_stack("item", "kr-imersium-plate", kr_stack_size_value)
    set_stack("item", "kr-inserter-parts", kr_stack_size_value)
    set_stack("item", "kr-iron-beam", kr_stack_size_value)
    set_stack("item", "kr-black-reinforced-plate", kr_stack_size_value)
    set_stack("item", "kr-white-reinforced-plate", kr_stack_size_value)
    set_stack("item", "kr-matter-cube", kr_stack_size_value)
    set_stack("item", "kr-matter-stabilizer", kr_stack_size_value * 0.5)
    set_stack("item", "kr-pollution-filter", kr_stack_size_value * 0.5)
    set_stack("item", "kr-steel-beam", kr_stack_size_value)
    set_stack("item", "kr-steel-gear-wheel", kr_stack_size_value)
    set_stack("item", "kr-used-pollution-filter", kr_stack_size_value * 0.5)
    set_stack("tool", "kr-optimization-tech-card", 200)
    set_stack("tool", "kr-advanced-tech-card", 200)
    set_stack("tool", "kr-basic-tech-card", 200)
    set_stack("tool", "kr-matter-tech-card", 200)
    set_stack("tool", "kr-singularity-tech-card", 200)
    
  end
end

if has_k2 then
  if settings.startup["ssp-combine-logistic-containers"].value then
    local tech1 = data.raw.technology["kr-logistic-containers-1"]
    local tech2 = data.raw.technology["kr-logistic-containers-2"]
    if tech1 and tech2 then
      -- Move effects from tech2 to tech1
      if tech2.effects then
        tech1.effects = tech1.effects or {}
        for _, effect in pairs(tech2.effects) do
          table.insert(tech1.effects, effect)
        end
        tech2.effects = {}
      end
      
      -- Disable and hide tech2
      tech2.enabled = false
      tech2.hidden = true
      
      -- Update prerequisites globally
      for _, tech in pairs(data.raw.technology) do
        if tech.prerequisites then
          local has_tech1 = false
          local has_tech2 = false
          local tech2_index = nil
          
          for i, prereq in ipairs(tech.prerequisites) do
            if prereq == "kr-logistic-containers-1" then
              has_tech1 = true
            elseif prereq == "kr-logistic-containers-2" then
              has_tech2 = true
              tech2_index = i
            end
          end
          
          if has_tech2 then
            if has_tech1 then
              table.remove(tech.prerequisites, tech2_index)
            else
              tech.prerequisites[tech2_index] = "kr-logistic-containers-1"
            end
          end
        end
      end
    end
  end
end

if mods["space-exploration"] and mods["aai-loaders"] then
  if settings.startup["ssp-se-space-loader-with-space-belt"].value then
    local tech1 = data.raw.technology["se-space-belt"]
    local tech2 = data.raw.technology["aai-se-space-loader"]
    if tech1 and tech2 then
      -- Move effects from tech2 to tech1
      if tech2.effects then
        tech1.effects = tech1.effects or {}
        for _, effect in pairs(tech2.effects) do
          table.insert(tech1.effects, effect)
        end
        tech2.effects = {}
      end
      
      -- Disable and hide tech2
      tech2.enabled = false
      tech2.hidden = true
      
      -- Update prerequisites globally
      for _, tech in pairs(data.raw.technology) do
        if tech.prerequisites then
          local has_tech1 = false
          local has_tech2 = false
          local tech2_index = nil
          
          for i, prereq in ipairs(tech.prerequisites) do
            if prereq == "se-space-belt" then
              has_tech1 = true
            elseif prereq == "aai-se-space-loader" then
              has_tech2 = true
              tech2_index = i
            end
          end
          
          if has_tech2 then
            if has_tech1 then
              table.remove(tech.prerequisites, tech2_index)
            else
              tech.prerequisites[tech2_index] = "se-space-belt"
            end
          end
        end
      end
    end
  end

  if settings.startup["ssp-se-cheaper-space-loader"].value then
    local function sanitize_ingredients(ingredients)
      if not ingredients then return end
      local new_ingredients = {}
      for _, ing in pairs(ingredients) do
        local name = ing.name or ing[1]
        local type = ing.type or "item"
        if name ~= "lubricant" then
          if ing.name then
            table.insert(new_ingredients, {type = type, name = name, amount = 1})
          else
            table.insert(new_ingredients, {name, 1})
          end
        end
      end
      return new_ingredients
    end

    for _, recipe_name in ipairs({"aai-se-space-loader", "aai-se-space-loader-unlubricated"}) do
      local recipe = data.raw.recipe[recipe_name]
      if recipe then
        if recipe.ingredients then
          recipe.ingredients = sanitize_ingredients(recipe.ingredients)
        end
        if recipe.normal then
          if recipe.normal.ingredients then
            recipe.normal.ingredients = sanitize_ingredients(recipe.normal.ingredients)
          end
        end
        if recipe.expensive then
          if recipe.expensive.ingredients then
            recipe.expensive.ingredients = sanitize_ingredients(recipe.expensive.ingredients)
          end
        end
      end
    end
  end
end
