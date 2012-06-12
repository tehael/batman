if typeof require isnt 'undefined'
  {restStorageTestSuite} = require('./rest_storage_helper')
else
  {restStorageTestSuite} = window

MockRequest = restStorageTestSuite.MockRequest

oldRequest = Batman.Request
oldExpectedForUrl = MockRequest.getExpectedForUrl

QUnit.module "Batman.RailsStorage"
  setup: ->
    MockRequest.getExpectedForUrl = (url) ->
      @expects[url.slice(0,-5)] || [] # cut off the .json so the fixtures from the test suite work fine

    Batman.Request = MockRequest
    MockRequest.reset()

    class @Store extends Batman.Model
      @encode 'id', 'name'
    @storeAdapter = new Batman.RailsStorage(@Store)
    @Store.persist @storeAdapter

    class @Product extends Batman.Model
      @encode 'id', 'name', 'cost'
    @productAdapter = new Batman.RailsStorage(@Product)
    @Product.persist @productAdapter

    @adapter = @productAdapter # for restStorageTestSuite

  teardown: ->
    Batman.Request = oldRequest
    MockRequest.getExpectedForUrl = oldExpectedForUrl

restStorageTestSuite.testOptionsGeneration('.json')
restStorageTestSuite()

asyncTest 'creating in storage: should callback with the record with errors on it if server side validation fails', ->
  MockRequest.expect
    url: '/products'
    method: 'POST'
  , error:
      status: 422
      response: JSON.stringify
        name: ["can't be test", "must be valid"]

  product = new @Product(name: "test")
  @productAdapter.perform 'create', product, {}, (err, record) =>
    ok err instanceof Batman.ErrorsSet
    ok record
    equal record.get('errors').length, 2
    QUnit.start()

asyncTest 'creating in storage: should callback with the record with errors applied to hasMany associated records if server side validation fails', ->
  MockRequest.expect
    url: '/products'
    method: 'POST'
  , error:
      status: 422
      response: JSON.stringify
        images: [{src: ["can't be blank"]}]
        name: ["can't be test", "must be valid"]

  class @Image extends Batman.Model
    @encode 'src'

  @Product.hasMany 'images', {namespace: @, autoload: false}
  product = new @Product(name: "test")
  product.get('images').add(new @Image(src: ""))
  @productAdapter.perform 'create', product, {}, (err, record) =>
    ok err instanceof Batman.ErrorsSet
    ok record
    equal record.get('errors').length, 0
    equal record.get('images.first.errors').length, 1
    QUnit.start()

asyncTest 'creating in storage: should callback with the record with errors applied to a belongsTo associated record if server side validation fails', ->
  MockRequest.expect
    url: '/products'
    method: 'POST'
  , error:
      status: 422
      response: JSON.stringify
        collection: {conditions: ["can't be blank"]}

  class @Collection extends Batman.Model
    @encode 'conditions'

  @Product.belongsTo 'collection', {namespace: @, autoload: false, saveInline: true}
  product = new @Product(name: "test")
  product.set('collection', new @Collection(conditions: ""))
  @productAdapter.perform 'create', product, {}, (err, record) =>
    ok err instanceof Batman.ErrorsSet
    ok record
    equal record.get('errors').length, 0
    equal record.get('collection.errors').length, 1
    QUnit.start()
