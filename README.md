# ConfigurableSettings

A Rails engine gem to easily add customizable settings for your models such as `Firm`, `User`, `Clinic`, etc.  
It generates setting definitions and per-record settings tables scoped by a user-defined base model.

---

## Features

- Define available setting keys and types (`key`, `data_type`, `default_value`)
- Store actual setting values for each model instance (e.g., per `Firm`, `User`)
- Models are namespaced under `ConfigurableSettings::` for clean reusability
- Fully dynamic: supports any model name (`firm`, `user`, `clinic`, etc.)

---

## Installation

1. Add the gem to your app's `Gemfile`:

```ruby
gem "configurable_settings", git: "https://github.com/Hayk01/configurable_settings_gem.git"
````

> Replace with your actual GitHub repo URL if needed.

2. Install dependencies:

```bash
bundle install
```

---

## Setup

Run the install generator:

```bash
rails generate configurable_settings:install
```

You will be prompted to enter your base model name (e.g., `firm`, `user`, `clinic`):

```
Enter base name (e.g., firm, user, clinic):
> firm
```

This generates:

* A migration file to create the `firm_setting_definitions` and `firm_settings` tables
* Model files:

  * `app/models/configurable_settings/firm_setting.rb`
  * `app/models/configurable_settings/firm_setting_definition.rb`

> ✅ Your base model (`Firm`, `User`, etc.) must already exist. The gem does **not** create or modify it.

---

## Run Migrations

After generation, apply the migrations:

```bash
rails db:migrate
```

---

## Usage

### Define Setting Keys

Use Rails Admin, ActiveAdmin, or create them programmatically:

```ruby
ConfigurableSettings::FirmSettingDefinition.create!(
  key: "enable_auto_email",
  data_type: "boolean",
  default_value: "true"
)
```

---

### Access and Set Values per Model Instance

In your base model (e.g., `Firm`):

```ruby
class Firm < ApplicationRecord
  has_many :firm_settings,
           class_name: "ConfigurableSettings::FirmSetting",
           dependent: :destroy

  def get_setting(key)
    setting = firm_settings.find_by(key: key)
    setting&.value || ConfigurableSettings::FirmSettingDefinition.find_by(key: key)&.default_value
  end

  def set_setting(key, value)
    definition = ConfigurableSettings::FirmSettingDefinition.find_by!(key: key)
    setting = firm_settings.find_or_initialize_by(setting_definition: definition, key: key)
    setting.value = value
    setting.save!
  end
end
```

---

## Optional: Mount the Engine (for future UI)

If you build shared UI components inside the engine, you can mount its routes:

```ruby
# config/routes.rb
mount ConfigurableSettings::Engine => "/configurable_settings"
```

---

## Customization

* Re-run the generator for another model (`user`, `clinic`, etc.)
* Extend or override the generated models to:

  * Add validations
  * Support enums
  * Add casting logic for `data_type`
