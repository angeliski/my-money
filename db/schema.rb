# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_10_19_010711) do
  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "account_type", default: 0, null: false
    t.integer "initial_balance_cents", default: 0, null: false
    t.string "icon", null: false
    t.string "color", null: false
    t.datetime "archived_at"
    t.integer "family_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "balance_cents", default: 0, null: false
    t.index ["archived_at"], name: "index_accounts_on_archived_at"
    t.index ["created_at"], name: "index_accounts_on_created_at"
    t.index ["family_id", "archived_at"], name: "index_accounts_on_family_id_and_archived_at"
    t.index ["family_id"], name: "index_accounts_on_family_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "families", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_families_on_created_at"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", limit: 1024, null: false
    t.binary "payload", limit: 536870912, null: false
    t.datetime "created_at", null: false
    t.integer "channel_hash", limit: 8, null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "transaction_type", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "BRL", null: false
    t.date "transaction_date", null: false
    t.text "description", null: false
    t.integer "account_id", null: false
    t.integer "category_id", null: false
    t.integer "user_id", null: false
    t.boolean "is_template", default: false, null: false
    t.string "frequency"
    t.date "start_date"
    t.date "end_date"
    t.integer "parent_transaction_id"
    t.datetime "effectuated_at"
    t.integer "linked_transaction_id"
    t.integer "editor_id"
    t.datetime "edited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["editor_id"], name: "index_transactions_on_editor_id"
    t.index ["is_template", "parent_transaction_id"], name: "index_transactions_on_is_template_and_parent_transaction_id"
    t.index ["linked_transaction_id"], name: "index_transactions_on_linked_transaction_id"
    t.index ["parent_transaction_id"], name: "index_transactions_on_parent_transaction_id"
    t.index ["transaction_date"], name: "index_transactions_on_transaction_date"
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "member", null: false
    t.string "name"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.integer "invited_by_id"
    t.integer "invitations_count", default: 0
    t.string "status"
    t.integer "family_id", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["family_id"], name: "index_users_on_family_id"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "families"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "transactions", column: "linked_transaction_id"
  add_foreign_key "transactions", "transactions", column: "parent_transaction_id"
  add_foreign_key "transactions", "users"
  add_foreign_key "transactions", "users", column: "editor_id"
  add_foreign_key "users", "families"
end
