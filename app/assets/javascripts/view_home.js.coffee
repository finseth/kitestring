view_home = angular.module('view_home', ['ajax'])

view_home.controller('HomeController', ['$scope', 'ajax', 'notice', ($scope, ajax, notice) ->
  # checkpoint

  $scope.active = active
  if $scope.active
    $scope.current_checkpoint = current_checkpoint
    $scope.current_message = current_message
    $scope.time_string = ''
    $scope.date_string = ''
    $scope.interval_string = ''
    $scope.datetime_utc = ''
    $scope.expired = false
  else
    $scope.current_checkpoint = new Date()
    $scope.current_message = ''
    $scope.time_string = ''
    $scope.date_string = ''
    $scope.interval_string = ''
    $scope.datetime_utc = ''
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

  window.getCheckpointInput = () ->
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

  updateCurrentCheckpointView = () ->
    if $scope.active
      adjusted_time = new Date()
      adjusted_time.setTime($scope.current_checkpoint.getTime() + 30 * 1000)

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
      $scope.time_string = hours_str + ':' + minutes_str + ' ' + period

      if compareDates(adjusted_time, (new Date()))
        $scope.date_string = ''
      else
        $scope.date_string = adjusted_time.toDateString()

      minutes = Math.round((adjusted_time.getTime() - (new Date()).getTime()) / (1000 * 60))
      if minutes < 1
        if !$scope.expired
          notice('Please end your trip or update your ETA so we know you\'re safe.')
        $scope.expired = true
      else
        $scope.expired = false
      if minutes < 0
        minutes = -minutes
        negative = true
      else
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
      if negative
        interval_string += ' ago'
      $scope.interval_string = interval_string

  updateTimeUTC = () ->
    time = getCheckpointInput()
    if time == null
      $scope.datetime_utc = ''
    else
      $scope.datetime_utc = String(getCheckpointInput().getTime())

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
  $scope.$watchCollection('[time, date]', updateTimeUTC)
  $scope.$watch('current_checkpoint', updateCurrentCheckpointView)
  setInterval((() -> $scope.$apply(updateCurrentCheckpointView)), 30000)
  setInterval((() ->
    ajax {
      url: '/status',
      type: 'post',
      success: $scope.updateCurrentCheckpointFromServer,
      scope: $scope
    }
    $scope.$apply(updateTimeUTC)
  ), 5000)

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

  $scope.delete_contact = (data, textStatus, jqXHR) ->
    $scope.contacts = JSON.parse(data.contacts)

  $scope.move_contact_up = (data, textStatus, jqXHR) ->
    $scope.contacts = JSON.parse(data.contacts)

  $scope.move_contact_down = (data, textStatus, jqXHR) ->
    $scope.contacts = JSON.parse(data.contacts)

  $scope.new_contact = (data, textStatus, jqXHR) ->
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

  $scope.delete_account = (event) ->
    notice('We&rsquo;re sad to see you go! Click <a href="/delete_account" ks-post-anchor>here</a> to delete your account.')
    event.preventDefault()
    event.stopPropagation()
])