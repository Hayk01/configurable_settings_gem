module ConfigurableSettings
  module Setting
    extend ActiveSupport::Concern

    included do
      belongs_to base_association_name
      belongs_to setting_definition_association_name,
                 class_name: "#{base_model_class}SettingDefinition"

      validates :value, presence: true
      validate :value_in_allowed_options

      validates "#{base_model_name}_id", uniqueness: {
        scope: "#{base_model_name}_setting_definition_id",
        message: 'already has this setting defined'
      }

      delegate :name, :value_type, :cast_value, to: setting_definition_association_name

      def typed_value
        cast_value(value)
      end
    end

    class_methods do
      def value_for(owner, setting_key)
        joins(setting_definition_association_name)
          .where(base_association_name => owner)
          .find_by("#{definition_table}.key = ?", setting_key)&.value
      end

      def base_model_name
        @base_model_name ||= name.sub(/Setting$/, '').underscore
      end

      def base_model_class
        @base_model_class ||= base_model_name.classify
      end

      def base_association_name
        base_model_name.to_sym
      end

      def setting_definition_association_name
        "#{base_model_name}_setting_definition".to_sym
      end

      def definition_table
        "#{base_model_name}_setting_definitions"
      end
    end

    private

    def value_in_allowed_options
      return if value.blank?

      definition = send(self.class.setting_definition_association_name)
      return if definition.options.blank? || definition.options.include?(value)

      errors.add(:value, "must be one of: #{definition.options.join(', ')}")
    end
  end
end
