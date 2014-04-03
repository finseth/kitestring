include ApplicationHelper
require 'json'

class HomeController < ApplicationController
  public_actions = [:index, :terms, :privacy, :faq, :sign_up_validate, :sign_up, :new_user, :sign_in, :update, :twilio]
  before_filter :require_login, :except => public_actions
  skip_before_filter :verify_authenticity_token, :only => [:update, :twilio]
  before_filter :use_https, :except => [:update, :twilio]

  def index
    if session[:authenticated_user_id]
      return redirect_to '/home'
    end
  end

  def terms
  end

  def privacy
  end

  def faq
  end

  def sign_up_validate
    name = (params['name'] || '').strip
    phone = (params['phone'] || '').strip
    if name.size == 0
      return render :json => { :success => false, :notice => 'Please enter your full name.' }
    end
    if phone.size == 0
      return render :json => { :success => false, :notice => 'Please enter a phone number.' }
    end
    begin
      phone = normalize_phone(phone)
    rescue
      return render :json => { :success => false, :notice => 'That phone number appears invalid.' }
    end
    user = User.find_by phone: phone
    if user
      return render :json => { :success => false, :notice => 'That phone number is taken.' }
    end
    return render :json => { :success => true }
  end

  def sign_up
    @error = false
    @name = (params['name'] || '').strip
    @phone = (params['phone'] || '').strip
    begin
      @phone = normalize_phone(@phone)
    rescue
      @error = true
    end
    begin
      if !@error
        twilio = Twilio::REST::Client.new TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN
        twilio.account.messages.create(:body => 'Welcome to Kitestring!  Your verification code is ' + verification_code(@phone) + '.', :to => @phone, :from => TWILIO_PHONE_NUMBER)
      end
    rescue
      @error = true
    end
  end

  def new_user
    verification = (params['verification'] || '').strip
    name = (params['name'] || '').strip
    password = params['password'] || ''
    confirm_password = params['confirm_password'] || ''
    phone = (params['phone'] || '').strip
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
    if phone.size == 0
      return render :json => { :success => false, :notice => 'Please enter a phone number.' }
    end
    begin
      phone = normalize_phone(phone)
    rescue
      return render :json => { :success => false, :notice => 'That phone number appears invalid.' }
    end
    user = User.find_by phone: phone
    if user
      return render :json => { :success => false, :notice => 'That phone number is taken.' }
    end
    if verification != verification_code(phone)
      return render :json => { :success => false, :notice => 'That verification code is incorrect.' }
    end
    salt = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
    user = User.create(:phone => phone, :phone => phone, :name => name, :password_salt => salt, :password_hash => password_hash(password, salt))
    session[:authenticated_user_id] = user.id
    return render :json => { :success => true, :location => '/home' }
  end

  def sign_in
    phone = (params['phone'] || '').strip
    password = params['password'] || ''
    if phone.size == 0
      return render :json => { :success => false, :notice => 'Please enter a phone number.' }
    end
    begin
      phone = normalize_phone(phone)
    rescue
      return render :json => { :success => false, :notice => 'That phone number appears invalid.' }
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
    phone = (params['phone'] || '').strip
    if name.strip.size == 0
      return render :json => { :success => false, :notice => 'Please enter a name for the contact.' }
    end
    if phone.size == 0
      return render :json => { :success => false, :notice => 'Please enter a phone number for the contact.' }
    end
    begin
      phone = normalize_phone(phone)
    rescue
      return render :json => { :success => false, :notice => 'That phone number appears invalid.' }
    end
    @user.contacts.create(:name => name, :phone => phone)
    return render :json => { :success => true, :contacts => @user.contacts.order(id: :asc).to_json }
  end

  def delete_contact
    if @user.contacts.size == 1 && @user.checkpoint
      return render :json => { :success => false, :notice => 'You cannot delete your only emergency contact while on a trip.' }
    end
    @user.contacts.find(params['id'].to_i).destroy
    return render :json => { :success => true, :contacts => @user.contacts.order(id: :asc).to_json }
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
    return render :json => { :success => true, :contacts => @user.contacts.order(id: :asc).to_json }
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
    return render :json => { :success => true, :contacts => @user.contacts.order(id: :asc).to_json }
  end

  def checkpoint
    if @user.contacts.size == 0
      return render :json => { :success => false, :notice => 'Add an emergency contact first.' }
    end
    message = (params['message'] || '').strip
    if message.size == 0
      return render :json => { :success => false, :notice => 'Please enter a message to be sent to your emergency contacts.' }
    end
    time = (params['datetime_utc'] || '').strip
    if !(time =~ /\d+?/)
      return render :json => { :success => false, :notice => 'Please format the date as YYYY-MM-DD and the time as HH:MM according to a 24-hour clock.' }
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
    return render :json => { :success => true, :active => true, :datetime_utc => (@user.checkpoint.utc().to_i * 1000), :message => message, :notice => msg }
  end

  def end_checkpoint
    @user.message = nil
    @user.checkpoint = nil
    @user.pinged = nil
    @user.responded = nil
    @user.alerted = nil
    @user.save
    return render :json => { :success => true, :active => false, :datetime_utc => nil, :message => nil }
  end

  def status
    if @user.checkpoint
      return render :json => { :success => true, :active => true, :datetime_utc => (@user.checkpoint.utc().to_i * 1000), :message => @user.message }
    else
      return render :json => { :success => true, :active => false, :datetime_utc => nil, :message => nil }
    end
  end

  def update_name
    name = (params['name'] || '').strip
    if name.size == 0
      return render :json => { :success => false, :notice => 'Please enter your full name.' }
    end
    @user.name = name
    @user.save
    return render :json => { :success => true, :name => name }
  end

  def update_password
    password = params['password'] || ''
    confirm_password = params['confirm_password'] || ''
    if password.size == 0
      return render :json => { :success => false, :notice => 'Please enter a password.' }
    end
    if password != confirm_password
      return render :json => { :success => false, :notice => 'Your passwords do not match.' }
    end
    salt = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
    @user.password_salt = salt
    @user.password_hash = password_hash(password, salt)
    @user.save
    return render :json => { :success => true, :notice => 'Your password has been updated.' }
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
        if now > user.checkpoint
          if user.pinged == false
            begin
              twilio.account.messages.create(:body => 'Your Kitestring trip is over!  Please reply \'ok\' to end your trip so we know you\'re safe.  You can also reply a duration like \'5m\' to extend your ETA.', :to => user.phone, :from => TWILIO_PHONE_NUMBER)
            rescue
            end
            user.pinged = true
            user.save
          else
            if now > user.checkpoint + 5.minutes
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
    phone = params['From'].strip
    body = params['Body'].strip.downcase
    begin
      phone = normalize_phone(phone)
    rescue
      return render :json => { :success => false, :notice => 'That phone number appears invalid.' }
    end
    now = Time.zone.now
    user = User.find_by phone: phone
    if user
      if body == 'password'
        salt = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
        password = (0...6).map { ('a'..'z').to_a[rand(26)] }.join
        user.password_salt = salt
        user.password_hash = password_hash(password, salt)
        user.save
        twiml = Twilio::TwiML::Response.new do |r|
          r.Message 'Your new password is: ' + password
        end
        return render :xml => twiml.text
      end
      if user.checkpoint
        if body =~ /[1-9]\d*\s*m(in|inute)?s?/
          num = body.scan(/\d+/)[0].to_i
          user.checkpoint = Time.zone.now + num.minutes
          user.pinged = false
          user.alerted = false
          user.save
          twiml = Twilio::TwiML::Response.new do |r|
            if num == 1
              r.Message 'Thanks!  Your ETA has been extended until ' + num.to_s + ' minute from now.'
            else
              r.Message 'Thanks!  Your ETA has been extended until ' + num.to_s + ' minutes from now.'
            end
          end
          return render :xml => twiml.text
        end
        if body =~ /[1-9]\d*\s*h(r|our)?s?/
          num = body.scan(/\d+/)[0].to_i
          user.checkpoint = Time.zone.now + num.hours
          user.pinged = false
          user.alerted = false
          user.save
          twiml = Twilio::TwiML::Response.new do |r|
            if num == 1
              r.Message 'Thanks!  Your ETA has been extended until ' + num.to_s + ' hour from now.'
            else
              r.Message 'Thanks!  Your ETA has been extended until ' + num.to_s + ' hours from now.'
            end
          end
          return render :xml => twiml.text
        end
        if body =~ /[1-9]\d*\s*d(ay|ays)?/
          num = body.scan(/\d+/)[0].to_i
          user.checkpoint = Time.zone.now + num.days
          user.pinged = false
          user.alerted = false
          user.save
          twiml = Twilio::TwiML::Response.new do |r|
            if num == 1
              r.Message 'Thanks!  Your ETA has been extended until ' + num.to_s + ' day from now.'
            else
              r.Message 'Thanks!  Your ETA has been extended until ' + num.to_s + ' days from now.'
            end
          end
          return render :xml => twiml.text
        end
        if body != 'ok'
          twiml = Twilio::TwiML::Response.new do |r|
            r.Message 'Sorry, what was that?'
          end
          return render :xml => twiml.text
        end
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

  # show a message on the next page load
  def notice(message)
    if flash[:notices]
      flash[:notices] << message
    else
      flash[:notices] = [message]
    end
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
