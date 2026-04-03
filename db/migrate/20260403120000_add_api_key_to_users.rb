class AddApiKeyToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :api_key, :string

    say_with_time "Backfilling api keys for existing users" do
      User.reset_column_information

      User.find_each do |user|
        next if user.api_key.present?

        user.update_columns(api_key: generate_unique_api_key)
      end
    end

    change_column_null :users, :api_key, false
    add_index :users, :api_key, unique: true
  end

  def down
    remove_index :users, :api_key
    remove_column :users, :api_key
  end

  private
    def generate_unique_api_key
      loop do
        token = SecureRandom.base58(24)
        break token unless User.exists?(api_key: token)
      end
    end
end
