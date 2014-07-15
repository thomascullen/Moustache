{View} = require 'atom'

renderTasksList = (tasksList, tasks) ->
  tasksList.find('li').remove()
  Array::forEach.call tasks, (el, i) ->
    tasksList.append("<li class='complete-"+el.complete+"'>\
      <div class='checkbox complete-"+el.complete+"'></div>\
        "+el.title+"\
      </li>")

module.exports =
class MoustacheView extends View

  _DB = undefined

  @content:(state) ->
    @div class: 'moustache-wrapper', =>
      @div class: "moustache", =>
        @input type:"text", placeholder:"New Task", id:"new-moustache-task", class:"native-key-bindings", keyup: "newTask"
        @ul outlet:"tasksList"

  initialize: (serializeState) ->
    atom.workspaceView.command "moustache:toggle", => @toggle()
    this.on "click", ".moustache li .checkbox", (e) ->
      e.currentTarget.classList.toggle "complete-false"
      e.currentTarget.classList.toggle "complete-true"

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      _this = this
      DBOpenRequest = indexedDB.open("Moustache_DB", 1)
      DBOpenRequest.onsuccess = (event) ->
        _DB = event.target.result
        atom.workspaceView.append(_this)
        document.getElementById("new-moustache-task").focus()
        _this.renderTasks()

  renderTasks: ->
    _list = @tasksList
    db = _DB
    transaction = db.transaction(["tasks"],"readwrite")
    tasksStore = transaction.objectStore("tasks")
    tasks = []
    cursor = tasksStore.openCursor()
    cursor.onsuccess = (event) ->
      response = event.target.result
      if response
        tasks.push(response.value)
        response.continue();
      else
        renderTasksList(_list, tasks)

  newTask: (event) ->
    _list = @tasksList
    newTaskInput = document.getElementById("new-moustache-task")
    if event.keyCode == 13 && newTaskInput.value.length > 0
      db = _DB
      transaction = db.transaction(["tasks"],"readwrite")
      tasksStore = transaction.objectStore("tasks")
      task =
        title:document.getElementById("new-moustache-task").value
        complete:false
        created_at:new Date()
      req = tasksStore.add(task)
      req.onsuccess = (e) ->
        newTaskInput.value = ""
        _list.prepend("<li class='animate'>\
          <div class='checkbox'></div>\
          "+task.title+"\
        </li>")
