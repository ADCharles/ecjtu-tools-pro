// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:js_interop';
import 'package:flutter/material.dart';
import '../../theme/ecjtu_theme.dart';
import 'physics_storage_scope.dart';
import 'physics_component_pdf.dart';

import 'physics_electron_charge_page.dart';
import 'physics_electron_charge_storage.dart';
import 'physics_electrostatic_field_page.dart';
import 'physics_electrostatic_field_storage.dart';
import 'physics_enamel_wire_resistivity_page.dart';
import 'physics_enamel_wire_resistivity_storage.dart';
import 'physics_franck_hertz_page.dart';
import 'physics_franck_hertz_storage.dart';
import 'physics_galvanometer_page.dart';
import 'physics_galvanometer_storage.dart';
import 'physics_hall_effect_page.dart';
import 'physics_hall_effect_storage.dart';
import 'physics_liquid_refraction_page.dart';
import 'physics_liquid_refraction_storage.dart';
import 'physics_metal_work_function_page.dart';
import 'physics_metal_work_function_storage.dart';
import 'physics_millikan_oil_drop_page.dart';
import 'physics_millikan_oil_drop_storage.dart';
import 'physics_newton_rings_page.dart';
import 'physics_newton_rings_storage.dart';
import 'physics_ohmmeter_page.dart';
import 'physics_ohmmeter_storage.dart';
import 'physics_photoelectric_planck_page.dart';
import 'physics_photoelectric_planck_storage.dart';
import 'physics_potential_difference_page.dart';
import 'physics_potential_difference_storage.dart';
import 'physics_rheostat_characteristic_page.dart';
import 'physics_rheostat_characteristic_storage.dart';
import 'physics_rigid_rotation_page.dart';
import 'physics_rigid_rotation_storage.dart';
import 'physics_single_arm_bridge_page.dart';
import 'physics_single_arm_bridge_storage.dart';
import 'physics_solid_density_page.dart';
import 'physics_solid_density_storage.dart';
import 'physics_sound_speed_page.dart';
import 'physics_sound_speed_storage.dart';
import 'physics_voltage_current_page.dart';
import 'physics_voltage_current_storage.dart';
import 'physics_youngs_modulus_page.dart';
import 'physics_youngs_modulus_storage.dart';

@JS('ecjtuPhysicsOpen')
external set _openCalculator(JSFunction callback);

@JS('ecjtuPhysicsCall')
external JSPromise<JSAny?> _call(JSString method, JSString json);
Future<Object?> _bridge(String method, [Object? data]) async =>
    (await _call(method.toJS, jsonEncode(data).toJS).toDart)?.dartify();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final options = Uri.base.queryParameters;
  var family = options['font'] ?? EcjtuTheme.platformFontSentinel;
  if (family == EcjtuTheme.platformFontSentinel ||
      family == 'Microsoft YaHei') {
    final response = await http.get(Uri.base.resolve('fonts/system.ttf'));
    if (response.statusCode == 200) {
      family = 'PhysicsSystem';
      await (FontLoader(family)
            ..addFont(Future.value(ByteData.sublistView(response.bodyBytes))))
          .load();
    } else {
      family = 'SourceHanSansCN';
    }
  }
  {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final entry in manifest) {
      if (entry['family'] != family &&
          entry['family'] != 'SourceHanSansCN' &&
          !('${entry['family']}'.startsWith('packages/flutter_math_fork/')))
        continue;
      final loader = FontLoader(entry['family'] as String);
      for (final font in entry['fonts'] as List) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  }
  final calculator = ValueNotifier(options['calculator'] ?? '');
  _openCalculator = ((JSString id) {
    if (calculator.value == id.toDart) {
      unawaited(_bridge('ready', {'calculator': id.toDart}));
    } else {
      calculator.value = id.toDart;
    }
  }).toJS;
  PhysicsStorageScope.componentRead = (key) async =>
      await _bridge('read', {'key': key}) as String?;
  PhysicsStorageScope.componentWrite = (key, value) async {
    await _bridge('write', {'key': key, 'value': value});
  };
  PhysicsComponentPdf.share = (bytes, name) async =>
      await _bridge('pdf', {'bytes': base64Encode(bytes), 'name': name}) ==
      true;
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: options['dark'] == 'true'
          ? EcjtuTheme.darkFor(fontFamily: family).copyWith(
              platform: options['platform'] == 'android'
                  ? TargetPlatform.android
                  : TargetPlatform.windows,
            )
          : EcjtuTheme.lightFor(fontFamily: family).copyWith(
              platform: options['platform'] == 'android'
                  ? TargetPlatform.android
                  : TargetPlatform.windows,
            ),
      builder: (context, child) {
        final theme = Theme.of(context);
        final size = MediaQuery.sizeOf(context);
        return Theme(
          data: theme.copyWith(
            textTheme: EcjtuTheme.responsiveTextTheme(theme.textTheme, size),
            primaryTextTheme: EcjtuTheme.responsiveTextTheme(
              theme.primaryTextTheme,
              size,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                double.tryParse(options['textScale'] ?? '') ?? 1,
              ),
            ),
            child: child!,
          ),
        );
      },
      home: Scaffold(
        body: ValueListenableBuilder<String>(
          valueListenable: calculator,
          builder: (context, id, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(
                WidgetsBinding.instance.endOfFrame.then(
                  (_) => _bridge('ready', {'calculator': id}),
                ),
              );
            });
            return id.isEmpty
                ? const SizedBox.expand()
                : _Calculator(key: ValueKey(id), id: id);
          },
        ),
      ),
    ),
  );
}

