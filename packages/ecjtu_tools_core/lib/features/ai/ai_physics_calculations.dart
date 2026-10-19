// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import '../physics/physics_catalog.dart';
import '../physics/physics_decimal.dart';
import '../physics/physics_electron_charge_models.dart';
import '../physics/physics_electron_charge_calculator.dart';
import '../physics/physics_electrostatic_field_models.dart';
import '../physics/physics_electrostatic_field_calculator.dart';
import '../physics/physics_enamel_wire_resistivity_models.dart';
import '../physics/physics_enamel_wire_resistivity_calculator.dart';
import '../physics/physics_franck_hertz_models.dart';
import '../physics/physics_franck_hertz_calculator.dart';
import '../physics/physics_galvanometer_models.dart';
import '../physics/physics_galvanometer_calculator.dart';
import '../physics/physics_hall_effect_models.dart';
import '../physics/physics_hall_effect_calculator.dart';
import '../physics/physics_liquid_refraction_models.dart';
import '../physics/physics_liquid_refraction_calculator.dart';
import '../physics/physics_metal_work_function_models.dart';
import '../physics/physics_metal_work_function_calculator.dart';
import '../physics/physics_millikan_oil_drop_models.dart';
import '../physics/physics_millikan_oil_drop_calculator.dart';
import '../physics/physics_newton_rings_models.dart';
import '../physics/physics_newton_rings_calculator.dart';
import '../physics/physics_ohmmeter_models.dart';
import '../physics/physics_ohmmeter_calculator.dart';
import '../physics/physics_photoelectric_planck_models.dart';
import '../physics/physics_photoelectric_planck_calculator.dart';
import '../physics/physics_potential_difference_models.dart';
import '../physics/physics_potential_difference_calculator.dart';
import '../physics/physics_rheostat_characteristic_models.dart';
import '../physics/physics_rheostat_characteristic_calculator.dart';
import '../physics/physics_rigid_rotation_models.dart';
import '../physics/physics_rigid_rotation_calculator.dart';
import '../physics/physics_single_arm_bridge_models.dart';
import '../physics/physics_single_arm_bridge_calculator.dart';
import '../physics/physics_solid_density_models.dart';
import '../physics/physics_solid_density_calculator.dart';
import '../physics/physics_sound_speed_models.dart';
import '../physics/physics_sound_speed_calculator.dart';
import '../physics/physics_voltage_current_models.dart';
import '../physics/physics_voltage_current_calculator.dart';
import '../physics/physics_youngs_modulus_models.dart';
import '../physics/physics_youngs_modulus_calculator.dart';
import 'ai_models.dart';
import 'ai_physics_units.dart';

