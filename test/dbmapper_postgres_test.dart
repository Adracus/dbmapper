library dbmapper.test.postgres;

import 'package:dbmapper/dbmapper.dart';
import 'package:unittest/unittest.dart';

main() => defineTests();

defineTests() {
  group("PostgresDatabase", () {
    test("buildExistsStatement", () {
      var statement = PostgresDatabase.buildExistsStatement("testtable");
      expect(
          statement,
          equals("SELECT EXISTS (SELECT table_name FROM " +
              "information_schema.tables WHERE table_schema = 'public' " +
              "AND table_name = 'testtable' )"));
    });

    test("getType", () {
      var t1 = PostgresDatabase.getType(new Field("test"));
      var t2 =
          PostgresDatabase.getType(new Field("test", type: FieldType.integer));
      var t3 = PostgresDatabase
          .getType(new Field("test", type: FieldType.doubleType));
      var t4 =
          PostgresDatabase.getType(new Field("test", type: FieldType.date));
      var t5 =
          PostgresDatabase.getType(new Field("test", type: FieldType.boolType));
      var t6 = PostgresDatabase.getType(
          (new FieldBuilder("test", type: FieldType.integer)
            ..addConstraint(autoIncrement)).build());

      expect(t1, equals("text"));
      expect(t2, equals("integer"));
      expect(t3, equals("double precision"));
      expect(t4, equals("timestamp"));
      expect(t5, equals("boolean"));
      expect(t6, equals("serial"));
    });

    test("getConstraints", () {
      var c1 = PostgresDatabase.getConstraints(primaryKey);
      var c2 = PostgresDatabase.getConstraints(unique);
      var c3 = PostgresDatabase.getConstraints(autoIncrement);

      expect(c1, equals("primary key"));
      expect(c2, equals("unique"));
      expect(c3, equals(""));
    });

    test("getColumn", () {
      var c1 = PostgresDatabase.getColumn(new Field("test"));
      var c2 = PostgresDatabase.getColumn(
          (new FieldBuilder("test", type: FieldType.integer)
            ..addConstraint(unique)).build());

      expect(c1, equals("\"test\" text"));
      expect(c2, equals("\"test\" integer unique"));
    });

    test("buildCreateTableStatement", () {
      var fields =
          new Set.from([new Field("myField"), new Field("otherField")]);
      var t = new Table("table", fields);

      var stmnt = PostgresDatabase.buildCreateTableStatement(t);
      expect(stmnt,
          equals('CREATE TABLE "table" ("myField" text, "otherField" text)'));
    });
  });
}
