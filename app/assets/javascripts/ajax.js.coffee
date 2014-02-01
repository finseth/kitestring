ajax = angular.module('ajax', ['notice'])

ajax.factory('ajax', ['notice', (notice) ->
  # options: { url, type, data, success, error, complete, scope }
  return (options) ->
    if !options.url then throw 'ajax call missing url'
    if !options.type? then options.type = 'get'
    if !options.data? then options.data = {}
    if !options.success? then options.success = (->)
    if !options.error? then options.error = (->)
    if !options.complete? then options.complete = (->)
    if !options.scope? then options.scope = { $apply: (fn) -> fn() }

    success_wrapper = (data, textStatus, jqXHR) ->
      if data.notice?
        notice(data.notice)
      if data.location?
        window.location.href = data.location
      if data.reload?
        window.location.reload()
      if !data.success
        return options.error(data, textStatus, jqXHR)
      return options.success(data, textStatus, jqXHR)

    $.ajax {
      url: options.url,
      type: options.type,
      data: options.data,
      success: (data, textStatus, jqXHR) -> options.scope.$apply(() -> success_wrapper(data, textStatus, jqXHR)),
      error: (jqXHR, textStatus, errorThrown) -> options.scope.$apply(() -> options.error(jqXHR, textStatus, errorThrown)),
      complete: (jqXHR, textStatus) -> options.scope.$apply(() -> options.complete(jqXHR, textStatus)),
    }
    return
])
