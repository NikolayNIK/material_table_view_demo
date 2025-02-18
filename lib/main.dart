import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_table_view/default_animated_switcher_transition_builder.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/shimmer_placeholder_shade.dart';
import 'package:material_table_view/sliver_table_view.dart';
import 'package:material_table_view/table_column_control_handles_popup_route.dart';
import 'package:material_table_view/table_view_typedefs.dart';
import 'package:material_table_view_demo/global_target_platform.dart';
import 'package:material_table_view_demo/style_controls.dart';
import 'package:yaml/yaml.dart';

void main() => runApp(const MaterialTableViewDemoApp());

const _title = 'material_table_view demo';

/// Complicated demo app designed to showcase full range of capabilities
/// of the `material_table_view` library. The fewer features you end up using,
/// the less complicated your code will end up.
class MaterialTableViewDemoApp extends StatelessWidget {
  const MaterialTableViewDemoApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: globalTargetPlatform,
        builder: (context, targetPlatform, _) => MaterialApp(
          title: _title,
          theme: _appTheme(Brightness.light, targetPlatform),
          darkTheme: _appTheme(Brightness.dark, targetPlatform),
          home: const DemoPage(),
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

/// Extends [TableColumn] to keep track of its original index
/// regardless of where it happened to move to. If the table controls are not
/// used, feel free to simply use the [TableColumn] instead.
class _DemoTableColumn extends TableColumn {
  _DemoTableColumn({
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
  _DemoTableColumn copyWith({
    double? width,
    int? freezePriority,
    bool? sticky,
    int? flex,
    double? translation,
    double? minResizeWidth,
    double? maxResizeWidth,
  }) =>
      _DemoTableColumn(
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

const _columnsPowerOfTwo = 12;

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage>
    with SingleTickerProviderStateMixin<DemoPage> {
  late TabController tabController;

  final stylingController = DemoStylingController();

  final selection = <int>{};
  int placeholderOffsetIndex = 0;
  late Timer periodicPlaceholderOffsetIncreaseTimer;

  final verticalSliverExampleScrollController = ScrollController();

  final columns = <_DemoTableColumn>[
    _DemoTableColumn(
      index: 0,
      width: 56.0,
      freezePriority: 1 * (_columnsPowerOfTwo + 1),
      sticky: true,
    ),
    for (var i = 1; i <= 1 << _columnsPowerOfTwo; i++)
      _DemoTableColumn(
        index: i,
        width: 64,
        minResizeWidth: 64.0,
        freezePriority: 1 *
            (_columnsPowerOfTwo - (_getPowerOfTwo(i) ?? _columnsPowerOfTwo)),
      ),
    _DemoTableColumn(
      index: -1,
      width: 48.0,
      freezePriority: 1 * (_columnsPowerOfTwo + 1),
    ),
  ];

  double get _rowHeight => 48.0 + 4 * Theme.of(context).visualDensity.vertical;

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
          title: FutureBuilder(
            future: rootBundle.loadString('pubspec.lock'),
            builder: (context, snapshot) {
              String? version;
              if (snapshot.hasData) {
                try {
                  var yaml = loadYaml(snapshot.data!);
                  version = yaml['packages']['material_table_view']['version'];
                } catch (e) {
                  // just in case, we ignore that
                }
              }

              return Text(
                version == null ? _title : 'material_table_view $version demo',
              );
            },
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                DemoStylingControlsPopup(stylingController: stylingController),
              ),
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
            builder: (context, constraints) => TabBarView(
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
            ),
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
                wiggleCount: stylingController.verticalDividerWiggleCount.value,
                wiggleOffset:
                    stylingController.verticalDividerWiggleOffset.value,
                wiggleInterval: _rowHeight,
              ),
            ),
          ),
          scrollbars: const TableViewScrollbarsStyle.symmetric(
            TableViewScrollbarStyle(
              interactive: true,
              enabled: TableViewScrollbarEnabled.always,
              thumbVisibility: WidgetStatePropertyAll(true),
              trackVisibility: WidgetStatePropertyAll(true),
            ),
          ),
        ),
        rowHeight: stylingController.doExpansion.value ? null : _rowHeight,
        rowHeightBuilder: stylingController.doExpansion.value
            ? (index, dimensions) =>
                selection.contains(index) ? 2 * _rowHeight : _rowHeight
            : null,
        // limit the row count when dynamic row height is used
        rowCount: stylingController.doExpansion.value
            ? (1 << 12) - 1
            : ((1 << 31) - 1),
        rowBuilder:
            createRowBuilder(context, stylingController.doExpansion.value),
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
        headerHeight: _rowHeight,
        footerBuilder: _footerBuilder,
        footerHeight: _rowHeight,
        // RefreshIndicator can be used as a parent of [TableView] as well
        bodyContainerBuilder: (context, bodyContainer) =>
            RefreshIndicator.adaptive(
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

    return Scrollbar(
      controller: verticalSliverExampleScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      child: RefreshIndicator.adaptive(
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
                        wiggleCount:
                            stylingController.verticalDividerWiggleCount.value,
                        wiggleOffset:
                            stylingController.verticalDividerWiggleOffset.value,
                      ),
                    ),
                  ),
                  scrollbars: const TableViewScrollbarsStyle.symmetric(
                    TableViewScrollbarStyle(
                      interactive: true,
                      enabled: TableViewScrollbarEnabled.always,
                      thumbVisibility: WidgetStatePropertyAll(true),
                      trackVisibility: WidgetStatePropertyAll(true),
                    ),
                  ),
                ),
                columns: columns,
                rowHeight: _rowHeight,
                rowCount: rowsPerTable,
                rowBuilder: createRowBuilder(context, false),
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
                itemExtent: _rowHeight,
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
                  onChanged: (value) => Navigator.of(context)
                      .push(_createColumnControlsRoute(context, column)));
            case -1:
              return Center(
                child: SizedBox(
                  width: _rowHeight,
                  height: _rowHeight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context)
                        .push(_createColumnControlsRoute(context, column)),
                    icon: Icon(Icons.more_vert),
                  ),
                ),
              );
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
  ) {
    final initialColumn = columns[columnIndex];
    return TableColumnControlHandlesPopupRoute.realtime(
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
      leadingImmovableColumnCount: 0,
      trailingImmovableColumnCount: 0,
      popupBuilder: (context, animation, secondaryAnimation, columnWidth) =>
          PreferredSize(
        preferredSize: Size(min(320, max(256, columnWidth)), 256),
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
            child: _DemoColumnEditor(
              column: initialColumn,
              onClickApply: (flex, freezePriority, sticky) => setState(
                () {
                  // find current column index
                  final index = columns.indexWhere(
                      (element) => element.key == initialColumn.key);

                  // change the column
                  columns[index] = columns[index].copyWith(
                    flex: flex,
                    freezePriority: freezePriority,
                    sticky: sticky,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  /// Creates [TableRowBuilder] closure.
  TableRowBuilder createRowBuilder(BuildContext context, bool doExpansion) {
    final theme = Theme.of(context);
    final rowTextStyle = Theme.of(context).textTheme.bodyMedium;

    final cellPadding = stylingController.useRTL.value
        ? const EdgeInsets.only(right: 8.0)
        : const EdgeInsets.only(left: 8.0);

    final cellAlignment = stylingController.useRTL.value
        ? Alignment.centerRight
        : Alignment.centerLeft;

    // this can be freely inlined instead
    return (context, row, TableRowContentBuilder contentBuilder) {
      if ((row + placeholderOffsetIndex) % 99 < 33) {
        return null; // show off the placeholder
      }

      final selected = selection.contains(row);
      final textStyle = selected
          ? rowTextStyle?.copyWith(color: theme.colorScheme.onPrimaryContainer)
          : rowTextStyle;

      // this is going to be our content
      var content = contentBuilder(context, (context, column) {
        switch (columns[column].index) {
          case 0:
            return Checkbox(
                value: selection.contains(row),
                onChanged: (value) => setState(() => (value ?? false)
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
              padding: cellPadding,
              child: Align(
                alignment: cellAlignment,
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
      });

      if (selected && doExpansion) {
        // expand the row
        content = Column(
          children: [
            Flexible(child: content),
            Flexible(
              child: contentBuilder(
                context,
                (context, column) {
                  switch (columns[column].index) {
                    case 0:
                    case -1:
                      return SizedBox();
                    default:
                      return Padding(
                        padding: cellPadding,
                        child: Align(
                          alignment: cellAlignment,
                          child: Text(
                            '${sqrt((row + 2) * columns[column].index)}',
                            style: textStyle,
                            overflow: TextOverflow.fade,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      );
                  }
                },
              ),
            )
          ],
        );
      }

      // Here we use placeholder based on an offset for the purposes of the demo.
      return _wrapRow(
        row,
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color:
              theme.colorScheme.primaryContainer.withAlpha(selected ? 0xFF : 0),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => setState(() {
                selection.clear();
                selection.add(row);
              }),
              child: content,
            ),
          ),
        ),
      );
    };
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
                return Checkbox(
                  value: selection.contains(row),
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

  /// Returns log2(number) if it is integer.
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

class _DemoColumnEditor extends StatefulWidget {
  final _DemoTableColumn column;
  final void Function(
    int? flex,
    int? freezePriority,
    bool sticky,
  ) onClickApply;

  const _DemoColumnEditor({
    super.key,
    required this.column,
    required this.onClickApply,
  });

  @override
  State<_DemoColumnEditor> createState() => _DemoColumnEditorState();
}

class _DemoColumnEditorState extends State<_DemoColumnEditor> {
  late TextEditingController _freezePriorityController, _flexController;

  late ValueNotifier<bool> _stickyController;

  final _freezePriorityErrorText = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();

    _freezePriorityController =
        TextEditingController(text: widget.column.freezePriority.toString());

    _flexController =
        TextEditingController(text: widget.column.flex.toString());

    _stickyController = ValueNotifier(widget.column.sticky);

    resetFreezePriorityError() => _freezePriorityErrorText.value = null;
    _freezePriorityController.addListener(resetFreezePriorityError);
    _stickyController.addListener(resetFreezePriorityError);
  }

  @override
  void dispose() {
    super.dispose();

    _freezePriorityController.dispose();
    _flexController.dispose();
    _stickyController.dispose();
    _freezePriorityErrorText.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 16.0,
              bottom: 48.0,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 4.0,
                    right: 16.0,
                    bottom: 4.0,
                  ),
                  child: TextField(
                    controller: _flexController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12.0),
                        ),
                      ),
                      labelText: 'Flex',
                      hintText: 'Larger is higher',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 4.0,
                    right: 16.0,
                    bottom: 4.0,
                  ),
                  child: ValueListenableBuilder(
                      valueListenable: _freezePriorityErrorText,
                      builder: (context, errorText, _) {
                        return TextField(
                          controller: _freezePriorityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12.0),
                              ),
                            ),
                            labelText: 'Freeze priority',
                            hintText: 'Larger is higher',
                            errorText: errorText,
                          ),
                        );
                      }),
                ),
                ListenableBuilder(
                  listenable: _stickyController,
                  builder: (context, _) => SwitchListTile.adaptive(
                    title: Text('Sticky'),
                    subtitle: Text('Scroll off even when frozen'),
                    value: _stickyController.value,
                    onChanged: (value) => _stickyController.value = value,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              height: 48.0,
              child: Material(
                type: MaterialType.card,
                color: Theme.of(context).scaffoldBackgroundColor.withValues(
                      alpha: .9,
                    ),
                child: InkWell(
                  onTap: () {
                    final freezePriority =
                        int.tryParse(_freezePriorityController.text);
                    final sticky = _stickyController.value;

                    if (sticky &&
                        (freezePriority == null || freezePriority <= 0)) {
                      _freezePriorityErrorText.value =
                          'Only freezable columns may be sticky';
                      return;
                    }

                    widget.onClickApply(
                      int.tryParse(_flexController.text),
                      freezePriority,
                      sticky,
                    );

                    Navigator.of(context).pop();
                  },
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'APPLY',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
