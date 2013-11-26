require! {
  'chai'
  'sinon-chai'
  'sinon'
  util: '../lib/util'
}

chai.use sinon-chai
expect = chai.expect

describe 'util' !->

  describe 'get' !-> ``it``

    .. 'should return value if passed a value' !->
      expect util.get 'foo' .to.equal 'foo'
      expect util.get 1 .to.equal 1
      expect util.get null .to.equal null
      expect util.get true .to.equal true

    .. 'should call a function if passed a function' !->
      fn = sinon.spy!
      expect util.get fn .to.equal fn.return-values.0

    .. 'should call a bound method if passed one' !->
      obj = foo: sinon.spy!
      expect util.get obj~foo .to.equal obj.foo.return-values.0

