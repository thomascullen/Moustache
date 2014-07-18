{View} = require 'atom'

module.exports =
class IssueView extends View

  @content: (issue, index) ->
    @li index:index, =>
      @div class:"moustache-issue-tag-dots", =>
        @div class:"moustache-issue-dot", style:"background:##{label.color}" for label in issue.labels
      @span issue.comments
      @h3 issue.title
      @p issue.body.substring(0,160)

  initialize: (serializeState) ->
    atom.workspaceView.append(this)

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()