class AiPhysicsCalculations {
  static final _adapters = <String, _PhysicsAdapter>{
    'electron-charge': _PhysicsAdapter(
      () => ElectronChargeState.fromJson(null).toJson(),
      (data) => ElectronChargeCalculator.calculate(
        ElectronChargeState.fromJson(data),
      ).toJson(),
    ),
    'electrostatic-field': _PhysicsAdapter(
      () => ElectrostaticFieldState.fromJson(null).toJson(),
      (data) => ElectrostaticFieldCalculator.calculate(
        ElectrostaticFieldState.fromJson(data),
      ).toJson(),
    ),
    'enamel-wire-resistivity': _PhysicsAdapter(
      () => EnamelWireResistivityState.fromJson(null).toJson(),
      (data) => EnamelWireResistivityCalculator.calculate(
        EnamelWireResistivityState.fromJson(data),
      ).toJson(),
    ),
    'franck-hertz': _PhysicsAdapter(
      () => FranckHertzState.fromJson(null).toJson(),
      (data) => FranckHertzCalculator.calculate(
        FranckHertzState.fromJson(data),
      ).toJson(),
    ),
    'galvanometer': _PhysicsAdapter(
      () => GalvanometerState.fromJson(null).toJson(),
      (data) => GalvanometerCalculator.calculate(
        GalvanometerState.fromJson(data),
      ).toJson(),
    ),
    'hall-effect': _PhysicsAdapter(
      () => HallEffectState.fromJson(null).toJson(),
      (data) => HallEffectCalculator.calculate(
        HallEffectState.fromJson(data),
      ).toJson(),
    ),
    'liquid-refractive-index': _PhysicsAdapter(
      () => LiquidRefractionState.fromJson(null).toJson(),
      (data) => LiquidRefractionCalculator.calculate(
        LiquidRefractionState.fromJson(data),
      ).toJson(),
    ),
    'metal-work-function': _PhysicsAdapter(
      () => MetalWorkState.fromJson(null).toJson(),
      (data) =>
          MetalWorkCalculator.calculate(MetalWorkState.fromJson(data)).toJson(),
    ),
    'millikan-oil-drop': _PhysicsAdapter(
      () => MillikanState.fromJson(null).toJson(),
      (data) =>
          MillikanCalculator.calculate(MillikanState.fromJson(data)).toJson(),
    ),
    'newton-rings': _PhysicsAdapter(
      () => NewtonRingsState.fromJson(null).toJson(),
      (data) => NewtonRingsCalculator.calculate(
        NewtonRingsState.fromJson(data),
      ).toJson(),
    ),
    'ohmmeter': _PhysicsAdapter(
      () => OhmmeterState.fromJson(null).toJson(),
      (data) =>
          OhmmeterCalculator.calculate(OhmmeterState.fromJson(data)).toJson(),
    ),
    'photoelectric-planck': _PhysicsAdapter(
      () => PhotoelectricPlanckState.fromJson(null).toJson(),
      (data) => PhotoelectricPlanckCalculator.calculate(
        PhotoelectricPlanckState.fromJson(data),
      ).toJson(),
    ),
    'potential-difference': _PhysicsAdapter(
      () => PotentialDifferenceState.fromJson(null).toJson(),
      (data) => PotentialDifferenceCalculator.calculate(
        PotentialDifferenceState.fromJson(data),
      ).toJson(),
    ),
    'rheostat-characteristic': _PhysicsAdapter(
      () => RheostatState.fromJson(null).toJson(),
      (data) => RheostatCharacteristicCalculator.calculate(
        RheostatState.fromJson(data),
      ).toJson(),
    ),
    'rigid-rotation': _PhysicsAdapter(
      () => RigidRotationState.fromJson(null).toJson(),
      (data) => RigidRotationCalculator.calculate(
        RigidRotationState.fromJson(data),
      ).toJson(),
    ),
    'single-arm-bridge': _PhysicsAdapter(
      () => SingleArmBridgeState.fromJson(null).toJson(),
      (data) => SingleArmBridgeCalculator.calculate(
        SingleArmBridgeState.fromJson(data),
      ).toJson(),
    ),
    'solid-density': _PhysicsAdapter(
      () => SolidDensityState.fromJson(null).toJson(),
      (data) => SolidDensityCalculator.calculate(
        SolidDensityState.fromJson(data),
      ).toJson(),
    ),
    'sound-speed': _PhysicsAdapter(
      () => SoundSpeedState.fromJson(null).toJson(),
      (data) => SoundSpeedCalculator.calculate(
        SoundSpeedState.fromJson(data),
      ).toJson(),
    ),
    'voltage-current': _PhysicsAdapter(
      () => VoltageCurrentState.fromJson(null).toJson(),
      (data) => VoltageCurrentCalculator.calculate(
        VoltageCurrentState.fromJson(data),
      ).toJson(),
    ),
    'youngs-modulus': _PhysicsAdapter(
      () => YoungsModulusState.fromJson(null).toJson(),
      (data) => YoungsModulusCalculator.calculate(
        YoungsModulusState.fromJson(data),
      ).toJson(),
    ),
  };

  static List<String> get experimentIds =>
      PhysicsCatalog.calculators.map((item) => item.id).toList();

  static Map<String, Object?> catalog(Map<String, Object?> args) {
    _keys(args, {'query', 'offset', 'limit'});
    final query = args.containsKey('query') ? args['query'] : '';
    final offset = args.containsKey('offset') ? args['offset'] : 0;
    final limit = args.containsKey('limit') ? args['limit'] : 20;
    if (query is! String ||
        query.length > 128 ||
        offset is! int ||
        offset < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > 20) {
      _invalid();
    }
    final matched = PhysicsCatalog.calculators
        .where(
          (item) => '${item.id} ${item.title} ${item.detail}'
              .toLowerCase()
              .contains(query.toLowerCase()),
        )
        .toList();
    return {
      'total': matched.length,
      'offset': offset,
      'nextOffset': offset + limit < matched.length ? offset + limit : null,
      'experiments': [
        for (final item in matched.skip(offset).take(limit))
          {
            'id': item.id,
            'title': item.title,
            'description': item.detail,
            'schemaTool': 'ecjtu_get_physics_schema',
            'calculationTool': 'ecjtu_calculate_physics',
          },
      ],
    };
  }

  static _PhysicsAdapter _adapter(Object? id) {
    if (id is! String || !_adapters.containsKey(id)) {
      throw const AiToolException('unknown_physics_experiment', '未找到此物理实验');
    }
    return _adapters[id]!;
  }

  static Map<String, Object?> getSchema(Map<String, Object?> args) {
    _keys(args, {'experimentId'});
    final adapter = _adapter(args['experimentId']);
    final defaults = adapter.defaults();
    return {
      'experimentId': args['experimentId'],
      'defaults': defaults,
      'inputSchema': _schema(defaults, ''),
      'units': _units[args['experimentId']] ?? <String, String>{},
      'unitReference': '字段采用对应实验页面的输入单位，不自动换算',
      'numberFormat': '测量值接受有限 JSON 数字或十进制字符串（支持科学计数）；空字符串保留为未填写',
    };
  }

