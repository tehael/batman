#= require ./abstract_binding

class Batman.DOM.ViewArgumentBinding extends Batman.DOM.AbstractBinding
  onlyObserve: Batman.BindingDefinitionOnlyObserve.None

  constructor: (definition, @view) ->
    super(definition)

  die: ->
    keys = @view._batman.properties.keys()
    if @key
      for argument in @view.get('argumentBindings')._batman.properties.toArray()
        for key in keys
          if key.indexOf("#{argument}") == 0
            subkey = key.slice(argument.length)
            keyPath = @view.get("argumentBindings.#{argument}").key
            existingHandlers = if subkey.indexOf('.') == 0
              subkey = subkey.slice(1)
              @view.get(argument).property(subkey, false)?.event('change', false)?.handlers
            else
              @view.property(key, false)?.event('change', false)?.handlers

            if existingHandlers
              if subkey.length > 0
                property = @get('keyContext')?.get(keyPath)?.property(subkey, false)
              else
                property = @get('keyContext')?.property(keyPath, false)

              continue unless property
              for handler in existingHandlers
                property.event('change', false).removeHandler handler
    @view = undefined
    super

