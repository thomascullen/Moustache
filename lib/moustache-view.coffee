{View} = require 'atom'
MoustacheRepoView = require './moustache-repo-view'
MoustacheIssueView = require './moustache-issue-view'
MoustacheIssueDetailView = require './moustache-issue-detail-view'
path = atom.packages.packageDirPaths[0] + "/moustache/"

module.exports =
class MoustacheView extends View

  @content: ->
    @div id:"moustache-wrapper", =>
      @div id: "moustache", =>
        @div id: "moustache-sidebar", =>
          @div id: "moustache-user", outlet:"moustacheUser", =>
            @img src: ""
            @h2 "Username"
            @span id: "moustache-logout", "Logout"
          @h4 'Repositories'
          @ul id:"moustache-repos", outlet:"moustacheRepos", =>
            @li class:"current", =>
              @p "All Issues"
        @div id:"moustache-issues-wrapper", =>
          @div id:"moustache-issue-filters", =>
            @ul =>
              @li "Open"
              @li "Closed"
              @li "All"
            @button id:"moustache-new-issue", 'New Issue'
          @ul id:"moustache-issues", outlet:"moustacheIssues", =>
        @div id:"moustache-main-view", outlet:"moustacheMainView", =>
  initialize: (serializeState) ->
    atom.workspaceView.append(this)

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  startIssuesLoading: ->
    @moustacheIssues.css('background',"url("+path+"stylesheets/loading.gif"+") no-repeat center");

  stopIssuesLoading: ->
    @moustacheIssues.css('background',"white");

  renderRepos: (repos) ->
    reposList = @moustacheRepos
    Array::forEach.call repos, (repo, i) ->
      repoView = new MoustacheRepoView(repo, i)
      reposList.append(repoView)

  renderIssues: (issues) ->
    issuesList = @moustacheIssues
    issuesList.html("")
    Array::forEach.call issues, (issue, i) ->
      issueView = new MoustacheIssueView(issue, i)
      issuesList.append(issueView)

  renderIssue: (github, issue, repository) ->
    mainView = @moustacheMainView
    issueDetailView = new MoustacheIssueDetailView(github, issue, repository)
    mainView.html(issueDetailView)
    issueDetailView.startCommentsLoading()
    github.issues.getComments { user:repository.owner.login, repo:repository.name, number:issue.number }, (err,comments) ->
      issueDetailView.renderComments(comments)

  renderUser: (user) ->
    @moustacheUser.find('img').attr('src', user.avatar_url)
    @moustacheUser.find("h2").text(user.login)
