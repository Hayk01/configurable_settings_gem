require "rails/generators"
require "rails/generators/migration"

module ConfigurableSettings
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def ask_for_base_name
        @base_name           = ask("Enter base name:").strip.downcase
        @base_class_name     = @base_name.camelize
        @setting_class       = "#{@base_class_name}Setting"
        @definition_class    = "#{@base_class_name}SettingDefinition"
        @migration_class     = "Create#{@setting_class.pluralize}Tables"
        @migration_file      = "create_#{@base_name}_settings_tables"
        @definitions_table   = "#{@base_name}_setting_definitions"
        @settings_table      = "#{@base_name}_settings"
      end

      def check_base_model_exists
        model_path = File.join("app", "models", "#{@base_name}.rb")
        unless File.exist?(model_path)
          say_status :error, "Base model '#{@base_class_name}' not found at #{model_path}. Please create it first.", :red
          exit 1
        end
      end

      def generate_models
        generate "scaffold", "configurable_settings/#{@definition_class} key:string data_type:string default_value:text"
        generate "scaffold", "configurable_settings/#{@setting_class} #{@base_name}:references #{@definition_class}:references key:string value:text"
      end

      def self.next_migration_number(dirname)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end
