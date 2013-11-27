require! {
  'chai'
  'sinon-chai'
  'sinon'
  './faux'
  '../lib/base'.controller
  '../lib/template'.context-mixin
  '../lib/template'.template-response-mixin
  '../lib/template'.template-controller
  '../lib/exceptions'.ConfigurationError
  '../lib/exceptions'.NotImplementedError
}

chai.use sinon-chai
expect = chai.expect

describe 'context-mixin' !-> ``it``

  .. 'context should return context object' !->
    ret = context-mixin.context!
    expect ret .to.deep.equal controller: context-mixin

  .. 'context returns extra arguments' !->
    ret = context-mixin.context foo: 'bar'
    expect ret .to.deep.equal do
      controller: context-mixin
      foo: 'bar'

describe 'template-response-mixin' !-> ``it``

  .. 'view should default to null' !->
    expect template-response-mixin.view .to.equal null

  .. 'contentType should default to text/html' !->
    expect template-response-mixin.content-type .to.equal 'text/html'

  .. 'render should throw if there is no view' !->
    t = ^^template-response-mixin
    t.view = null
    expect (!-> t.render!) .to.throw ConfigurationError

  .. 'render should call res.render' !->
    res = faux.response!
    t = ^^template-response-mixin
    t.view = 'foo'
    t.res = res
    t.render!
    expect res.render .to.be.called-with 'foo', {}

  .. 'rendered content should be sent with content type' !->
    res = faux.response do
      render: (v, ctx, fn) ->
        fn null, 'foo bar'
    t = ^^template-response-mixin
    t.view = 'foo'
    t.res = res
    t.content-type = 'text/pancakes'
    t.render!
    expect res.set .to.be.called-with 'Content-Type', 'text/pancakes'
    expect res.send .to.be.called-with 200, 'foo bar'

  .. 'should call the next callback if rendering results in error' !->
    res = faux.response do
      render: (v, ctx, fn) ->
        fn 'shoe'
    t = ^^template-response-mixin
    t.view = 'foo'
    t.res = res
    t.next = sinon.spy!
    t.render!
    expect t.next .to.be.called-with 'shoe'

describe 'template-controller' !-> ``it``

  .. 'should inherit base controller' !->
    for k, v of controller when k not in <[ allowedMethods textResponse ]>
      expect template-controller[k] .to.equal v

  .. 'should only allow get method' !->
    expect template-controller.allowed-methods .to.deep.equal <[ get ]>

  .. 'should render in with context handler' !->
    t =  ^^template-controller
    t.render = sinon.spy!
    t.context = sinon.spy!
    t.text-response foo: 'bar'
    expect t.render .to.be.called-with t.context.return-values.0
    expect t.context .to.be.called-with foo: 'bar'

