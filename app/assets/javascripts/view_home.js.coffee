view_home = angular.module('view_home', ['ajax'])

view_home.controller('HomeController', ['$scope', 'ajax', 'notice', ($scope, ajax, notice) ->
  # checkpoint

  $scope.active = active
  if $scope.active
    $scope.current_checkpoint = current_checkpoint
    $scope.current_message = current_message
    $scope.time_string = ''
    $scope.interval_string = ''
    $scope.time_utc = ''
    $scope.expired = false
  else
    $scope.current_checkpoint = new Date()
    $scope.current_message = ''
    $scope.time_string = ''
    $scope.interval_string = ''
    $scope.time_utc = ''
    $scope.expired = false

  setTimeInput = (date) ->
    hours_str = String(date.getHours())
    minutes_str = String(date.getMinutes())
    while hours_str.length < 2
      hours_str = '0' + hours_str
    while minutes_str.length < 2
      minutes_str = '0' + minutes_str
    $scope.time = hours_str + ':' + minutes_str

  getTimeInput = () ->
    if /\d\d?:\d\d?/g.test($scope.time)
      parts = $scope.time.split(':')
      hours = Number(parts[0])
      minutes = Number(parts[1])
      date = new Date()
      date.setHours(hours)
      date.setMinutes(minutes)
      if date < (new Date())
        date.setTime(date.getTime() + 1000 * 60 * 60 * 24)
      return date
    return null

  updateCurrentCheckpointView = () ->
    if $scope.active
      if $scope.current_checkpoint.getHours() > 12
        hours_str = String($scope.current_checkpoint.getHours() - 12)
        period = 'PM'
      else
        hours_str = String($scope.current_checkpoint.getHours())
        period = 'AM'
      minutes_str = String($scope.current_checkpoint.getMinutes())
      while minutes_str.length < 2
        minutes_str = '0' + minutes_str
      $scope.time_string = hours_str + ':' + minutes_str + ' ' + period
      minutes = Math.round(($scope.current_checkpoint.getTime() - (new Date()).getTime()) / (1000 * 60))
      if minutes < 1
        if !$scope.expired
          notice('Please end your trip or update it with a later ETA so we know you\'re safe.')
        $scope.expired = true
      else
        $scope.expired = false
      if minutes < 0
        minutes = -minutes
        negative = true
      else
        negative = false
      hours = Math.floor(minutes / 60)
      minutes = Math.round(minutes % 60)
      interval_string = ''
      if hours > 0
        if hours > 1
          interval_string += String(hours) + ' hours'
        else
          interval_string += String(hours) + ' hour'
      if hours > 0 && minutes > 0
        interval_string += ' and '
      if minutes > 0
        if minutes > 1
          interval_string += String(minutes) + ' minutes'
        else
          interval_string += String(minutes) + ' minute'
      if interval_string == ''
        interval_string = 'now'
      if negative
        interval_string += ' ago'
      $scope.interval_string = interval_string

  $scope.checkpointIn = (event, minutes) ->
    time = new Date()
    time.setTime(time.getTime() + 1000 * 60 * minutes)
    setTimeInput(time)
    event.preventDefault()
    event.stopPropagation()

  $scope.updateCurrentCheckpointFromServer = (data, textStatus, jqXHR) ->
    $scope.active = data.active
    if $scope.active
      $scope.current_checkpoint = new Date()
      $scope.current_checkpoint.setTime(data.time_utc)
      $scope.current_message = data.message

  if $scope.active
    setTimeInput(current_checkpoint)
    $scope.message = $scope.current_message
  else
    initial = new Date()
    initial.setTime(initial.getTime() + 1000 * 60 * 30)
    setTimeInput(initial)
    $scope.message = 'This is ' + window.user_name + '. If you get this message, I did not get home safely when planned, and I might be in danger. (Do not reply to this message.)'
  $scope.$watch('time', () ->
    time = getTimeInput()
    if time == null
      $scope.time_utc = ''
    else
      $scope.time_utc = String(getTimeInput().getTime())
  )
  $scope.$watch('current_checkpoint', updateCurrentCheckpointView)
  setInterval((() -> $scope.$apply(updateCurrentCheckpointView)), 30000)
  setInterval((() ->
    ajax {
      url: '/status',
      type: 'post',
      success: $scope.updateCurrentCheckpointFromServer,
      scope: $scope
    }
  ), 5000)

  # contacts

  $scope.contacts = window.contacts

  $scope.delete_contact = (data, textStatus, jqXHR) ->
    $scope.contacts = JSON.parse(data.contacts)

  $scope.move_contact_up = (data, textStatus, jqXHR) ->
    $scope.contacts = JSON.parse(data.contacts)

  $scope.move_contact_down = (data, textStatus, jqXHR) ->
    $scope.contacts = JSON.parse(data.contacts)

  $scope.new_contact = (data, textStatus, jqXHR) ->
    $scope.contacts = JSON.parse(data.contacts)
    $scope.contact_name = ''
    $scope.contact_phone = ''
    $('*').blur()
])