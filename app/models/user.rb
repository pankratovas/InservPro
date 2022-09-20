class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable ,:registerable,
  # :recoverable, :rememberable, :validatable :omniauthable
  devise :database_authenticatable, :trackable
  belongs_to :role

  before_create :generate_channel_key
  before_save { self.email = email.downcase }
  before_save :set_nil_values

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  VALID_SIPNUMBER_REGEX = /\A\d{4}\z/

  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :sip_number, format: { with: VALID_SIPNUMBER_REGEX }, uniqueness: true, allow_nil: true, allow_blank: true
  validates :password, on: :create, length: { in: 6..128 }

  def set_nil_values
    self.sip_number = nil if self.sip_number.blank?
    self.phone_number = nil if self.phone_number.blank?
    self.cell_number = nil if self.cell_number.blank?
  end

  def name
    [self.last_name, self.first_name, self.middle_name].join(' ')
  end

  def phone_numbers
    @pn = self.phone_number.to_s
    @pn = @pn+', '+self.phone_number_s unless self.phone_number_s.nil? || self.phone_number_s.blank?
    @pn = @pn+', '+self.phone_number_t unless self.phone_number_t.nil? || self.phone_number_t.blank?
    return @pn
  end

  def current_login
    if self.current_sign_in_at
      [I18n.localize(self.current_sign_in_at, format: '%d %b %Y'),
       I18n.t(:at), I18n.localize(self.current_sign_in_at, format: '%H:%M'),
       I18n.t(:from_ip), self.current_sign_in_ip].join(' ')
    else
      '-'
    end
  end

  def last_login
    if self.last_sign_in_at
      [I18n.localize(self.last_sign_in_at, format: '%d %b %Y'),
       I18n.t(:at), I18n.localize(self.last_sign_in_at, format: '%H:%M'),
       I18n.t(:from_ip), self.last_sign_in_ip].join(' ')
    else
      '-'
    end
  end

  def role_key
    self.role.permissions[:role]
  end

  def permitted_reports
    Report.where(id: self.role.permissions[:reports]).where.not(id: 100)
  end

  def realtime_permit?
    self.role.permissions[:reports].include?('100')
  end




  private

  def activated?
    self.activated
  end

  def active_for_authentication?
    super && activated?
  end

  def generate_channel_key
    begin
      key = SecureRandom.urlsafe_base64
    end while User.where(:channel_key => key).exists?
    self.channel_key = key
  end
end
