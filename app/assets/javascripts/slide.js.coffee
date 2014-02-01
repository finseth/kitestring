slide = angular.module('slide', ['ngAnimate'])

ANIMATION_DURATION = 300

slide.animation('.slide', () ->
  return {
    enter: ((element, done) ->
      $(element).css('max-height', 'none')
      height = $(element).outerHeight()
      $(element).css('max-height', 0)
      $(element).animate({
        'max-height': height
      }, {
        'duration': ANIMATION_DURATION,
        complete: (() ->
          $(element).css('max-height', 'none')
          done()
        )
      })
      return (isCancelled) ->
        if isCancelled
          $(element).stop()
    ),
    removeClass: ((element, className, done) ->
      if className != 'ng-hide'
        return
      $(element).css('max-height', 'none')
      height = $(element).outerHeight()
      $(element).css('max-height', 0)
      $(element).animate({
        'max-height': height
      }, {
        'duration': ANIMATION_DURATION,
        complete: (() ->
          $(element).css('max-height', 'none')
          done()
        )
      })
      return (isCancelled) ->
        if isCancelled
          $(element).stop()
    ),
    leave: ((element, done) ->
      $(element).css('max-height', $(element).outerHeight())
      $(element).animate({
        'max-height': 0
      }, {
        'duration': ANIMATION_DURATION,
        complete: done
      })
      return (isCancelled) ->
        if isCancelled
          $(element).stop()
    ),
    beforeAddClass: ((element, className, done) ->
      if className != 'ng-hide'
        return
      $(element).css('max-height', $(element).outerHeight())
      $(element).animate({
        'max-height': 0
      }, {
        'duration': ANIMATION_DURATION,
        complete: done
      })
      return (isCancelled) ->
        if isCancelled
          $(element).stop()
    )
  }
)
