form = angular.module('anchor', [])

form.directive('ksNamedAnchor', [() ->
  return {
    link: (scope, element, attrs) ->
      element.click (event) ->
        target = $($(this).attr('href'))
        event.preventDefault()
        event.stopPropagation()
        scrollElement = 'html, body'
        if documentElement?
          scrollElement = documentElement
        $(scrollElement).animate(
          { scrollTop: target.offset().top },
          500,
          'swing',
          (() -> target.find(".focus-target").focus())
        )
  }
])

form.directive('ksPostAnchor', ['ajax', (ajax) ->
  return {
    link: (scope, element, attrs) ->
      element.click (event) ->
        event.preventDefault()
        event.stopPropagation()
        ajax {
          url: $(this).attr('href'),
          type: 'post',
          success: scope[attrs['ksPostAnchor']],
          scope: scope
        }
  }
])
