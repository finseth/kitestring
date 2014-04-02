view_index = angular.module('view_index', ['ajax'])

view_index.controller('IndexController', ['$scope', 'ajax', 'notice', ($scope, ajax, notice) ->
  $scope.signUpValidate = (data, textStatus, jqXHR) ->
    $('#verify_form').submit()

  $scope.forgotPassword = (event) ->
    notice('Text "password" to ' + window.kitestring_phone + ' to reset your password.')
    event.preventDefault()
    event.stopPropagation()
])