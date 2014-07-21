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

MTIssue = (title, state) ->
  @title = title
  @state = state
  return

MTRepo = (name, open_issues) ->
  @name = name
  @open_issues = open_issues

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

    # Fetch all the users repositories
    github.repos.getAll {}, (err, repos) ->

      Array::forEach.call repos, (repo, i) ->
        MTRepos.push(new MTRepo(repo.name, repo.open_issues))

      moustacheRepositories = repos if repos # update the stored repos
      _view.renderRepos(repos) if repos # render the repos
      console.log err if err

    # Fetch all of the users open issues
    github.issues.getAll { state:"open", filter:"all" }, (err, issues) ->

      Array::forEach.call issues, (issue, i) ->
        MTIssues.push(new MTIssue(issue.title, issue.state))

      _view.stopIssuesLoading()
      _view.renderIssues(issues) if issues
      moustacheIssues = issues if issues
      console.log err if err

  viewRepo: (index) ->
    _view = @currentView
    _view.find("#moustache-issues").html("") # Clear issues view
    _view.find("#moustache-moustache-main-view").html("") # Clear main view
    _view.find("#moustache-issue-filters ul li").removeClass("current")
    _view.find("#moustache-issue-filters ul li").first().addClass("current")
    _view.startIssuesLoading() # Show loading animation

    # if an index was passed then fetch that repo from the moustacheRepositories array.
    # Otherwise assume they have selected all issues and load all issues
    if index
      repository = moustacheRepositories[index]
      moustacheRepo = repository # Set the current repository
      # Fetch reposiroies issues
      github.issues.repoIssues { user:repository.owner.login, repo:repository.name }, (err, issues) ->
        _view.stopIssuesLoading() # Stop loading animation
        _view.renderIssues(issues) if issues # render the issues
        moustacheIssues = issues if issues # store the issues
        console.log err if err
    else
      moustacheRepo = null
      # Geth all the users issues
      github.issues.getAll {}, (err, issues) ->
        _view.stopIssuesLoading() # stop loading animation
        _view.renderIssues(issues) if issues # render the issues
        moustacheIssues = issues if issues #store the issues
        console.log err if err

  viewIssue: (index) ->
    _view = @currentView
    issue = moustacheIssues[index] # Get the issues from the stored issues array
    moustacheIssue = issue # Set the current issue
    moustacheRepo = issue.repository if issue.repository # set the current repo if there is one
    _view.renderIssue(github, issue, moustacheRepo) # render the issue

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
