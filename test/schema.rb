ActiveRecord::Schema.define(:version => 1) do
  create_table :accounts, :force => true do |t|
    t.column :primary_account_holder_id, :string
    t.column :secondary_account_holder_id, :string
    t.column :email_address, :string
    t.column :login_name, :string
    t.column :full_name, :string
  end
end