import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_table_view/default_animated_switcher_transition_builder.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/shimmer_placeholder_shade.dart';
import 'package:material_table_view/sliver_table_view.dart';
import 'package:material_table_view/table_column_control_handles_popup_route.dart';
import 'package:material_table_view/table_view_typedefs.dart';
import 'package:material_table_view_demo/global_target_platform.dart';
import 'package:material_table_view_demo/style_controls.dart';

void main() => runApp(const MyApp());

const _title = 'material_table_view demo';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: globalTargetPlatform,
        builder: (context, targetPlatform, _) => MaterialApp(
          title: _title,
          theme: _appTheme(Brightness.light, targetPlatform),
          darkTheme: _appTheme(Brightness.dark, targetPlatform),
          home: const MyHomePage(),
        ),
      );

  ThemeData _appTheme(Brightness brightness, TargetPlatform? platform) =>
      ThemeData(
        useMaterial3: true,
        platform: platform,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: brightness,
        ),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const _columnsPowerOfTwo = 12;
const _rowCount = (1 << 31) - 1;

/// Extends [TableColumn] to keep track of its original index regardless of where it happened to move to.
class _MyTableColumn extends TableColumn {
  _MyTableColumn({
    required int index,
    required super.width,
    super.freezePriority = 0,
    super.sticky = false,
    super.flex = 0,
    super.translation = 0,
    super.minResizeWidth,
    super.maxResizeWidth,
  })  : key = ValueKey<int>(index),
        // ignore: prefer_initializing_formals
        index = index;

  final int index;

  @override
  final ValueKey<int> key;

  @override
  _MyTableColumn copyWith({
    double? width,
    int? freezePriority,
    bool? sticky,
    int? flex,
    double? translation,
    double? minResizeWidth,
    double? maxResizeWidth,
  }) =>
      _MyTableColumn(
        index: index,
        width: width ?? this.width,
        freezePriority: freezePriority ?? this.freezePriority,
        sticky: sticky ?? this.sticky,
        flex: flex ?? this.flex,
        translation: translation ?? this.translation,
        minResizeWidth: minResizeWidth ?? this.minResizeWidth,
        maxResizeWidth: maxResizeWidth ?? this.maxResizeWidth,
      );
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin<MyHomePage> {
  late TabController tabController;

  final stylingController = StylingController();

  final selection = <int>{};
  int placeholderOffsetIndex = 0;
  late Timer periodicPlaceholderOffsetIncreaseTimer;

  final verticalSliverExampleScrollController = ScrollController();

  final columns = <_MyTableColumn>[
    _MyTableColumn(
      index: 0,
      width: 56.0,
      freezePriority: 1 * (_columnsPowerOfTwo + 1),
      sticky: true,
    ),
    for (var i = 1; i <= 1 << _columnsPowerOfTwo; i++)
      _MyTableColumn(
        index: i,
        width: 64,
        minResizeWidth: 64.0,
        flex: i,
        // this will make the column expand to fill remaining width
        freezePriority: 1 *
            (_columnsPowerOfTwo - (_getPowerOfTwo(i) ?? _columnsPowerOfTwo)),
      ),
    _MyTableColumn(
      index: -1,
      width: 48.0,
      freezePriority: 1 * (_columnsPowerOfTwo + 1),
    ),
  ];

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 2, vsync: this);
    periodicPlaceholderOffsetIncreaseTimer = Timer.periodic(
        const Duration(milliseconds: 1000),
        (timer) => setState(() => placeholderOffsetIndex++));

    stylingController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    verticalSliverExampleScrollController.dispose();
    periodicPlaceholderOffsetIncreaseTimer.cancel();
    tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const shimmerBaseColor = Color(0x20808080);
    const shimmerHighlightColor = Color(0x40FFFFFF);

