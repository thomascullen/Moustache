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

MTCurrentUser = null
MTCurrentIssues = []
MTCurrentRepo = null
MTCurrentIssue = null
MTCurrentView = null
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
  currentView: null

  sync: ->
    console.log "Moustache Syncing Issues"

    MTCurrentView.startIssuesLoading() unless MTDataIssues.objects.length > 0

    MTSyncIssues 1, ->
      console.log "Finished Syncing Issues"
      MTCurrentView.renderIssues(MTDataIssues.objects) unless MTCurrentIssues.length > 0

    MTSyncRepos ->
      MTCurrentView.renderRepos(MTDataRepos.objects)

  activate: (state) ->
    atom.workspaceView.command "moustache:toggle", => @toggle()

  deactivate: ->
    @currentView.destroy()

  serialize: ->
    moustacheViewState: @currentview.serialize()

  listeners: ->
    _this = this

    # Login
    MTCurrentView.on "click", "#moustache-login-button", ->
      _this.login()

    # Logout
    MTCurrentView.on "click", "#moustache-logout", (e) ->
      _this.logout()

    # View Repo
    MTCurrentView.on "click", "#moustache-repos li", (e) ->
      MTCurrentView.find("#moustache-repos li").removeClass "current"
      e.currentTarget.classList.add("current")
      _this.viewRepo(parseInt(e.currentTarget.getAttribute('repo')))

    # View Issue
    MTCurrentView.on "click", "#moustache-issues li", (e) ->
      MTCurrentView.find("#moustache-issues li").removeClass "current"
      e.currentTarget.classList.add("current")
      _this.viewIssue(parseInt(e.currentTarget.getAttribute('issue')))

    # username field tab fix
    MTCurrentView.on "keyup", "#moustache-username", (e) ->
      if e.keyCode == 9
        atom.workspaceView.find('#moustache-password').focus()

    # submit login with return
    MTCurrentView.on "keydown", "#moustache-password", (e) ->
      if e.keyCode == 13
        _this.login()

    # Filter issues
    MTCurrentView.on "click", "#moustache-issue-filters ul li", (e) ->
      MTCurrentView.find("#moustache-issue-filters ul li").removeClass "current"
      e.currentTarget.classList.add("current")
      _this.filterIssues(e.currentTarget.textContent.toLowerCase())

    # Toggle Issue State
    MTCurrentView.on "click", "#moustache-toggle-issue-state", (e) ->
      id = parseInt(e.currentTarget.getAttribute('issue'))
      _this.toggleIssueState(id)

    # New Comment
    MTCurrentView.on "keyup", "#moustache-new-comment", (e) ->
      if e.keyCode == 13

        content = document.getElementById("moustache-new-comment").value
        document.getElementById("moustache-new-comment").value = ""

        # create the issue comment
        github.issues.createComment {
          user:MTCurrentIssue.repository.owner.login,
          repo:MTCurrentIssue.repository.name,
          number:MTCurrentIssue.number,
          body: content }, (err, issues) ->
            console.log err if err

        # Create a new comment object
        comment =
          user:
            avatar_url:MTCurrentUser.avatar_url
          body: content

        # Render the new comment
        commentView = new MoustacheCommentView(comment, true)
        MTCurrentView.find("#moustache-comments").append(commentView)

  toggle: ->
    _this = this

    # If the moustache view is open then remove it
    if MTCurrentView
      MTCurrentView.toggle()
      if MTCurrentView.hasClass("login-wrapper")
        atom.workspaceView.find('.horizontal').toggleClass("blur")
        atom.workspaceView.find('#moustache-username').focus()
      atom.workspaceView.find('#moustache-login-button').removeClass("loading")
      atom.workspaceView.find('#moustache-login').removeClass("error")
    else
      MTCurrentView = new MoustacheLoginView()
      atom.workspaceView.append(MTCurrentView)
      _this.listeners()
      atom.workspaceView.find('#moustache-username').focus()

    atom.workspaceView.find('#moustache-login-button').addClass("animated")

  login: ->
    _this = this
    atom.workspaceView.find('#moustache-login-button').removeClass("animated")

    username = document.getElementById("moustache-username").value
    password = document.getElementById("moustache-password").value

    if username.length > 0 && password.length > 0
      atom.workspaceView.find('#moustache-login-button').addClass("loading")
      atom.workspaceView.find("#moustache-login").removeClass("error")

      # Authenticate the github API with basic auth
      github.authenticate
        type: "basic"
        username: username
        password: password

      # Check successfull login
      github.user.get {}, (err, response) ->
        atom.workspaceView.find('#moustache-login-button').removeClass("loading")
        if err
          atom.workspaceView.find("#moustache-login").addClass("error")
          _this.loginError(JSON.parse(err.message).message)
        else
          MTCurrentView.destroy() if MTCurrentView
          MTCurrentView = new MoustacheView()
          atom.workspaceView.append(MTCurrentView)
          _this.load()

    else
      atom.workspaceView.find("#moustache-login").addClass("error")
      _this.loginError("Please enter a valid username & password")

  logout: ->
    window.localStorage.removeItem("moustacheToken")
    MTCurrentView.destroy()
    MTCurrentView = new MoustacheLoginView()
    atom.workspaceView.append(MTCurrentView)

  loginError: (error) ->
    if MTCurrentView.find("#mt-login-error").length > 0
      MTCurrentView.find("#mt-login-error").text error
    else
      MTCurrentView.find("#mt-logo").before("<div id='mt-login-error'>"+error+"</div>")
    atom.workspaceView.find('#moustache-username').focus()

  load: ->
    MTCurrentView.renderRepos(MTDataRepos.objects)

    MTCurrentIssues = MTDataIssues.where ( {state:MTState} )
    MTCurrentView.renderIssues(MTCurrentIssues)

    this.sync()
    this.listeners()

  viewRepo: (id) ->
    MTState = "open"
    MTCurrentView.find("#moustache-issues").html("") # Clear issues view
    MTCurrentView.find("#moustache-moustache-main-view").html("") # Clear main view
    MTCurrentView.find("#moustache-issue-filters ul li").removeClass("current")
    MTCurrentView.find("#moustache-issue-filters ul li").first().addClass("current")

    # if an index was passed then fetch that repo from the moustacheRepositories array.
    # Otherwise assume they have selected all issues and load all issues
    if id
      MTCurrentRepo = MTDataRepos.find({id:id})
      MTCurrentIssues = MTDataIssues.where( {state:MTState, repository_id:id} )
    else
      MTCurrentRepo = null
      MTCurrentIssues = MTDataIssues.where( {state:MTState} )

    MTCurrentView.renderIssues(MTCurrentIssues)

  viewIssue: (id) ->
    issue = MTDataIssues.find({id:id})
    MTCurrentIssue = issue
    MTCurrentView.renderIssue(github, issue) # render the issue

  filterIssues: (state) ->
    MTState = state

    if MTCurrentRepo
      issues = MTDataIssues.where( {repository_id:MTCurrentRepo.id})
    else
      issues = MTDataIssues.getAll()

    if state == "all"
      MTCurrentIssues = issues
    else
      MTCurrentIssues = _.where(issues, {state:state})

    MTCurrentView.renderIssues(MTCurrentIssues)

  toggleIssueState: (id) ->
    # Remove issue from list view as state has changed
    MTCurrentView.find(".moustache-issue[issue=#{id}]").remove()

    issue = MTDataIssues.find({id:id})

    if issue.state == "open"
      MTCurrentView.find('#moustache-toggle-issue-state').addClass("open").text("Reopen Issue")

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
      MTCurrentView.find('#moustache-toggle-issue-state').removeClass("open").text("Close Issue")

      issue.state = "open"
      MTDataIssues.replace({id:id}, issue)

      github.issues.edit {
        user:issue.repository.owner.login,
        repo:issue.repository.name,
        number:issue.number,
        state:"open"
        }, (err) ->
          console.log "Issue re opened"
