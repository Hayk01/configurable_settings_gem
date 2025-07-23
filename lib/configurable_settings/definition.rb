# frozen_string_literal: true

module ConfigurableSettings
  module Definition
    extend ActiveSupport::Concern

    included do
      has_many :settings,
               class_name: "#{name.sub(/SettingDefinition$/, '')}Setting",
               foreign_key: "#{base_model_name}_setting_definition_id",
               dependent: :destroy

      validates :key, :name, presence: true
      validates :key, uniqueness: true
    end

    class_methods do
      def create_default_settings
        unless const_defined?(:DEFAULT_SETTINGS)
          warn '[ConfigurableSettings] WARNING: DEFAULT_SETTINGS constant is not defined.'
          return
        end

        self::DEFAULT_SETTINGS.each do |key, attrs|
          next if exists?(key: key.to_s)

          begin
            create!(
              key: key.to_s,
              name: attrs[:name] || key.to_s.humanize,
              default_value: attrs[:default_value],
              options: attrs[:options],
              description: attrs[:description],
              value_type: attrs[:value_type] || infer_value_type(attrs[:default_value])
            )
          rescue StandardError => e
            warn "[ConfigurableSettings] ERROR creating setting definition for key '\#{key}': \#{e.message}"
          end
        end

        backfill_missing_settings
      end

      def backfill_missing_settings
        base = base_model_name
        model_class = base.classify.constantize
        setting_class = "#{base.classify}Setting".constantize
        definition_association = "#{base}_setting_definition".to_sym

        all.find_each do |definition|
          defined_ids = setting_class
                        .where("#{base}_setting_definition_id": definition.id)
                        .pluck("#{base}_id")

          missing_records = model_class.where.not(id: defined_ids)

          missing_records.find_each do |record|
            setting_class.create!(
              base.to_sym => record,
              definition_association => definition,
              value: definition.default_value
            )
          end

          Rails.logger.info "[ConfigurableSettings] Backfilled \#{missing_records.count} settings for \#{definition.name}."
        rescue StandardError => e
          warn "[ConfigurableSettings] ERROR backfilling settings for '\#{definition.key}': \#{e.message}"
        end
      end

      def value_for_parent(parent_record, setting_key)
        base = base_model_name
        setting_class = "#{base.classify}Setting".constantize
        association_name = "#{base}_setting_definition".to_sym
        definition_table = "#{base}_setting_definitions"

        setting = setting_class
                  .where("#{base}_id": parent_record.id)
                  .joins(association_name)
                  .find_by("#{definition_table}.key": setting_key)

        return setting&.typed_value if setting

        definition = find_by(key: setting_key)
        definition&.typed_default_value
      end

      def find_by_parent_and_key(parent_record, setting_key)
        base = base_model_name
        setting_class = "#{base.classify}Setting".constantize
        association_name = "#{base}_setting_definition".to_sym
        definition_table = "#{base}_setting_definitions"

        setting_class
          .where("#{base}_id": parent_record.id)
          .joins(association_name)
          .find_by("#{definition_table}.key": setting_key)
      end

      def set_for_parent(parent_record, setting_key, value)
        base = base_model_name
        setting_class = "#{base.classify}Setting".constantize

        definition = find_by!(key: setting_key)
        setting = setting_class.find_or_initialize_by(
          "#{base}_id": parent_record.id,
          "#{base}_setting_definition": definition
        )
        setting.update!(value: value)
      end

      private

      def base_model_name
        name.sub(/SettingDefinition$/, '').underscore
      end

      def infer_value_type(value)
        case value
        when TrueClass, FalseClass then 'boolean'
        when Integer then 'integer'
        when Hash, Array then 'json'
        else 'string'
        end
      end
    end

    # Instance methods
    def create_parent_settings
      base = self.class.send(:base_model_name)
      parent_class = base.classify.constantize
      setting_class = "#{base.classify}Setting".constantize

      existing_ids = setting_class.where("#{base}_setting_definition_id": id).pluck("#{base}_id")
      missing_records = parent_class.where.not(id: existing_ids)

      missing_records.find_each do |record|
        setting_class.create!(
          base.to_sym => record,
          "#{base}_setting_definition": self,
          value: default_value
        )
      end

      Rails.logger.info "[ConfigurableSettings] Created \#{missing_records.count} missing settings for '#{name}'"
    end

    def cast_value(raw_value)
      case value_type
      when 'boolean' then raw_value.to_s == 'true'
      when 'integer' then raw_value.to_i
      when 'json'
        begin
          JSON.parse(raw_value)
        rescue JSON::ParserError => e
          Rails.logger.error "[ConfigurableSettings] Failed to parse JSON for setting \#{name}: \#{e.message}"
          raw_value
        end
      else
        raw_value
      end
    end

    def typed_default_value
      cast_value(default_value)
    end
  end
end
