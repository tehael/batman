class TestStorageAdapter extends Batman.StorageAdapter
  @autoCreate: true
  constructor: ->
    super
    @counter = 10
    @storage = {}
    @lastQuery = false
    @create(new @model, {}, ->) if @constructor.autoCreate
    @env = {}

  _setRecordID: (record) ->
    record._withoutDirtyTracking => record.set('id', @counter++)

  update: (record, options, callback) ->
    id = record.get('id')
    if id
      object = record.toJSON()
      @storage[@storageKey(record) + id] = object

      callback(undefined, object, @env)
    else
      callback(new Error("Couldn't get record primary key."))

  create: (record, options, callback) ->
    id = @_setRecordID(record)
    if id
      object = record.toJSON()
      @storage[@storageKey(record) + id] = object
      object['id'] = id
      debugger
      callback(undefined, object, @env)
    else
      callback(new Error("Couldn't get record primary key."))

  read: (record, options, callback) ->
    id = record.get('id')
    if id
      object = @storage[@storageKey(record) + id]
      if object
        callback(undefined, object, @env)
      else
        callback(new Error("Couldn't find record!"))
    else
      callback(new Error("Couldn't get record primary key."))

  readAll: (_, options, callback) ->
    records = []
    for storageKey, data of @storage
      match = true
      for k, v of options
        if data[k] != v
          match = false
          break
      records.push data if match

    callback(undefined, records, @env)

  destroy: (record, options, callback) ->
    id = record.get('id')
    if id
      key = @storageKey(record) + id
      if @storage[key]
        delete @storage[key]
        callback(undefined, record, @env)
      else
        callback(new Error("Can't delete nonexistant record!"), record)
    else
      callback(new Error("Can't delete record without an primary key!"), record)

  perform: (action, record, options, callback) ->
    throw new Error("No options passed to storage adapter!") unless options?
    @[action](record, options.data, callback)

class AsyncTestStorageAdapter extends TestStorageAdapter
  perform: (args...) ->
    setTimeout =>
      TestStorageAdapter::perform.apply(@, args)
    , 0

createStorageAdapter = (modelClass, adapterClass, data = {}) ->
  adapter = new adapterClass(modelClass)
  adapter.storage = data
  modelClass.persist adapter
  adapter

generateSorterOnProperty = (property) ->
  if typeof property is 'string'
    key = property
    property = (x) -> x[key]
  return (array) ->
    array.sort (a, b) ->
      a = property(a)
      b = property(b)
      if a < b
        -1
      else if a > b
        1
      else
        0

if typeof exports is 'undefined'
  window.TestStorageAdapter = TestStorageAdapter
  window.AsyncTestStorageAdapter = AsyncTestStorageAdapter
  window.createStorageAdapter = createStorageAdapter
  window.generateSorterOnProperty = generateSorterOnProperty
else
  exports.TestStorageAdapter = TestStorageAdapter
  exports.AsyncTestStorageAdapter = AsyncTestStorageAdapter
  exports.createStorageAdapter = createStorageAdapter
  exports.generateSorterOnProperty = generateSorterOnProperty
