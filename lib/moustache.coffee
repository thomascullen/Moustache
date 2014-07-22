MoustacheView = require './moustache-view'
MoustacheLoginView = require './moustache-login-view'
MoustacheCommentView = require './moustache-comment-view'

# Setup github API
GitHubApi = require "github"
github = new GitHubApi( version: "3.0.0" )

moustacheRepositories = null
moustacheIssues = null
moustacheRepo = null
moustacheIssue = null
moustacheUser = null

MTIssues = []
MTRepos = []
MTCurrentIssues = []
MTCurrentRepo = null
MTState = "open"

# method to fetch a single issue
MTIssues.get = (id) ->
  i = 0
  issue = undefined
  while i < MTIssues.length
    if parseInt(MTIssues[i].id) == id
      issue = MTIssues[i]
      break
    i++
  return issue

MTRepos.get = (id) ->
  i = 0
  repo = undefined
  while i < MTRepos.length
    if parseInt(MTRepos[i].id) == id
      repo = MTRepos[i]
      break
    i++
  return repo

# Issue Class
MTIssue = (issue) ->
  @id = issue.id
  @number = issue.number
  @title = issue.title
  @state = issue.state
  @comments = issue.comments
  @body = issue.body
  @labels = issue.labels
  @repository = issue.repository
  return

# Repo Class
MTRepo = (repo) ->
  @id = repo.id
  @name = repo.name
  @open_issues = repo.open_issues

  @getIssues = ->
    i = 0
    issues = []
    repoID = parseInt(repo.id)
    while i < MTIssues.length
      if parseInt(MTIssues[i].repository.id) == repoID
        issues.push(MTIssues[i])
      i++
    return issues

  return

# Filter issues
MTFilter = (state, repo) ->

  MTState = state

  if repo
    MTCurrentIssues = repo.getIssues()
  else
    MTCurrentIssues = MTIssues

  if state == "all"
    return MTCurrentIssues

  i = 0
  issues = []
  while i < MTCurrentIssues.length
    if MTCurrentIssues[i].state == state
      issues.push(MTCurrentIssues[i])
    i++
  return issues

