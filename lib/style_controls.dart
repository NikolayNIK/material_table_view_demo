import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view_demo/global_target_platform.dart';

/// Holds [TableViewStyle] values to allow changing them on the fly
/// for the purposes of the demo.
class DemoStylingController with ChangeNotifier {
  final verticalDividerWiggleCount = ValueNotifier<int>(3);
  final verticalDividerWiggleOffset = ValueNotifier<double>(6.0);
  final lineDividerEnabled = ValueNotifier<bool>(false);
  final useRTL = ValueNotifier<bool>(false);
  final doExpansion = ValueNotifier<bool>(true);

  DemoStylingController() {
    verticalDividerWiggleCount.addListener(notifyListeners);
    verticalDividerWiggleOffset.addListener(notifyListeners);
    lineDividerEnabled.addListener(notifyListeners);
    useRTL.addListener(notifyListeners);
    doExpansion.addListener(notifyListeners);
  }

  TableViewStyle get tableViewStyle => TableViewStyle(
        dividers: TableViewDividersStyle(
          vertical: TableViewVerticalDividersStyle.symmetric(
            TableViewVerticalDividerStyle(
              wiggleOffset: verticalDividerWiggleOffset.value,
              wiggleCount: verticalDividerWiggleCount.value,
            ),
          ),
        ),
      );

  @override
  void dispose() {
    verticalDividerWiggleCount.removeListener(notifyListeners);
    verticalDividerWiggleOffset.removeListener(notifyListeners);
    lineDividerEnabled.removeListener(notifyListeners);
    useRTL.removeListener(notifyListeners);
    doExpansion.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Popup route for the style controls.
class DemoStylingControlsPopup extends ModalRoute<void> {
  final DemoStylingController stylingController;

  DemoStylingControlsPopup({
    required this.stylingController,
  });

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      SafeArea(
        child: ValueListenableBuilder(
          valueListenable: stylingController.useRTL,
          builder: (context, useRTL, child) => Align(
            alignment: useRTL ? Alignment.topLeft : Alignment.topRight,
            child: Directionality(
              textDirection: useRTL ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FadeTransition(
              opacity: animation,
              child: SizedBox(
                width: 256,
                child: IntrinsicHeight(
                  child: Material(
                    type: MaterialType.card,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      side: Divider.createBorderSide(context),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(16.0),
                      ),
                    ),
                    child: DemoStylingControls(
                      controller: stylingController,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  @override
  bool get maintainState => false;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);
}

/// Widget to control [TableViewStyle] values.
class DemoStylingControls extends StatelessWidget {
  final DemoStylingController controller;

  const DemoStylingControls({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        clipBehavior: Clip.none,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ValueListenableBuilder(
                valueListenable: globalTargetPlatform,
                builder: (context, currentPlatform, _) =>
                    DropdownButton<TargetPlatform?>(
                  items: <DropdownMenuItem<TargetPlatform?>>[
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Default target platform'),
                    ),
                  ]
                      .followedBy(
                        TargetPlatform.values.map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toString()),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  value: currentPlatform,
                  onChanged: (value) => globalTargetPlatform.value = value,
                ),
              ),
              SizedBox(
                height: 16.0 + 4.0 * Theme.of(context).visualDensity.vertical,
              ),
              Text(
                'Number of wiggles in vertical dividers per row',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ListenableBuilder(
                listenable: controller.verticalDividerWiggleCount,
                builder: (context, _) => Slider(
                  min: .0,
                  max: 16.0,
                  value: controller.verticalDividerWiggleCount.value.toDouble(),
                  onChanged: (value) => controller
                      .verticalDividerWiggleCount.value = value.round(),
                ),
              ),
              Text(
                'Vertical dividers wiggle offset',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ListenableBuilder(
                listenable: controller.verticalDividerWiggleOffset,
                builder: (context, _) => Slider(
                  min: .0,
                  max: 64.0,
                  value: controller.verticalDividerWiggleOffset.value,
                  onChanged: (value) =>
                      controller.verticalDividerWiggleOffset.value = value,
                ),
              ),
              Text(
                'Enable horizontal row divider',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ListenableBuilder(
                listenable: controller.lineDividerEnabled,
                builder: (context, child) => Checkbox(
                  value: controller.lineDividerEnabled.value,
                  onChanged: (value) =>
                      controller.lineDividerEnabled.value = value ?? false,
                ),
              ),
              Text(
                'Enable selected rows expansion',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ListenableBuilder(
                listenable: controller.doExpansion,
                builder: (context, child) => Checkbox(
                  value: controller.doExpansion.value,
                  onChanged: (value) =>
                      controller.doExpansion.value = value ?? false,
                ),
              ),
              Text(
                'Use RTL layout',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ListenableBuilder(
                listenable: controller.useRTL,
                builder: (context, child) => Checkbox(
                  value: controller.useRTL.value,
                  onChanged: (value) =>
                      controller.useRTL.value = value ?? false,
                ),
              ),
            ],
          ),
        ),
      );
}
