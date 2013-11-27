require! {
  './base'.controller
  'lodash'
  './exceptions'.ConfigurationError
  './exceptions'.NotImplementedError
}

template = module.exports

# # `contextMixin`
#
# Mixin object for use with controllers.
#
# This mixin implements methods for setting up response context.
#
template.context-mixin =

  # ## `context([extraContext])`
  #
  # Return a context object.
  #
  # This method returns an object which can be used as template context. The
  # default implementation returns an object with single property,
  # `controller`, which references the controller on which this method is
  # called.
  #
  # The `extraContext` argument should be an object, and its properties are
  # shallow-copied into the context object. This argument is optional and
  # defaults to empty object. Note that only own properties will be copied.
  #
  context: (extra-context = {}) ->
    ctx = controller: this
    ctx <<< extra-context

template.template-response-mixin =

  view: null

  content-type: 'text/html'

  render: (context = {}) ->
    if not @view?
      throw new ConfigurationError 'No view defined'
    view = lodash.result this, 'view'
    type = lodash.result this, 'contentType'
    err, content <~ @res.render view, context
    if err?
      @next err
    else
      @res.set 'Content-Type', type
      @res.send 200, content

template.template-controller = ^^controller
  .. <<< template.template-response-mixin
  .. <<< template.context-mixin
  .. <<< do

    allowed-methods: <[ get ]>

    text-response: (data) ->
      @render @context data
