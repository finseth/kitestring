notice = angular.module('notice', [])

notice.value('notices', [])

notice.controller('NoticeController', ['$scope', 'notices', ($scope, notices) ->
  $scope.notices = notices
  window.notices = notices

  $('body').keyup((e) ->
    if e.which == 27
      if notices.length > 0
        $scope.$apply () ->
          notices.splice(0, notices.length)
  )

  $scope.close = (event, notice_id) ->
    $scope.notices.splice(notice_id, 1)
    event.preventDefault()
    event.stopPropagation()
])

notice.factory('notice', ['$sce', 'notices', ($sce, notices) ->
  return (message) ->
    if notices.length > 0
      notices.splice(0, notices.length)
    notices.push($sce.trustAsHtml(message))
    return
])
