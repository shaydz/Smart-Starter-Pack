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
