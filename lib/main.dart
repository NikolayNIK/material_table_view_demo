import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_table_view/default_animated_switcher_transition_builder.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/shimmer_placeholder_shade.dart';
import 'package:material_table_view/sliver_table_view.dart';
import 'package:material_table_view/table_column_controls.dart';
import 'package:material_table_view/table_view_typedefs.dart';

void main() => runApp(const MyApp());

const _title = 'material_table_view demo';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: _title,
        theme: _appTheme(Brightness.light),
        darkTheme: _appTheme(Brightness.dark),
        home: const MyHomePage(),
      );

  ThemeData _appTheme(Brightness brightness) => ThemeData(
        useMaterial3: true,
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
  })  : key = ValueKey<int>(index),
        // ignore: prefer_initializing_formals
        index = index;

  final int index;

  @override
  final ValueKey<int> key;

  /// This is a vital override because [TableColumnControls] uses this method to copy the column.
  /// Because of this we can expect [TableColumnControls] to give us an instance of this method.
  @override
  _MyTableColumn copyWith(
          {double? width,
          int? freezePriority,
          bool? sticky,
          int? flex,
          double? translation}) =>
      _MyTableColumn(
        index: index,
        width: width ?? this.width,
        freezePriority: freezePriority ?? this.freezePriority,
        sticky: sticky ?? this.sticky,
        flex: flex ?? this.flex,
        translation: translation ?? this.translation,
      );
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin<MyHomePage> {
  late TabController tabController;

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
        // translation: i,
        flex: i, // this will make the column expand to fill remaining width
        freezePriority: 1 *
            (_columnsPowerOfTwo - (_getPowerOfTwo(i) ?? _columnsPowerOfTwo)),
      ),
  ];

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 2, vsync: this);
    periodicPlaceholderOffsetIncreaseTimer = Timer.periodic(
        const Duration(milliseconds: 1000),
        (timer) => setState(() => placeholderOffsetIndex++));
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

    return TableColumnControls(
      columns: columns,
      // We can freely cast the columns here thanks to the override of [_MyTableColumn.copyWith]

      // Note that both the [TableColumnControls] and the [TableView]/[SliverTableView] must be rebuilt when columns
      // change
      onColumnTranslate: (index, newColumn) =>
          setState(() => columns[index] = newColumn as _MyTableColumn),
      onColumnResize: (index, newColumn) =>
          setState(() => columns[index] = newColumn as _MyTableColumn),
      onColumnMove: (oldIndex, newIndex) =>
          setState(() => columns.insert(newIndex, columns.removeAt(oldIndex))),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
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
              // make the checkbox column sticky to conserve it
              columns[0] = columns[0].copyWith(sticky: constraints.maxWidth <= 512);
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
        rowHeight: 48.0 + 4 * Theme.of(context).visualDensity.vertical,
        rowCount: _rowCount - 1,
        rowBuilder: _rowBuilder,
        placeholderBuilder: _placeholderBuilder,
        placeholderShade: placeholderShade,
        headerBuilder: _headerBuilder,
        footerBuilder: _footerBuilder,
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
      child: CustomScrollView(
        controller: verticalSliverExampleScrollController,
        slivers: [
          for (var i = 0; i < tableCount; i++) ...[
            SliverTableView.builder(
              style: const TableViewStyle(
                // If we want the content to scroll out from underneath
                // the vertical scrollbar
                // we need to specify scroll padding here since we are
                // managing that scrollbar.
                scrollPadding: EdgeInsets.only(right: 10),
              ),
              columns: columns,
              rowHeight: itemExtent,
              rowCount: rowsPerTable,
              rowBuilder: _rowBuilder,
              placeholderBuilder: _placeholderBuilder,
              placeholderShade: placeholderShade,
              headerBuilder: _headerBuilder,
              footerBuilder: _footerBuilder,
            ),
            SliverFixedExtentList(
              delegate: SliverChildBuilderDelegate(
                childCount: 8,
                (context, index) => Padding(
                  padding: const EdgeInsets.only(left: 18.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
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
    );
  }

  Widget _headerBuilder(
    BuildContext context,
    TableRowContentBuilder contentBuilder,
  ) =>
      contentBuilder(
        context,
        (context, column) => column == 0
            ? Checkbox(
                value: selection.isEmpty ? false : null,
                tristate: true,
                onChanged: (value) {
                  if (!(value ?? true)) {
                    setState(() => selection.clear());
                  }
                },
              )
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => TableColumnControls.of(context).invoke(column),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("${columns[column].index}"),
                    ),
                  ),
                ),
              ),
      );

  /// This is used to wrap both regular and placeholder rows to achieve fade
  /// transition between them.
  Widget _wrapRow(Widget child) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: tableRowDefaultAnimatedSwitcherTransitionBuilder,
        child: child,
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
                  child: contentBuilder(
                    context,
                    (context, column) => column == 0
                        ? Checkbox(
                            value: selection.contains(row),
                            onChanged: (value) => setState(() =>
                                (value ?? false)
                                    ? selection.add(row)
                                    : selection.remove(row)))
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                '${(row + 2) * columns[column].index}',
                                style: textStyle,
                                overflow: TextOverflow.fade,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
  }

  Widget _placeholderBuilder(
    BuildContext context,
    TableRowContentBuilder contentBuilder,
  ) =>
      _wrapRow(
        contentBuilder(
          context,
          (context, column) => column == 0
              ? const Checkbox(
                  value: false,
                  onChanged: _dummyCheckboxOnChanged,
                )
              : const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(16)))),
                ),
        ),
      );

  Widget _footerBuilder(
    BuildContext context,
    TableRowContentBuilder contentBuilder,
  ) =>
      contentBuilder(
        context,
        (context, column) => Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Align(
            alignment: column == 0 ? Alignment.center : Alignment.centerLeft,
            child: Text(column == 0
                ? '${selection.length}'
                : '${columns[column].index}'),
          ),
        ),
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
