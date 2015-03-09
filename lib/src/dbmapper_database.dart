library dbmapper.database;

import 'dart:async' show Future;

import 'dbmapper_definition.dart';

abstract class Database {
  Future createTable(Table table);
  
  Future<bool> hasTable(String table);
  
  Future<Map<String, dynamic>>
    store(String tableName, Map<String, dynamic> record);
  
  Future<List<Map<String, dynamic>>>
    where(String tableName, Map<String, dynamic> criteria);
  
  Future delete(String tableName, Map<String, dynamic> criteria);
  
  Future update(String tableName, Map<String, dynamic> criteria,
                Map<String, dynamic> values);
  
  Future drop(String tableName);
}