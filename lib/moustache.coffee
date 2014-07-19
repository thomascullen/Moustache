MoustacheView = require './moustache-view'
MoustacheLoginView = require './moustache-login-view'
MoustacheCommentView = require './moustache-comment-view'
GitHubApi = require "github"
github = new GitHubApi( version: "3.0.0" )
moustacheRepositories = null
moustacheIssues = null
moustacheRepo = null
moustacheIssue = null
moustacheUser = null

module.exports =
  currentview: null
  username: null

  activate: (state) ->
    atom.workspaceView.command "moustache:toggle", => @toggle()
    atom.workspaceView.command "moustache:new_issue", => @newIssue()

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
      _currentView.find("#moustache-main-view").html("")
      _currentView.find("#moustache-repos li").removeClass "current"
      e.currentTarget.classList.add("current")
      _this.viewRepo(e.currentTarget.getAttribute('index'))

    # View Issue
    @currentView.on "click", "#moustache-issues li", (e) ->
      _currentView.find("#moustache-issues li").removeClass "current"
      e.currentTarget.classList.add("current")
      _this.viewIssue(e.currentTarget.getAttribute('index'))

    # Filter issues
    @currentView.on "click", "#moustache-issue-filters ul li", (e) ->
      _currentView.find("#moustache-issue-filters ul li").removeClass "current"
      e.currentTarget.classList.add("current")
      _this.filterIssues(e.currentTarget.textContent.toLowerCase())

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

    # If the moustache view is open then remove it
    if @currentView
      @currentView.destroy()
      @currentView = null
    else
      @username = window.localStorage.getItem("github-username")
      password = window.localStorage.getItem("github-password")

      # If there is a username & password then proceed with login
      if @username && password
        _this.login(@username, password)
      else
        # present login form
        @currentView = new MoustacheLoginView()
        atom.workspaceView.append(@currentView)

      # Attach moustache listeners
      _this.listeners()

  login: (username, password) ->
    _this = this

    if username.length > 0 && password.length > 0
      console.log "Moustache: Logging In"

      # Save username and password in localstorage
      window.localStorage.setItem("github-username", username)
      window.localStorage.setItem("github-password", password)

      @currentView.destroy() if @currentView

      # Authenticate github API
      github.authenticate
        type: "basic"
        username: username
        password: password

      # Render the main moustache view
      @currentView = new MoustacheView()
      _currentView = @currentView
      atom.workspaceView.append(@currentView)

      # Render any previously loaded repositories & issues
      @currentView.renderRepos(moustacheRepositories) if moustacheRepositories
      @currentView.renderIssues(moustacheIssues) if moustacheIssues

      # Fetch data from github
      _this.loadData()

      # unless there is already a current user
      unless moustacheUser
        # get the users information
        github.user.get {}, (err, user) ->
          moustacheUser = user # store user
          _currentView.renderUser(moustacheUser)
      else
        # Render the current user section
        _currentView.renderUser(moustacheUser)

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

    # Get repositories
    github.repos.getAll {}, (err, repos) ->
      moustacheRepositories = repos if repos # update the stored repos
      _view.renderRepos(repos) if repos # render the repos
      console.log err if err

    # Get issues
    github.issues.getAll { state:"open" }, (err, issues) ->
      _view.stopIssuesLoading()
      _view.renderIssues(issues) if issues
      moustacheIssues = issues if issues
      console.log err if err

  viewRepo: (i) ->
    _view = @currentView
    _view.find("#moustache-issues").html("")
    _view.find("#moustache-moustache-main-view").html("")
    _view.find("#moustache-issue-filters ul li").removeClass("current")
    _view.find("#moustache-issue-filters ul li").first().addClass("current")
    _view.startIssuesLoading()

    if i
      repository = moustacheRepositories[i]
      moustacheRepo = repository
      github.issues.repoIssues { user:repository.owner.login, repo:repository.name }, (err, issues) ->
        _view.stopIssuesLoading()
        _view.renderIssues(issues) if issues
        moustacheIssues = issues if issues
        console.log err if err
    else
      moustacheRepo = null
      github.issues.getAll {}, (err, issues) ->
        _view.stopIssuesLoading()
        _view.renderIssues(issues) if issues
        moustacheIssues = issues if issues
        console.log err if err

  viewIssue: (i) ->
    _view = @currentView
    issue = moustacheIssues[i]
    moustacheIssue = issue
    moustacheRepo = issue.repository if issue.repository
    _view.renderIssue(github, issue, moustacheRepo)

  filterIssues: (filter) ->
    _view = @currentView
    _view.startIssuesLoading()

    if moustacheRepo
      github.issues.repoIssues { user:moustacheRepo.owner.login, repo:moustacheRepo.name, state:filter }, (err, issues) ->
        _view.stopIssuesLoading()
        _view.renderIssues(issues) if issues
        moustacheIssues = issues if issues
        console.log err if err
    else
      github.issues.getAll { state:filter }, (err, issues) ->
        _view.stopIssuesLoading()
        _view.renderIssues(issues) if issues
        moustacheIssues = issues if issues
        console.log err if err
