view_home = angular.module('view_home', ['ajax'])

view_home.controller('HomeController', ['$scope', 'ajax', 'notice', ($scope, ajax, notice) ->
  # checkpoint

  $scope.active = active
  if $scope.active
    $scope.current_checkpoint = current_checkpoint
    $scope.current_message = current_message
    $scope.current_time_string = ''
    $scope.current_date_string = ''
    $scope.current_interval_string = ''
    $scope.datetime_utc = ''
    $scope.interval = ''
    $scope.expired = false
  else
    $scope.current_checkpoint = new Date()
    $scope.current_message = ''
    $scope.current_time_string = ''
    $scope.current_date_string = ''
    $scope.current_interval_string = ''
    $scope.datetime_utc = ''
    $scope.interval = ''
    $scope.expired = false

  numberToString = (num, minWidth) ->
    str = String(num)
    while str.length < minWidth
      str = '0' + str
    return str

  compareDates = (date1, date2) ->
    return date1.getFullYear() == date2.getFullYear() && date1.getMonth() == date2.getMonth() && date1.getDate() == date2.getDate()

  setCheckpointInput = (datetime) ->
    hours_str = numberToString(datetime.getHours(), 2)
    minutes_str = numberToString(datetime.getMinutes(), 2)
    $scope.time = hours_str + ':' + minutes_str
    year_str = numberToString(datetime.getFullYear(), 4)
    month_str = numberToString(datetime.getMonth() + 1, 2)
    day_str = numberToString(datetime.getDate(), 2)
    $scope.date = year_str + '-' + month_str + '-' + day_str

  getCheckpointInput = () ->
    if /\d\d\d\d-\d\d-\d\d/g.test($scope.date) && /\d\d?:\d\d?/g.test($scope.time)
      time_parts = $scope.time.split(':')
      hours = Number(time_parts[0])
      minutes = Number(time_parts[1])
      date_parts = $scope.date.split('-')
      year = Number(date_parts[0])
      month = Number(date_parts[1])
      day = Number(date_parts[2])
      return new Date(year, month - 1, day, hours, minutes)
    return null

  getTimeString = (datetime) ->
    adjusted_time = new Date()
    adjusted_time.setTime(datetime.getTime() + 30 * 1000)
    if adjusted_time.getHours() > 12
      hours_str = numberToString(adjusted_time.getHours() - 12, 1)
      period = 'PM'
    if adjusted_time.getHours() == 12
      hours_str = '12'
      period = 'PM'
    if adjusted_time.getHours() < 12
      hours_str = numberToString(adjusted_time.getHours(), 1)
      period = 'AM'
    if adjusted_time.getHours() == 0
      hours_str = '12'
      period = 'AM'
    minutes_str = numberToString(adjusted_time.getMinutes(), 2)
    return hours_str + ':' + minutes_str + ' ' + period

  getDateString = (datetime) ->
    adjusted_time = new Date()
    adjusted_time.setTime(datetime.getTime() + 30 * 1000)
    if compareDates(adjusted_time, (new Date()))
      return 'today'
    return adjusted_time.toDateString()

  getRelativeTimeString = (datetime) ->
    adjusted_time = new Date()
    adjusted_time.setTime(datetime.getTime() + 30 * 1000)
    adjusted_time.setSeconds(0)
    now = new Date()
    adjusted_time.setSeconds(0)
    minutes = Math.ceil((adjusted_time.getTime() - now.getTime()) / (1000 * 60))
    if minutes < 0
      minutes = -minutes
      positive = false
      negative = true
    else if minutes > 0
      positive = true
      negative = false
    else
      positive = false
      negative = false
    days = Math.floor(minutes / (24 * 60))
    hours = Math.floor((minutes / 60) % 24)
    minutes = Math.round(minutes % 60)
    parts = []
    if days > 0
      if days > 1
        parts.push(String(days) + ' days')
      else
        parts.push(String(days) + ' day')
    if hours > 0
      if hours > 1
        parts.push(String(hours) + ' hours')
      else
        parts.push(String(hours) + ' hour')
    if minutes > 0
      if minutes > 1
        parts.push(String(minutes) + ' minutes')
      else
        parts.push(String(minutes) + ' minute')
    if parts.length == 0
      interval_string = 'now'
    if parts.length == 1
      interval_string = parts[0]
    if parts.length == 2
      interval_string = parts[0] + ' and ' + parts[1]
    if parts.length == 3
      interval_string = parts[0] + ', ' + parts[1] + ' and ' + parts[2]
    if positive
      interval_string += ' from now'
    if negative
      interval_string += ' ago'
    return interval_string

  isNow = (datetime) ->
    adjusted_time = new Date()
    adjusted_time.setTime(datetime.getTime() + 30 * 1000)
    adjusted_time.setSeconds(0)
    now = new Date()
    adjusted_time.setSeconds(0)
    minutes = Math.ceil((adjusted_time.getTime() - now.getTime()) / (1000 * 60))
    return minutes == 0

  updateCurrentCheckpointView = () ->
    if $scope.active
      $scope.current_time_string = getTimeString($scope.current_checkpoint)
      $scope.current_date_string = getDateString($scope.current_checkpoint)
      $scope.current_interval_string = getRelativeTimeString($scope.current_checkpoint)
      if isNow($scope.current_checkpoint)
        if !$scope.expired
          notice('Please end your trip or update your ETA so we know you\'re safe.')
        $scope.expired = true
      else
        $scope.expired = false

  step = () ->
    time = getCheckpointInput()
    if time == null
      $scope.datetime_utc = ''
      $scope.interval = ''
    else
      checkpoint = getCheckpointInput()
      $scope.datetime_utc = String(checkpoint.getTime())
      $scope.interval = getRelativeTimeString(checkpoint)
      $scope.interval = $scope.interval.charAt(0).toUpperCase() + $scope.interval.slice(1) + '.'
    updateCurrentCheckpointView()

  $scope.checkpointIn = (event, minutes) ->
    time = new Date()
    time.setTime(time.getTime() + 1000 * 60 * minutes)
    setCheckpointInput(time)
    event.preventDefault()
    event.stopPropagation()

  $scope.updateCurrentCheckpointFromServer = (data, textStatus, jqXHR) ->
    $scope.active = data.active
    if $scope.active
      $scope.current_checkpoint = new Date()
      $scope.current_checkpoint.setTime(data.datetime_utc)
      $scope.current_message = data.message

  if $scope.active
    setCheckpointInput(current_checkpoint)
    $scope.message = $scope.current_message
  else
    initial = new Date()
    initial.setTime(initial.getTime() + 1000 * 60 * 30)
    setCheckpointInput(initial)
    $scope.message = 'This is ' + window.user_name + '. If you get this message, I did not get home safely when planned, and I might be in danger. (Do not reply to this message.)'
  $scope.$watchCollection('[time, date]', step)
  $scope.$watch('current_checkpoint', updateCurrentCheckpointView)
  setInterval((() ->
    ajax {
      url: '/status',
      type: 'post',
      success: $scope.updateCurrentCheckpointFromServer,
      scope: $scope
    }
  ), 5000)
  setInterval((() ->
    $scope.$apply(step)
  ), 1000)

  $scope.checkpointForm = (data, textStatus, jqXHR) ->
    scrollTop = $('body').scrollTop()
    if scrollTop > 0
      $('html, body').animate({ scrollTop: 0 }, scrollTop, 'swing', (() ->
        $scope.$apply (() -> $scope.updateCurrentCheckpointFromServer(data, textStatus, jqXHR))
      ))
    else
      $scope.updateCurrentCheckpointFromServer(data, textStatus, jqXHR)

  # contacts

  $scope.contacts = window.contacts

  $scope.deleteContact = (data, textStatus, jqXHR) ->
    $scope.contacts = JSON.parse(data.contacts)

  $scope.moveContactUp = (data, textStatus, jqXHR) ->
    $scope.contacts = JSON.parse(data.contacts)

  $scope.moveContactDown = (data, textStatus, jqXHR) ->
    $scope.contacts = JSON.parse(data.contacts)

  $scope.newContact = (data, textStatus, jqXHR) ->
    new_contacts = JSON.parse(data.contacts)
    $scope.contact_name = ''
    $scope.contact_phone = ''
    $('*').blur()
    if $scope.contacts.length == 0
      scrollTop = $('body').scrollTop()
      if scrollTop > 0
        $('html, body').animate({ scrollTop: 0 }, scrollTop, 'swing', (() ->
          $scope.$apply (() -> $scope.contacts = new_contacts)
        ))
      else
        $scope.contacts = new_contacts
    else
      $scope.contacts = new_contacts

  # account

  $scope.name = window.user_name
  $scope.name_update = $scope.name
  $scope.name_locked = true

  $scope.startUpdateName = (event) ->
    event.preventDefault()
    event.stopPropagation()
    $scope.name_locked = false
    $scope.name_update = $scope.name
    setTimeout((() -> $("#update-name-input").focus()), 1)

  $scope.cancelUpdateName = (event) ->
    event.preventDefault()
    event.stopPropagation()
    $scope.name_locked = true

  $scope.updateName = (data, textStatus, jqXHR) ->
    $scope.name_locked = true
    $scope.name = data.name

  $scope.password_update = ''
  $scope.confirm_password_update = ''
  $scope.password_locked = true

  $scope.startUpdatePassword = (event) ->
    event.preventDefault()
    event.stopPropagation()
    $scope.password_locked = false
    $scope.password_update = ''
    $scope.confirm_password_update = ''
    setTimeout((() -> $("#update-password-input").focus()), 1)

  $scope.cancelUpdatePassword = (event) ->
    event.preventDefault()
    event.stopPropagation()
    $scope.password_locked = true

  $scope.updatePassword = (data, textStatus, jqXHR) ->
    $scope.password_locked = true

  $scope.deleteAccount = (event) ->
    event.preventDefault()
    event.stopPropagation()
    notice('We&rsquo;re sad to see you go! Click <a href="/delete_account" ks-post-anchor>here</a> to delete your account.')
])