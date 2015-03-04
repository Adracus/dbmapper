library dbmapper.definition;

typeCode(Type type) => type.hashCode;

class Definition {
  final Set<Table> tables;
  
  Definition(this.tables);
  
  Table getTable(String name) =>
      tables.firstWhere((table) => table.name == name);
}

class Table {
  final String name;
  final Set<Field> fields;
  
  Table(this.name, Set<Field> fields)
      : fields = checkFields(fields);
  
  bool operator==(other) {
    if (other is! Table) return false;
    return this.name == other.name;
  }
  
  Field getField(String name) =>
      fields.firstWhere((field) => field.name == name);
  
  int get hashCode => name.hashCode;
  
  static Set<Field> checkFields(Set<Field> fields) {
    if (fields.isEmpty)
      throw new ArgumentError.value(fields, "fields", "Cannot be empty");
    return fields;
  }
}

class Field {
  final String name;
  final FieldType type;
  final Set<Constraint> constraints;
  
  Field(this.name, {this.type: FieldType.text, Set<Constraint> constraints})
      : constraints = null == constraints ? new Set() : constraints;
      
  bool operator==(other) {
    if (other is! Field) return false;
    return name == other.name;
  }
  
  int get hashCode => name.hashCode;
}

abstract class FieldType {
  static const number = const Number();
  static const text = const Text();
  static const boolType = const Bool();
  static const date = const Date();
}

class Number implements FieldType {
  const Number();
  
  bool operator==(other) => other is Number;
  int get hashCode => typeCode(Number);
}

class Bool implements FieldType {
  const Bool();
  
  bool operator==(other) => other is Bool;
  int get hashCode => typeCode(Bool);
}

class Date implements FieldType {
  const Date();
  
  bool operator==(other) => other is Date;
  int get hashCode => typeCode(Date);
}

class Text implements FieldType {
  const Text();
  
  bool operator==(other) => other is Text;
  int get hashCode => typeCode(Text);
}

abstract class Constraint {
  static const unique = const Unique();
  static const primaryKey = const PrimaryKey();
  static const autoIncrement = const AutoIncrement();
  static const notNull = const NotNull();
}

class Unique {
  const Unique();
  
  bool operator==(other) => other is Unique;
  int get hashCode => typeCode(Unique);
}

class PrimaryKey implements Unique, NotNull {
  const PrimaryKey();
  
  bool operator==(other) => other is PrimaryKey;
  int get hashCode => typeCode(PrimaryKey);
}

class AutoIncrement implements Constraint {
  const AutoIncrement();
  
  bool operator==(other) => other is AutoIncrement;
  int get hashCode => typeCode(AutoIncrement);
}

class NotNull implements Constraint {
  const NotNull();
  
  bool operator==(other) => other is NotNull;
  int get hashCode => typeCode(NotNull);
}