library dbmapper.postgres;

import 'dart:async' show Future;
import 'package:postgresql/postgresql.dart';
import 'package:logging/logging.dart';

import 'dbmapper_definition.dart';
import 'dbmapper_database.dart';

class PostgresDatabase implements Database {
  final Uri _uri;

  final Logger logger = new Logger("PostgresDatabase");

  PostgresDatabase(uri) : _uri = uri is Uri ? uri : Uri.parse(uri);

  Future<Connection> obtainConnection() => connect(_uri.toString());

  Future<int> _execute(String sql, [values]) => obtainConnection().then((conn) {
        return conn.execute(sql, values).whenComplete(() => conn.close());
      });

  Future<List<Row>> _query(String sql, [values]) =>
      obtainConnection().then((conn) {
        return conn.query(sql, values).toList().catchError((e) {
          print(e);
        }).whenComplete(() => conn.close());
      });

  Future<bool> hasTable(String tableName) {
    return obtainConnection().then((conn) {
      var stmnt = buildExistsStatement(tableName);
      logger.info(() => stmnt);
      return conn.query(stmnt).toList().then((rows) {
        return rows.first[0];
      }).whenComplete(() => conn.close());
    });
  }

  static String buildExistsStatement(String tableName) {
    return "SELECT EXISTS (" +
        "SELECT table_name " +
        "FROM information_schema.tables " +
        "WHERE table_schema = 'public' " +
        "AND table_name = '$tableName' "
        ")";
  }

  Future createTable(Table table) {
    var stmnt = buildCreateTableStatement(table);
    return _execute(stmnt).then((_) => new Future.value());
  }

  static String buildCreateTableStatement(Table table) {
    var variables = table.fields.map(getColumn).join(", ");
    return "CREATE TABLE \"${table.name}\" ($variables)";
  }

  static String getType(Field variable) {
    if (variable.constraints
        .any((elem) => elem is AutoIncrement)) return "serial";
    if (variable.type == FieldType.text) return "text";
    if (variable.type == FieldType.integer) return "integer";
    if (variable.type == FieldType.doubleType) return "double precision";
    if (variable.type == FieldType.date) return "timestamp";
    if (variable.type == FieldType.boolType) return "boolean";
    throw new UnsupportedError("Type '${variable.type}' not supported");
  }

  static String getColumn(Field variable) {
    var type = getType(variable);
    return ("\"${variable.name}\" $type " +
        variable.constraints.map(getConstraints).join(" ")).trim();
  }

  static String getConstraints(Constraint constraint) {
    if (constraint is PrimaryKey) return "primary key";
    if (constraint is Unique) return "unique";
    return "";
  }

  Future<List<Map<String, dynamic>>> all(String tableName) {
    return where(tableName, {});
  }

  Future delete(String tableName, Map<String, dynamic> condition) {
    return _execute(
        "DELETE FROM \"$tableName\" WHERE " +
            "${generateAndClause(condition.keys)}",
        condition).then((res) => new Future.value());
  }

  Future drop(String tableName) {
    return _execute("DROP TABLE \"$tableName\"")
        .then((res) => new Future.value());
  }

  Future<List<Map<String, dynamic>>> where(
      String tableName, Map<String, dynamic> condition) {
    if (condition.length == 0) return _query("SELECT * FROM \"$tableName\"")
        .then(transformRows);
    return _query(
        "SELECT * FROM \"$tableName\" WHERE " +
            generateAndClause(condition.keys),
        condition).then(transformRows);
  }

  List<Map<String, dynamic>> transformRows(List<Row> rows) =>
      rows.map(rowToMap).toList();

  Map<String, dynamic> rowToMap(Row row) {
    var result = {};
    row.forEach((name, value) => result[name] = value);
    return result;
  }

  static String generateAndClause(Iterable<String> keyNames) =>
      keyNames.map((k) => "\"$k\" = @$k").join(" AND ");

  static String generateOrClause(Iterable<String> keyNames) =>
      keyNames.map((k) => "\"$k\" = @$k").join(" OR ");

  String generateInsertStatement(
      String tableName, Map<String, dynamic> values) {
    var statement = "INSERT INTO \"$tableName\" ";
    if (values.length == 0) return statement + "DEFAULT VALUES RETURNING *";
    var keyNames = values.keys.map((key) => '"$key"').join(", ");
    var keySubs = values.keys.map((name) => "@$name").join(", ");
    return statement + "($keyNames) VALUES ($keySubs) RETURNING *";
  }

  Future<Map<String, dynamic>> store(
      String tableName, Map<String, dynamic> values) {
    return _query(generateInsertStatement(tableName, values), values)
        .then((rows) => transformRows(rows).first);
  }

  Future<Map<String, dynamic>> update(String tableName,
      Map<String, dynamic> values, Map<String, dynamic> condition) {
    values.remove("id");
    var substitutes = {}..addAll(values)..addAll(condition);
    var keyNames = values.keys.join(", ");
    var keySubs = values.keys.map((name) => "@$name").join(", ");
    return _query(
        "UPDATE \"$tableName\" SET ($keyNames) = ($keySubs) " +
            "WHERE ${generateAndClause(condition.keys)} " +
            "RETURNING *",
        substitutes).then((rows) => transformRows(rows).first);
  }

  Future renameTable(String oldTableName, String newTableName) {
    return _execute(
        "ALTER TABLE \"$oldTableName\" RENAME TO \"$newTableName\"");
  }

  Future addColumnToTable(String tableName, Field column) {
    return _execute(
        "ALTER TABLE \"$tableName\" ADD COLUMN " + "${getColumn(column)}");
  }

  Future removeColumnFromTable(String tableName, Field removed) {
    return _execute(
        "ALTER TABLE \"$tableName\" DROP COLUMN " + "\"${removed.name}\"");
  }
}
