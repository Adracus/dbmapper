library dbmapper.memory;

import 'dart:async' show Future;
import 'dart:math' show max;

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
  
  Future<List<Map<String, dynamic>>> update(String tableName, Map<String, dynamic> criteria,
                                                              Map<String, dynamic> values) {
    var table = getTable(tableName);
    return new Future.value(table.update(criteria, values));
  }
}


class MemoryTable {
  final Table table;
  final Incrementor incrementor = new Incrementor();
  final RecordList _records = new RecordList();
  
  MemoryTable(this.table);
  
  String get name => table.name;
  
  List<Map<String, dynamic>> get records => _records.toMapList();
  
  void store(Map<String, dynamic> data) {
    var record = new Record(data);
    if (!validate(record))
      throw new ArgumentError.value(record, "record", "Invalid record");
    var incremented = applyIncrements(record);
    _records.add(record);
  }
  
  bool validate(Record record, {Record without}) {
    return record.keys.every((name) {
      var field = table.getField(name);
      var value = record[name];
      return validateField(field, value, without: without);
    });
  }
  
  Record applyIncrements(Record record) {
    var incrementFields = table.fields.where((field) =>
        field.constraints.any((constraint) => constraint is AutoIncrement));
    incrementFields.forEach((field) { // If field is present, skip it
      if (null != record[field.name]) {
        incrementor.update(field.name, record[field.name]); // Update the incrementor to not use the id again
        return;
      }
      record[field.name] = incrementor.getIncrement(field.name);
    });
    return record;
  }
  
  bool validateField(Field field, value, {Record without}) {
    var validator = new Validator(field);
    var targetRecords = null == without ? _records : _records.without(without);
    var values = targetRecords.getValues(field.name);
    return validator.isValid(value, values);
  }
  
  bool operator==(other) {
    if (other is! MemoryTable) return false;
    return table == other.table;
  }
  
  int get hashCode => table.hashCode;
  
  List<Map<String, dynamic>> where(Map<String, dynamic> criteria) {
    return _records.where(criteria).toMapList();
  }
  
  void delete(Map<String, dynamic> criteria) {
    _records.delete(criteria);
  }
  
  List<Map<String, dynamic>> update(Map<String, dynamic> criteria,
                                    Map<String, dynamic> values) {
    var targets = _records.where(criteria);
    targets.forEach((record) {
      var clone = record.clone();
      clone.update(values);
      if (!validate(clone, without: record))
        throw new ArgumentError.value(values, "values",
            "Update values violate constraints");
      record.update(values);
    });
    return targets.toMapList();
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
  
  void update(String name, int value) {
    if (null == increments[name]) {
      increments[name] = value;
      return;
    }
    increments[name] = max(increments[name], value);
  }
}


class RecordList {
  final List<Record> _records;
  
  RecordList([List<Record> records])
      : _records = null == records ? [] : records;
  
  void add(Record record) => _records.add(record);
  
  RecordList where(Map<String, dynamic> criteria) {
    return new RecordList(
        _records.where((record) => record.matches(criteria))
                .toList());
  }
  
  List get records => _records;
  
  List getValues(String name) {
    return _records.map((record) => record[name]).toList();
  }
  
  RecordList without(Record record) {
    return new RecordList(
        _records.where((rec) => !identical(rec, record))
                .toList());
  }
  
  void forEach(f(Record record)) {
    _records.forEach(f);
  }
  
  void delete(Map<String, dynamic> criteria) {
    _records.removeWhere((record) => record.matches(criteria));
  }
  
  List<Map<String, dynamic>> toMapList() =>
      _records.fold([], (List acc, record) => acc..add(record.toMap()));
}


class Record {
  final Map<String, dynamic> _values;
  
  Iterable<String> get keys => _values.keys;
  Iterable get values => _values.values;
  
  Record(this._values);
  
  Record.empty() : this({});
  
  void update(Map<String, dynamic> values) {
    values.forEach((name, value) {
      this._values[name] = value;
    });
  }
  
  operator[](String name) => _values[name];
  
  operator[]=(String name, value) => _values[name] = value;
  
  Map<String, dynamic> toMap() => _values;
  
  bool matches(Map<String, dynamic> criteria) {
    return criteria.keys.every((key) {
      return this._values[key] == criteria[key];
    });
  }
  
  Record clone() => new Record(new Map.from(_values));
  
  toString() => _values.toString();
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
    return constraints.any((constraint) => constraint is NotNull);
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