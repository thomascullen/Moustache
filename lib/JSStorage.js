var fs = require('fs');
var _ = require('underscore')

function JSStorage(){
  this.collection = function (path){
    // End path for the file
    var fullPath = path + ".json"
    // Create file if collection doesnt already exist
    if ( fs.existsSync(fullPath) == false ){
      // Create a blank collection
      fs.writeFileSync(fullPath, "[]")
    }
    return new JSStorageCollection(fullPath)
  }
}

function JSStorageCollection(path){
  this.path = path
  this.objects = JSON.parse(fs.readFileSync(path,'utf8').toString())

  this.getAll = function(){
    return this.objects
  }

  this.add = function(object){
    this.objects.push(object)
    this.sync()
  }

  this.delete = function(object){
    var index = this.objects.indexOf(object)
    if ( index > -1 ){
      this.objects.splice(index,1)
      this.sync()
    }
  }

  this.find = function(conditions){
    return _.findWhere(this.objects, conditions)
  }

  this.where = function(conditions){
    return _.where(this.objects, conditions)
  }

  this.replace = function(conditions, object){
    object = _.findWhere(this.objects, conditions)
    var index = this.objects.indexOf(object)
    this.objects[index] = object
    this.sync()
  }

  this.deleteWhere = function(conditions){
    _this = this
    objects = _.where(this.objects, conditions)
    if ( objects.length > 0 ){
      Array.prototype.forEach.call(objects, function(object, i){
        _this.delete(object)
      });
    }
  }

  this.deleteAll = function(){
    this.objects = []
    this.sync()
  }

  this.sync = function(){
    fs.writeFileSync(this.path, JSON.stringify(this.objects))
  }

}

module.exports = new JSStorage()
