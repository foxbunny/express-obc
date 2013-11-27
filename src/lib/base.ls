require! {
  './exceptions'.ConfigurationError
  './exceptions'.NotImplementedError
}

base = module.exports

const VALID_METHODS = <[ get post put patch delete head copy options ]>
const VALID_FORMATS = <[ json jsonp xml text ]>

# # `controller`
#
# This object implements the base controller.
#
# The controller object is `cloned` for each request. This means that each
# time a new request is handled, a prototypical child object is created which
# inhertis all methods from this object, but has properties specific to the
# request as well.
#
# This has several implications, including the fact that any properties you
# set on instances aren't available to other instances.
#
base.controller =

  # ## `path`
  #
  # The path for which this controller with handle request. This property
  #
  path: null

  # ## `allowedMethods`
  #
  # Set of HTTP verbs in lower case that the controller accept.
  #
  # This property is an array of strings. The default includes the following
  # verbs: get, post, put, patch, delete, head, copy, and options.
  #
  allowed-methods: VALID_METHODS

  # ## `allowedFormats`
  #
  # Set of allowed response formats.
  #
  # Possible values are 'json', 'jsonp' and 'text'. Default is all three.
  #
  allowed-formats: VALID_FORMATS

  # ## Verb methods
  #
  # The verb methods are methods named after HTTP verbs. They implements the
  # main logic of handling requests.
  #
  # Default implementation of all verb methods except `options` throw a
  # `NotImplementedError`. It is your job to implement the methods you need.
  #
  # Within the controller class, all methods have access to the following three
  # properties:
  #
  #  + `req`: request object
  #  + `res`: response object
  #  + `next`: callback function to skip processing and execute next middleware
  #
  # These objects are the same objects that are used in Express framework.
  #
  # The usual flow is to end the method by calling `req.send`.
  #
  # Note that `delete` method is called `delete`. Even though it is not a very
  # clean solution, we believe that consistency of this kind is better than
  # introducing additonal code to remove it. Remember to access it using square
  # brackets.
  #
  get: !->
    throw new NotImplementedError 'overload `get` in subclass'

  post: !->
    throw new NotImplementedError 'overload `post` in subclass'

  put: !->
    throw new NotImplementedError 'overload `put` in subclass'

  patch: !->
    throw new NotImplementedError 'overload `patch` in subclass'

  delete: !->
    throw new NotImplementedError 'overload `delete` in subclass'

  head: !->
    throw new NotImplementedError 'overload `head` in subclass'

  copy: !->
    throw new NotImplementedError 'overload `copy` in subclass'

  options: !->
    @res.set do
      'Content-Length': '0'
      'Content-Type': 'text/plain'
      'Allow': [v.to-upper-case! for v in @allowed-methods].join ', '
    @res.send 200

  # ## notSupported
  #
  # Called when request method name is not accepted by the controller. Default
  # implementation simply sends a 'Method not supported' string with HTTP
  # status code of 405.
  #
  not-supported: !->
    @res.send 405 'Method not supported'

  # ## `base.requestMethodName()`
  #
  # Returns the lower-case name of the HTTP verb for the request being handled.
  #
  request-method-name: ->
    @req.route.method.to-lower-case!

  # ## `base.requestFormat()`
  #
  # Returns the request format.
  request-format: ->
    accepts = @req.accepts?.0?.value
    format = @req.params?.format

    can-json = \json in @allowed-formats
    can-jsonp = \jsonp in @allowed-formats
    can-xml = \xml in @allowed-formats

    if format?
      if can-json and format is \json
        \json
      else if can-jsonp and format is \jsonp
        \jsonp
      else if can-xml and format is \xml
        \xml
      else
        \text
    else if accepts?
      if can-json and accepts is 'application/json'
        \json
      else if can-jsonp and accepts is 'text/javascript'
        \jsonp
      else if can-xml and accepts is 'application/xml'
        \xml
      else
        \text
    else
      \text

  # ## `base.dispatch()`
  #
  # Handles the rquest.
  #
  # This method contains boilerplate for setting up request handling. It
  # determines whether requested method is supported, and selects the correct
  # handler method.
  #
  dispatch: !->
    verb = @request-method-name!

    ## Reject unsupported methods
    if verb not in @allowed-methods
      @not-supported!
      return

    ## Delegate to appropraite http verb
    if this[verb]?
      this[verb] this~respond
    else
      throw new ConfigurationError "No handler method for #{verb}"

  respond: (err, data) ->
    return @next err if err?
    this["#{@request-format!}Response"] data

  json-response: (data) ->
    @res.json 200 data

  jsonp-response: (data) ->
    @res.jsonp 200 data

  xml-response: (data) ->
    @res.set \Content-Type, \application/xml
    @res.send 200 data.to-xml!

  text-response: (data) ->
    @res.send 200 "#{data}"

  # ## `base.handle(req, res, next)`
  #
  # Clones this object and handles the request with it.
  #
  # Creates a new object that inherits from this one and calls its `dispatch`
  # method. The three arguments it takes are set as object properties so all
  # methods have access to `req`, `res`, and `next`.
  #
  handle: (req, res, next) ->
    o = ^^this
      .. .req = req
      .. .res = res
      .. .next = next
      .. .dispatch!

  # ## `base.route(app, route)`
  #
  # Crate routes for an `app` using this controller.
  #
  # In essence this methods maps the `handle` method to the specified route.
  #
  # This methods always performs checks to see if listed allowed methods are
  # listed, and ensures that all listed methods are valid.
  #
  route: (app) !->
    ## Check if there are any allowed methods
    if @allowed-methods.length is 0
      throw new ConfigurationError "No allowed methods specified"

    ## Check if allowed methods are all valid
    for verb in @allowed-methods
      if verb not in VALID_METHODS
        throw new ConfigurationError "#{verb} is not a valid HTTP verb"

    ## Check if there are any allowed response formats
    if @allowed-formats.length is 0
      throw new ConfigurationError "No allowed response formats specified"

    ## Check if all response formats are valid
    for format in @allowed-formats
      if format not in VALID_FORMATS
        throw new ConfigurationError "#{format} is not a valid response format"

    if not @path?
      throw new ConfigurationError "No path defined for this controller"

    app.all @path, @handle

