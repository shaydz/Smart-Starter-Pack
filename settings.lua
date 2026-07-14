data:extend({
  -- Startup settings (require game restart)
  {
    type = "bool-setting",
    name = "ssp-k2-remove-fuel-requirement",
    setting_type = "startup",
    default_value = true
  },
  -- Runtime-global settings
  {
    type = "bool-setting",
    name = "ssp-enable-universal",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "int-setting",
    name = "ssp-repair-pack-count",
    setting_type = "runtime-global",
    default_value = 200,
    minimum_value = 0,
    maximum_value = 1000
  },
  {
    type = "bool-setting",
    name = "ssp-enable-mining-drones",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "int-setting",
    name = "ssp-mining-drone-count",
    setting_type = "runtime-global",
    default_value = 200,
    minimum_value = 0,
    maximum_value = 1000
  },
  {
    type = "int-setting",
    name = "ssp-mining-depot-count",
    setting_type = "runtime-global",
    default_value = 4,
    minimum_value = 0,
    maximum_value = 50
  },
  {
    type = "bool-setting",
    name = "ssp-enable-aai-loaders",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "int-setting",
    name = "ssp-aai-loader-count",
    setting_type = "runtime-global",
    default_value = 200,
    minimum_value = 0,
    maximum_value = 1000
  },
  {
    type = "bool-setting",
    name = "ssp-give-armor",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-enable-k2",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "int-setting",
    name = "ssp-k2-robot-count",
    setting_type = "runtime-global",
    default_value = 50,
    minimum_value = 0,
    maximum_value = 500
  },
  {
    type = "bool-setting",
    name = "ssp-enable-vanilla-armor",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "int-setting",
    name = "ssp-vanilla-robot-count",
    setting_type = "runtime-global",
    default_value = 20,
    minimum_value = 0,
    maximum_value = 500
  },
  {
    type = "bool-setting",
    name = "ssp-td-default-full-stack",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-se-multiply-landfill",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "int-setting",
    name = "ssp-se-landfill-multiplier",
    setting_type = "startup",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 100
  },
  {
    type = "bool-setting",
    name = "ssp-se-k2-revert-wood",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-td-streamline-techs",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-se-k2-revert-electrolysis-power",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-se-k2-revert-robot-stats",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-se-k2-revert-fuel-refinery",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-se-k2-revert-condenser",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-se-k2-revert-water-recipes",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-se-k2-revert-advanced-buildings",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-se-k2-revert-void-crushing",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-se-k2-revert-stack-sizes",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-combine-logistic-containers",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-se-space-loader-with-space-belt",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ssp-se-cheaper-space-loader",
    setting_type = "startup",
    default_value = true
  }
})
