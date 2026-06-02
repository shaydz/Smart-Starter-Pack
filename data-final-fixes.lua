-- data-final-fixes.lua
-- Runs after all other mods (including Krastorio 2) have finished their data stage.
-- Removes Krastorio 2's fuel requirements from personal equipment generators
-- and spidertron power sources, reverting them to vanilla-style free power.

if mods["Krastorio2"] and settings.startup["ssp-k2-remove-fuel-requirement"].value then

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
