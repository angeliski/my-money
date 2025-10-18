require 'rails_helper'

RSpec.describe "categories/index", type: :view do
  before(:each) do
    assign(:categories, [
      Category.create!(name: "Name 1"),
      Category.create!(name: "Name 2")
    ])
  end

  it "renders a list of categories" do
    render
    expect(rendered).to match(/Name 1/)
    expect(rendered).to match(/Name 2/)
  end
end
