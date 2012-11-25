#= require ./plural_association

class Batman.HasManyAssociation extends Batman.PluralAssociation
  associationType: 'hasMany'
  indexRelatedModelOn: 'foreignKey'

  constructor: (model, label, options) ->
    if options?.as
      return new Batman.PolymorphicHasManyAssociation(arguments...)
    super
    @primaryKey = @options.primaryKey or "id"
    @foreignKey = @options.foreignKey or "#{Batman.helpers.underscore(model.get('resourceName'))}_id"

  apply: (baseSaveError, base) ->
    unless baseSaveError
      if relations = @getFromAttributes(base)
        relations.forEach (model) =>
          model.set @foreignKey, base.get(@primaryKey)
      base.set @label, set = @setForRecord(base)
      if base.lifecycle.get('state') == 'creating'
        set.markAsLoaded()

  encoder: ->
    association = @
    (relationSet, _, __, record) ->
      if relationSet?
        jsonArray = []
        relationSet.forEach (relation) ->
          relationJSON = relation.toJSON()
          if !association.inverse() || association.inverse().options.encodeForeignKey
            relationJSON[association.foreignKey] = record.get(association.primaryKey)
          jsonArray.push relationJSON

      #
      # when we encoded hasMany relationships for sets that we're not loaded
      # we shouldn't respond an empty array...?
      #
      jsonArray if jsonArray.length > 0

  #
  # INPUT:  Object
  # OUTPUT: Object
  #
  decoder: ->
    association = @
    (data, key, _, __, parentRecord) ->
      if relatedModel = association.getRelatedModel()
        existingRelations = association.getFromAttributes(parentRecord) || association.setForRecord(parentRecord)

        #
        # As we move over all the nodes we should pass them to _mapIdentity
        # If _mapIdentity has the objects it will return them
        # Otherwise, it will call fromJSON and return the new object
        #
        for jsonObject in data
          record = relatedModel._mapIdentity(jsonObject)
          existingRelations.add record

          if association.options.inverseOf
            record.set association.options.inverseOf, parentRecord

        existingRelations.markAsLoaded()
      else
        Batman.developer.error "Can't decode model #{association.options.name} because it hasn't been loaded yet!"
      existingRelations
