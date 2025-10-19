require 'rails_helper'

RSpec.describe Family, type: :model do
  describe 'associations' do
    it { should have_many(:users).dependent(:restrict_with_error) }
    it { should have_many(:accounts).dependent(:restrict_with_error) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      family = build(:family)
      expect(family).to be_valid
    end
  end
end
