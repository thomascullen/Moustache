{View} = require 'atom'

module.exports =
class IssueView extends View

  @content: (comment, animated) ->
    @li class:"clearfix #{animated}", =>
      @img src:comment.user.avatar_url
      @div class:"comment-content", =>
        @div class:"tab"
        @p comment.body

  initialize: (serializeState) ->
    atom.workspaceView.append(this)

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()
