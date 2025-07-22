module ConfigurableSettings
  class Manager
    def initialize(owner)
      @owner = owner
    end

    def get(key)
      setting = find_setting(key)
      setting&.casted_value || setting&.definition&.default_value
    end

    def set(key, value)
      definition = SettingDefinition.find_by!(key: key)
      setting = Setting.find_or_initialize_by(owner: @owner, definition: definition)
      setting.value = value
      setting.save!
    end

    private

    def find_setting(key)
      Setting.joins(:definition).find_by(
        owner: @owner,
        configurable_settings_setting_definitions: { key: key }
      )
    end
  end
end
