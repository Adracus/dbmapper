library dbmapper.mirrors;

import 'dart:mirrors';

import 'dbmapper_definition.dart';


Map<Symbol, VariableMirror> getFields(Type type, {bool recursive: false}) {
  var clazz = reflectClass(type);
  var result = {};
  clazz.declarations.forEach((symbol, declaration) {
    if (declaration is VariableMirror)
      result[symbol] = declaration;
  });
  if (recursive && null != clazz.superclass) {
    var superType = clazz.superclass.reflectedType;
    result.addAll(getFields(superType, recursive: true));
  }
  return result;
}

Map<Symbol, VariableMirror> getInstanceFields(Type type, {bool recursive: false}) {
  var _fields = getFields(type, recursive: recursive);
  var result = {};
  _fields.forEach((symbol, variable) {
    if (!variable.isStatic)
      result[symbol] = variable;
  });
  return result;
}

class ValueExtractor<E> {
  final Map<Symbol, String> symbolNames;
  
  ValueExtractor(Type type, {bool recursive: false})
      : symbolNames =
      extractSymbolNames(getInstanceFields(type, recursive: recursive).keys);
  
  Map<String, dynamic> extract(E instance) {
    var instanceMirror = reflect(instance);
    var result = {};
    symbolNames.forEach((symbol, name) {
      result[name] = instanceMirror.getField(symbol).reflectee;
    });
    return result;
  }
  
  static Map<String, dynamic> extractValues(Object instance, {bool recursive: false}) {
    var extractor = new ValueExtractor(instance.runtimeType, recursive: recursive);
    return extractor.extract(instance);
  }
  
  static Map<Symbol, String> extractSymbolNames(Iterable<Symbol> symbols) {
    var result = {};
    symbols.forEach((symbol) {
      result[symbol] = MirrorSystem.getName(symbol);
    });
    return result;
  }
}

Table tableFromClass(Type type, {bool recursive: false}) {
  var variables = getInstanceFields(type, recursive: recursive).values;
  var fields = variables.map(fieldFromVariable).toSet();
  var name = MirrorSystem.getName(reflectClass(type).simpleName);
  return new Table(name, fields);
}

Field fieldFromVariable(VariableMirror variable) {
  var metadata = variable.metadata.map((data) => data.reflectee);
  var constraints = metadata.where((data) => data is Constraint).toSet();
  var type = typeMapping(variable.type);
  var name = MirrorSystem.getName(variable.simpleName);
  return new Field(name, type: type, constraints: constraints);
}

/// Converts the given [type] to the corresponding [FieldType]
/// 
/// The mapping is as follows:
/// [int] => [Integer]
/// [double] => [Double]
/// [String] => [Text]
/// [bool] => [Bool]
/// [DateTime] => [Date]
/// 
/// If the field type cannot be resolved according to this mapping,
/// the return value of [toField] is returned. If [toField] is null,
/// an [ArgumentError] is thrown.
FieldType typeMapping(TypeMirror type, {toField(TypeMirror type)}) {
  if (type.reflectedType == num)
    throw new ArgumentError.value(type, "type", "Num is not supported");
  if (type.isAssignableTo(reflectType(int)))
    return FieldType.integer;
  if (type.isAssignableTo(reflectType(double)))
    return FieldType.doubleType;
  if (type.isAssignableTo(reflectType(String)))
    return FieldType.text;
  if (type.isAssignableTo(reflectType(bool)))
    return FieldType.boolType;
  if (type.isAssignableTo(reflectType(DateTime)))
    return FieldType.date;
  if (null != toField) return toField(type);
  throw new ArgumentError.value(type, "type",
      "Unsupported type");
}