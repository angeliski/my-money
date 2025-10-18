class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :validatable
  after_invitation_accepted :updated_status_after_accept_invitation

  # usando essas roles fixas por hora
  enum :role, {
    admin: "Administrador",
    member: "Membro"
  }, suffix: true, default: :member

  enum :status, {
    active: "Ativo",
    disabled: "Desativado",
    blocked: "Bloqueado",
    invited: "Convidado"
  }, suffix: true, default: :invited

  def updated_status_after_accept_invitation
    self.status = :active
    save!
  end
end
