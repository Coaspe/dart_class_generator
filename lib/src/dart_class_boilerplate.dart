import 'dart:io';

/// Provides several methods that generate class boilerplate codes.
///
/// Use this methods for data models.
/// You must use Dart formatter to use this class.
class DartClassBoilerplate {
  /// Build class with given fields spec
  ///
  /// You must use Dart formatter to use this class.
  ///
  /// For example:
  ///
  /// ```dart
  /// class TestClass {
  ///   final String str;
  ///   int num;
  /// }
  /// ```
  ///
  /// Above code snippet generates:
  ///
  /// ```dart
  /// class TestClass{
  ///   TestClass({
  ///   required this.str,
  ///   required this.num,
  ///   })
  /// }
  /// ```
  static void buildConstructor(String folderPath) async {
    File file = File(folderPath);
    final readFile = await file.readAsLines();

    List<String> fields = [];
    int classLine = -1;
    String className = "";
    bool constFlag = true;

    // Find start line number of class.
    for (var i = 0; i < readFile.length; i++) {
      if (readFile[i].contains("class ")) {
        classLine = i;
        className = readFile[i].split('class ')[1].split(' {')[0];
        break;
      }
    }

    if (classLine == -1 || className == "")
      throw Exception("There is no class");

    fields.addAll(readFile.getRange(0, classLine + 1));
    fields.add('$className ({');

    // Process fields.
    for (var i = classLine + 1; i < readFile.length; i++) {
      var fieldsLine = readFile[i].trim().split(' ');
      if (fieldsLine.length < 2) continue;
      if (fieldsLine.length == 2) constFlag = false;
      fields.add(fieldsLine.sublist(fieldsLine.length - 2).join(' '));
    }
    // Check can constructor be const.
    if (constFlag) {
      fields[classLine + 1] = 'const ${fields[classLine + 1]}';
    }
    fields.add('});');

    if (fields.length <= 3) throw Exception("Has no field");

    // Combine type, name and required keyword if needed.
    for (var i = 2; i < fields.length - 1; i++) {
      var splited = fields[i].split(' ');
      String type = splited[0];
      String name = splited[1];
      String fieldName = 'this.${name.substring(0, name.length - 1)},';
      if (type[type.length - 1] != '?') {
        fieldName = 'required $fieldName';
      }
      fields[i] = fieldName;
    }

    // Rewrite all
    fields.addAll(readFile.getRange(1, readFile.length));
    await file.writeAsString(fields.join('\n'));
  }

  /// Add boilerplate code for json_serializable pacakges
  ///
  /// [folderPath] represents folder that has model classes.
  static void addSerializationStrings(String folderPath) async {
    Uri uri = Uri.parse(folderPath);
    Directory current = Directory.fromUri(uri);
    await for (var element in current.list()) {
      File file = File(element.path);
      String fileName = file.path.split("/").last.split('.')[0];
      final readFile = await file.readAsLines();
      int classLine = -1;
      int lastCloseBracket = -1;
      String partString = "part '$fileName.g.dart';";
      String importString =
          "import 'package:json_annotation/json_annotation.dart';";
      String jsonString = "@JsonSerializable(createToJson: false)";
      String className = "";
      for (var i = 0; i < readFile.length; i++) {
        if (classLine == -1 && readFile[i].contains("class ")) {
          classLine = i;
          className = readFile[i].split('class ')[1].split(' ')[0];
        }
        if (readFile[i] == '}') {
          lastCloseBracket = i;
        }
      }
      String factoryString =
          "factory $className.fromJson(json) => _\$${className}FromJson(json);";

      if (classLine != -1 && lastCloseBracket != -1 && className != "") {
        readFile.insert(lastCloseBracket, factoryString);
        readFile.insert(classLine, jsonString);
        readFile.insert(classLine, partString);
        readFile.insert(0, importString);
        await file.writeAsString(readFile.join('\n'));
      }
    }
  }

  static void addModelExport(String folderPath) async {
    Directory current = Directory.fromUri(Uri.parse(folderPath));
    List<String> arr = [];
    await for (var element in current.list()) {
      File file = File(element.path);
      String fileName = file.path.split("/").last;
      if (fileName.contains('.g.dart')) continue;
      arr.add("export '$fileName';");
    }
    await File('$folderPath/model.dart').writeAsString(arr.join('\n'));
  }
}
