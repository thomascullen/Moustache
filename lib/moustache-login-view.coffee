{View} = require 'atom'

module.exports =
class MoustacheLoginView extends View

  @content:(state) ->
    @div class: 'moustache-wrapper', id:"moustache-wrapper", =>
      @div id: "moustache-login", =>
        @input type:"text", placeholder:"Github Username", class:"native-key-bindings", id:"moustache-username"
        @input type:"password", placeholder:"Github Password", class:"native-key-bindings", id:"moustache-password"
        @input type:"submit", value:"Login", id:"moustache-login-button"

  initialize: (serializeState) ->


  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
