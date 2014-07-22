{View} = require 'atom'

module.exports =
class RepoView extends View

  @content: (repo) ->
    @li id:repo.id, =>
      @p repo.name.substring(0,17);
      @span "( "+repo.open_issues+" )"

  initialize: (serializeState) ->
    atom.workspaceView.append(this)

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()
