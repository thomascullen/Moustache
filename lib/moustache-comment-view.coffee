{View} = require 'atom'

module.exports =
class IssueView extends View

  @content: (comment) ->
    @li =>
      @img src:comment.user.avatar_url
      @div class:"comment-content", =>
        @p comment.body

  initialize: (serializeState) ->
    atom.workspaceView.append(this)

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()
