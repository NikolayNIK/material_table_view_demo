import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';

class StylingController with ChangeNotifier {
  final verticalDividerWigglesPerRow = ValueNotifier<int>(1);
  final verticalDividerWiggleOffset = ValueNotifier<double>(16.0);
  final lineDividerEnabled = ValueNotifier<bool>(false);

  StylingController() {
    verticalDividerWigglesPerRow.addListener(notifyListeners);
    verticalDividerWiggleOffset.addListener(notifyListeners);
    lineDividerEnabled.addListener(notifyListeners);
  }

  TableViewStyle get tableViewStyle => TableViewStyle(
        dividers: TableViewDividersStyle(
          vertical: TableViewVerticalDividersStyle.symmetric(
            TableViewVerticalDividerStyle(
              wiggleOffset: verticalDividerWiggleOffset.value,
              wigglesPerRow: verticalDividerWigglesPerRow.value,
            ),
          ),
        ),
      );

  @override
  void dispose() {
    verticalDividerWigglesPerRow.removeListener(notifyListeners);
    verticalDividerWiggleOffset.removeListener(notifyListeners);
    lineDividerEnabled.removeListener(notifyListeners);
    super.dispose();
  }
}

class StylingControlsPopup extends ModalRoute<void> {
  final StylingController stylingController;

  StylingControlsPopup({
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
      Align(
        alignment: Alignment.topRight,
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
                  child: StylingControls(
                    controller: stylingController,
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

class StylingControls extends StatelessWidget {
  final StylingController controller;

  const StylingControls({
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
              Text(
                'Number of wiggles in vertical dividers per row',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ListenableBuilder(
                listenable: controller.verticalDividerWigglesPerRow,
                builder: (context, _) => Slider(
                  min: .0,
                  max: 16.0,
                  value:
                      controller.verticalDividerWigglesPerRow.value.toDouble(),
                  onChanged: (value) => controller
                      .verticalDividerWigglesPerRow.value = value.round(),
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
            ],
          ),
        ),
      );
}
