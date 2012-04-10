{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model",
  setup: ->
    class @Product extends Batman.Model

test "constructors should always be called with new", ->
  Product = @Product
  raises (-> product = Product()),
    (message) -> ok message; true

  Namespace = Product: Product
  raises (-> product = Namespace.Product()),
    (message) -> ok message; true

  product = new Namespace.Product()
  ok product instanceof Product

test "properties can be stored", ->
  product = new @Product
  product.set('foo', 'bar')
  equal product.get('foo'), 'bar'

test "falsey properties can be stored", ->
  product = new @Product
  product.set('foo', false)
  equal product.get('foo'), false

test "primary key is undefined on new models", ->
  product = new @Product
  ok product.isNew()
  equal typeof product.get('id'), 'undefined'

test "primary key is 'id' by default", ->
  product = new @Product(id: 10)
  equal product.get('id'), 10

test "integer string ids should be coerced into integers", 1, ->
  product = new @Product(id: "1234")
  strictEqual product.get('id'), 1234

test "non-integer string ids should not be coerced", 1, ->
  product = new @Product(id: "123d")
  strictEqual product.get('id'), "123d"

test "updateAttributes will update a model's attributes", ->
  product = new @Product(id: 10)
  product.updateAttributes {name: "foobar", id: 20}
  equal product.get('id'), 20
  equal product.get('name'), "foobar"

test "updateAttributes will returns the updated record", ->
  product = new @Product(id: 10)
  equal product, product.updateAttributes {name: "foobar", id: 20}

test "primary key can be changed by setting primary key on the model class", ->
  @Product.set 'primaryKey', 'uuid'
  product = new @Product(uuid: "abc123")
  equal product.get('id'), 'abc123'

test 'the \'state\' key should be a valid attribute name', ->
  p = new @Product(state: "silly")
  equal p.get('state'), "silly"
  equal p.state(), "dirty"

test 'the \'batmanState\' key should be gettable and report the internal state', ->
  p = new @Product(state: "silly")
  equal p.state(), "dirty"
  equal p.get('batmanState'), "dirty"

test 'the instantiated storage adapter should be returned when persisting', ->
  returned = false
  class StorageAdapter extends Batman.StorageAdapter
    isTestStorageAdapter: true

  class Product extends Batman.Model
    returned = @persist StorageAdapter

  ok returned.isTestStorageAdapter

test 'the array of instantiated storage adapters should be returned when persisting', ->
  [a, b, c] = [false, false, false]
  class StorageAdapter extends Batman.StorageAdapter
    isTestStorageAdapter: true

  class Product extends Batman.Model
    [a,b,c] = @persist StorageAdapter, StorageAdapter, StorageAdapter

  for instance in [a,b,c]
    ok instance.isTestStorageAdapter

QUnit.module "Batman.Model class clearing"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new TestStorageAdapter(@Product)
    @adapter.storage =
      'products1': {name: "One", cost: 10, id:1}

    @Product.persist @adapter

asyncTest 'clearing the model should remove instances from the identity map', ->
  @Product.load =>
    equal @Product.get('loaded.length'), 1
    @Product.clear()
    equal @Product.get('loaded.length'), 0
    QUnit.start()

QUnit.module 'Batman.Model.urlNestsUnder',
  setup: ->
    class @Product extends Batman.Model
      @urlNestsUnder 'shop'

test 'urlNestsUnder should nest collection URLs', 1, ->
  equal @Product.url(data: shop_id: 1), 'shops/1/products'

test 'urlNestsUnder should nest record URLs', 1, ->
  product = new @Product(id: 1, shop_id: 2)
  equal product.url(), 'shops/2/products/1'

test 'urlNestsUnder should nest new record URLs', 1, ->
  product = new @Product(shop_id: 2)
  equal product.url(), 'shops/2/products'

QUnit.module 'Batman.Model modelConstructor overriding', 
  setup: ->
    namespace = @
    class @Foo extends Batman.Model
      @encode 'name', 'fumbles', 'bumbles'
      @modelConstructor: (attributes) ->
        if attributes.type == 'bar' then namespace.Bar else namespace.Foo

    @adapter = new TestStorageAdapter(@Foo)
    @adapter.storage =
      'foos1': {name: "One", fumbles: 1, id:1, bumbles: 42, type: 'foo'},
      'foos2': {name: "Two", fumbles: 21, id:2, bumbles: 28, type: 'foo'},
      'foos3': {name: "Three", fumbles: 31, id:3, bumbles: 17, type: 'bar'},
      'foos4': {name: "four", fumbles: 41, id:4, bumbles: 80, type: 'foo'}
      'foos5': {name: "four", fumbles: 51, id:5, bumbles: 51, type: 'bar'}
    @Foo.persist @adapter


    class @Bar extends @Foo

test 'loading a set of Models will return a mixed type Set based on @modelConstructor', ->
  @Foo.load (err, records) => 
    equal @Foo.get('loaded.length'), 5
  
    equal records[0].id, 1
    ok records[0] instanceof @Foo
    equal 2, records[1].id
    ok records[1] instanceof @Foo
    equal 3, records[2].id
    ok records[2] instanceof @Bar
    equal 4, records[3].id
    ok records[3] instanceof @Foo
    equal 5, records[4].id
    ok records[4] instanceof @Bar

test 'finding a single Model will return a typed object based on @modelConstructor', ->
  foo1 = @Foo.find 1, (err, foo) ->
    throw err if err
  foo3 = @Foo.find 3, (err, foo) ->
    throw err if err
  ok foo1 instanceof @Foo
  ok foo3 instanceof @Bar
