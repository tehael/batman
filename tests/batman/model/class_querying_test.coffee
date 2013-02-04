{TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model class finding"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new AsyncTestStorageAdapter(@Product)
    @adapter.storage =
      'products1': {name: "One", cost: 10, id:1}
      'products2': {name: "Two", cost: 5, id:2}

    @Product.persist @adapter

test "will error unless a callback is provided", ->
  raises => @Product.find 1

asyncTest "models will find an instance in the store", ->
  @Product.find 1, (err, product, env) ->
    throw err if err
    equal product.get('name'), 'One'
    ok env
    QUnit.start()

asyncTest "found models should end up in the loaded set", ->
  @Product.find 1, (err, firstProduct) =>
    throw err if err
    equal @Product.get('loaded').length, 1
    QUnit.start()

asyncTest "not found models should not end up in the loaded set", ->
  equal @Product.get('loaded').length, 0
  @Product.find 10000, (err, product) =>
    ok err
    equal @Product.get('loaded').length, 0
    QUnit.start()

asyncTest "models will find the same instance if called twice", ->
  @Product.find 1, (err, firstProduct) =>
    throw err if err
    @Product.find 1, (err, secondProduct) =>
      throw err if err
      equal firstProduct, secondProduct
      equal @Product.get('loaded').length, 1
      QUnit.start()

asyncTest "models will find instances even if the constructor is overridden", ->
  class LiskovsEnemy extends Batman.Model
    @encode 'name', 'cost'
    constructor: (name, cost) ->
      super()
      @set 'name', name
      @set 'cost', cost

  @adapter = new AsyncTestStorageAdapter(LiskovsEnemy)
  @adapter.storage =
    'liskovs_enemies1': {name: "One", cost: 10, id:1}
    'liskovs_enemies2': {name: "Two", cost: 5, id:2}

  LiskovsEnemy.persist @adapter

  LiskovsEnemy.find 1, (err, firstProduct) =>
    throw err if err
    LiskovsEnemy.find 1, (err, secondProduct) =>
      throw err if err
      equal firstProduct, secondProduct
      equal LiskovsEnemy.get('loaded').length, 1
      QUnit.start()

asyncTest "find calls in an accessor will have no sources", ->
  obj = Batman()
  callCount = 0
  obj.accessor 'foo', =>
    callCount += 1
    @Product.find 1, (err, product, env) ->
      throw err if err
      delay ->
        equal callCount, 1
  obj.get('foo')
  deepEqual obj.property('foo').sources, []

QUnit.module "Batman.Model class findOrCreating"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new AsyncTestStorageAdapter(@Product)
    @adapter.storage =
      'products1': {name: "One", cost: 10, id:1}

    @Product.persist @adapter

asyncTest "models will create a fixture model", ->
  @Product.findOrCreate {id: 3, name: "three"}, (err, product) =>
    throw err if err
    ok !product.isNew()
    equal @Product.get('loaded').length, 1, "the product is added to the identity map"
    QUnit.start()

asyncTest "models will find an already loaded model and update the data", ->
  @Product.find 1, (err, existingProduct) =>
    throw err if err
    ok existingProduct

    @Product.findOrCreate {id: 1, name: "three"}, (err, product) =>
      throw err if err
      ok !product.isNew()
      equal @Product.get('loaded').length, 1, "the identity map is maintained"
      equal product.get('id'), 1
      equal product.get('name'), 'three'
      equal product.get('cost'), 10
      QUnit.start()

QUnit.module "Batman.Model class loading"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new AsyncTestStorageAdapter(@Product)
    @adapter.storage =
      'products1': {name: "One", cost: 10, id:1}
      'products2': {name: "Two", cost: 5, id:2}

    @Product.persist @adapter


asyncTest "models will load all their records", ->
  @Product.load (err, products, env) =>
    throw err if err
    equal products.length, 2
    equal @Product.get('all.length'), 2
    ok env
    QUnit.start()

asyncTest "Model.all will load all records", ->
  set =  @Product.get('all')
  delay ->
    equal set.length, 2

asyncTest "Model.all will load all records even if another piece of code has triggered a load", ->
  readAllSpy = spyOn @adapter, 'readAll'
  @Product.load {name: "One"}, (err, products) ->
  set = @Product.get('all')
  delay ->
    equal set.length, 2
    equal readAllSpy.callCount, 2

asyncTest "Model.all will get all without storage adapters", ->
  class Order extends Batman.Model

  set = Order.get('all')
  equal set.length, 0
  delay ->
    equal set.length, 0

asyncTest "classes fire their loading/loaded callbacks", ->
  callOrder = []

  @Product.on 'loading', -> callOrder.push 1
  @Product.on 'loaded', -> callOrder.push 2

  @Product.load (err, products) =>
    deepEqual callOrder, [1,2]
    QUnit.start()

asyncTest "models will load all their records matching an options hash", ->
  @Product.load {name: 'One'}, (err, products) ->
    equal products.length, 1
    QUnit.start()

asyncTest "models will load all their records with options other than a data hash", ->
  @Product.loadWithOptions { data: { name: 'One' }, option1: 'foo' }, (err, products) ->
    equal products.length, 1
    QUnit.start()

asyncTest "models will maintain the loaded set", ->
  @Product.load {name: 'One'}, (err, products) =>
    equal @Product.get('loaded').length, 1, 'Products loaded are added to the set'

    @Product.load {name: 'Two'}, (err, products) =>
      equal @Product.get('loaded').length, 2, 'Products loaded are added to the set'

      @Product.load {name: 'Two'}, (err, products) =>
        equal @Product.get('loaded').length, 2, "Duplicate products aren't added to the set."

        QUnit.start()

asyncTest "models will maintain the loaded set if no callbacks are given", ->
  @Product.load {name: 'One'}
  delay =>
    equal @Product.get('loaded').length, 1, 'Products loaded are added to the set'
    @Product.load {name: 'Two'}
    delay =>
      equal @Product.get('loaded').length, 2, 'Products loaded are added to the set'
      @Product.load {name: 'Two'}
      delay =>
        equal @Product.get('loaded').length, 2, "Duplicate products aren't added to the set."

asyncTest "loading the same models will return the same instances", ->
  @Product.load {name: 'One'}, (err, productsOne) =>
    equal @Product.get('loaded').length, 1

    @Product.load {name: 'One'}, (err, productsTwo) =>
      deepEqual productsOne, productsTwo
      equal @Product.get('loaded').length, 1
      QUnit.start()

test "models without storage adapters should throw errors when trying to be loaded", 1, ->
  class Silly extends Batman.Model
  raises ->
    Silly.load()

asyncTest "load calls in an accessor will have no sources", ->
  obj = Batman()
  callCount = 0
  obj.accessor 'foo', =>
    callCount += 1
    @Product.load (err, product, env) ->
      throw err if err
      delay ->
        equal callCount, 1
  obj.get('foo')
  deepEqual obj.property('foo').sources, []
