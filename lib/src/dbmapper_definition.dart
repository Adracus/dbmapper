library dbmapper.definition;

import 'package:quiver/core.dart';

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


typeCode(Type type) => type.hashCode;

abstract class FieldType {
  static const number = const Number();
  static const text = const Text();
}

class Number implements FieldType {
  const Number();
  
  bool operator==(other) => other is Number;
  int get hashCode => typeCode(Number);
}

class Text implements FieldType {
  const Text();
  
  bool operator==(other) => other is Text;
  int get hashCode => typeCode(Text);
}

abstract class Constraint {
  static const unique = const Unique();
  static const primaryKey = const PrimaryKey();
}

class Unique {
  const Unique();
  
  bool operator==(other) => other is Unique;
  int get hashCode => typeCode(Unique);
}

class PrimaryKey implements Unique {
  const PrimaryKey();
  
  bool operator==(other) => other is PrimaryKey;
  int get hashCode => typeCode(PrimaryKey);
}