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

  .. 'default format parameter' !->
    expect controller.format-parameter .to.equal \format

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

  .. 'requestFormat handles JSON requests correctly' !->
    b = ^^controller
    b.req = faux.request!
    b.req.{}params.format = \json
    b.req.accepts = [value: \application/json]
    expect b.request-format! .to.equal \json

  .. 'requestFormat handles JSONP requests correctly' !->
    b = ^^controller
    b.req = faux.request!
    b.req.{}params.format = \jsonp
    b.req.accepts = [value: \text/javascript]
    expect b.request-format! .to.equal \jsonp

  .. 'requestFormat handles XML requests correctly' !->
    b = ^^controller
    b.req = faux.request!
    b.req.{}params.format = \xml
    b.req.accepts = [value: \application/xml]
    expect b.request-format! .to.equal \xml

  .. 'requestFormat handles any other format as text' !->
    b = ^^controller
    b.req = faux.request!
    b.req.{}params.format = \html
    b.req.accepts = [value: \text/html]
    b.req.[]accepts.0.value = \text/html
    expect b.request-format! .to.equal \text
    b.req.{}params.format = null
    b.req.accepts = [value: \text/foobar]
    expect b.request-format! .to.equal \text

  .. 'requestFormat prioritizes format parameter' !->
    b = ^^controller
    b.req = faux.request!
    b.req.{}params.format = \json
    b.req.accepts = [value: \application/xml]
    expect b.request-format! .to.equal \json
    b.req.{}params.format = \jsonp
    b.req.accepts = [value: \application/json]
    expect b.request-format! .to.equal \jsonp
    b.req.{}params.format = \xml
    b.req.accepts = [value: \application/json]
    expect b.request-format! .to.equal \xml

  .. 'requestFormat should read the format-parameter' !->
    b = ^^controller
    b.req = faux.request!
    b.req.{}params.foo = 'xml'
    expect b.request-format! .to.equal \text
    b.format-parameter = \foo
    expect b.request-format! .to.equal \xml

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

  .. 'respond should call next callback if error is passed' !->
    b = ^^controller
    b.next = sinon.spy!
    b.respond true
    expect b.next .to.be.called-once

  .. 'respond should call appropriate response method' !->
    b = ^^controller
    b.req = faux.request!
    b.json-response = sinon.spy!
    b.jsonp-response = sinon.spy!
    b.xml-response = sinon.spy!
    b.text-response = sinon.spy!
    data = foo: 'bar'

    b.req.{}params.format = 'json'
    b.respond null, data
    expect b.json-response .to.be.called-with data

    b.req.{}params.format = 'jsonp'
    b.respond null, data
    expect b.jsonp-response .to.be.called-with data

    b.req.{}params.format = 'xml'
    b.respond null, data
    expect b.xml-response .to.be.called-with data

    b.req.{}params.format = null
    b.respond null, data
    expect b.text-response .to.be.called-with data

  .. 'jsonResponse calls res.json' !->
    b = ^^controller
    b.res = faux.response!
    b.json-response foo: 'bar'
    expect b.res.json .to.be.called-with 200, foo: 'bar'

  .. 'jsonpResponse calls res.jsonp' !->
    b = ^^controller
    b.res = faux.response!
    b.jsonp-response foo: 'bar'
    expect b.res.jsonp .to.be.called-with 200, foo: 'bar'

  .. 'xmlResponse calls res.send' !->
    b = ^^controller
    b.res = faux.response!
    data =
      foo: 'bar'
      to-xml: sinon.spy!
    b.xml-response data
    expect b.res.send .to.be.called-with 200, data.to-xml.return-values.0

  .. 'textResponse calls res.send' !->
    b = ^^controller
    b.res = faux.response!
    b.text-response 21
    expect b.res.send .to.be.called-with 200, '21'

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

  .. 'route throws if no allowed formats are listed' !->
    app = all: sinon.spy!
    b = ^^controller
    b.allowed-formats = []
    expect (!-> b.route app) .to.throw ConfigurationError

  .. 'route throws if allowed format is invalid' !->
    app = all: sinon.spy!
    b = ^^controller
    b.allowed-formats = <[ json xml foo ]>
    expect (!-> b.route app) .to.throw ConfigurationError