class _Calculator extends StatelessWidget {
  const _Calculator({super.key, required this.id});
  final String id;
  void _back() {
    _bridge('back');
  }

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case 'newton-rings':
        return PhysicsNewtonRingsPage(
          onBack: _back,
          loadSaved: () => NewtonRingsStorage().read(),
          save: (state, calculation) =>
              NewtonRingsStorage().write(state, calculation),
        );
      case 'electron-charge':
        return PhysicsElectronChargePage(
          onBack: _back,
          loadSaved: () => ElectronChargeStorage().read(),
          save: (state, calculation) =>
              ElectronChargeStorage().write(state, calculation),
        );
      case 'galvanometer':
        return PhysicsGalvanometerPage(
          onBack: _back,
          loadSaved: () => GalvanometerStorage().read(),
          save: (state, calculation) =>
              GalvanometerStorage().write(state, calculation),
        );
      case 'electrostatic-field':
        return PhysicsElectrostaticFieldPage(
          onBack: _back,
          loadSaved: () => ElectrostaticFieldStorage().read(),
          save: (state, calculation) =>
              ElectrostaticFieldStorage().write(state, calculation),
        );
      case 'voltage-current':
        return PhysicsVoltageCurrentPage(
          onBack: _back,
          loadSaved: () => VoltageCurrentStorage().read(),
          save: (state, calculation) =>
              VoltageCurrentStorage().write(state, calculation),
        );
      case 'youngs-modulus':
        return PhysicsYoungsModulusPage(
          onBack: _back,
          loadSaved: () => YoungsModulusStorage().read(),
          save: (state, calculation) =>
              YoungsModulusStorage().write(state, calculation),
        );
      case 'potential-difference':
        return PhysicsPotentialDifferencePage(
          onBack: _back,
          loadSaved: () => PotentialDifferenceStorage().read(),
          save: (state, calculation) =>
              PotentialDifferenceStorage().write(state, calculation),
        );
      case 'sound-speed':
        return PhysicsSoundSpeedPage(
          onBack: _back,
          loadSaved: () => SoundSpeedStorage().read(),
          save: (state, calculation) =>
              SoundSpeedStorage().write(state, calculation),
        );
      case 'liquid-refractive-index':
        return PhysicsLiquidRefractionPage(
          onBack: _back,
          loadSaved: () => LiquidRefractionStorage().read(),
          save: (state, calculation) =>
              LiquidRefractionStorage().write(state, calculation),
        );
      case 'solid-density':
        return PhysicsSolidDensityPage(
          onBack: _back,
          loadSaved: () => SolidDensityStorage().read(),
          save: (state, calculation) =>
              SolidDensityStorage().write(state, calculation),
        );
      case 'single-arm-bridge':
        return PhysicsSingleArmBridgePage(
          onBack: _back,
          loadSaved: () => SingleArmBridgeStorage().read(),
          save: (state, calculation) =>
              SingleArmBridgeStorage().write(state, calculation),
        );
      case 'hall-effect':
        return PhysicsHallEffectPage(
          onBack: _back,
          loadSaved: () => HallEffectStorage().read(),
          save: (state, calculation) =>
              HallEffectStorage().write(state, calculation),
        );
      case 'franck-hertz':
        return PhysicsFranckHertzPage(
          onBack: _back,
          loadSaved: () => FranckHertzStorage().read(),
          save: (state, calculation) =>
              FranckHertzStorage().write(state, calculation),
        );
      case 'photoelectric-planck':
        return PhysicsPhotoelectricPlanckPage(
          onBack: _back,
          loadSaved: () => PhotoelectricPlanckStorage().read(),
          save: (state, calculation) =>
              PhotoelectricPlanckStorage().write(state, calculation),
        );
      case 'millikan-oil-drop':
        return PhysicsMillikanOilDropPage(
          onBack: _back,
          loadSaved: () => MillikanOilDropStorage().read(),
          save: (state, calculation) =>
              MillikanOilDropStorage().write(state, calculation),
        );
      case 'metal-work-function':
        return PhysicsMetalWorkFunctionPage(
          onBack: _back,
          loadSaved: () => MetalWorkFunctionStorage().read(),
          save: (state, calculation) =>
              MetalWorkFunctionStorage().write(state, calculation),
        );
      case 'rigid-rotation':
        return PhysicsRigidRotationPage(
          onBack: _back,
          loadSaved: () => RigidRotationStorage().read(),
          save: (state, calculation) =>
              RigidRotationStorage().write(state, calculation),
        );
      case 'ohmmeter':
        return PhysicsOhmmeterPage(
          onBack: _back,
          loadSaved: () => OhmmeterStorage().read(),
          save: (state, calculation) =>
              OhmmeterStorage().write(state, calculation),
        );
      case 'enamel-wire-resistivity':
        return PhysicsEnamelWireResistivityPage(
          onBack: _back,
          loadSaved: () => EnamelWireResistivityStorage().read(),
          save: (state, calculation) =>
              EnamelWireResistivityStorage().write(state, calculation),
        );
      case 'rheostat-characteristic':
        return PhysicsRheostatCharacteristicPage(
          onBack: _back,
          loadSaved: () => RheostatCharacteristicStorage().read(),
          save: (state, calculation) =>
              RheostatCharacteristicStorage().write(state, calculation),
        );
      default:
        return const Scaffold(body: Center(child: Text('计算器暂不可用')));
    }
  }
}
