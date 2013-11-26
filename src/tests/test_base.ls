require! {
  'chai'
  'sinon-chai'
  'sinon'
  './faux'
  '../lib/base'.controller
  '../lib/exceptions'.ConfigurationError
  '../lib/exceptions'.NotImplementedError
}

chai.use sinon-chai
{expect} = chai

describe 'base.controller' !-> ``it``

  .. 'any of the default http verb methods should throw' !->
    b = ^^controller
    expect (!-> b.get!) .to.throw NotImplementedError
    expect (!-> b.post!) .to.throw NotImplementedError
    expect (!-> b.put!) .to.throw NotImplementedError
    expect (!-> b.delete!) .to.throw NotImplementedError
    expect (!-> b.head!) .to.throw NotImplementedError
    expect (!-> b.copy!) .to.throw NotImplementedError

  .. 'options method does not throw' !->
    b = ^^controller
    b.allowed-methods = <[ get post ]>
    b.res = faux.response!
    expect (!-> b.options!) .to.not.throw
    b.options!
    expect b.res.set .to.be.called-with do
      'Content-Length': '0'
      'Content-Type': 'text/plain'
      'Allow': 'GET, POST'
    expect b.res.send .to.be.called-with 200

  .. 'notSupported should return a 405' !->
    b = ^^controller
    b.res = faux.response!
    b.not-supported!
    expect b.res.send .to.be.called-with 405, 'Method not supported'

  .. 'requestMethodName should return the method name' !->
    b = ^^controller
    b.req = faux.request!
    expect b.request-method-name! .to.equal 'get'

  .. 'dispatch should call method for matching verb' !->
    b = ^^controller
    b.get = sinon.spy!
    b.post = sinon.spy!
    b.req = faux.request!
    b.req.route.method = 'get'
    b.dispatch!
    expect b.get .to.be.called-once
    b.req.route.method = 'post'
    b.dispatch!
    expect b.post .to.be.called-once

  .. 'dispatch should call notSupported for invalid verbs' !->
    b = ^^controller
    b.allowed-methods = <[ post put ]>
    b.get = sinon.spy!
    b.not-supported = sinon.spy!
    b.req = faux.request!
    b.dispatch!
    expect b.get .to.not.be.called
    expect b.not-supported .to.be.called-once

  .. 'dispatch should throw for unimplemented handlers' !->
    b = ^^controller
    b.req = faux.request!
    b.get = null
    expect (!-> b.dispatch!) .to.throw ConfigurationError

  .. 'handle should take three arguments and crate a new object' !->
    b = ^^controller
    req = faux.request!
    res = faux.response!
    next = sinon.spy!
    b.dispatch = sinon.spy!
    c = b.handle req, res, next
    for k, v of b
      expect c[k] .to.equal v
    expect c.req .to.equal req
    expect c.res .to.equal res
    expect c.next .to.equal next
    expect b.dispatch .to.be.called-once

  .. 'route should set up a route for given application' !->
    app = all: sinon.spy!
    b = ^^controller
    b.path = '/foo'
    b.route app
    expect app.all .to.be.called-with '/foo', b.handle

  .. 'route throws if path is missing' !->
    app = all: sinon.spy!
    b = ^^controller
    b.path = void
    expect (!-> b.route app) .to.throw ConfigurationError

  .. 'route throws if no verbs are listed' !->
    app = all: sinon.spy!
    b = ^^controller
    b.allowed-methods = []
    expect (!-> b.route app) .to.throw ConfigurationError

  .. 'route throws if listed verb is invalid' !->
    app = all: sinon.spy!
    b = ^^controller
    b.allowed-methods = <[ get post foo bar ]>
    expect (!-> b.route app) .to.throw ConfigurationError

