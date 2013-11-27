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

  # ## `controller.path`
  #
  # The path for which this controller with handle request.
  #
  # This property must be set to a valid Express path. It is `null` by default.
  #
  path: null

  # ## `controller.allowedMethods`
  #
  # Set of HTTP verbs in lower case that the controller accept.
  #
  # This property is an array of strings. The default includes the following
  # verbs: get, post, put, patch, delete, head, copy, and options.
  #
  allowed-methods: VALID_METHODS

  # ## `controller.allowedFormats`
  #
  # Set of allowed response formats.
  #
  # Possible values are 'json', 'jsonp' and 'text'. Default is all three.
  #
  allowed-formats: VALID_FORMATS

  # ## `controller.formatParameter`
  #
  # Name of the URL parameter that contains the desired response format.
  #
  # Set this to `null` if you do not have such a parameter in the URL. May be
  # any valid parameter name. Defaults to 'format'.
  #
  format-parameter: \format

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
  # To finish handling the request, you can either use the `res.send()`,
  # `res.json()` and similar methods, or you can call the controller's
  # `respond()` method. Respond is different from the standard Express methods
  # in that it will automatically pick an appropriate format for your data
  # based on request headers or format URL parameter. On the other hand,
  # `respond()` always sends HTTP 200 OK so it cannot be used for non-200
  # responses.
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

  # ## `controller.notSupported()`
  #
  # Called when request method name is not accepted by the controller. Default
  # implementation simply sends a 'Method not supported' string with HTTP
  # status code of 405.
  #
  not-supported: !->
    @res.send 405 'Method not supported'

  # ## `controller.requestMethodName()`
  #
  # Returns the lower-case name of the HTTP verb for the request being handled.
  #
  request-method-name: ->
    @req.route.method.to-lower-case!

  # ## `controller.requestFormat()`
  #
  # Returns the request format.
  #
  # Return value may be one of the following: 'json', 'jsonp', 'xml', or
  # 'text'.
  #
  # This method evaluates the `allowedFormats` array, and compares it to
  # request's `Accept` header as well as the `format` parameter if it appears
  # in the URL. The latter takes precedence over the header.
  #
  # The accept headers that are used to determine the format are the following:
  #
  #  + application/json: JSON format
  #  + text/javascript: JSONP format
  #  + application/xml: XML format
  #
  # The format parameter in the URL may contain one of the following:
  #
  #  + json: JSON format
  #  + jsonp: JSONP format
  #  + xml: XML format
  #
  # The 'text' format is a catch-all and always returned if no other formats
  # match. If you need a more elaborate scheme (or even a simpler one), you
  # should override this method with your own.
  #
  request-format: ->
    accepts = @req.accepts?.0?.value
    format = @req.params?.[@format-parameter]

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

  # ## `controller.dispatch()`
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
      this[verb]!
    else
      throw new ConfigurationError "No handler method for #{verb}"

  # ## `controller.respond(err, data)`
  #
  # Takes error object and data and formulates a response.
  #
  # If the error object is passed and is not `null`, it will be passed on the
  # the `next()` callback. Otherwise, appropriate response method will be
  # chosen based on the requested response format, and it will be passed the
  # data object.
  #
  respond: (err, data) ->
    return @next err if err?
    this["#{@request-format!}Response"] data

  # ## `controller.jsonResponse(data)`
  #
  # Returns JSON response.
  #
  json-response: (data) ->
    @res.json 200 data

  # ## `controller.jsonpResponse(data)`
  #
  # Returns JSONP reponse.
  #
  jsonp-response: (data) ->
    @res.jsonp 200 data

  # ## `controller.xmlResponse(data)`
  #
  # Returns XML response.
  #
  # The `data` argument should be an object that implements `toXml` method.
  # This method should not expect any arguments and must return a string.
  #
  xml-response: (data) ->
    @res.set \Content-Type, \application/xml
    @res.send 200 data.to-xml!

  # ## `controller.textResponse(data)`
  #
  # Returns text response.
  #
  # This method is a dummy that simply coerces `data` to string and returns as
  # response. It's almost always better to override this method with a more
  # sensible one, or use a specialized controller like the
  # `templateController`.
  #
  text-response: (data) ->
    @res.send 200 "#{data}"

  # ## `controller.handle(req, res, next)`
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

  # ## `controller.route(app, route)`
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

