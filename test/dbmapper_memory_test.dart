library dbmapper.test.memory;

import 'package:dbmapper/dbmapper.dart';

import 'package:unittest/unittest.dart';

main() => defineTests();
async(Function callback) => expectAsync(callback);

defineTests() {
  group("MemoryDatabase", () {
    test("createTable", () {
      var db = new MemoryDatabase();
      var fields = new Set.from([new Field("myField"),
                                 new Field("otherField")]);
      var t = new Table("table", fields);
      db.createTable(t).then(async((_) {
        db.createTable(t).catchError(async((e) {
          expect(e, new isInstanceOf<Exception>());
        }));
      }));
    });
    
    test("hasTable", () {
      var db = new MemoryDatabase();
      
      db.hasTable("notknown").then(async((answer) {
        expect(answer, isFalse);
        
        var fields = new Set.from([new Field("myField"),
                                   new Field("otherField")]);
        var t = new Table("table", fields);
        db.createTable(t).then(async((_) {
          db.hasTable("table").then(async((result) {
            expect(result, isTrue);
          }));
        }));
      }));
    });
  });
  
  group("Record", () {
    test("update", () {
      var r = new Record({"some": "attributes", "and": "stuff"});
      
      r.update({"some": "people", "should": "think"});
      expect(r.toMap(), equals({
        "some": "people",
        "and": "stuff",
        "should": "think"
      }));
    });
    
    test("matches", () {
      var r = new Record({"criteria": "that", "could": "be matched"});
      
      expect(r.matches({"criteria": "that"}), isTrue);
      expect(r.matches({}), isTrue);
      expect(r.matches({"could": "not match"}), isFalse);
    });
  });
  
  group("RecordList", () {
    test("without", () {
      var r1 = new Record.empty();
      var r2 = new Record.empty();
      var r3 = new Record.empty();
      
      var recordList = new RecordList([r1, r2]);
      expect(recordList.without(r1).records, equals([r2]));
      expect(recordList.without(r3).records, equals([r1, r2]));
    });
    
    test("getValues", () {
      var r1 = new Record({"target": "value"});
      var r2 = new Record({"target": "value2"});
      var r3 = new Record.empty();
      var recordList = new RecordList([r1, r2, r3]);
      
      expect(recordList.getValues("target"),
          equals(["value", "value2", null]));
    });
    
    test("where", () {
      var r1 = new Record({"target": "value"});
      var r2 = new Record({"target": "value2"});
      var r3 = new Record.empty();
      var recordList = new RecordList([r1, r2, r3]);
      
      var list = recordList.where({"target": "value2"});
      expect(list.records, equals([r2]));
    });
    
    test("delete", () {
      var r1 = new Record({"target": "value"});
      var r2 = new Record({"target": "value2"});
      var r3 = new Record.empty();
      var recordList = new RecordList([r1, r2, r3]);
      
      recordList.delete({"target": "value2"});
      expect(recordList.records, equals([r1, r3]));
    });
  });
  
  group("MemoryTable", () {
    test("==", () {
      var fields1 = new Set.from([new Field("myField")]);
      var fields2 = new Set.from([new Field("otherField")]);
      var t1 = new Table("table", fields1);
      var t2 = new Table("table", fields2);
      var t3 = new Table("notTable", fields1);
      var m1 = new MemoryTable(t1);
      var m2 = new MemoryTable(t2);
      var m3 = new MemoryTable(t3);
      
      expect(m1, equals(m2));
      expect(m1, isNot(equals(m3)));
    });
    
    test("hashCode", () {
      var fields1 = new Set.from([new Field("myField")]);
      var fields2 = new Set.from([new Field("otherField")]);
      var t1 = new Table("table", fields1);
      var t2 = new Table("table", fields2);
      var t3 = new Table("notTable", fields1);
      var m1 = new MemoryTable(t1);
      var m2 = new MemoryTable(t2);
      var m3 = new MemoryTable(t3);
      
      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1.hashCode, isNot(equals(m3.hashCode)));
      expect(m1.hashCode, equals("table".hashCode));
    });
    
    test("store", () {
      var fields = new Set.from([
        new Field("myField",
            type: FieldType.number,
            constraints: new Set.from([Constraint.autoIncrement,
                                           Constraint.unique])),
        new Field("otherField")]);
      var table = new Table("table", fields);
      var memoryTable = new MemoryTable(table);
      
      memoryTable.store({"otherField": "yeah"});
      expect(memoryTable.records.length, equals(1));
      expect(memoryTable.records.single, equals({
        "myField": 0, "otherField": "yeah"
      }));
      expect(() => memoryTable.store({
        "myField": 0, "otherField": "yeah"
      }), throws);
      expect(() => memoryTable.store({
        "myField": 1, "otherField": "yeah"
      }), returnsNormally);
      expect(memoryTable.records.length, equals(2));
      expect(memoryTable.records.last, equals({
        "myField": 1, "otherField": "yeah"
      }));
    });
    
    test("where", () {
      var fields = new Set.from([
        new Field("myField",
            constraints: new Set.from([Constraint.autoIncrement,
                                           Constraint.unique])),
        new Field("otherField")]);
      var table = new Table("table", fields);
      var memoryTable = new MemoryTable(table);
      memoryTable.store({});
      memoryTable.store({"otherField": "yeah"});
      memoryTable.store({"otherField": "test"});
      memoryTable.store({"otherField": "test"});
      
      var rs1 = memoryTable.where({"otherField": "test"});
      expect(rs1, equals([
        {"myField": 2, "otherField": "test"},
        {"myField": 3, "otherField": "test"}
      ]));
    });
    
    test("delete", () {
      var fields = new Set.from([
        new Field("myField",
            constraints: new Set.from([Constraint.autoIncrement,
                                           Constraint.unique])),
        new Field("otherField")]);
      var table = new Table("table", fields);
      var memoryTable = new MemoryTable(table);
      memoryTable.store({});
      memoryTable.store({"otherField": "yeah"});
      memoryTable.store({"otherField": "test"});
      memoryTable.store({"otherField": "test"});
      
      expect(memoryTable.records.length, equals(4));
      
      memoryTable.delete({"otherField": "yeah"});
      expect(memoryTable.records, equals([
        {"myField": 0},
        {"myField": 2, "otherField": "test"},
        {"myField": 3, "otherField": "test"}
      ]));
      
      memoryTable.delete({"otherField": "test"});
      expect(memoryTable.records.single, equals({"myField": 0}));
    });
    
    test("update", () {
      var fields = new Set.from([
        new Field("myField",
            type: FieldType.number,
            constraints: new Set.from([Constraint.autoIncrement,
                                           Constraint.unique])),
        new Field("otherField")]);
      var table = new Table("table", fields);
      var memoryTable = new MemoryTable(table);
      memoryTable.store({});
      memoryTable.store({"otherField": "yeah"});
      memoryTable.store({"otherField": "test"});
      memoryTable.store({"otherField": "test"});
      
      var updated = memoryTable.update({"otherField": "yeah"},
          {"otherField": "not yeah"});
      
      expect(memoryTable.records, equals([
        {"myField": 0},
        {"myField": 1, "otherField": "not yeah"},
        {"myField": 2, "otherField": "test"},
        {"myField": 3, "otherField": "test"}
      ]));
      
      expect(() => memoryTable.update({"otherField": "not yeah"},
          {"myField": 0}), throws);
    });
    
    test("applyIncrements", () {
      var fields = new Set.from([
        new Field("myField",
            constraints: new Set.from([Constraint.autoIncrement])),
        new Field("otherField")]);
      var table = new Table("table", fields);
      var memoryTable = new MemoryTable(table);
      
      var incremented1 = memoryTable.applyIncrements(new Record({
        "myField": null, "otherField": null
      }));
      var incremented2 = memoryTable.applyIncrements(new Record({
        "myField": 10
      }));
      var incremented3 = memoryTable.applyIncrements(new Record.empty());
      
      expect(incremented1.toMap(), equals({
        "myField": 0, "otherField": null
      }));
      expect(incremented2.toMap(), equals({
        "myField": 10
      }));
      expect(incremented3.toMap(), equals({
        "myField": 11
      }));
    });
  });
  
  group("Incrementor", () {
    test("getIncrement", () {
      var incrementor = new Incrementor();
      
      expect(incrementor.getIncrement("test"), equals(0));
      expect(incrementor.getIncrement("test"), equals(1));
      expect(incrementor.getIncrement("test"), equals(2));
      expect(incrementor.getIncrement("ping"), equals(0));
      expect(incrementor.getIncrement("ping"), equals(1));
    });
  });
  
  group("Validation", () {
    group("UniqueValidation", () {
      test("isValid", () {
        var u = new UniqueValidation();
        
        expect(u.isValid(1, [2, 3, 4]), isTrue);
        expect(u.isValid(1, [1, 2]), isFalse);
        expect(u.isValid(1, []), isTrue);
      });
      
      test("==", () {
        var u1 = new UniqueValidation();
        var u2 = new UniqueValidation();
        
        expect(u1, equals(u2));
      });
      
      test("hashCode", () {
        var u1 = new UniqueValidation();
        var u2 = new UniqueValidation();
        
        expect(u1.hashCode, equals(u2.hashCode));
        expect(u1.hashCode, equals(typeCode(UniqueValidation)));
      });
      
      test("shouldValidate", () {
        var c1s = new Set.from([Constraint.unique, Constraint.notNull]);
        var c2s = new Set.from([Constraint.notNull]);
        var c3s = new Set();
        var shouldValidate = UniqueValidation.shouldValidate;
        
        expect(shouldValidate(c1s), isTrue);
        expect(shouldValidate(c2s), isFalse);
        expect(shouldValidate(c3s), isFalse);
      });
    });
    
    group("NotNullValidation", () {
      test("isValid", () {
        var n = new NotNullValidation();
        
        expect(n.isValid(null, []), isFalse);
        expect(n.isValid("test", []), isTrue);
      });
      
      test("==", () {
        var n1 = new NotNullValidation();
        var n2 = new NotNullValidation();
        
        expect(n1, equals(n2));
      });
      
      test("hashCode", () {
        var n1 = new NotNullValidation();
        var n2 = new NotNullValidation();
        
        expect(n1.hashCode, equals(n2.hashCode));
        expect(n1.hashCode, equals(typeCode(NotNullValidation)));
      });
      
      test("shouldValidate", () {
        var c1s = new Set.from([Constraint.autoIncrement, Constraint.notNull]);
        var c2s = new Set.from([Constraint.notNull]);
        var c3s = new Set();
        var c4s = new Set.from([Constraint.primaryKey]);
        
        var shouldValidate = NotNullValidation.shouldValidate;
        expect(shouldValidate(c1s), isTrue);
        expect(shouldValidate(c2s), isTrue);
        expect(shouldValidate(c3s), isFalse);
        expect(shouldValidate(c4s), isTrue);
      });
    });
    
    group("TypeValidation", () {
      test("==", () {
        var v1 = new TypeValidation(FieldType.boolType);
        var v2 = new TypeValidation(FieldType.text);
        
        expect(v1, equals(v2));
      });
      
      test("hashCode", () {
        var v1 = new TypeValidation(FieldType.boolType);
        var v2 = new TypeValidation(FieldType.text);
        
        expect(v1.hashCode, equals(v2.hashCode));
        expect(v1.hashCode, equals(typeCode(TypeValidation)));
      });
      
      test("isValid", () {
        var numValidator = new TypeValidation(FieldType.number);
        var textValidator = new TypeValidation(FieldType.text);
        var boolValidator = new TypeValidation(FieldType.boolType);
        var dateValidator = new TypeValidation(FieldType.date);
        
        expect(numValidator.isValid(1, []), isTrue);
        expect(numValidator.isValid("t", []), isFalse);
        expect(textValidator.isValid("t", []), isTrue);
        expect(textValidator.isValid(1, []), isFalse);
        expect(boolValidator.isValid(true, []), isTrue);
        expect(boolValidator.isValid(1, []), isFalse);
        expect(dateValidator.isValid(new DateTime.now(), []), isTrue);
        expect(dateValidator.isValid(1, []), isFalse);
      });
    });
    
    group("Validator", () {
      test("isValid", () {
        var f1 = new Field("myfield");
        var f2 = new Field("other",
            constraints: new Set.from([Constraint.unique]));
        var v1 = new Validator(f1); 
        var v2 = new Validator(f2);
        
        expect(v1.isValid("test", ["test", "other", "some"]), isTrue);
        expect(v2.isValid("test", ["test", "other", "some"]), isFalse);
        expect(v1.isValid("test", []), isTrue);
        expect(v2.isValid("test", []), isTrue);
      });
      
      test("buildValidations", () {
        var f1 = new Field("other",
            constraints: new Set.from([Constraint.unique,
                                       Constraint.autoIncrement,
                                       Constraint.notNull]));
        var f2 = new Field("other",
            constraints: new Set.from([Constraint.notNull]));
        var f3 = new Field("other",
            constraints: new Set.from([Constraint.primaryKey]));
        
        var buildValidations = Validator.buildValidations;
        
        expect(buildValidations(f1),
            equals(new Set.from([new TypeValidation(null),
                                 Validation.uniqueValidation,
                                 Validation.notNullValidation])));
        expect(buildValidations(f2),
            equals(new Set.from([new TypeValidation(null),
                                 Validation.notNullValidation])));
        expect(buildValidations(f3),
            equals(new Set.from([new TypeValidation(null),
                                 Validation.notNullValidation,
                                 Validation.uniqueValidation])));
      });
    });
  });
}