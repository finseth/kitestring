require 'digest'
require 'json'
require 'twilio-ruby'

TWILIO_ACCOUNT_SID = ENV['TWILIO_ACCOUNT_SID']
TWILIO_AUTH_TOKEN = ENV['TWILIO_AUTH_TOKEN']
TWILIO_PHONE_NUMBER = ENV['TWILIO_PHONE_NUMBER']
APP_SECRET = ENV['APP_SECRET']

class HomeController < ApplicationController
  public_actions = [:index, :terms, :privacy, :send_verification, :verify, :new_user, :sign_in, :update, :twilio]
  before_filter :require_login, :except => public_actions
  skip_before_filter :verify_authenticity_token, :only => [:twilio]
  before_filter :use_https

  def index
    if session[:authenticated_user_id]
      return redirect_to '/home'
    end
  end

  def terms
  end

  def privacy
  end

  def send_verification
    name = (params['name'] || '').strip
    phone = normalize_phone(params['phone'] || '')
    if name.size == 0
      return render :json => { :success => false, :notice => 'Please enter your full name.' }
    end
    if phone == nil
      return render :json => { :success => false, :notice => 'That phone number does not appear valid.' }
    end
    user = User.find_by phone: phone
    if user
      return render :json => { :success => false, :notice => 'That phone number is taken.' }
    end
    twilio = Twilio::REST::Client.new TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN
    begin
      twilio.account.messages.create(:body => 'Welcome to Kitestring!  Your verification code is ' + verification_code(phone) + '.', :to => phone, :from => TWILIO_PHONE_NUMBER)
    rescue
      return render :json => { :success => false, :notice => 'That phone number does not appear valid.' }
    end
    return render :json => { :success => true, :location => '/verify/' + name +  '/' + phone }
  end

  def verify
    @name = params['name']
    @phone = params['phone']
  end

  def new_user
    verification = (params['verification'] || '').strip
    name = (params['name'] || '').strip
    password = params['password'] || ''
    confirm_password = params['confirm_password'] || ''
    phone = normalize_phone(params['phone'] || '')
    if verification.size == 0
      return render :json => { :success => false, :notice => 'Please enter the verification code sent to your mobile device.' }
    end
    if name.size == 0
      return render :json => { :success => false, :notice => 'Please enter your full name.' }
    end
    if password.size == 0
      return render :json => { :success => false, :notice => 'Please enter a password.' }
    end
    if password != confirm_password
      return render :json => { :success => false, :notice => 'Your passwords do not match.' }
    end
    if phone == nil
      return render :json => { :success => false, :notice => 'That phone number does not appear valid.' }
    end
    user = User.find_by phone: phone
    if user
      return render :json => { :success => false, :notice => 'That phone number is taken.' }
    end
    if verification != verification_code(phone)
      return render :json => { :success => false, :notice => 'That verification code is incorrect.' }
    end
    salt = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
    user = User.create(:phone => phone, :name => name, :password_salt => salt, :password_hash => password_hash(password, salt))
    session[:authenticated_user_id] = user.id
    return render :json => { :success => true, :location => '/home' }
  end

  def sign_in
    phone = normalize_phone(params['phone'] || '')
    password = params['password'] || ''
    if phone == nil
      return render :json => { :success => false, :notice => 'That phone number does not appear valid.' }
    end
    if password.size == 0
      return render :json => { :success => false, :notice => 'Please enter a password.' }
    end
    user = User.find_by phone: phone
    if user == nil
      return render :json => { :success => false, :notice => 'Invalid phone number or password.' }
    end
    if password_hash(password, user.password_salt) != user.password_hash
      return render :json => { :success => false, :notice => 'Invalid phone number or password.' }
    end
    session[:authenticated_user_id] = user.id
    return render :json => { :success => true, :location => '/home' }
  end

  def sign_out
    session[:authenticated_user_id] = nil
    return render :json => { :success => true, :location => '/' }
  end

  def home
  end

  def new_contact
    name = (params['name'] || '').strip
    phone = normalize_phone(params['phone'] || '')
    if name.strip.size == 0
      return render :json => { :success => false, :notice => 'Please enter a name for the contact.' }
    end
    if phone == nil
      return render :json => { :success => false, :notice => 'That phone number does not appear valid.' }
    end
    @user.contacts.create(:name => name, :phone => phone)
    return render :json => { :success => true, :contacts => @user.contacts.to_json }
  end

  def delete_contact
    if @user.contacts.size == 1 && @user.checkpoint
      return render :json => { :success => false, :notice => 'You cannot delete your only emergency contact while on a trip.' }
    end
    @user.contacts.find(params['id'].to_i).destroy
    return render :json => { :success => true, :contacts => @user.contacts.to_json }
  end

  def move_contact_up
    this_contact = @user.contacts.find(params['id'].to_i)
    prev_contact = @user.contacts.order(id: :asc).where('id < ?', params['id'].to_i).last
    old_name = this_contact.name
    old_phone = this_contact.phone
    this_contact.name = prev_contact.name
    this_contact.phone = prev_contact.phone
    prev_contact.name = old_name
    prev_contact.phone = old_phone
    this_contact.save
    prev_contact.save
    return render :json => { :success => true, :contacts => @user.contacts.to_json }
  end

  def move_contact_down
    this_contact = @user.contacts.find(params['id'].to_i)
    next_contact = @user.contacts.order(id: :asc).where('id > ?', params['id'].to_i).first
    old_name = this_contact.name
    old_phone = this_contact.phone
    this_contact.name = next_contact.name
    this_contact.phone = next_contact.phone
    next_contact.name = old_name
    next_contact.phone = old_phone
    this_contact.save
    next_contact.save
    return render :json => { :success => true, :contacts => @user.contacts.to_json }
  end

  def checkpoint
    if @user.contacts.size == 0
      return render :json => { :success => false, :notice => 'Add an emergency contact first.' }
    end
    message = (params['message'] || '').strip
    if message.size == 0
      return render :json => { :success => false, :notice => 'Please enter a message to be sent to your emergency contacts.' }
    end
    time = (params['time_utc'] || '').strip
    if !(time =~ /\d+?/)
      return render :json => { :success => false, :notice => 'Please format the time as HH:MM according to a 24-hour clock.' }
    end
    if Time.zone.at(time.to_i / 1000) <= Time.zone.now
      return render :json => { :success => false, :notice => 'The time must be in the future.' }
    end
    if @user.checkpoint
      msg = 'Your trip has been updated.'
    end
    @user.message = message
    @user.checkpoint = Time.zone.at(time.to_i / 1000)
    @user.pinged = false
    @user.responded = false
    @user.alerted = false
    @user.save
    return render :json => { :success => true, :active => true, :time_utc => (@user.checkpoint.utc().to_i * 1000), :message => message, :notice => msg }
  end

  def end_checkpoint
    @user.message = nil
    @user.checkpoint = nil
    @user.pinged = nil
    @user.responded = nil
    @user.alerted = nil
    @user.save
    return render :json => { :success => true, :active => false, :time_utc => nil, :message => nil }
  end

  def status
    if @user.checkpoint
      return render :json => { :success => true, :active => true, :time_utc => (@user.checkpoint.utc().to_i * 1000), :message => @user.message }
    else
      return render :json => { :success => true, :active => false, :time_utc => nil, :message => nil }
    end
  end

  def delete_account
    @user.destroy
    session[:authenticated_user_id] = nil
    notice('Your account has been deleted.')
    return render :json => { :success => true, :location => '/' }
  end

  def update
    now = Time.zone.now
    twilio = Twilio::REST::Client.new TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN
    User.all.each do |user|
      if user.checkpoint
        if now > user.checkpoint - 30.seconds
          if user.pinged == false
            begin
              twilio.account.messages.create(:body => 'Your Kitestring trip is over!  Please reply \'ok\' to end your trip so we know you\'re safe.  You can also reply a duration like \'5m\' to extend your ETA.', :to => user.phone, :from => TWILIO_PHONE_NUMBER)
            rescue
            end
            user.pinged = true
            user.save
          else
            if now > user.checkpoint + 5.minutes - 30.seconds
              if user.responded == false
                if user.alerted == false
                  user.contacts.each do |contact|
                    begin
                      twilio.account.messages.create(:body => user.message, :to => contact.phone, :from => TWILIO_PHONE_NUMBER)
                    rescue
                    end
                  end
                  twilio.account.messages.create(:body => 'You did not respond.  Your alert message has been sent to your emergency contacts.', :to => user.phone, :from => TWILIO_PHONE_NUMBER)
                  user.alerted = true
                  user.save
                end
              end
            end
          end
        end
      end
    end
    return render :text => ''
  end

  def twilio
    phone = normalize_phone(params['From'])
    body = params['Body'].strip()
    now = Time.zone.now
    user = User.find_by phone: phone
    if user
      if user.checkpoint
        if body =~ /[1-9]\d*m(in)?/
          num = body.scan(/\d+/)[0].to_i
          user.checkpoint = Time.zone.now + num.minutes
          user.pinged = false
          user.alerted = false
          user.save
          twiml = Twilio::TwiML::Response.new do |r|
            if num == 1
              r.Message 'Thanks!  Your ETA has been extended by ' + num.to_s + ' minute.'
            else
              r.Message 'Thanks!  Your ETA has been extended by ' + num.to_s + ' minutes.'
            end
          end
          return render :xml => twiml.text
        end
        if body =~ /[1-9]\d*h(r|our)?s?/
          num = body.scan(/\d+/)[0].to_i
          user.checkpoint = Time.zone.now + num.hours
          user.pinged = false
          user.alerted = false
          user.save
          twiml = Twilio::TwiML::Response.new do |r|
            if num == 1
              r.Message 'Thanks!  Your ETA has been extended by ' + num.to_s + ' hour.'
            else
              r.Message 'Thanks!  Your ETA has been extended by ' + num.to_s + ' hours.'
            end
          end
          return render :xml => twiml.text
        end
        if now > user.checkpoint - 30.seconds
          if user.pinged == true
            if user.responded == false
              user.message = nil
              user.checkpoint = nil
              user.pinged = nil
              user.responded = nil
              user.alerted = nil
              user.save
              twiml = Twilio::TwiML::Response.new do |r|
                r.Message 'Thanks!  Your trip has been ended.'
              end
              return render :xml => twiml.text
            end
          end
        end
      end
    end
    return render :text => ''
  end

