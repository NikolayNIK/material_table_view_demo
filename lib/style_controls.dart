import 'package:flutter/foundation.dart';
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
  final doExpansion = ValueNotifier<bool>(false);
  final statefulRandomBackground = ValueNotifier<bool>(false);
  final doPlaceholders = ValueNotifier<bool>(true);
  late final _doPlaceholdersShift =
      _BoolConjunctionValueNotifier(doPlaceholders, true);

  DemoStylingController() {
    verticalDividerWiggleCount.addListener(notifyListeners);
    verticalDividerWiggleOffset.addListener(notifyListeners);
    lineDividerEnabled.addListener(notifyListeners);
    useRTL.addListener(notifyListeners);
    doExpansion.addListener(notifyListeners);
    statefulRandomBackground.addListener(notifyListeners);
    doPlaceholders.addListener(notifyListeners);
    _doPlaceholdersShift.addListener(notifyListeners);
  }

  get doPlaceholdersShift => _doPlaceholdersShift;

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
    statefulRandomBackground.removeListener(notifyListeners);
    super.dispose();
  }
}

class _BoolConjunctionValueNotifier extends ValueNotifier<bool> {
  _BoolConjunctionValueNotifier(
    this._other,
    super.value,
  ) {
    _other.addListener(notifyListeners);
  }

  final ValueListenable<bool> _other;

  @override
  bool get value => _other.value && super.value;

  @override
  void dispose() {
    super.dispose();

    _other.removeListener(notifyListeners);
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
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      SafeArea(
        child: ValueListenableBuilder(
          valueListenable: stylingController.useRTL,
          builder: (context, useRTL, child) {
            final alignment = useRTL ? Alignment.topLeft : Alignment.topRight;
            return Align(
              alignment: alignment,
              child: Directionality(
                textDirection: useRTL ? TextDirection.rtl : TextDirection.ltr,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.fastEaseInToSlowEaseOut,
                    ),
                    alignment: alignment,
                    child: child!,
                  ),
                ),
              ),
            );
          },
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            ),
            child: SizedBox(
              width: 320,
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleTextStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurface,
    );

    final subtitleTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SingleChildScrollView(
      clipBehavior: Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              top: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: Text(
              style: theme.textTheme.titleLarge,
              'Styling controls',
            ),
          ),
          Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 56.0),
            child: ValueListenableBuilder(
              valueListenable: globalTargetPlatform,
              builder: (context, currentPlatform, _) =>
                  DropdownButton<TargetPlatform?>(
                menuWidth: 320,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                style: titleTextStyle,
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
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 4.0,
            ),
            child: Text(
              'Vertical divider wiggle count',
              style: titleTextStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Number of wiggles in vertical dividers per row',
              style: subtitleTextStyle,
            ),
          ),
          ListenableBuilder(
            listenable: controller.verticalDividerWiggleCount,
            builder: (context, _) => Slider.adaptive(
              label: controller.verticalDividerWiggleCount.value.toString(),
              min: .0,
              max: 16.0,
              value: controller.verticalDividerWiggleCount.value.toDouble(),
              onChanged: (value) =>
                  controller.verticalDividerWiggleCount.value = value.round(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Vertical dividers wiggle offset',
              style: titleTextStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'How far vertical dividers will stray from a straight line',
              style: subtitleTextStyle,
            ),
          ),
          ListenableBuilder(
            listenable: controller.verticalDividerWiggleOffset,
            builder: (context, _) => Slider.adaptive(
              label: controller.verticalDividerWiggleOffset.value
                  .toStringAsFixed(0),
              min: .0,
              max: 64.0,
              value: controller.verticalDividerWiggleOffset.value,
              onChanged: (value) => controller
                  .verticalDividerWiggleOffset.value = value.roundToDouble(),
            ),
          ),
          ListenableBuilder(
            listenable: controller.lineDividerEnabled,
            builder: (context, child) => SwitchListTile.adaptive(
              title: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'Row divider',
              ),
              subtitle: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'Horizontal row divider',
              ),
              value: controller.lineDividerEnabled.value,
              onChanged: (value) => controller.lineDividerEnabled.value = value,
            ),
          ),
          ListenableBuilder(
            listenable: controller.doExpansion,
            builder: (context, child) => SwitchListTile.adaptive(
              title: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'Expand selected rows',
              ),
              subtitle: Text(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                'Decreases the number of rows due to performance',
              ),
              isThreeLine: true,
              value: controller.doExpansion.value,
              onChanged: (value) => controller.doExpansion.value = value,
            ),
          ),
          ListenableBuilder(
            listenable: controller.useRTL,
            builder: (context, child) => SwitchListTile.adaptive(
              title: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'RTL layout',
              ),
              subtitle: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'Use right-to-left layout',
              ),
              value: controller.useRTL.value,
              onChanged: (value) => controller.useRTL.value = value,
            ),
          ),
          ListenableBuilder(
            listenable: controller.statefulRandomBackground,
            builder: (context, child) => SwitchListTile.adaptive(
              title: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'Random background',
              ),
              subtitle: Text(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                'Stateful random background for each cell',
              ),
              isThreeLine: true,
              value: controller.statefulRandomBackground.value,
              onChanged: (value) =>
                  controller.statefulRandomBackground.value = value,
            ),
          ),
          ListenableBuilder(
            listenable: controller.doPlaceholders,
            builder: (context, child) => SwitchListTile.adaptive(
              title: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'Placeholders',
              ),
              subtitle: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'Enable placeholders with shaders',
              ),
              isThreeLine: false,
              value: controller.doPlaceholders.value,
              onChanged: (value) => controller.doPlaceholders.value = value,
            ),
          ),
          ListenableBuilder(
            listenable: controller.doPlaceholdersShift,
            builder: (context, child) => SwitchListTile.adaptive(
              title: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'Placeholder shifting',
              ),
              subtitle: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'Enable placeholder shifting',
              ),
              isThreeLine: false,
              value: controller.doPlaceholdersShift.value,
              onChanged: controller.doPlaceholders.value
                  ? (value) => controller.doPlaceholdersShift.value = value
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
