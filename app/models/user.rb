class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :validatable
  after_invitation_accepted :updated_status_after_accept_invitation

  # Associations
  belongs_to :family
  has_many :accounts, through: :family

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

  # Callbacks
  before_validation :create_family_if_needed, on: :create

  def updated_status_after_accept_invitation
    self.status = :active
    save!
  end

  private

  def create_family_if_needed
    self.family ||= Family.create!
  end
end
