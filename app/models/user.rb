class User < ActiveRecord::Base

  require 'digest/sha1'

  # Validations
  validates_presence_of :email, :password, :first_name, :last_name
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :on => :create
  validates_uniqueness_of :email


  # Callbacks
  after_create :generate_token, :set_login_count


  # Virtual Attributes
  attr_accessor :send_password


  # self.login(email, password)
  # ======================
  # Returns the users record if it's a valid login, otherwise
  # it will return false.
  def self.login(email, password)
    hashed_password = Digest::SHA1.hexdigest(password)
    user = User.where(:email => email, :password => hashed_password, :confirmed => true).first
    if user.blank?
      false
    else
      if user.login_count.is_a? Integer
        user.update_attributes(:login_count => (user.login_count + 1), :reset_token => nil)
      else
        user.update_attributes(:login_count => 0, :reset_token => nil)
      end
      user
    end
  end


  # self.confirm_by_token(token)
  # ============================
  # When provided a token, this class method will confirm a user
  # and return their data. If they are not found, then it should 
  # return false.
  def self.confirm_by_token(token)
    user = self.find_by_token(token)
    if user
      user.confirmed = true
      user.save
    else
      user = false
    end
    user
  end


  # self.user_levels
  # ===============
  # Outputs a hash of potential user_levels
  def self.user_levels
    {'Normal User' => 'user', 'Admin' => 'admin'}
  end


  # password=(attribute)
  # ====================
  # Overrides the password setter and ensures that it will always be
  # hashed when changed.
  def password=(attribute)
    unless attribute.blank?
      hashed_password = Digest::SHA1.hexdigest(attribute)
      write_attribute(:password, hashed_password)
      hashed_password
    end
  end


  # can_update?(user)
  # =================
  # Returns true if a user can update the passed user, otherwise
  # it returns false.
  def can_update?(user)
    if user_level == 'admin' || user_level == 'super-admin'
      return true
    end
    if id == user.id
      return true
    end
    return false
  end


  # admin?
  # ======
  # Returns true if a user has a user_level of 'admin', otherwise
  # returns false.
  def admin?
    if user_level === 'admin' || user_level === 'super-admin'
      true
    else
      false
    end
  end


  # confirmed?
  # ==========
  # Returns true if a user has been confirmed, otherwise it
  # returns false.
  def confirmed?
    if confirmed
      true
    else
      false
    end
  end


  # confirm!
  # ========
  # Marks as user as confirmed and clears their token
  def confirm!
    self.update_attributes(:confirmed => true, :token => false)
  end


  # request_password_reset
  # ======================
  # Generates a reset_token that can be used for password resets.
  def request_password_reset
    self.update_attributes(:reset_token => random_token)
  end


  # reconfirm!
  # ==========
  # Marks a user as confirmed, generates a new token.
  # TODO - send a new confirmation email
  def reconfirm!
    self.update_attributes(:confirmed => false, :token => random_token)
  end


  # Callbacks


  # set_login_count
  # ===============
  # Sets the initial login_count to 0
  def set_login_count
    self.login_count = 0
    self.save
  end


  # generate_token
  # ==============
  # Generates a new token
  def generate_token
    write_attribute(:token, random_token)
  end


  # random_token
  # ============
  # Returns a random token, concept taken from
  # http://blog.logeek.fr/2009/7/2/creating-small-unique-tokens-in-ruby
  def random_token
    rand(36**8).to_s(36)
  end


end