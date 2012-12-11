#= require ./abstract_binding

class Batman.DOM.ViewArgumentBinding extends Batman.DOM.AbstractBinding
  onlyObserve: Batman.BindingDefinitionOnlyObserve.None

  constructor: (definition, @view) ->
    super(definition)

  die: ->
    args = @view.get('argumentBindings')._batman.properties.toArray()
    for arg in args
      lookup = {}
      for key in @view._batman.properties.keys()
        if key.indexOf("#{arg}.") == 0
          k = key.slice(arg.length+1)
          lookup[k] ||= []
          lookup[k].push(key)

      for key, val of lookup
        keypath = @view.get("argumentBindings.#{arg}").keyPath
        for omg in val
          existingHandlers = @view.get(arg).property(key).event('change', false)?.handlers
          if existingHandlers
            for handler in existingHandlers
              @view.context.get(keypath).property(key).event('change', false)?.removeHandler handler
    @view = undefined
    super
