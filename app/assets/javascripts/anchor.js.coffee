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
        if !element.hasClass('disabled')
          element.addClass('disabled')
          event.stopPropagation()
          ajax {
            url: $(this).attr('href'),
            type: 'post',
            success: scope[attrs['ksPostAnchor']],
            complete: (() -> element.removeClass('disabled')),
            scope: scope
          }
  }
])
