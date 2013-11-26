# # util
#
# Utility functions.
#

util = module.exports

# ## `util.get(v)`
#
# If `v` is a function or bound method, call it, otherwise return its value.
#
util.get = (v) ->
  if typeof v is \function then v! else v
