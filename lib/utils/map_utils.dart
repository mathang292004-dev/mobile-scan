// utils/map_utils.dart

import 'package:emergex/data/model/incident/incident_detail.dart';

class MapUtils {
  /// Helper method to find a key case-insensitively in a map
  static String? _findCaseInsensitiveKey(Map? map, String targetKey) {
    if (map == null) return null;
    final lowerTarget = targetKey.toLowerCase();
    for (var key in map.keys) {
      if (key is String && key.toLowerCase() == lowerTarget) {
        return key;
      }
    }
    return null;
  }

  /// Safely gets a value from a nested map using dot notation or direct key access
  static dynamic getValueFromMap(
    dynamic map, {
    String? key,
    List<String>? path,
    dynamic defaultValue,
  }) {
    if (map == null) return defaultValue;

    final keys = path ?? (key != null ? [key] : []);

    if (keys.isEmpty) return map is Map ? map : defaultValue;

    dynamic current = map;

    for (final currentKey in keys) {
      if (current is Map) {
        // First try exact match
        if (current.containsKey(currentKey)) {
          current = current[currentKey];
        } else {
          // Try case-insensitive lookup for observation keys
          final foundKey = _findCaseInsensitiveKey(current, currentKey);
          if (foundKey != null) {
            current = current[foundKey];
          } else {
            return defaultValue;
          }
        }
      } else {
        return defaultValue;
      }
    }

    return current ?? defaultValue;
  }

  /// Gets a String value from nested map
  static String getString(
    dynamic map, {
    String? key,
    List<String>? path,
    String defaultValue = '',
  }) {
    final value = getValueFromMap(
      map,
      key: key,
      path: path,
      defaultValue: defaultValue,
    );
    return value?.toString() ?? defaultValue;
  }

  // Add this to your MapUtils class
  static dynamic getDynamic(
    Map<String, dynamic>? map, {
    required List<String> path,
    dynamic defaultValue,
  }) {
    if (map == null) return defaultValue;
    dynamic current = map;
    for (String key in path) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return defaultValue;
      }
    }
    return current;
  }

  /// Gets a bool value from nested map
  static bool getBool(
    dynamic map, {
    String? key,
    List<String>? path,
    bool defaultValue = false,
  }) {
    final value = getValueFromMap(map, key: key, path: path);
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is int) return value == 1;
    return defaultValue;
  }

  static Map<String, BehaviourItem?> getBehaviorItems(dynamic map) {
    final result = <String, BehaviourItem?>{};
    if (map is Map<String, dynamic>) {
      map.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          result[key] = BehaviourItem(
            safe: value['safe'] ?? false,
            atRisk: value['atRisk'] ?? false,
          );
        }
      });
    }
    return result;
  }

  /// Gets a Map from nested map
  static Map<String, dynamic> getMap(
    dynamic map, {
    String? key,
    List<String>? path,
    Map<String, dynamic> defaultValue = const {},
  }) {
    final value = getValueFromMap(map, key: key, path: path);
    if (value is Map) {
      try {
        return value.cast<String, dynamic>();
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// Gets a List from nested map
  static List<T> getList<T>(
    dynamic map, {
    String? key,
    List<String>? path,
    List<T> defaultValue = const [],
  }) {
    final value = getValueFromMap(map, key: key, path: path);
    if (value is List) {
      try {
        return value.cast<T>();
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  static Map<String, dynamic> getOthers(dynamic map) {
    return getMap(map, key: 'others');
  }
}
