require ['lib/vendor/almond',
         'app', 'slides',
         'jquery', 'prefixfree'], (_almond, App, Slides) ->

  # If the page looks like an app frame, it's probably just that
  if $('#Pik-Frame').length > 0
    app = new App()
    console.log app


  # otherwise it's obviously a slide set
  else
    console.log 'Präsi!'