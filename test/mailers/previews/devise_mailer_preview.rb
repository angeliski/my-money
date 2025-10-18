# Preview all emails at http://localhost:3000/rails/mailers/devise_mailer
class DeviseMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/devise_mailer/invitation_instructions
  def invitation_instructions
    user = User.new(
      email: "exemplo@MyMoney.com",
      name: "Novo Operador",
      role: :sales_operator
    )
    user.invitation_token = "fake_token_123"

    Devise::Mailer.invitation_instructions(user, "fake_token_123")
  end
end
