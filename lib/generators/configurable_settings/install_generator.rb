require "rails/generators"
require "rails/generators/migration"

module ConfigurableSettings
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def ask_for_base_name
        @base_name = ask("Enter base name (e.g., firm, user, clinic):").strip.downcase
        @migration_file = "create_#{@base_name}_settings_tables"
        @migration_class = @migration_file.camelize
        @definitions_table = "#{@base_name}_setting_definitions"
        @settings_table = "#{@base_name}_settings"
        @model_namespace = @base_name.camelize
      end

      def generate_scaffolds
        generate "scaffold", "#{@model_namespace}::SettingDefinition key:string data_type:string default_value:text"
        generate "scaffold", "#{@model_namespace}::Setting #{@base_name}:references key:string value:text"
      end

      def self.next_migration_number(dirname)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end
