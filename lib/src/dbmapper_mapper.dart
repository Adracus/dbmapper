library dbmapper.mapper;

import 'dart:async' show Future;

import 'package:postgresql/postgresql.dart';

class Mapped {
  int id;
}


abstract class Mapper<E extends Mapped> {
  Future<E> getById(int id);
  Future<List<E>> where(Map<String, dynamic> arguments);
  Future<E> store(E value);
}