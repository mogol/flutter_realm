# flutter_realm

A Flutter plugin to use [Realm Database](https://realm.io).

Note: This plugin is still under development, and some APIs might not be available yet. Feedback and Pull Requests are most welcome!

## Important

Current implementation requires definition of schema in native [Java](https://github.com/mogol/flutter_realm/blob/master/example/android/app/src/main/java/com/example/flutter_realm_example/Product.java) and [ObjC](https://github.com/mogol/flutter_realm/blob/master/example/ios/Runner/RealmSchema.h) host apps.
  
## Getting Started

See the `example` directory for a complete sample app using Realm Database.

## Setup
* Add flutter_realm as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).
* Add Realm 5.13.0 to your [Android host app](https://realm.io/docs/java/latest#getting-started)
* Add models files in  in native [Java](https://github.com/mogol/flutter_realm/blob/master/example/android/app/src/main/java/com/example/flutter_realm_example/Product.java) and [ObjC](https://github.com/mogol/flutter_realm/blob/master/example/ios/Runner/RealmSchema.h) host apps.  

## Features 

- [x] Persistent and In-memory Realm
- [x] deleteAllObjects
- [x] Get allObjects by classname
- [x] Create object 
- [x] Delete object 
- [x] Update object 
- [x] Query with `>`, `>=`, `<`, `<=`, `=`, `!=` and `contains` operators on fields
- [x] Subscribe on queries and allObjects
- [x] Fields with array of String and int


 