private
  # render a 404 page
  def render_404
    render '404', :status => 404
  end

  # make sure the user is logged in before continuing
  # used as a before filter
  def require_login
    if session[:authenticated_user_id] == nil
      return render_404
    end
    begin
      @user = User.find(session[:authenticated_user_id].to_i)
    rescue
      session[:authenticated_user_id] = nil
      return render_404
    end
  end

  # compute the verification code for a phone number
  def verification_code(phone)
    return Digest::SHA256.hexdigest(APP_SECRET + phone + APP_SECRET).to_i(16).to_s(10)[0...6]
  end

  # compute a password hash
  def password_hash(password, salt)
    return Digest::SHA256.hexdigest(salt + password + salt)
  end

  # show a message on the next page load
  def notice(message)
    if flash[:notices]
      flash[:notices] << message
    else
      flash[:notices] = [message]
    end
  end

  # normalize a phone number
  def normalize_phone(phone)
    phone = phone.strip.gsub(/[-+() ]/, '')
    if phone == '' || phone.gsub(/[0-9]/, '') != ''
      return nil
    end
    if phone.size == 10
      phone = '1' + phone
    end
    return phone
  end

  # make sure we are using https
  # used as a before filter
  def use_https
    if Rails.env.production?
      if request.protocol != 'https://'
        return redirect_to "https://#{request.url[(request.protocol.size)..(-1)]}"
      end
    end
  end

end
