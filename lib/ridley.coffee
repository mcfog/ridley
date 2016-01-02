IDL = require './idl'

class Defination
  toJSON: ->
    @_define

module.exports = class Ridley
  constructor: ()->
    @struct = {}
    @enum = {}
    @service = {}

  @fromSource: (src)->
    ast = IDL.parse src
    r = new Ridley
    r.loadAst ast

    r

  @fromJson: (json)->
    r = new Ridley
    r.loadJson json

    r

  loadJson: (json)->
    for id, def of json.struct
      @struct[id] = new Ridley.Struct def
    for id, def of json.enum
      @enum[id] = new Ridley.Enum def
    for id, def of json.service
      @service[id] = new Ridley.Service def

    @init()

  loadAst: (ast)->
    ast.forEach (@loadDefine.bind @)

    @init()

  loadDefine: (def)->
    if @[def.define][def.id]
      throw new Error("#{def.define}[#{def.id}] already exist!");
    register[def.define](@, def)

  init: ->
    for id, struct of @struct
      struct.resolveFields @

    for id, service of @service
      service.resolveMethods @

  toJSON: ->
    struct: @struct
    enum: @enum
    service: @service

  @Enum: class Enum extends Defination
    constructor: (@_define)->
      @name = @_define.id
      @entry = @_define.reverse

  @Struct: class Struct extends Defination
    constructor: (@_define)->
      @name = @_define.id
      @comment = @_define.comment
    resolveFields: (ridley)->
      @fields = new Fields ridley, @_define.fields

  @Service: class Service extends Defination
    constructor: (@_define)->
      @name = @_define.id
      @methodMap = {}
    resolveMethods: (ridley)->
      @_define.methods.map (methodMapper @methodMap, ridley)

  @Type: class Type
    @cast: (typeDef, ridley)->
      if !ridley.struct
        throw new Error

      switch
        when typeDef is "bool" then new BoolType
        when typeDef is "int" then new IntType
        when typeDef is "float" then new FloatType
        when typeDef is "string" then new StringType

        when typeDef.ref && ridley.struct[typeDef.ref] then new StructType ridley, typeDef.ref
        when typeDef.ref && ridley.enum[typeDef.ref] then new EnumType ridley, typeDef.ref

        when typeDef.arrayOf then new ArrayType(Type.cast typeDef.arrayOf, ridley)
        else
          throw new Error("unknown type #{JSON.stringify typeDef}")

  @BuiltinType: class BuiltinType extends Type
    builtin: true
  @BoolType: class BoolType extends BuiltinType
    name: "bool"
  @IntType: class IntType extends BuiltinType
    name: "int"
  @FloatType: class FloatType extends BuiltinType
    name: "float"
  @StringType: class StringType extends BuiltinType
    name: "string"

  @StructType: class StructType extends Type
    builtin: false
    name: 'struct'
    constructor: (ridley, id)->
      @struct = ridley.struct[id]

  @EnumType: class EnumType extends Type
    builtin: false
    name: 'enum'
    constructor: (ridley, id)->
      @enum = ridley.enum[id]

  @ArrayType: class ArrayType extends Type
    builtin: false
    name: 'array'
    constructor: (@innerType)->

  @Fields: class Fields
    constructor: (ridley, fields)->
      @map = {}  
      @seq = fields.map (field)=>
        if @map[field.id]
          throw new Error("field #{field.id} already exist");

        @map[field.id] =
          name: field.id
          type: Type.cast field.type, ridley
          optional: !!field.optional
          comment: field.comment

        field.id

  methodMapper = (map, ridley)->
    (method)->
      if map[method.id]
        throw new Error("method #{method.id} already exist");

      paramMap = {}
      map[method.id] =
        name: method.id
        comment: method.comment
        param: new Fields ridley, method.params

      if method.ret isnt 'void'
        map[method.id].return = Type.cast method.ret, ridley

      method.id

  register = 
    struct: (ridley, def)->
      ridley.struct[def.id] = new Ridley.Struct def
    enum: (ridley, def)->
      ridley.enum[def.id] = new Ridley.Enum def
    service: (ridley, def)->
      ridley.service[def.id] = new Ridley.Service def;
