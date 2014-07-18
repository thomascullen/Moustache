{View} = require 'atom'

MoustacheCommentView = require './moustache-comment-view'
moustacheIssue = null
moustacheRepository = null
moustacheGithub = null

module.exports =
class IssueDetailView extends View

  @content: (github, issue, repository) ->
    moustacheIssue = issue
    moustacheRepository = repository
    moustacheGithub = github
    @div id:"moustache-issue-detail", =>
      @button id:"moustache-close-issue", click:"closeIssue", outlet:"closeButton", 'Close Issue'
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

  closeIssue: ->
    moustacheGithub.issues.edit {
      user:moustacheRepository.owner.login,
      repo:moustacheRepository.name,
      number:moustacheIssue.number,
      state:"closed"
      }, (err) ->
        alert "done"
