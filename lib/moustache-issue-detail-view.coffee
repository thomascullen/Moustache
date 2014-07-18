{View} = require 'atom'

MoustacheCommentView = require './moustache-comment-view'

module.exports =
class IssueDetailView extends View

  @content: (issue, repository) ->
    @div id:"mosutache-issue-detail", =>
      @h4 repository.name
      @h3 issue.title
      @ul id:"moustache-issue-labels", =>
        @li style:"border-color:##{label.color};color:##{label.color}", label.name for label in issue.labels
      @p issue.body
      @ul id:"moustache-comments", outlet:"moustacheComments", =>
      @textarea id:"moustache-new-comment", placeholder:"Write a new comment", class:"native-key-bindings"

  initialize: (serializeState) ->
    atom.workspaceView.append(this)

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  renderComments: (comments) ->
    commentsList = @moustacheComments
    Array::forEach.call comments, (comment, i) ->
      commentView = new MoustacheCommentView(comment)
      commentsList.append(commentView)
