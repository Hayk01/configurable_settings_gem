# lib/configurable_settings/engine.rb
module ConfigurableSettings
  class Engine < ::Rails::Engine
    isolate_namespace ConfigurableSettings
  end
end
