library dbmapper.test.mirrors;

import 'dart:mirrors';

import 'package:dbmapper/dbmapper.dart';

import 'package:unittest/unittest.dart';

main() => defineTests();

class User {
  static int userCount = 0;
  
  @unique
  String name;
  String mail;
}

class Admin extends User {
  String adminName;
}

equalFields(Field f1, Field f2) {
  expect(f1.name, equals(f2.name));
  expect(f1.constraints.difference(f2.constraints), isEmpty);
  expect(f1.type, equals(f2.type));
}

defineTests() {
  group("getFields", () {
    test("non recursive", () {
      var userFields = getFields(User);
      var adminFields = getFields(Admin);
      
      expect(userFields.keys.toList(),
          equals([#userCount, #name, #mail]));
      expect(adminFields.keys.toList(),
          equals([#adminName]));
    });
    
    test("recursive", () {
      var fields = getFields(User, recursive: true);
      
      expect(fields.keys.take(3).toList(),
          equals([#userCount, #name, #mail]));
      var last = fields.keys.last; // Some strange equality bug in symbols
      var name = MirrorSystem.getName(last);
      expect(name, equals("_hashCodeRnd"));
    });
  });
  
  group("instanceFields", () {
    test("non recursive", () {
      var userFields = getInstanceFields(User);
      var adminFields = getInstanceFields(Admin);
      
      expect(userFields.keys.toList(), equals([#name, #mail]));
      expect(adminFields.keys.toList(), equals([#adminName]));
    });
    
    test("recursive", () {
      var userFields = getInstanceFields(User, recursive: true);
      var adminFields = getInstanceFields(Admin, recursive: true);
      
      expect(userFields.keys.toList(), equals([#name, #mail]));
      expect(adminFields.keys.toList(), equals([#adminName, #name, #mail]));
    });
  });
  
  group("ValueExtractor", () {
    group("Constructor", () {
      test("non recursive", () {
        var e1 = new ValueExtractor<User>(User);
        var e2 = new ValueExtractor<Admin>(Admin);
        
        expect(e1.symbolNames, equals({
          #name: "name",
          #mail: "mail"
        }));
        
        expect(e2.symbolNames, equals({
          #adminName: "adminName"
        }));
      });
      
      test("recursive", () {
        var e1 = new ValueExtractor<User>(User, recursive: true);
        var e2 = new ValueExtractor<Admin>(Admin, recursive: true);
        
        expect(e1.symbolNames, equals({
          #name: "name",
          #mail: "mail"
        }));
        
        expect(e2.symbolNames, equals({
          #name: "name",
          #mail: "mail",
          #adminName: "adminName"
        }));
      });
    });
    
    group("extractValues", () {
      test("non recursive", () {
        var admin = new Admin()
          ..adminName = "root"
          ..mail = "admin@example.org"
          ..name = "guenther";
        var user = new User()
          ..name = "john"
          ..mail = "john@example.org";
        
        var userValues = ValueExtractor.extractValues(user);
        var adminValues = ValueExtractor.extractValues(admin);
        
        expect(userValues, equals({
          "name": "john", "mail": "john@example.org"
        }));
        expect(adminValues, equals({
          "adminName": "root"
        }));
      });
      
      test("recursive", () {
        var admin = new Admin()
          ..adminName = "root"
          ..mail = "admin@example.org"
          ..name = "guenther";
        var user = new User()
          ..name = "john"
          ..mail = "john@example.org";
        
        var userValues = ValueExtractor.extractValues(user, recursive: true);
        var adminValues = ValueExtractor.extractValues(admin, recursive: true);
        
        expect(userValues, equals({
          "name": "john", "mail": "john@example.org"
        }));
        expect(adminValues, equals({
          "adminName": "root",
          "name": "guenther", "mail": "admin@example.org"
        }));
      });
    });
  });
  
  group("tableFromClass", () {
    test("non recursive", () {
      var t1 = tableFromClass(User);
      var t2 = tableFromClass(Admin);
      var nameField = (new FieldBuilder("name", type: FieldType.text)
        ..addConstraint(unique))
        .build();
      var mailField = new FieldBuilder("mail", type: FieldType.text).build();
      var adminNameField = new FieldBuilder("adminName", type: FieldType.text).build();
      
      equalFields(t2.fields.single, adminNameField);
      equalFields(t1.fields.first, nameField);
      equalFields(t1.fields.last, mailField);
    });
    
    test("recursive", () {
      var t1 = tableFromClass(User, recursive: true);
      var t2 = tableFromClass(Admin, recursive: true);
      var nameField = (new FieldBuilder("name", type: FieldType.text)
        ..addConstraint(unique))
        .build();
      var mailField = new FieldBuilder("mail", type: FieldType.text).build();
      var adminNameField = new FieldBuilder("adminName", type: FieldType.text).build();
      
      equalFields(t1.fields.toList()[0], nameField);
      equalFields(t1.fields.toList()[1], mailField);
      equalFields(t2.fields.toList()[0], adminNameField);
      equalFields(t2.fields.toList()[1], nameField);
      equalFields(t2.fields.toList()[2], mailField);
    });
  });
  
  test("typeMapping", () {
    expect(typeMapping(reflectType(String)), equals(FieldType.text));
    expect(typeMapping(reflectType(bool)), equals(FieldType.boolType));
    expect(typeMapping(reflectType(DateTime)), equals(FieldType.date));
    expect(typeMapping(reflectType(int)), equals(FieldType.number));
    expect(() => typeMapping(reflectType(Symbol)), throws);
    expect(typeMapping(reflectType(Symbol), toField: (mirror) => FieldType.date),
        equals(FieldType.date));
  });
}