part of 'library.dart';

class Configurations {
  String id;
  String package;
  String? language;
  bool? debugging;
  Environment? environment;
  bool httpLogging;

  Configurations({required this.id, required this.package, this.language, this.debugging, this.environment, this.httpLogging = false});

  @override
  String toString() =>
      'Configurations{id: $id, package: $package, language: $language, debugging: $debugging, environment: $environment, httpLogging: $httpLogging}';
}