    return Directionality(
      textDirection: stylingController.useRTL.value
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
          actions: [
            IconButton(
              onPressed: () => Navigator.push(context,
                  StylingControlsPopup(stylingController: stylingController)),
              icon: const Icon(Icons.style_rounded),
            ),
          ],
          bottom: TabBar(
            controller: tabController,
            tabs: const [
              Tooltip(
                message:
                    'Standalone box TableView with its own vertically scrollable space between the header and the footer',
                child: Tab(text: 'Regular box'),
              ),
              Tooltip(
                message:
                    'Multiple SliverTableViews alongside other slivers scrolled vertically by its parent',
                child: Tab(text: 'Slivers'),
              ),
            ],
          ),
        ),
        body: ShimmerPlaceholderShadeProvider(
          loopDuration: const Duration(seconds: 2),
          colors: const [
            shimmerBaseColor,
            shimmerHighlightColor,
            shimmerBaseColor,
            shimmerHighlightColor,
            shimmerBaseColor
          ],
          stops: const [.0, .45, .5, .95, 1],
          builder: (context, placeholderShade) => LayoutBuilder(
            builder: (context, constraints) {
              // when the horizontal space is limited
              // make the checkbox column sticky to conserve it (the space not the column)
              columns[0] =
                  columns[0].copyWith(sticky: constraints.maxWidth <= 512);
              return TabBarView(
                controller: tabController,
                children: [
                  _buildBoxExample(
                    context,
                    placeholderShade,
                  ),
                  _buildSliverExample(
                    context,
                    placeholderShade,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds a regular [TableView].
  Widget _buildBoxExample(
    BuildContext context,
    TablePlaceholderShade placeholderShade,
  ) =>
      TableView.builder(
        columns: columns,
        style: TableViewStyle(
          dividers: TableViewDividersStyle(
            vertical: TableViewVerticalDividersStyle.symmetric(
              TableViewVerticalDividerStyle(
                  wigglesPerRow:
                      stylingController.verticalDividerWigglesPerRow.value,
                  wiggleOffset:
                      stylingController.verticalDividerWiggleOffset.value),
            ),
          ),
        ),
        rowHeight: 48.0 + 4 * Theme.of(context).visualDensity.vertical,
        rowCount: _rowCount - 1,
        rowBuilder: _rowBuilder,
        rowReorder: TableRowReorder(
          onReorder: (oldIndex, newIndex) {
            // for the purposes of the demo we do not handle actual
            // row reordering
            print('$oldIndex -> $newIndex');
          },
        ),
        placeholderRowBuilder: _placeholderBuilder,
        placeholderShade: placeholderShade,
        headerBuilder: _headerBuilder,
        footerBuilder: _footerBuilder,
        // RefreshIndicator can be used as a parent of [TableView] as well
        bodyContainerBuilder: (context, bodyContainer) => RefreshIndicator(
          onRefresh: () => Future.delayed(const Duration(seconds: 2)),
          child: bodyContainer,
        ),
      );

  /// Builds multiple [SliverTableView]s alongside [SliverFixedExtentList]s
  /// in a single vertical [CustomScrollView].
  Widget _buildSliverExample(
    BuildContext context,
    TablePlaceholderShade placeholderShade,
  ) {
    /// the count is on the low side to make reaching table boundaries easier
    const rowsPerTable = 90;
    const tableCount = 32;

    final itemExtent = 48.0 + 4 * Theme.of(context).visualDensity.vertical;

    return Scrollbar(
      controller: verticalSliverExampleScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      child: RefreshIndicator(
        onRefresh: () => Future.delayed(const Duration(seconds: 2)),
        child: CustomScrollView(
          controller: verticalSliverExampleScrollController,
          slivers: [
            for (var i = 0; i < tableCount; i++) ...[
              SliverTableView.builder(
                style: TableViewStyle(
                  // If we want the content to scroll out from underneath
                  // the vertical scrollbar
                  // we need to specify scroll padding here since we are
                  // managing that scrollbar.
                  scrollPadding: const EdgeInsets.only(right: 10),
                  dividers: TableViewDividersStyle(
                    vertical: TableViewVerticalDividersStyle.symmetric(
                      TableViewVerticalDividerStyle(
                          wigglesPerRow: stylingController
                              .verticalDividerWigglesPerRow.value,
                          wiggleOffset: stylingController
                              .verticalDividerWiggleOffset.value),
                    ),
                  ),
                ),
                columns: columns,
                rowHeight: itemExtent,
                rowCount: rowsPerTable,
                rowBuilder: _rowBuilder,
                rowReorder: TableRowReorder(
                  onReorder: (oldIndex, newIndex) {
                    // for the purposes of the demo we do not handle actual
                    // row reordering
                    print('$oldIndex -> $newIndex');
                  },
                ),
                placeholderRowBuilder: _placeholderBuilder,
                placeholderShade: placeholderShade,
                headerBuilder: _headerBuilder,
                footerBuilder: _footerBuilder,
              ),
              SliverFixedExtentList(
                delegate: SliverChildBuilderDelegate(
                  childCount: 8,
                  (context, index) => Padding(
                    padding: stylingController.useRTL.value
                        ? const EdgeInsets.only(right: 18.0)
                        : const EdgeInsets.only(left: 18.0),
                    child: Align(
                      alignment: stylingController.useRTL.value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        'boring old sliver list element inbetween tables #${index + rowsPerTable * i}',
                      ),
                    ),
                  ),
                ),
                itemExtent: itemExtent,
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerBuilder(
    BuildContext context,
    TableRowContentBuilder contentBuilder,
  ) =>
      contentBuilder(
        context,
        (context, column) {
          switch (columns[column].index) {
            case 0:
              return Checkbox(
                value: selection.isEmpty ? false : null,
                tristate: true,
                onChanged: (value) {
                  if (!(value ?? true)) {
                    setState(() => selection.clear());
                  }
                },
              );
            case -1:
              return const SizedBox();
            default:
              return Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => Navigator.of(context)
                      .push(_createColumnControlsRoute(context, column)),
                  child: Padding(
                    padding: stylingController.useRTL.value
                        ? const EdgeInsets.only(right: 8.0)
                        : const EdgeInsets.only(left: 8.0),
                    child: Align(
                      alignment: stylingController.useRTL.value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text('${columns[column].index}'),
                    ),
                  ),
                ),
              );
          }
        },
      );

  ModalRoute<void> _createColumnControlsRoute(
    BuildContext cellBuildContext,
    int columnIndex,
  ) =>
      TableColumnControlHandlesPopupRoute.realtime(
        controlCellBuildContext: cellBuildContext,
        columnIndex: columnIndex,
        tableViewChanged: null,
        onColumnTranslate: (index, newTranslation) => setState(
          () => columns[index] =
              columns[index].copyWith(translation: newTranslation),
        ),
        onColumnResize: (index, newWidth) => setState(
          () => columns[index] = columns[index].copyWith(width: newWidth),
        ),
        onColumnMove: (oldIndex, newIndex) => setState(
          () => columns.insert(newIndex, columns.removeAt(oldIndex)),
        ),
        leadingImmovableColumnCount: 1,
        trailingImmovableColumnCount: 1,
        popupBuilder: (context, animation, secondaryAnimation, columnWidth) =>
            PreferredSize(
          preferredSize: Size(min(256, max(192, columnWidth)), 256),
          child: FadeTransition(
            opacity: animation,
            child: Material(
              type: MaterialType.card,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                side: Divider.createBorderSide(context),
                borderRadius: const BorderRadius.all(
                  Radius.circular(16.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Custom widget to control sorting, stickiness and whatever',
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Button to cancel the controls',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// This is used to wrap both regular and placeholder rows to achieve fade
  /// transition between them and to insert optional row divider.
  Widget _wrapRow(int index, Widget child) => KeyedSubtree(
        key: ValueKey(index),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: stylingController.lineDividerEnabled.value
                ? Border(bottom: Divider.createBorderSide(context))
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: tableRowDefaultAnimatedSwitcherTransitionBuilder,
            child: child,
          ),
        ),
      );

  Widget? _rowBuilder(
    BuildContext context,
    int row,
    TableRowContentBuilder contentBuilder,
  ) {
    final selected = selection.contains(row);

    var textStyle = Theme.of(context).textTheme.bodyMedium;
    if (selected) {
      textStyle = textStyle?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer);
    }

    return (row + placeholderOffsetIndex) % 99 < 33
        ? null
        : _wrapRow(
            row,
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withAlpha(selected ? 0xFF : 0),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => setState(() {
                    selection.clear();
                    selection.add(row);
                  }),
                  child: contentBuilder(context, (context, column) {
                    switch (columns[column].index) {
                      case 0:
                        return Checkbox(
                            value: selection.contains(row),
                            onChanged: (value) => setState(() =>
                                (value ?? false)
                                    ? selection.add(row)
                                    : selection.remove(row)));
                      case -1:
                        return ReorderableDragStartListener(
                          index: row,
                          child: const SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Icon(Icons.drag_indicator),
                          ),
                        );
                      default:
                        return Padding(
                          padding: stylingController.useRTL.value
                              ? const EdgeInsets.only(right: 8.0)
                              : const EdgeInsets.only(left: 8.0),
                          child: Align(
                            alignment: stylingController.useRTL.value
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Text(
                              '${(row + 2) * columns[column].index}',
                              style: textStyle,
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        );
                    }
                  }),
                ),
              ),
            ),
          );
  }

  Widget _placeholderBuilder(
    BuildContext context,
    int row,
    TableRowContentBuilder contentBuilder,
  ) =>
      _wrapRow(
        row,
        contentBuilder(
          context,
          (context, column) {
            switch (columns[column].index) {
              case 0:
                return const Checkbox(
                  value: false,
                  onChanged: _dummyCheckboxOnChanged,
                );
              case -1:
                return ReorderableDragStartListener(
                  index: row,
                  child: const SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Icon(Icons.drag_indicator),
                  ),
                );
              default:
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(16)))),
                );
            }
          },
        ),
      );

  Widget _footerBuilder(
    BuildContext context,
    TableRowContentBuilder contentBuilder,
  ) =>
      contentBuilder(
        context,
        (context, column) {
          final index = columns[column].index;
          if (index == -1) {
            return const SizedBox();
          }

          return Padding(
            padding: stylingController.useRTL.value
                ? const EdgeInsets.only(right: 8.0)
                : const EdgeInsets.only(left: 8.0),
            child: Align(
              alignment: stylingController.useRTL.value
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(index == 0 ? '${selection.length}' : '$index'),
            ),
          );
        },
      );

  /// This is used to create const [Checkbox]es that are enabled.
  static void _dummyCheckboxOnChanged(bool? _) {}

  static int? _getPowerOfTwo(int number) {
    assert(!number.isNegative);
    if (number == 0) return null;

    for (int i = 0;; i++) {
      if (number & 1 == 1) {
        return ((number & ~1) >> 1) == 0 ? i : null;
      }

      number = (number & ~1) >> 1;
    }
  }
}
