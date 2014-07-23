{View} = require 'atom'
markdown = require( "markdown" ).markdown
MoustacheCommentView = require './moustache-comment-view'
MTIssue = null
moustacheRepository = null
MTGithub = null
path = atom.packages.packageDirPaths[0] + "/moustache/"

module.exports =
class IssueDetailView extends View

  @content: (issue) ->
    MTIssue = issue
    @div id:"moustache-issue-detail", =>
      @button id:"moustache-toggle-issue-state", issue:issue.id, outlet:"toggleButton", ''
      @h4 issue.repository.name
      @h3 issue.title
      @div class:"mt-labels", =>
          @div class:"mt-label", style:"border-color:##{label.color};color:##{label.color}", label.name for label in issue.labels
      @p outlet:"moustacheDescription", id:"moustache-description", issue.body
      @ul id:"moustache-comments", outlet:"moustacheComments", =>
      @textarea id:"moustache-new-comment", placeholder:"Write a new comment", class:"native-key-bindings"

  initialize: (serializeState) ->
    atom.workspaceView.append(this)
    @moustacheDescription.html( markdown.toHTML( @moustacheDescription.text() ) )

    _toggleButton = @toggleButton
    if MTIssue.state == "open"
      _toggleButton.text("Close Issue")
    else
      _toggleButton.addClass("open").text("Reopen Issue")

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  startCommentsLoading: ->
    @moustacheComments.css('background',"url("+path+"stylesheets/loading.gif"+") no-repeat center");

  stopCommentsLoading: ->
    @moustacheComments.css({background:'white',minHeight:0});

  renderComments: (comments) ->
    _this = this
    this.stopCommentsLoading();
    Array::forEach.call comments, (comment, i) ->
      _this.renderComment(comment, false)

  renderComment: (comment, animated) ->
    commentView = new MoustacheCommentView(comment, animated)
    @moustacheComments.append(commentView)
