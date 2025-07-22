module ConfigurableSettings
  class Setting < ApplicationRecord
    self.table_name = ENV.fetch("CONFIGURABLE_SETTINGS_TABLE", "configurable_settings_settings")

    belongs_to :definition, class_name: "ConfigurableSettings::SettingDefinition"
    belongs_to :owner, polymorphic: true

    validates :value, presence: true

    def casted_value
      case definition.data_type
      when "integer" then value.to_i
      when "boolean" then ActiveModel::Type::Boolean.new.cast(value)
      when "json" then value.is_a?(String) ? JSON.parse(value) : value
      else value.to_s
      end
    end

    def value=(val)
      super(cast_to_type(val))
    end

    private

    def cast_to_type(val)
      case definition.data_type
      when "integer" then val.to_i
      when "boolean" then ActiveModel::Type::Boolean.new.cast(val)
      when "json" then val.is_a?(String) ? JSON.parse(val) : val
      else val.to_s
      end
    end
  end
end
