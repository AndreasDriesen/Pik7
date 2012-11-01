# Default app view
#
# 1. When the app instance is first created, an `Iframe` instance is created and connected
# 2. `connectIframe()` triggers `@init()` on first load
# 3. `connectIframe()` adds an onload event to the iframe, which calls `@connectController()` and `@iframeOnload()`
# 4. `init()` creates a controller from the default state and redirects the iframe to the controller's selected file
# 5. as soon as the iframe loads, `@connectController()` and `@iframeOnload()` fire
# 6. `@connectController()` does many things but mainly connects controller events to actions in the app

define ['lib/emitter','lib/controller', 'lib/iframe', 'lib/hash'], (Emitter, Controller, Iframe, Hash) ->
  return class App extends Emitter


    # Different things need to happen when the iframe loads depending on if this is the
    # first load or a late change of slides, so `@initialized` keeps track of this.
    constructor: (defaults) ->
      super('load')
      window.Pik = app: new Emitter('ready')
      @initialized = no
      @connectIframe(defaults)


    # Connects the iframe to the app. Triggers `@init()` on first load and listens for
    # load notifications from the slides.
    connectIframe: (defaults) ->
      @iframe = new Iframe('iframe')
      if not @initialized then @init(defaults)
      # This would normally be a job for the iframe object's load emitter, but since
      # browsers don't fire load events for iframes reliably, the slides have to publish
      # their load event to the app manually via `window.parent.Pik.app.trigger('load')`
      window.Pik.app.on 'ready', =>
        @trigger('load')
        @connectController()
        controls = @iframe.window.Pik.controls
        controls.on('next', @controller.goNext.bind(@controller))
        controls.on('prev', @controller.goPrev.bind(@controller))
        controls.on('toggleHidden', @controller.toggleHidden.bind(@controller))
        @iframe.do('slide', @controller.getSlide())
        @iframe.do('hidden', @controller.getHidden())


    # Things to do when the controller reports changes. Also needed for init on first load
    # of the frame (see `@init`)
    onFile: (file) ->
      # Check if the iframe already contains our file before triggering a loop of endless
      # reloads...
      if file != @iframe.window.location.href.slice(-file.length)
        @iframe.do('file', file)
    onSlide: (slide) ->
      @iframe.do('slide', slide)
    onHidden: (state) ->
      @iframe.do('hidden', state)


    # On first load, create a temporary controller from the supplied defaults. The
    # temporary controller figures out what the *real* initial state is (apart from the
    # defaults there are also sync and hash as potential data sources) and triggers the
    # first real load of the iframe
    init: (defaults) ->
      @initialized = yes
      @controller = new Controller(defaults)
      @iframe.do('file', @controller.getFile())


    # Throws away the old controller and creates a new from from a fresh state
    connectController: ->
      # Figure out the (short) path to the slides that are loaded into the iframe
      location = window.location.href
      iframeLocation = @iframe.window.location.href
      basePath = Hash::commonPath location, iframeLocation
      slidesPath = iframeLocation.substring(basePath.length, iframeLocation.length)
      # Find out if the current slides are different from the ones that are currently
      # in the controller state. This happens on manual navigation (e.g. via "browse"
      # link) and necessitates that the new `slide` and `hidden` values *must* be
      # default-ish (`0` and `false`) - navigating away from the current slides means a
      # complete reset.
      newFile = slidesPath != @controller.getFile()
      state = {
        file: '/' + slidesPath
        numSlides: @iframe.window.Pik.numSlides
        slide: if newFile then 0 else @controller.getSlide()
        hidden: if newFile then no else @controller.getHidden()
      }
      # Kill the old controller, create and connect a new one
      @disconnectController()
      @controller = new Controller(state)
      @controller.on('file', @onFile.bind(@))
      @controller.on('slide', @onSlide.bind(@))
      @controller.on('hidden', @onHidden.bind(@))


    # Off the current controller (if present)
    disconnectController: ->
      if @controller?
        @controller.offAll()
        @controller = null