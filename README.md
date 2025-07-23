# ConfigurableSettings

`ConfigurableSettings` is a flexible Rails engine for managing per-record configurable settings. It generates setting definitions, setting models, migrations, controllers, and views — all scoped to the model you specify (`User`, `Firm`, `Company`, etc.).

---

## ✨ Features

- Define **setting definitions** for any model.
- Store **per-record settings** with typed defaults and options.
- Auto-generate models, migrations, controllers, and views.
- Supports **default values**, **value types**, and **option validation**.
- Supports **backfilling** missing settings across existing records.
- Dynamic access helpers: fetch, set, and validate settings in code.
- Works with **any model**: `User`, `Firm`, `Company`, etc.

---

## 💾 Installation

Add the gem to your `Gemfile`:

```ruby
gem 'configurable_settings', path: 'path/to/configurable_settings' # or use git:
gem 'configurable_settings', git: 'https://github.com/Hayk01/configurable_settings.git'
```

Install it:

```bash
bundle install
```

---

## ⚙️ Setup

Generate settings for a model (example with `User`):

```bash
rails generate configurable_settings:install User
```

This will:

- Check that the `User` model exists.
- Create migrations:

  - `create_user_setting_definitions`
  - `create_user_settings`

- Generate models:

  - `UserSettingDefinition`
  - `UserSetting`

- Create controllers & views.
- Add routes to `config/routes.rb`.

Run the migrations:

```bash
rails db:migrate
```

---

## 🚀 Usage

### 1. Define Default Settings

In your `UserSettingDefinition` model:

```ruby
# app/models/user_setting_definition.rb

class UserSettingDefinition < ApplicationRecord
  include ConfigurableSettings::Definition

  DEFAULT_SETTINGS = {
    timezone: {
      name: "Timezone",
      default_value: "UTC",
      options: ["UTC", "EST", "PST"],
      description: "User timezone",
      value_type: "string"
    },
    notifications: {
      name: "Notifications",
      default_value: true,
      options: [true, false],
      description: "Enable or disable notifications",
      value_type: "boolean"
    }
  }
end
```

### 2. Create and Backfill

Run once to initialize all default settings and backfill users missing any:

```ruby
UserSettingDefinition.create_default_settings
```

This will:

- Create any `DEFAULT_SETTINGS` that are missing
- Backfill all users with those settings using the default value

---

## Access Settings Programmatically

### Get a setting for a user

```ruby
UserSettingDefinition.value_for_parent(user, "timezone")
# => "UTC"
```

### Set a setting for a user

```ruby
UserSettingDefinition.set_for_parent(user, "timezone", "PST")
```

### Get full setting record

```ruby
UserSettingDefinition.find_by_parent_and_key(user, "timezone")
# => <UserSetting id:..., value: "UTC", ...>
```

### Get typed value

```ruby
setting = UserSettingDefinition.find_by_parent_and_key(user, "notifications")
setting.typed_value # => true
```

---

## Validation

- Ensures required `value` presence.
- Ensures value is one of the allowed `options`.
- `value_type` casting is supported:

  - `"boolean"` → `true`/`false`
  - `"integer"` → `123`
  - `"json"` → `{}`, `[]`
  - `"string"` → `"text"`

---

## Customization

- Generated controllers and views can be modified like any Rails app.
- Migrations and models can be extended with your business logic.
- Supports any model (`Firm`, `Client`, `Tenant`, etc.) via generator.

---
