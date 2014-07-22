{View} = require 'atom'

module.exports =
class IssueView extends View

  @content: (issue) ->
    @li issue:issue.id, =>
      @div class:"moustache-issue-tag-dots", =>
        @div class:"moustache-issue-dot", style:"background:##{label.color}" for label in issue.labels
      @span issue.comments
      @h3 issue.title
      @h4 issue.state

  initialize: (serializeState) ->
    atom.workspaceView.append(this)

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()
