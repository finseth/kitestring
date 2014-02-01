form = angular.module('form', [])

form.directive('ksForm', ['ajax', (ajax) ->
  return {
    link: (scope, element, attrs) ->
      element.submit (event) ->
        button = element.find('input[type=submit]')
        event.preventDefault()
        if !button? || !button.hasClass('disabled')
          event.stopPropagation()
          button.addClass('disabled')
          form_submitted = true
          data = {}
          element.find('input, textarea, select').each (index) ->
            if !$(this).is('input[type=submit]')
              data[$(this).attr('name')] = $(this).val()
          ajax {
            url: element.attr('action'),
            type: element.attr('method'),
            data: data,
            success: scope[attrs['ksForm']],
            complete: ((data) -> button.removeClass('disabled')),
            scope: scope
          }
  }
])
