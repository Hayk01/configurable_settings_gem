module ConfigurableSettings
  class SettingDefinition < ApplicationRecord
    self.table_name = ENV.fetch("CONFIGURABLE_SETTINGS_DEFINITIONS_TABLE", "configurable_settings_setting_definitions")

    has_many :settings, class_name: "ConfigurableSettings::Setting", foreign_key: :definition_id, dependent: :destroy

    validates :key, presence: true, uniqueness: true
    validates :data_type, inclusion: { in: %w[string integer boolean json] }
  end
end
