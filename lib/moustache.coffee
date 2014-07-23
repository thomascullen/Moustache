MoustacheView = require './moustache-view'
MoustacheLoginView = require './moustache-login-view'
MoustacheCommentView = require './moustache-comment-view'
DocStore = require('./JSStorage')
GitHubApi = require "github"
_ = require('underscore')

# Persistant storage
MTDataPath = process.env["HOME"]+"/.atom/packages/moustache/data/"
MTDataRepos = DocStore.collection(MTDataPath+"repositories")
MTDataIssues = DocStore.collection(MTDataPath+"issues")

# Setup github API
github = new GitHubApi( version: "3.0.0" )

moustacheUser = null
MTCurrentIssues = []
MTCurrentRepo = null
MTState = "open"

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
  @repository_id = issue.repository.id
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

MTIssues = []
MTSyncIssues = (page, callback) ->
  github.issues.getAll { state:"all", filter:"all", per_page:100, page:page }, (err, issues) ->
    console.log err if err

    if issues.length > 0
      Array::forEach.call issues, (issue, i) ->
        MTIssues.push(new MTIssue(issue))

      MTSyncIssues(page+1, callback)
    else
      MTDataIssues.objects = MTIssues
      MTDataIssues.sync()
      callback()

MTRepos = []
MTSyncRepos = (callback) ->
  github.repos.getAll {}, (err, repos) ->
    console.log err if err
    Array::forEach.call repos, (repo, i) ->
      MTRepos.push(new MTRepo(repo))
    MTDataRepos.objects = MTRepos
    MTDataRepos.sync()
    callback()

module.exports =
  currentview: null
  username: null

  sync: ->
    _view = @currentView
    console.log "Moustache Syncing Issues"

    _view.startIssuesLoading() unless MTDataIssues.objects.length > 0

    MTSyncIssues 1, ->
      console.log "Finished Syncing Issues"
      _view.renderIssues(MTDataIssues.objects) unless MTCurrentIssues.length > 0

    MTSyncRepos ->
      _view.renderRepos(MTDataRepos.objects)

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

    # Toggle Issue State
    @currentView.on "click", "#moustache-toggle-issue-state", (e) ->
      id = parseInt(e.currentTarget.getAttribute('issue'))
      _this.toggleIssueState(id)

    # New Comment
    # @currentView.on "keyup", "#moustache-new-comment", (e) ->
    #   if e.keyCode == 13
    #
    #     content = document.getElementById("moustache-new-comment").value
    #     document.getElementById("moustache-new-comment").value = ""
    #
    #     # create the issue comment
    #     github.issues.createComment {
    #       user:moustacheRepo.owner.login,
    #       repo:moustacheRepo.name,
    #       number:moustacheIssue.number,
    #       body: content }, (err, issues) ->
    #         console.log err if err
    #
    #     # Create a new comment object
    #     # This is the same structure as returned
    #     # from the github issues api comments call
    #     comment =
    #       user:
    #         login: "Current User"
    #       body: content
    #
    #     # Render the new comment
    #     commentView = new MoustacheCommentView(comment)
    #     _currentView.find("#moustache-comments").append(commentView)

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

      # Fetch the current user if there isnt one
      unless moustacheUser
        # get the users information
        github.user.get {}, (err, user) ->
          moustacheUser = user # store user
          _currentView.renderUser(moustacheUser)
      else
        # Render the current user section
        _currentView.renderUser(moustacheUser)

      _this.load()

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

  load: ->
    _view = @currentView
    _view.renderRepos(MTDataRepos.objects)

    MTCurrentIssues = MTDataIssues.where ( {state:MTState} )
    _view.renderIssues(MTCurrentIssues)

    this.sync()

  viewRepo: (id) ->
    _view = @currentView
    MTState = "open"
    _view.find("#moustache-issues").html("") # Clear issues view
    _view.find("#moustache-moustache-main-view").html("") # Clear main view
    _view.find("#moustache-issue-filters ul li").removeClass("current")
    _view.find("#moustache-issue-filters ul li").first().addClass("current")

    # if an index was passed then fetch that repo from the moustacheRepositories array.
    # Otherwise assume they have selected all issues and load all issues
    if id
      MTCurrentRepo = MTDataRepos.find({id:id})
      MTCurrentIssues = MTDataIssues.where( {state:MTState, repository_id:id} )
    else
      MTCurrentRepo = null
      MTCurrentIssues = MTDataIssues.where( {state:MTState} )

    _view.renderIssues(MTCurrentIssues)

  viewIssue: (id) ->
    _view = @currentView
    issue = MTDataIssues.find({id:id})
    _view.renderIssue(github, issue) # render the issue

  filterIssues: (state) ->
    _view = @currentView
    MTState = state

    if MTCurrentRepo
      issues = MTDataIssues.where( {repository_id:MTCurrentRepo.id})
    else
      issues = MTDataIssues.getAll()

    if state == "all"
      MTCurrentIssues = issues
    else
      MTCurrentIssues = _.where(issues, {state:state})

    _view.renderIssues(MTCurrentIssues)

  toggleIssueState: (id) ->
    _view = @currentView
    # Remove issue from list view as state has changed
    _view.find(".moustache-issue[issue=#{id}]").remove()

    issue = MTDataIssues.find({id:id})

    if issue.state == "open"
      _view.find('#moustache-toggle-issue-state').addClass("open").text("Reopen Issue")

      issue.state = "closed"
      MTDataIssues.replace({id:id}, issue)

      github.issues.edit {
        user:issue.repository.owner.login,
        repo:issue.repository.name,
        number:issue.number,
        state:"closed"
        }, (err) ->
          console.log "Issue closed"
    else
      _view.find('#moustache-toggle-issue-state').removeClass("open").text("Close Issue")

      issue.state = "open"
      MTDataIssues.replace({id:id}, issue)

      github.issues.edit {
        user:issue.repository.owner.login,
        repo:issue.repository.name,
        number:issue.number,
        state:"open"
        }, (err) ->
          console.log "Issue re opened"
