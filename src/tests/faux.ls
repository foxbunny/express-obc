# # `faux`
#
# This module contains mocks for express API.
#

require! 'sinon'

faux = module.exports

# ## `faux.request([props])`
#
# Returns a fake request object.
#
# The optional `props` object can be used to override any of the request object
# properties.
#
faux.request = (props = {}) ->
  req =
    method: 'get'
    route:
      method: 'get'
      path: '/path/:foo/:bar'
    params:
      foo: 1
      bar: 2
    param: sinon.spy!
  req <<< props

# ## `faux.response([props])`
#
# Returns a fake response object.
#
# The optional `props` object can be used to override any of the response
# object properties.
#
faux.response = (props = {}) ->
  res =
    set: sinon.spy!
    send: sinon.spy!
    render: sinon.spy!
  res <<< props

