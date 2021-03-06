require 'test_helper'
require 'digest/sha1'

class UserTest < ActiveSupport::TestCase

  test "new and valid users are unconfirmed by default" do
    user = User.new({:email => 'emerson@plankdesign.com', :first_name => 'Emerson', :last_name => 'Lackey'})
    assert_equal(false, user.confirmed?)
  end

  test "unconfirmed user cannot login" do
    user = User.login('john.smith@gmail.com', 'password')
    assert_equal(false, user)
  end

  test "new users should have a login_count of 0" do
    user = Factory.create(:user, :confirmed => true, :token => nil, :email => 'new_user_count@text.com')
    assert_equal(0, user.login_count)
  end

  test "user.login_count should increment every login" do
    user = User.login('emerson.lackey@gmail.com', 'password')
    current_login_count = user.login_count
    user = User.login('emerson.lackey@gmail.com', 'password')
    assert_equal((current_login_count + 1), user.login_count)
  end

  test "confirm! should confirm a user" do
    user = User.new({:email => 'confirm@test.com', :password => 'password'})
    user.confirm!
    assert( (user.confirmed? && user.token.blank?) )
  end

  test "reconfirm! should reconfirm a user" do
    user = User.find_by_email('emerson.lackey@gmail.com')
    user.reconfirm!
    assert((user.confirmed === false && !user.token.blank?))
  end

  test "admin? should be true when user_level equals 'admin'" do
    user = User.find_by_email('admin@application.com')
    assert(user.admin?)
  end

  test "admin? should also be true when user_level equals 'super-admin'" do
    user = Factory.create(:super_admin)
    assert(user.admin?)
  end

  test "validate user by token" do
    user = User.confirm_by_token('supersecrettoken')
    assert_equal(true, user.confirmed)
  end

  test "new users have a random token" do
    user = User.new({:email => 'emerson@plankdesign.com', :password => 'password', :first_name => 'Emerson', :last_name => 'Lackey'})
    if user.save
      assert(user.token, "Token is not set")
    else
      assert(false, "Unable to save user")
    end
  end

  test "new user has minimum requirements (email and password)" do
    user = User.new({:email => 'emerson_valid@gmail.com', :first_name => 'Emerson_valid', :last_name => 'Lackey_valid', :password => 'password'})
    assert(user.valid?)
  end

  test "confirmed user are allowed to login" do
    user = User.login('emerson.lackey@gmail.com', 'password')
    assert_equal('emerson.lackey@gmail.com', user.email)
  end

  test 'password should be hashed when set' do
    password = 'example'
    user = User.new({:email => 'password@hashing.com', :password => password})
    assert_equal(user.password, Digest::SHA1.hexdigest(password))
  end

  test 'non-admin users cannot change other users accounts' do
    user = Factory.create(:valid_user, :email => 'naughty-user@bad.com')
    another_user = Factory.create(:valid_user)
    assert_equal(false, user.can_update?(another_user))
  end

  test 'request_password_reset should generate a reset_token' do
    user = Factory.create(:valid_user)
    user.request_password_reset
    assert(user.reset_token)
  end

  test "logins should clear a users reset_token" do
    user = Factory.create(:valid_user)
    user.request_password_reset
    user = User.login(user.email, 'password')
    assert_equal(nil, user.reset_token)
  end

end
