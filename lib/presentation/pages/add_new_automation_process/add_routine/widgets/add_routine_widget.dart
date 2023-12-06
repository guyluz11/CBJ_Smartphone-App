import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cbj_integrations_controller/domain/routine/i_routine_cbj_repository.dart';
import 'package:cbj_integrations_controller/domain/routine/value_objects_routine_cbj.dart';
import 'package:cbj_integrations_controller/domain/vendors/login_abstract/core_login_failures.dart';
import 'package:cbj_integrations_controller/infrastructure/gen/cbj_hub_server/protoc_as_dart/cbj_hub_server.pbgrpc.dart';
import 'package:cbj_integrations_controller/infrastructure/generic_devices/abstract_device/device_entity_abstract.dart';
import 'package:cybear_jinni/domain/device/i_device_repository.dart';
import 'package:cybear_jinni/presentation/atoms/atoms.dart';
import 'package:cybear_jinni/presentation/core/snack_bar_service.dart';
import 'package:cybear_jinni/presentation/pages/add_new_automation_process/add_routine/widgets/routine_action_widget.dart';
import 'package:cybear_jinni/presentation/core/routes/app_router.gr.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddRoutineWidget extends StatefulWidget {
  @override
  State<AddRoutineWidget> createState() => _AddRoutineWidgetState();
}

class _AddRoutineWidgetState extends State<AddRoutineWidget> {
  List<DeviceEntityAbstract> _allDevices = [];

  String? routineName;

  RoutineCbjRepeatDateDays? daysToRepeat;
  RoutineCbjRepeatDateHour? hourToRepeat;
  RoutineCbjRepeatDateMinute? minutesToRepeat;

  /// List of devices with entities, will be treated as actions
  List<MapEntry<DeviceEntityAbstract, MapEntry<String?, String?>>>
      allDevicesWithNewAction = [];
  List<MapEntry<String, String>> allEntityActions = [];
  bool showErrorMessages = false;
  bool isSubmitting = false;
  dartz.Option<dartz.Either<CoreLoginFailure, dartz.Unit>>
      authFailureOrSuccessOption = dartz.none();

  @override
  @override
  void initState() {
    super.initState();
    _initialized();
  }

  Future<void> _initialized() async {
    List<DeviceEntityAbstract?> temp = [];
    (await IDeviceRepository.instance.getAllDevices()).fold((l) => null, (r) {
      temp = List<DeviceEntityAbstract?>.from(r.iter);
    });
    temp.removeWhere((element) => element == null);

    setState(() {
      _allDevices = temp.map((e) => e!).toList();
    });
  }

  Future<void> _sendRoutineToHub() async {
    if (daysToRepeat == null ||
        hourToRepeat == null ||
        minutesToRepeat == null ||
        routineName == null) {
      return;
    }
    IRoutineCbjRepository.instance
        .addOrUpdateNewRoutineInHubFromDevicesPropertyActionList(
      routineName!,
      allDevicesWithNewAction,
      daysToRepeat!,
      hourToRepeat!,
      minutesToRepeat!,
    );
  }

  Future<void> _routineNameChange(String value) async {
    routineName = value;
  }

  Future<void> _addDevicesWithNewActions(
    Iterable<MapEntry<DeviceEntityAbstract, MapEntry<String?, String?>>> value,
  ) async {
    setState(() {
      allDevicesWithNewAction.addAll(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_allDevices.isNotEmpty) {
      return const CircularProgressIndicatorAtom();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(
            height: 30,
          ),
          TextFormField(
            decoration: const InputDecoration(
              prefixIcon: FaIcon(FontAwesomeIcons.fileSignature),
              labelText: 'Routine Name',
            ),
            onChanged: _routineNameChange,
          ),
          SizedBox(
            height: 300,
            width: 500,
            child: ListView.builder(
              itemCount: allDevicesWithNewAction.length,
              itemBuilder: (BuildContext context, int index) {
                final MapEntry<DeviceEntityAbstract, MapEntry<String?, String?>>
                    currentDevice = allDevicesWithNewAction[index];

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  child: RoutineActionWidget(
                    deviceEntityAbstract: currentDevice.key,
                    propertyToChange:
                        currentDevice.value.key ?? 'Missing property',
                    actionToChange: currentDevice.value.value ??
                        EntityActions.actionNotSupported.toString(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withOpacity(0.5),
              // Red border with the width is equal to 5
              border: Border.all(),
            ),
            child: TextButton(
              onPressed: () {
                showAdaptiveActionSheet(
                  context: context,
                  actions: <BottomSheetAction>[
                    BottomSheetAction(
                      title: const TextAtom(
                        'Add device action',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 23,
                        ),
                      ),
                      onPressed: (_) async {
                        final List<
                                MapEntry<DeviceEntityAbstract,
                                    MapEntry<String?, String?>>>? actionList =
                            await context.router.push<
                                List<
                                    MapEntry<DeviceEntityAbstract,
                                        MapEntry<String?, String?>>>>(
                          const AddActionRoute(),
                        );
                        if (actionList != null) {
                          _addDevicesWithNewActions(actionList);
                        }
                      },
                    ),
                    BottomSheetAction(
                      title: TextAtom(
                        'Add service action',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 23,
                        ),
                      ),
                      onPressed: (_) {
                        SnackBarService().show(
                          context,
                          'Adding service action will be added in the future',
                        );
                      },
                    ),
                    BottomSheetAction(
                      title: const TextAtom(
                        'Add time based action',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 23,
                        ),
                      ),
                      onPressed: (_) {
                        SnackBarService().show(
                          context,
                          'Adding time based action will be added in the future',
                        );
                      },
                    ),
                  ],
                );
              },
              child: const TextAtom('+ Add action'),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withOpacity(0.5),
              // Red border with the width is equal to 5
              border: Border.all(),
            ),
            child: TextButton(
              onPressed: () {
                SnackBarService().show(
                  context,
                  'Adding Routine',
                );
                _sendRoutineToHub();
              },
              child: const TextAtom('Add Routine'),
            ),
          ),
        ],
      ),
    );
  }
}
