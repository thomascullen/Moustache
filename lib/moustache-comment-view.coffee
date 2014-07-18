{View} = require 'atom'

module.exports =
class IssueView extends View

  @content: (comment) ->
    @li =>
      @img src:"http://api.randomuser.me/portraits/men/69.jpg"
      @h4 comment.user.login
      @p comment.body

  initialize: (serializeState) ->
    atom.workspaceView.append(this)

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()
