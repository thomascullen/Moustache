{View} = require 'atom'

module.exports =
class IssueView extends View

  @content: (issue) ->
    @li class:"moustache-issue", issue:issue.id, =>
      @h4 issue.repository.name
      @h3 issue.title
      @div class:"mt-labels", =>
        @div class:"mt-label", style:"border-color:##{label.color};color:##{label.color}", label.name for label in issue.labels

  initialize: (serializeState) ->
    atom.workspaceView.append(this)

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()