MTSyncIssues = (page, callback) ->
  console.log "Getting issues page : #{page}"
  github.issues.getAll { state:"all", filter:"all", per_page:100, page:page }, (err, issues) ->
    console.log err if err

    if issues.length > 0
      # Store each issue
      Array::forEach.call issues, (issue, i) ->
        MTIssues.push(new MTIssue(issue))

      MTSyncIssues(page+1, callback)
    else
      callback()

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
      _this.viewRepo(parseInt(e.currentTarget.getAttribute('repo')))

    # View Issue
    @currentView.on "click", "#moustache-issues li", (e) ->
      _currentView.find("#moustache-issues li").removeClass "current"
      e.currentTarget.classList.add("current")
      _this.viewIssue(parseInt(e.currentTarget.getAttribute('issue')))

    # Filter issues
    @currentView.on "click", "#moustache-issue-filters ul li", (e) ->
      _currentView.find("#moustache-issue-filters ul li").removeClass "current"
      e.currentTarget.classList.add("current")
      _this.filterIssues(e.currentTarget.textContent.toLowerCase())

    # Close Repo
    @currentView.on "click", "#moustache-toggle-issue-state", (e) ->
      id = parseInt(e.currentTarget.getAttribute('issue'))
      issue = MTIssues.get(id)
      _this.toggleIssueState(issue)

    # New Comment
    @currentView.on "keyup", "#moustache-new-comment", (e) ->
      if e.keyCode == 13

        content = document.getElementById("moustache-new-comment").value
        document.getElementById("moustache-new-comment").value = ""

        # create the issue comment
        github.issues.createComment {
          user:moustacheRepo.owner.login,
          repo:moustacheRepo.name,
          number:moustacheIssue.number,
          body: content }, (err, issues) ->
            console.log err if err

        # Create a new comment object
        # This is the same structure as returned
        # from the github issues api comments call
        comment =
          user:
            login: "Current User"
          body: content

        # Render the new comment
        commentView = new MoustacheCommentView(comment)
        _currentView.find("#moustache-comments").append(commentView)

  toggle: ->
    _this = this

    # If the moustache view is open then remove it
    if @currentView
      @currentView.toggle()
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

      # Store the username & password in localstorage
      window.localStorage.setItem("github-username", username)
      window.localStorage.setItem("github-password", password)

      # Destroy any current views there might be
      @currentView.destroy() if @currentView

      # Authenticate the github API
      github.authenticate
        type: "basic"
        username: username
        password: password

      # Create a new main moustache view
      @currentView = new MoustacheView()
      _currentView = @currentView
      atom.workspaceView.append(@currentView)

      # Render any previously stored repositories or issues
      @currentView.renderRepos(moustacheRepositories) if moustacheRepositories
      @currentView.renderIssues(moustacheIssues) if moustacheIssues

      # Fetch new data from github
      _this.loadData()

      # Fetch the current user if there isnt one
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
    # Remove the username & password from localstorage
    window.localStorage.removeItem("github-username")
    window.localStorage.removeItem("github-password")
    # Destroy the current view
    @currentView.destroy()
    # Show the login form
    @currentView = new MoustacheLoginView()
    atom.workspaceView.append(@currentView)

  loadData: ->
    _view = @currentView

    _view.startIssuesLoading unless MTCurrentIssues.length > 0

    # Render the repos
    _view.renderRepos(MTRepos)

    if MTRepos.length > 0
      _view.renderRepos(MTRepos)
    else
      # Fetch all the users repositories
      github.repos.getAll {}, (err, repos) ->
        console.log err if err

        # upate the repos
        Array::forEach.call repos, (repo, i) ->
          MTRepos.push(new MTRepo(repo))

        # Refresh the repos
        _view.renderRepos(MTRepos)


    # Render the current Issues
    _view.renderIssues(MTCurrentIssues) if MTCurrentIssues.length > 0

    unless MTIssues.length > 1
      _view.startIssuesLoading()
      # Fetch all of the users issues
      MTSyncIssues 1, ->
        # If there isnt already a selected issue set then load all
        unless MTCurrentIssues.length > 1
          MTCurrentIssues = MTIssues
          MTCurrentIssues = MTFilter(MTState)
          _view.renderIssues(MTCurrentIssues)

        # Stop any loading animation
        _view.stopIssuesLoading()
    else
      MTCurrentIssues = MTIssues
      MTCurrentIssues = MTFilter(MTState)
      _view.renderIssues(MTCurrentIssues)

  viewRepo: (id) ->
    _view = @currentView
    _view.find("#moustache-issues").html("") # Clear issues view
    _view.find("#moustache-moustache-main-view").html("") # Clear main view
    _view.find("#moustache-issue-filters ul li").removeClass("current")
    _view.find("#moustache-issue-filters ul li").first().addClass("current")

    # if an index was passed then fetch that repo from the moustacheRepositories array.
    # Otherwise assume they have selected all issues and load all issues
    if id
      MTCurrentRepo = MTRepos.get(id)
    else
      MTCurrentRepo = null

    MTCurrentIssues = MTFilter("open", MTCurrentRepo)
    _view.renderIssues(MTCurrentIssues)

  viewIssue: (id) ->
    _view = @currentView
    issue = MTIssues.get(id)
    _view.renderIssue(github, issue) # render the issue

  filterIssues: (state) ->
    _view = @currentView
    MTCurrentIssues = MTFilter(state, MTCurrentRepo)
    _view.renderIssues(MTCurrentIssues)

  toggleIssueState: (issue) ->
    _view = @currentView
    if issue.state == "open"
      _view.find('#moustache-toggle-issue-state').addClass("open").text("Reopen Issue")
      github.issues.edit {
        user:issue.repository.owner.login,
        repo:issue.repository.name,
        number:issue.number,
        state:"closed"
        }, (err) ->
          console.log "Issue closed"
    else
      _view.find('#moustache-toggle-issue-state').removeClass("open").text("Close Issue")
      github.issues.edit {
        user:issue.repository.owner.login,
        repo:issue.repository.name,
        number:issue.number,
        state:"open"
        }, (err) ->
          console.log "Issue re opened"