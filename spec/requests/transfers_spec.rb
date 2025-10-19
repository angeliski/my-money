require 'rails_helper'

RSpec.describe "Transfers", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/transfers/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/transfers/create"
      expect(response).to have_http_status(:success)
    end
  end

end
