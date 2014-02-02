view_index = angular.module('view_index', ['ajax'])

view_index.controller('IndexController', ['$scope', 'ajax', ($scope, ajax, notice) ->
  $scope.signUpValidate = (data, textStatus, jqXHR) ->
    $('#verify_form').submit()
])