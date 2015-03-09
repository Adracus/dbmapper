library dbmapper.test.definition;

import 'package:dbmapper/dbmapper.dart';

import 'package:unittest/unittest.dart';

main() => defineTests();

defineTests() {
  test("typeCode", () {
    var stringType = String;
    var intType = int;
    
    expect(stringType.hashCode, equals(typeCode(String)));
    expect(intType.hashCode, isNot(equals(typeCode(String))));
  });
  
  group("Definition", () {
    test("getTable", () {
      var fields1 = new Set.from([new Field("myField")]);
      var fields2 = new Set.from([new Field("otherField")]);
      var t1 = new Table("table", fields1);
      var t2 = new Table("othertable", fields2);
      var definition = new Definition(new Set.from([t1, t2]));
      
      expect(definition.getTable("table"), equals(t1));
      expect(definition.getTable("othertable"), equals(t2));
      expect(() => definition.getTable("notexist"), throws);
    });
  });
  
  group("Table", () {
    test("checkFields", () {
      expect(() => Table.checkFields(new Set()), throws);
      expect(() => Table.checkFields(new Set.from([new Field("test")])),
          returnsNormally);
    });
    
    test("==", () {
      var fields1 = new Set.from([new Field("myField")]);
      var fields2 = new Set.from([new Field("otherField")]);
      var t1 = new Table("table", fields1);
      var t2 = new Table("table", fields2);
      var t3 = new Table("notTable", fields1);
      
      expect(t1, equals(t2));
      expect(t1, isNot(equals(t3)));
    });
    
    test("getField", () {
      var fields = new Set.from([new Field("myField"), new Field("otherField")]);
      var t = new Table("table", fields);
      
      expect(t.getField("myField"), equals(new Field("myField")));
      expect(t.getField("otherField"), equals(new Field("otherField")));
      expect(() => t.getField("unknown"), throws);
    });
    
    test("hashCode", () {
      var fields1 = new Set.from([new Field("myField")]);
      var fields2 = new Set.from([new Field("otherField")]);
      var t1 = new Table("table", fields1);
      var t2 = new Table("table", fields2);
      var t3 = new Table("notTable", fields1);
      
      expect(t1.hashCode, equals(t2.hashCode));
      expect(t1.hashCode, isNot(equals(t3.hashCode)));
      expect(t1.hashCode, equals("table".hashCode));
    });
  });
  
  group("Field", () {
    test("Constructor", () {
      var f1 = new Field("test");
      var f2 = new Field("test", type: FieldType.integer);
      var f3 = new Field("test",
          type: FieldType.integer,
          constraints: new Set.from([unique]));
      var f4 = new Field("test",
          type: FieldType.integer,
          constraints: new Set.from([autoIncrement]));
      
      expect(f1.type, equals(FieldType.text));
      expect(f1.constraints, isEmpty);
      
      expect(f2.type, equals(FieldType.integer));
      expect(f2.constraints, isEmpty);
      
      expect(f3.type, equals(FieldType.integer));
      expect(f3.constraints, equals(new Set.from([unique])));
      
      expect(f4.type, equals(FieldType.integer));
      expect(f4.constraints, equals(new Set.from([autoIncrement])));
      
      expect(() => new Field("test",
          type: FieldType.text,
          constraints: new Set.from([autoIncrement])), throwsArgumentError);
    });
    
    test("==", () {
      var f1 = new Field("myfield");
      var f2 = new Field("myfield");
      var f3 = new Field("myfield", type: FieldType.integer);
      var f4 = new Field("notMyField");
      
      expect(f1, equals(f2));
      expect(f2, equals(f3));
      expect(f1, isNot(equals(f4)));
    });
    
    test("hashCode", () {
      var f1 = new Field("myfield");
      var f2 = new Field("myfield");
      var f3 = new Field("myfield", type: FieldType.integer);
      var f4 = new Field("notMyField");
      
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1.hashCode, equals(f3.hashCode));
      expect(f1.hashCode, isNot(equals(f4.hashCode)));
      expect(f1.hashCode, equals("myfield".hashCode));
    });
  });
  
  group("FieldType", () {
    group("Integer", () {
      test("==", () {
        var n1 = new Integer();
        var n2 = new Integer();
        
        expect(n1, equals(n2));
      });
      
      test("hashCode", () {
        var n1 = new Integer();
        var n2 = new Integer();
        
        expect(n1.hashCode, equals(n2.hashCode));
        expect(n1.hashCode, equals(typeCode(Integer)));
      });
    });
    
    group("Text", () {
      test("==", () {
        var t1 = new Text();
        var t2 = new Text();
        
        expect(t1, equals(t2));
      });
      
      test("hashCode", () {
        var t1 = new Text();
        var t2 = new Text();
        
        expect(t1.hashCode, equals(t2.hashCode));
        expect(t1.hashCode, equals(typeCode(Text)));
      });
    });
    
    group("Double", () {
      test("==", () {
        var d1 = new Double();
        var d2 = new Double();
        
        expect(d1, equals(d2));
      });
      
      test("hashCode", () {
        var d1 = new Double();
        var d2 = new Double();
        
        expect(d1.hashCode, equals(d2.hashCode));
        expect(d1.hashCode, equals(typeCode(Double)));
      });
    });
    
    group("Bool", () {
      test("==", () {
        var b1 = new Bool();
        var b2 = new Bool();
        
        expect(b1, equals(b2));
      });
      
      test("hashCode", () {
        var b1 = new Bool();
        var b2 = new Bool();
        
        expect(b1.hashCode, equals(b2.hashCode));
        expect(b1.hashCode, equals(typeCode(Bool)));
      });
    });
    
    group("Date", () {
      test("==", () {
        var d1 = new Date();
        var d2 = new Date();
        
        expect(d1, equals(d2));
      });
      
      test("hashCode", () {
        var d1 = new Date();
        var d2 = new Date();
        
        expect(d1.hashCode, equals(d2.hashCode));
        expect(d1.hashCode, equals(typeCode(Date)));
      });
    });
  });
  
  group("Constraint", () {
    group("Unique", () {
      test("==", () {
        var u1 = new Unique();
        var u2 = new Unique();
        
        expect(u1, equals(u2));
      });
      
      test("hashCode", () {
        var u1 = new Unique();
        var u2 = new Unique();
        
        expect(u1.hashCode, equals(u2.hashCode));
        expect(u1.hashCode, equals(typeCode(Unique)));
      });
      
      test("compatible", () {
        expect(FieldType.types.every(unique.compatible), isTrue);
      });
    });
    
    group("PrimaryKey", () {
      test("==", () {
        var p1 = new PrimaryKey();
        var p2 = new PrimaryKey();
        
        expect(p1, equals(p2));
      });
      
      test("hashCode", () {
        var p1 = new PrimaryKey();
        var p2 = new PrimaryKey();
        
        expect(p1.hashCode, equals(p2.hashCode));
        expect(p1.hashCode, equals(typeCode(PrimaryKey)));
      });
      
      test("compatible", () {
        expect(FieldType.types.every(primaryKey.compatible), isTrue);
      });
    });
    
    group("AutoIncrement", () {
      test("==", () {
        var a1 = new AutoIncrement();
        var a2 = new AutoIncrement();
        
        expect(a1, equals(a2));
      });
      
      test("hashCode", () {
        var a1 = new AutoIncrement();
        var a2 = new AutoIncrement();
        
        expect(a1.hashCode, equals(a2.hashCode));
        expect(a1.hashCode, equals(typeCode(AutoIncrement)));
      });
      
      test("comptatible", () {
        expect(autoIncrement.compatible(FieldType.integer), isTrue);
        expect(FieldType.types.where((field) => field is! Integer)
                              .every((type) => !autoIncrement.compatible(type)),
                              isTrue);
      });
    });
    
    group("NotNull", () {
      test("==", () {
        var n1 = new NotNull();
        var n2 = new NotNull();
        
        expect(n1, equals(n2));
      });
      
      test("hashCode", () {
        var n1 = new NotNull();
        var n2 = new NotNull();
        
        expect(n1.hashCode, equals(n2.hashCode));
        expect(n1.hashCode, equals(typeCode(NotNull)));
      });
      
      test("compatible", () {
        expect(FieldType.types.every(notNull.compatible), isTrue);
      });
    });
  });
}