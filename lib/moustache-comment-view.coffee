{View} = require 'atom'

module.exports =
class IssueView extends View

  @content: (comment) ->
    @li =>
      @img src:comment.user.avatar_url
      @h4 comment.user.login
      @p comment.body

  initialize: (serializeState) ->
    atom.workspaceView.append(this)

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()
