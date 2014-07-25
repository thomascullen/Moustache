{View} = require 'atom'

module.exports =
class MoustacheLoginView extends View

  @content:(state) ->
    @div class: 'moustache-wrapper login-wrapper', id:"moustache-wrapper", =>
      @div id: "moustache-login", =>
        @h2 'Sign In'
        @input type:"text", placeholder:"Github Username", class:"native-key-bindings", id:"moustache-username"
        @input type:"password", placeholder:"Github Password", class:"native-key-bindings", id:"moustache-password"
        @input type:"submit", value:"Login", id:"moustache-login-button"
        @div id:"mt-logo"

  initialize: (serializeState) ->
    atom.workspaceView.find('.horizontal').first().addClass("blur")

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
