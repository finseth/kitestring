compile = angular.module('compile', [])

compile.directive('compile', ['$compile', ($compile) ->
  return {
    link: (scope, element, attrs) ->
      scope.$watch(((myscope) ->
        return myscope.$eval(attrs.compile).$$unwrapTrustedValue()
      ), ((value) ->
        element.html(value)
        $compile(element.contents())(scope)
      ))
  }
])
