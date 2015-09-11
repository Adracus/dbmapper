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

  Future drop(String tableName) {
    _tables.removeWhere((table) => table.name == tableName);
    return new Future.value();
  }

  bool _hasTable(String tableName) {
    return _tables.any((table) => table.name == tableName);
  }

  Future createTable(Table table) {
    if (_hasTable(table.name)) return new Future.error(
        new Exception("Table ${table.name} already exists"));
    _tables.add(new MemoryTable(table));
    return new Future.value();
  }

  MemoryTable getTable(String name) {
    return _tables.firstWhere((table) => table.name == name);
  }

  Future<Map<String, dynamic>> store(
      String tableName, Map<String, dynamic> record) {
    var table = getTable(tableName);
    var stored = table.store(record);
    return new Future.value(stored);
  }

  Future<List<Map<String, dynamic>>> where(
      String tableName, Map<String, dynamic> criteria) {
    var table = getTable(tableName);
    return new Future.value(table.where(criteria));
  }

  Future delete(String tableName, Map<String, dynamic> criteria) {
    var table = getTable(tableName);
    table.delete(criteria);
    return new Future.value();
  }

  Future<List<Map<String, dynamic>>> update(String tableName,
      Map<String, dynamic> criteria, Map<String, dynamic> values) {
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

  Map<String, dynamic> store(Map<String, dynamic> data) {
    var record = new Record(data);
    var incremented = applyIncrements(record);
    var validation = validate(incremented);
    if (!validation.isValid) throw validation;
    _records.add(incremented);
    return incremented.toMap();
  }

  RecordValidation validate(Record record, {Record without}) {
    var validations = record.keys.map((name) {
      var field = table.getField(name);
      var value = record[name];
      return validateField(field, value, without: without);
    }).toSet();
    return new RecordValidation(record, validations);
  }

  Record applyIncrements(Record record) {
    var incrementFields = table.fields.where((field) =>
        field.constraints.any((constraint) => constraint is AutoIncrement));
    incrementFields.forEach((field) {
      // If field is present, skip it
      if (null != record[field.name]) {
        incrementor.update(
            field.name,
            record[
                field.name]); // Update the incrementor to not use the id again
        return;
      }
      record[field.name] = incrementor.getIncrement(field.name);
    });
    return record;
  }

  FieldValidation validateField(Field field, value, {Record without}) {
    var validator = new Validator(field);
    var targetRecords = null == without ? _records : _records.without(without);
    var values = targetRecords.getValues(field.name);
    return new FieldValidation(field, value, validator.validate(value, values));
  }

  bool operator ==(other) {
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

  List<Map<String, dynamic>> update(
      Map<String, dynamic> criteria, Map<String, dynamic> values) {
    var targets = _records.where(criteria);
    targets.forEach((record) {
      var clone = record.clone();
      clone.update(values);
      var validation = validate(clone, without: record);
      if (!validation.isValid) throw validation;
      record.update(values);
    });
    return targets.toMapList();
  }
}

class FieldValidation {
  final ValidationResult validation;
  final Field field;
  final value;

  FieldValidation(this.field, this.value, this.validation);

  bool get isValid => validation.isValid;

  operator ==(other) {
    if (other is! FieldValidation) return false;
    return field == other.field;
  }

  int get hashCode => field.hashCode;
}

class RecordValidation {
  final bool isValid;
  final Record record;
  final Set<FieldValidation> validations;

  RecordValidation(this.record, Set<FieldValidation> validations)
      : validations = validations,
        isValid = validations.every((validation) => validation.isValid);
}

class Incrementor {
  final Map<String, int> increments = {};

  int getIncrement(String name) {
    if (null == increments[name]) return increments[name] = 0;
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
        _records.where((record) => record.matches(criteria)).toList());
  }

  List get records => _records;

  List getValues(String name) {
    return _records.map((record) => record[name]).toList();
  }

  RecordList without(Record record) {
    return new RecordList(
        _records.where((rec) => !identical(rec, record)).toList());
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

  operator [](String name) => _values[name];

  operator []=(String name, value) => _values[name] = value;

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

  Validator(Field field) : validations = buildValidations(field);

  ValidationResult validate(value, List compare) {
    return validations.fold(new ValidationResult(), (result, validation) {
      return result..combine(validation.validate(value, compare));
    });
  }

  static Set<Validation> buildValidations(Field field) {
    var validations = new Set();
    validations.add(new TypeValidation(field.type));
    if (UniqueValidation.shouldValidate(field.constraints)) validations
        .add(new UniqueValidation());
    if (NotNullValidation.shouldValidate(field.constraints)) validations
        .add(new NotNullValidation());
    return validations;
  }
}

class ValidationError {
  final value;
  final String cause;

  ValidationError(this.value, [this.cause = "Inavlid value"]);

  operator ==(other) {
    if (other is! ValidationError) return false;
    return value == other.value && cause == other.cause;
  }

  int get hashCode => "${value.hashCode}|${cause.hashCode}".hashCode;

  toString() => this.cause;
}

class ValidationResult {
  List<ValidationError> errors = [];

  ValidationResult([List<ValidationError> errors])
      : errors = null == errors ? [] : errors;

  ValidationResult.error(value, [String cause = "Invalid value"])
      : errors = [new ValidationError(value, cause)];

  void addError(ValidationError error) {
    errors.add(error);
  }

  void combine(ValidationResult other) {
    this.errors.addAll(other.errors);
  }

  bool get isValid => errors.isEmpty;
}

abstract class Validation {
  static const UniqueValidation uniqueValidation = const UniqueValidation();
  static const NotNullValidation notNullValidation = const NotNullValidation();

  ValidationResult validate(value, List compare);
}

class TypeValidation implements Validation {
  static final Map<FieldType, Function> _validators = {
    Date: (val) => val is DateTime,
    Bool: (val) => val is bool,
    Integer: (val) => val is int,
    Double: (val) => val is double,
    Text: (val) => val is String
  };

  final _validator;

  TypeValidation(FieldType type) : _validator = _validators[type.runtimeType];

  ValidationResult validate(value, List compare) {
    if (_validator(value)) return new ValidationResult();
    return new ValidationResult.error(value, "Value is not of expected type");
  }

  bool operator ==(other) => other is TypeValidation;
  int get hashCode => typeCode(TypeValidation);
}

class NotNullValidation implements Validation {
  const NotNullValidation();

  ValidationResult validate(value, List compare) {
    if (value != null) return new ValidationResult();
    return new ValidationResult.error(value, "Is null");
  }

  bool operator ==(other) {
    return other is NotNullValidation;
  }

  int get hashCode => typeCode(NotNullValidation);

  static bool shouldValidate(Set<Constraint> constraints) {
    return constraints.any((constraint) => constraint is NotNull);
  }
}

class UniqueValidation implements Validation {
  const UniqueValidation();

  ValidationResult validate(value, List compare) {
    if (compare
        .every((element) => element != value)) return new ValidationResult();
    return new ValidationResult.error(value, "Is not unique");
  }

  bool operator ==(other) {
    return other is UniqueValidation;
  }

  int get hashCode => typeCode(UniqueValidation);

  static bool shouldValidate(Set<Constraint> constraints) {
    return constraints.any((constraint) => constraint is Unique);
  }
}