  static Map<String, Object?> calculate(Map<String, Object?> args) {
    _keys(args, {'experimentId', 'data'});
    final adapter = _adapter(args['experimentId']);
    if (!args.containsKey('data') || args['data'] is! Map<String, Object?>) {
      _invalid();
    }
    final normalized =
        _normalize(args['data'], adapter.defaults(), '')
            as Map<String, Object?>;
    final raw = adapter.calculate(normalized);
    final nonFinite = <String>[];
    final result = _jsonSafe(raw, '', nonFinite);
    return {
      'experimentId': args['experimentId'],
      'calculation': result,
      'nonFiniteResultFields': nonFinite,
    };
  }

  static Map<String, Object?> normalizeInputs(String id, Object? data) =>
      _normalize(data, _adapter(id).defaults(), '') as Map<String, Object?>;

  static bool _fixed(String path, Object? template) =>
      path.startsWith('calibrationSettings.') ||
      path.endsWith('.id') ||
      path.endsWith('.type') ||
      template is int ||
      path.startsWith('calibration.') && path.endsWith('.resistance');

  static Object? _normalize(Object? value, Object? template, String path) {
    if (_fixed(path, template)) {
      if (jsonEncode(value) != jsonEncode(template)) {
        if (template is String &&
            PhysicsDecimal.parse(template) != null &&
            value is num &&
            value.isFinite &&
            value == num.tryParse(template)) {
          return template;
        }
        _invalid(path);
      }
      return template;
    }
    if (template is Map) {
      if (value is! Map<String, Object?> ||
          value.keys.any((key) => !template.containsKey(key))) {
        _invalid(path);
      }
      return <String, Object?>{
        for (final entry in template.entries)
          '${entry.key}': value.containsKey(entry.key)
              ? _normalize(
                  value[entry.key],
                  entry.value,
                  path.isEmpty ? '${entry.key}' : '$path.${entry.key}',
                )
              : entry.value,
      };
    }
    if (template is List) {
      if (value is! List || value.length != template.length) _invalid(path);
      return [
        for (var index = 0; index < template.length; index++)
          _normalize(value[index], template[index], '$path.$index'),
      ];
    }
    if (template is String) {
      if (value is num) {
        if (!value.isFinite) _invalid(path);
        value = value.toString();
      }
      if (value is! String || value.length > 80) _invalid(path);
      final text = value.trim();
      if (text.isEmpty) return '';
      if (!RegExp(
            r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$',
          ).hasMatch(text) ||
          PhysicsDecimal.parse(text) == null ||
          !(num.tryParse(text)?.isFinite ?? false)) {
        _invalid(path);
      }
      return text;
    }
    if (value.runtimeType != template.runtimeType) _invalid(path);
    return value;
  }

  static Map<String, Object?> _schema(Object? value, String path) {
    if (_fixed(path, value)) return {'const': value, 'default': value};
    if (value is Map) {
      return {
        'type': 'object',
        'additionalProperties': false,
        'properties': {
          for (final entry in value.entries)
            '${entry.key}': _schema(
              entry.value,
              path.isEmpty ? '${entry.key}' : '$path.${entry.key}',
            ),
        },
      };
    }
    if (value is List) {
      return {
        'type': 'array',
        'minItems': value.length,
        'maxItems': value.length,
        'prefixItems': [
          for (var index = 0; index < value.length; index++)
            _schema(value[index], '$path.$index'),
        ],
        'items': false,
      };
    }
    return {
      'anyOf': [
        {'type': 'number'},
        {
          'type': 'string',
          'maxLength': 80,
          'pattern': r'^$|^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$',
        },
      ],
      'default': value,
    };
  }

  static Object? _jsonSafe(Object? value, String path, List<String> nonFinite) {
    if (value is num && !value.isFinite) {
      nonFinite.add(path);
      return null;
    }
    if (value is Map) {
      return {
        for (final entry in value.entries)
          '${entry.key}': _jsonSafe(
            entry.value,
            '$path.${entry.key}',
            nonFinite,
          ),
      };
    }
    if (value is List) {
      return [
        for (var index = 0; index < value.length; index++)
          _jsonSafe(value[index], '$path.$index', nonFinite),
      ];
    }
    return value;
  }

  static void _keys(Map<String, Object?> args, Set<String> allowed) {
    if (args.keys.any((key) => !allowed.contains(key))) _invalid();
  }

  static Never _invalid([String path = '']) => throw AiToolException(
    'invalid_physics_data',
    path.isEmpty ? '物理实验参数不正确' : '物理实验字段 $path 的类型、结构或数量不正确',
  );

  static const _units = AiPhysicsUnits.byExperiment;
}

class _PhysicsAdapter {
  const _PhysicsAdapter(this.defaults, this.calculate);
  final Map<String, Object?> Function() defaults;
  final Map<String, Object?> Function(Map<String, Object?> data) calculate;
}
