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

  Table(this.name, Set<Field> fields) : fields = checkFields(fields);

  bool operator ==(other) {
    if (other is! Table) return false;
    return this.name == other.name;
  }

  Field getField(String name) =>
      fields.firstWhere((field) => field.name == name);

  int get hashCode => name.hashCode;

  static Set<Field> checkFields(Set<Field> fields) {
    if (fields.isEmpty) throw new ArgumentError.value(
        fields, "fields", "Cannot be empty");
    return fields;
  }
}

class Field {
  final String name;
  final FieldType type;
  final Set<Constraint> constraints;

  Field(this.name,
      {FieldType type: FieldType.text, Set<Constraint> constraints})
      : type = type,
        constraints = null == constraints
            ? new Set()
            : validConstraints(type, constraints)
                ? constraints
                : throw new ArgumentError.value(constraints, "constraints",
                    "Constraints not compatible with $type");

  static bool validConstraints(FieldType type, Set<Constraint> constraints) {
    return constraints.every((constraint) => constraint.compatible(type));
  }

  bool operator ==(other) {
    if (other is! Field) return false;
    return name == other.name;
  }

  int get hashCode => name.hashCode;
}

abstract class FieldType {
  static const integer = const Integer();
  static const doubleType = const Double();
  static const text = const Text();
  static const boolType = const Bool();
  static const date = const Date();

  static const List<FieldType> types = const [
    integer,
    doubleType,
    text,
    boolType,
    date
  ];
}

class Integer implements FieldType {
  const Integer();

  bool operator ==(other) => other is Integer;
  int get hashCode => typeCode(Integer);
}

class Bool implements FieldType {
  const Bool();

  bool operator ==(other) => other is Bool;
  int get hashCode => typeCode(Bool);
}

class Date implements FieldType {
  const Date();

  bool operator ==(other) => other is Date;
  int get hashCode => typeCode(Date);
}

class Text implements FieldType {
  const Text();

  bool operator ==(other) => other is Text;
  int get hashCode => typeCode(Text);
}

class Double implements FieldType {
  const Double();

  bool operator ==(other) => other is Double;
  int get hashCode => typeCode(Double);
}

const unique = const Unique();
const primaryKey = const PrimaryKey();
const autoIncrement = const AutoIncrement();
const notNull = const NotNull();

abstract class Constraint {
  const Constraint();

  bool compatible(FieldType type) => true;
}

class Unique implements Constraint {
  const Unique();

  bool operator ==(other) => other is Unique;
  int get hashCode => typeCode(Unique);
  bool compatible(FieldType type) => true;
}

class PrimaryKey implements Unique, NotNull {
  const PrimaryKey();

  bool operator ==(other) => other is PrimaryKey;
  int get hashCode => typeCode(PrimaryKey);
  bool compatible(FieldType type) => true;
}

class AutoIncrement implements Constraint {
  const AutoIncrement();

  bool operator ==(other) => other is AutoIncrement;
  int get hashCode => typeCode(AutoIncrement);

  bool compatible(FieldType type) => type is Integer;
}

class NotNull implements Constraint {
  const NotNull();

  bool operator ==(other) => other is NotNull;
  int get hashCode => typeCode(NotNull);

  bool compatible(FieldType field) => true;
}
