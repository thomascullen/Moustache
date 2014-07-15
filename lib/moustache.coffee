MoustacheView = require './moustache-view'

module.exports =
  moustacheView: null

  activate: (state) ->
    @moustacheView = new MoustacheView(state.moustacheViewState)
    _moustacheView = @moustacheView
    DBOpenRequest = indexedDB.open("Moustache_DB", 1)

    DBOpenRequest.onsuccess = (event) ->
      db = event.target.result

    DBOpenRequest.onerror = (event) ->
      alert "Database error: " + event.target.errorCode
      return

    DBOpenRequest.onupgradeneeded = (event) ->
      db = event.target.result
      db.createObjectStore("tasks", {autoIncrement:true}) unless db.objectStoreNames.contains("tasks")

  deactivate: ->
    @moustacheView.destroy()

  serialize: ->
    moustacheViewState: @moustacheView.serialize()
