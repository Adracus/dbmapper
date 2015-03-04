library dbmapper.memory;

import 'dart:async' show Future;

import 'dbmapper_definition.dart';
import 'dbmapper_database.dart';


class MemoryDatabase implements Database {
  final Set<MemoryTable> _tables = new Set();
  
  Future<bool> hasTable(String tableName) {
    return new Future.value(_hasTable(tableName));
  }
  
  bool _hasTable(String tableName) {
    return _tables.any((table) => table.name == tableName);
  }
  
  Future createTable(Table table) {
    if (_hasTable(table.name))
      return new Future.error(new Exception("Table ${table.name} already exists"));
    _tables.add(new MemoryTable(table));
    return new Future.value();
  }
  
  MemoryTable getTable(String name) {
    return _tables.firstWhere((table) => table.name == name);
  }
  
  Future<Map<String, dynamic>> store(String tableName, Map<String, dynamic> record){
    var table = getTable(tableName);
    table.store(record);
    return new Future.value();
  }
  
  Future<List<Map<String, dynamic>>> where(String tableName, Map<String, dynamic> criteria) {
    var table = getTable(tableName);
    return new Future.value(table.where(criteria));
  }
  
  Future delete(String tableName, Map<String, dynamic> criteria) {
    var table = getTable(tableName);
    table.delete(criteria);
    return new Future.value();
  }
}


class MemoryTable {
  final Table table;
  final Incrementor incrementor = new Incrementor();
  final List<Map<String, dynamic>> _records = [];
  
  MemoryTable(this.table);
  
  String get name => table.name;
  
  List<Map<String, dynamic>> get records => _records;
  
  void store(Map<String, dynamic> record) {
    if (!validate(record))
      throw new ArgumentError.value(record, "record", "Invalid record");
    var incremented = applyIncrements(record);
    _records.add(incremented);
  }
  
  bool validate(Map<String, dynamic> record) {
    return record.keys.every((name) {
      var field = table.getField(name);
      var value = record[name];
      return validateField(field, value);
    });
  }
  
  Map<String, dynamic> applyIncrements(Map<String, dynamic> record) {
    var incrementFields = table.fields.where((field) =>
        field.constraints.any((constraint) => constraint is AutoIncrement));
    incrementFields.forEach((field) {
      if (null != record[field.name]) return; // If field is present, skip it
      record[field.name] = incrementor.getIncrement(field.name);
    });
    return record;
  }
  
  bool validateField(Field field, value) {
    var validator = new Validator(field);
    return validator.isValid(value, getValues(field.name));
  }
  
  List getValues(String name) =>
      _records.map((record) => record[name]).toList();
  
  bool operator==(other) {
    if (other is! MemoryTable) return false;
    return table == other.table;
  }
  
  int get hashCode => table.hashCode;
  
  List<Map<String, dynamic>> where(Map<String, dynamic> criteria) {
    return _records.where(recordMatcher(criteria)).toList();
  }
  
  void delete(Map<String, dynamic> criteria) {
    records.removeWhere(recordMatcher(criteria));
  }
  
  static recordMatcher(Map<String, dynamic> criteria) {
    return (record) {
      return criteria.keys.every((key) {
        return record[key] == criteria[key];
      });
    };
  }
}

class Incrementor {
  final Map<String, int> increments = {};
  
  int getIncrement(String name) {
    if (null == increments[name])
      return increments[name] = 0;
    increments[name]++;
    return increments[name];
  }
}


class Validator implements Validation {
  final Set<Validation> validations;
  
  Validator(Field field)
      : validations = buildValidations(field);
  
  bool isValid(value, List compare) {
    return validations.every((validation) =>
        validation.isValid(value, compare));
  }
  
  static Set<Validation> buildValidations(Field field) {
    var validations = new Set();
    if (UniqueValidation.shouldValidate(field.constraints))
      validations.add(new UniqueValidation());
    if (NotNullValidation.shouldValidate(field.constraints))
      validations.add(new NotNullValidation());
    return validations;
  }
}

abstract class Validation {
  static const UniqueValidation uniqueValidation = const UniqueValidation();
  static const NotNullValidation notNullValidation = const NotNullValidation();
  
  bool isValid(value, List compare);
}

class NotNullValidation implements Validation {
  const NotNullValidation();
  
  bool isValid(value, List compare) {
    return value != null;
  }
  
  bool operator==(other) {
    return other is NotNullValidation;
  }
  
  int get hashCode => typeCode(NotNullValidation);
  
  static bool shouldValidate(Set<Constraint> constraints) {
    var result = false;
    for (var constraint in constraints) {
      if (constraint is AutoIncrement) return false;
      if (constraint is NotNull) result = true;
    }
    return result;
  }
}

class UniqueValidation implements Validation {
  const UniqueValidation();
  
  bool isValid(value, List compare) {
    return compare.every((element) => element != value);
  }
  
  bool operator==(other) {
    return other is UniqueValidation;
  }
  
  int get hashCode => typeCode(UniqueValidation);
  
  static bool shouldValidate(Set<Constraint> constraints) {
    return constraints.any((constraint) => constraint is Unique);
  }
}