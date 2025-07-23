require "rails/generators"
require "rails/generators/migration"
require "active_support/inflector"

module ConfigurableSettings
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      # This __dir__ is .../install
      source_root File.expand_path("templates", __dir__)
      argument :model_name, type: :string, banner: "ModelName"

      # Ensure unique timestamps for migrations
      def self.next_migration_number(dirname)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end

      # Prepare instance vars
      def init_names
        @base          = model_name.underscore
        @defs_table    = "#{@base}_setting_definitions"
        @settings_table = "#{@base}_settings"
      end

      # 1) Abort if host model missing
      def validate_model_exists
        unless File.exist?(File.join(destination_root, "app/models", "#{@base}.rb"))
          say_status :error, "Model #{model_name} not found", :red
          exit(1)
        end
      end

      # 2) Migrations
      def create_migrations
        migration_template "db/migrate/create_model_setting_definitions.rb.tt",
                           "db/migrate/create_#{@defs_table}.rb"
        migration_template "db/migrate/create_model_settings.rb.tt",
                           "db/migrate/create_#{@settings_table}.rb"
      end

      # 3) Models
      def create_models
        template "models/model_setting_definition.rb.tt",
                 "app/models/#{@base}_setting_definition.rb"
        template "models/model_setting.rb.tt",
                 "app/models/#{@base}_setting.rb"
      end

      # 4) Controllers
      def create_definition_controller
        template "controllers/model_setting_definitions_controller.rb.tt",
                 "app/controllers/#{@base}_setting_definitions_controller.rb"
      end

      def create_setting_controller
        template "controllers/model_settings_controller.rb.tt",
                 "app/controllers/#{@base}_settings_controller.rb"
      end

      # 5) Views
      def create_definition_views
        directory "views/model_setting_definitions",
                  "app/views/#{@base}_setting_definitions"
      end

      def create_setting_views
        directory "views/model_settings",
                  "app/views/#{@base}_settings"
      end

      # 6) Routes
      def add_routes
        route <<~RUBY
          resources :#{@defs_table}
          resources :#{@settings_table}
        RUBY
      end
    end
  end
end
