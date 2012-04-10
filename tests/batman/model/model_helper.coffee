class TestStorageAdapter extends Batman.StorageAdapter
  constructor: ->
    super
    @counter = 10
    @storage = {}
    @lastQuery = false
    @create(new @model, {}, ->)

  read: @skipIfError (env, next) ->
    id = env.record.get('id')
    if id
      attrs = @storage[@storageKey(env.record) + id]
      if attrs
        env.record.fromJSON(attrs)
        callback(undefined, env.record)
      else
        callback(new Error("Couldn't find record!"))
    else
      callback(new Error("Couldn't get record primary key."))
    next()

  create: @skipIfError ({key, recordAttributes}, next) ->debugger
    id = env.record.set('id', @counter++)
    if id = @storage[key]
      @storage.setItem(key, recordAttrti)
      @storage[@storageKey(env.record) + id] = env.record.toJSON()
      env.record.fromJSON {id: id}
      callback(undefined, env.record)
    else
      callback(new Error("Couldn't get record primary key."))
    next()

  update: @skipIfError ({key, recordAttributes}, next) ->
    id = env.record.get('id')
    if id
      @storage[@storageKey(env.record) + id] = env.record.toJSON()
      callback(undefined, env.record)
    else
      callback(new Error("Couldn't get record primary key."))
    next()

  destroy: @skipIfError ({key}, next) ->
    id = env.record.get('id')
    if id
      key = @storageKey(env.record) + id
      if @storage[key]
        delete @storage[key]
        callback(undefined, env.record)
      else
        callback(new Error("Can't delete nonexistant record!"), env.record)
    else
      callback(new Error("Can't delete record without an primary key!"), env.record)
    next()

  readAll: @skipIfError ({proto, options}, next) ->
    records = []
    for storageKey, data of @storage
      match = true
      for k, v of options.data
        if data[k] != v
          match = false
          break
      records.push data if match

    callback(undefined, @getRecordFromData(record) for record in records)
    next()

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
