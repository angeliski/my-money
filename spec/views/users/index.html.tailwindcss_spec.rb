require 'rails_helper'

RSpec.describe "users/index", type: :view do
  before(:each) do
    users = [
      User.create!(
        name: "Name",
        email: "test1@example.com",
        role: :admin,
        password: "password123"
      ),
      User.create!(
        name: "Name",
        email: "test2@example.com",
        role: :member,
        password: "password123"
      )
    ]
    assign(:users, users)
    # Mock @pagy object for pagination
    pagy_double = double("Pagy", count: 2, from: 1, to: 2, page: 1, prev: nil, next: nil)
    assign(:pagy, pagy_double)
  end

  it "renders a list of users" do
    render
    assert_select "td", text: Regexp.new("Name".to_s), count: 2
    assert_select "td", text: Regexp.new("test1@example.com".to_s), count: 2
    assert_select "td", text: Regexp.new("test2@example.com".to_s), count: 2
  end
end
