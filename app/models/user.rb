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
  validates :last_name, presence: true


  def self.search(filter = '')
    return all if filter.blank?

    if filter.compact_blank!.empty?
      all
    else
      conditions_str = filter.keys.map { |field| "#{field} LIKE ? AND " }.join[0..-6]
      search_values = filter.values
      where(conditions_str, search_values)
    end
  end

  def set_nil_values
    self.sip_number = nil if sip_number.blank?
    self.phone_number = nil if phone_number.blank?
    self.cell_number = nil if cell_number.blank?
  end

  def full_name
    [last_name, first_name, middle_name].join(' ')
  end

  def current_login
    if current_sign_in_at
      [I18n.localize(current_sign_in_at, format: '%d %b %Y'),
       'в', I18n.localize(current_sign_in_at, format: '%H:%M'),
       'с ip', current_sign_in_ip].join(' ')
    else
      '-'
    end
  end

  def last_login
    if last_sign_in_at
      [I18n.localize(last_sign_in_at, format: '%d %b %Y'),
       'в', I18n.localize(last_sign_in_at, format: '%H:%M'),
       'с ip', last_sign_in_ip].join(' ')
    else
      '-'
    end
  end

  def role_key
    role.permissions['role']
  end

  def permitted_reports
    Report.where(id: role.permissions['reports']).where.not(id: 100)
  end

  def realtime_permit?
    role.permissions['reports'].include?('100')
  end

  def permitted_ingroups
    role.permissions['ingroups']
  end

  def permitted_campaigns
    role.permissions['campaigns']
  end


  private

  def activated?
    activated
  end

  def active_for_authentication?
    super && activated?
  end

  def generate_channel_key
    loop do
      key = SecureRandom.urlsafe_base64
      self.channel_key = key
      break if User.where(channel_key: key).empty?
    end
  end

end
