# enable fastclick
$ -> FastClick.attach(document.body)

# application module
kitestring = angular.module('kitestring', ['notice', 'slide', 'compile', 'form', 'anchor', 'view_index', 'view_home'])

kitestring.run(['notice', (notice) ->
  $('.focus-now').focus()

  for msg in window.flash_notices
    notice(msg)
])