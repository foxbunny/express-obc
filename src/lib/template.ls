/**!
 * @author Branko Vukelic <branko@brankovukelic.com>
 * @license MIT
 */

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

  # ## `templateResponseMixin.view`
  #
  # Name of the view to render.
  #
  # This property is either a string or function that returns a string. It is
  # `null` by default.
  #
  view: null

  # ## `templateResponseMixin.contentType`
  #
  # Response content type.
  #
  # This property is either a string or a function that returns a string. It is
  # 'text/html' by default.
  #
  content-type: 'text/html'

  # ## `templateResponseMixin.render([context])`
  #
  # Renders the context object usign a view, and returns it as response.
  #
  # This method will take the view specified by the `view` property, and render
  # the supplied context. The response is returned with content type specified
  # in the `contentType` property.
  #
  # If there are errors during template rendering, it will call the `next`
  # callback.
  #
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

    # ## `templateController.allowedMethods`
    #
    # Template controller only allows GET method by default.
    #
    allowed-methods: <[ get ]>

    # ## `templateController.textResponse(data)`
    #
    # Renders the template response using the `render` method, passing `data`
    # as context.
    #
    text-response: (data) ->
      @render @context data
