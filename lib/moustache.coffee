MoustacheView = require './moustache-view'
MoustacheLoginView = require './moustache-login-view'
MoustacheCommentView = require './moustache-comment-view'
GitHubApi = require "github"
github = new GitHubApi( version: "3.0.0" )
moustacheRepositories = null
moustacheIssues = null
moustacheRepo = null
moustacheIssue = null

module.exports =
  currentview: null
  username: null

  activate: (state) ->
    atom.workspaceView.command "moustache:toggle", => @toggle()

  deactivate: ->
    @currentView.destroy()

  serialize: ->
    moustacheViewState: @currentview.serialize()

  listeners: ->
    _this = this
    _currentView = @currentView

    # Login
    @currentView.on "click", "#moustache-login-button", ->
      username = document.getElementById("moustache-username").value
      password = document.getElementById("moustache-password").value
      _this.login(username, password)

    # Logout
    @currentView.on "click", "#moustache-logout", (e) ->
      _this.logout()

    # View Repo
    @currentView.on "click", "#moustache-repos li", (e) ->
      _currentView.find("#moustache-repos li").removeClass "current"
      e.currentTarget.classList.add("current")
      _this.viewRepo(e.currentTarget.getAttribute('index'))

    # View Issue
    @currentView.on "click", "#moustache-issues li", (e) ->
      _this.viewIssue(e.currentTarget.getAttribute('index'))

    # New Comment
    @currentView.on "keyup", "#moustache-new-comment", (e) ->
      if e.keyCode == 13

        content = document.getElementById("moustache-new-comment").value
        document.getElementById("moustache-new-comment").value = ""

        github.issues.createComment {
          user:moustacheRepo.owner.login,
          repo:moustacheRepo.name,
          number:moustacheIssue.number,
          body: content }, (err, issues) ->
            console.log "Moustache: Finished posting comment"

        comment =
          user:
            login: "Current User"
          body: content

        commentView = new MoustacheCommentView(comment)
        _currentView.find("#moustache-comments").append(commentView)

  toggle: ->
    _this = this

    if @currentView
      @currentView.destroy()
      @currentView = null
    else
      @username = window.localStorage.getItem("github-username")
      password = window.localStorage.getItem("github-password")

      if @username && password
        _this.login(@username, password)
      else
        @currentView = new MoustacheLoginView()
        atom.workspaceView.append(@currentView)

      _this.listeners()

  login: (username, password) ->
    _this = this

    if username.length > 0 && password.length > 0
      console.log "Moustache: Logging In"

      window.localStorage.setItem("github-username", username)
      window.localStorage.setItem("github-password", password)

      @currentView.destroy() if @currentView

      github.authenticate
        type: "basic"
        username: username
        password: password

      @currentView = new MoustacheView()
      atom.workspaceView.append(@currentView)
      @currentView.renderRepos(moustacheRepositories) if moustacheRepositories
      @currentView.renderIssues(moustacheIssues) if moustacheIssues
      _this.loadData()
    else
      alert "Please enter a valid username & password"

  logout: ->
    window.localStorage.removeItem("github-username")
    window.localStorage.removeItem("github-password")
    @currentView.destroy()
    @currentView = new MoustacheLoginView()
    atom.workspaceView.append(@currentView)

  loadData: ->
    _view = @currentView
    github.repos.getAll {}, (err, repos) ->
      _view.renderRepos(repos) if repos
      moustacheRepositories = repos if repos
      console.log err if err
    github.issues.getAll { page:1, per_page:100 }, (err, issues) ->
      _view.renderIssues(issues) if issues
      moustacheIssues = issues if issues
      console.log err if err

  viewRepo: (i) ->
    _view = @currentView
    _view.find("#moustache-issues").html("")
    _view.find("#moustache-moustache-main-view").html("")
    repository = moustacheRepositories[i]
    moustacheRepo = repository
    github.issues.repoIssues { user:repository.owner.login, repo:repository.name }, (err, issues) ->
      _view.renderIssues(issues) if issues
      moustacheIssues = issues if issues
      console.log err if err

  viewIssue: (i) ->
    _view = @currentView
    issue = moustacheIssues[i]
    moustacheIssue = issue
    moustacheRepo = issue.repository if issue.repository
    _view.renderIssue(github, issue, moustacheRepo)
