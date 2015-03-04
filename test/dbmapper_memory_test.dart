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
    
    test("applyIncrements", () {
      var fields = new Set.from([
        new Field("myField",
            constraints: new Set.from([Constraint.autoIncrement])),
        new Field("otherField")]);
      var table = new Table("table", fields);
      var memoryTable = new MemoryTable(table);
      
      var incremented1 = memoryTable.applyIncrements({
        "myField": null, "otherField": null
      });
      var incremented2 = memoryTable.applyIncrements({
        "myField": 10
      });
      var incremented3 = memoryTable.applyIncrements({
      });
      
      expect(incremented1, equals({
        "myField": 0, "otherField": null
      }));
      expect(incremented2, equals({
        "myField": 10
      }));
      expect(incremented3, equals({
        "myField": 1
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
    });
  });
}