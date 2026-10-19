// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
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

class PhysicsNativeCalculator extends StatelessWidget {
  const PhysicsNativeCalculator({
    super.key,
    required this.id,
    required this.studentId,
    required this.onBack,
  });
  final String id;
  final String studentId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case 'newton-rings':
        return PhysicsNewtonRingsPage(
          onBack: onBack,
          loadSaved: () => NewtonRingsStorage().read(studentId),
          save: (state, calculation) =>
              NewtonRingsStorage().write(state, calculation, studentId),
        );
      case 'electron-charge':
        return PhysicsElectronChargePage(
          onBack: onBack,
          loadSaved: () => ElectronChargeStorage().read(studentId),
          save: (state, calculation) =>
              ElectronChargeStorage().write(state, calculation, studentId),
        );
      case 'galvanometer':
        return PhysicsGalvanometerPage(
          onBack: onBack,
          loadSaved: () => GalvanometerStorage().read(studentId),
          save: (state, calculation) =>
              GalvanometerStorage().write(state, calculation, studentId),
        );
      case 'electrostatic-field':
        return PhysicsElectrostaticFieldPage(
          onBack: onBack,
          loadSaved: () => ElectrostaticFieldStorage().read(studentId),
          save: (state, calculation) =>
              ElectrostaticFieldStorage().write(state, calculation, studentId),
        );
      case 'voltage-current':
        return PhysicsVoltageCurrentPage(
          onBack: onBack,
          loadSaved: () => VoltageCurrentStorage().read(studentId),
          save: (state, calculation) =>
              VoltageCurrentStorage().write(state, calculation, studentId),
        );
      case 'youngs-modulus':
        return PhysicsYoungsModulusPage(
          onBack: onBack,
          loadSaved: () => YoungsModulusStorage().read(studentId),
          save: (state, calculation) =>
              YoungsModulusStorage().write(state, calculation, studentId),
        );
      case 'potential-difference':
        return PhysicsPotentialDifferencePage(
          onBack: onBack,
          loadSaved: () => PotentialDifferenceStorage().read(studentId),
          save: (state, calculation) =>
              PotentialDifferenceStorage().write(state, calculation, studentId),
        );
      case 'sound-speed':
        return PhysicsSoundSpeedPage(
          onBack: onBack,
          loadSaved: () => SoundSpeedStorage().read(studentId),
          save: (state, calculation) =>
              SoundSpeedStorage().write(state, calculation, studentId),
        );
      case 'liquid-refractive-index':
        return PhysicsLiquidRefractionPage(
          onBack: onBack,
          loadSaved: () => LiquidRefractionStorage().read(studentId),
          save: (state, calculation) =>
              LiquidRefractionStorage().write(state, calculation, studentId),
        );
      case 'solid-density':
        return PhysicsSolidDensityPage(
          onBack: onBack,
          loadSaved: () => SolidDensityStorage().read(studentId),
          save: (state, calculation) =>
              SolidDensityStorage().write(state, calculation, studentId),
        );
      case 'single-arm-bridge':
        return PhysicsSingleArmBridgePage(
          onBack: onBack,
          loadSaved: () => SingleArmBridgeStorage().read(studentId),
          save: (state, calculation) =>
              SingleArmBridgeStorage().write(state, calculation, studentId),
        );
      case 'hall-effect':
        return PhysicsHallEffectPage(
          onBack: onBack,
          loadSaved: () => HallEffectStorage().read(studentId),
          save: (state, calculation) =>
              HallEffectStorage().write(state, calculation, studentId),
        );
      case 'franck-hertz':
        return PhysicsFranckHertzPage(
          onBack: onBack,
          loadSaved: () => FranckHertzStorage().read(studentId),
          save: (state, calculation) =>
              FranckHertzStorage().write(state, calculation, studentId),
        );
      case 'photoelectric-planck':
        return PhysicsPhotoelectricPlanckPage(
          onBack: onBack,
          loadSaved: () => PhotoelectricPlanckStorage().read(studentId),
          save: (state, calculation) =>
              PhotoelectricPlanckStorage().write(state, calculation, studentId),
        );
      case 'millikan-oil-drop':
        return PhysicsMillikanOilDropPage(
          onBack: onBack,
          loadSaved: () => MillikanOilDropStorage().read(studentId),
          save: (state, calculation) =>
              MillikanOilDropStorage().write(state, calculation, studentId),
        );
      case 'metal-work-function':
        return PhysicsMetalWorkFunctionPage(
          onBack: onBack,
          loadSaved: () => MetalWorkFunctionStorage().read(studentId),
          save: (state, calculation) =>
              MetalWorkFunctionStorage().write(state, calculation, studentId),
        );
      case 'rigid-rotation':
        return PhysicsRigidRotationPage(
          onBack: onBack,
          loadSaved: () => RigidRotationStorage().read(studentId),
          save: (state, calculation) =>
              RigidRotationStorage().write(state, calculation, studentId),
        );
      case 'ohmmeter':
        return PhysicsOhmmeterPage(
          onBack: onBack,
          loadSaved: () => OhmmeterStorage().read(studentId),
          save: (state, calculation) =>
              OhmmeterStorage().write(state, calculation, studentId),
        );
      case 'enamel-wire-resistivity':
        return PhysicsEnamelWireResistivityPage(
          onBack: onBack,
          loadSaved: () => EnamelWireResistivityStorage().read(studentId),
          save: (state, calculation) => EnamelWireResistivityStorage().write(
            state,
            calculation,
            studentId,
          ),
        );
      case 'rheostat-characteristic':
        return PhysicsRheostatCharacteristicPage(
          onBack: onBack,
          loadSaved: () => RheostatCharacteristicStorage().read(studentId),
          save: (state, calculation) => RheostatCharacteristicStorage().write(
            state,
            calculation,
            studentId,
          ),
        );
      default:
        return const Scaffold(body: Center(child: Text('计算器暂不可用')));
    }
  }
}
