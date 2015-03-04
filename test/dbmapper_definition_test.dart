library dbmapper.test.definition;

import 'package:dbmapper/dbmapper.dart';

import 'package:unittest/unittest.dart';

main() => defineTests();

defineTests() {
  group("Field", () {
    test("==", () {
      var f1 = new Field("myfield");
      var f2 = new Field("myfield");
      var f3 = new Field("myfield", type: FieldType.number);
      var f4 = new Field("notMyField");
      
      expect(f1, equals(f2));
      expect(f2, equals(f3));
      expect(f1, isNot(equals(f4)));
    });
    
    test("hashCode", () {
      var f1 = new Field("myfield");
      var f2 = new Field("myfield");
      var f3 = new Field("myfield", type: FieldType.number);
      var f4 = new Field("notMyField");
      
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1.hashCode, equals(f3.hashCode));
      expect(f1.hashCode, isNot(equals(f4.hashCode)));
      expect(f1.hashCode, equals("myfield".hashCode));
    });
  });
  
  group("FieldType", () {
    group("Number", () {
      test("==", () {
        var n1 = new Number();
        var n2 = new Number();
        
        expect(n1, equals(n2));
      });
      
      test("hashCode", () {
        var n1 = new Number();
        var n2 = new Number();
        
        expect(n1.hashCode, equals(n2.hashCode));
        expect(n1.hashCode, equals(typeCode(Number)));
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
    });
  });
}