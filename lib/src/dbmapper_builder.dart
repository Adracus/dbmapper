library dbmapper.builder;

import 'dbmapper_definition.dart';


class FieldBuilder {
  String name;
  FieldType type;
  Set<Constraint> constraints = new Set();
  
  FieldBuilder(this.name, {this.type: FieldType.text});
  
  void addConstraint(Constraint constraint) {
    constraints.add(constraint);
  }
  
  Field build() => new Field(name, type: type, constraints: constraints);
}


class TableBuilder {
  String name;
  Set<Field> fields = new Set();
  
  TableBuilder(this.name);
  
  void addField(Field field) {
    this.fields.add(field);
  }
  
  Table build() => new Table(name, fields);
}