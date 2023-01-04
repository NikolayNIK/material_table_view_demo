import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:shimmer/shimmer.dart';

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
        dividerColor: const Color(0x60808080),
        dividerTheme: const DividerThemeData(
          color: Color(0x60808080),
        ),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const _columnsPowerOfTwo = 12;
const _rowCount = (1 << 48) - 1; // 281_474_976_710_656 - 1

class _MyHomePageState extends State<MyHomePage> {
  final selection = <int>{};
  int placeholderOffsetIndex = 0;

  final _rowKeys = <int, GlobalKey<_MyHomePageState>>{};

  late Timer periodicPlaceholderOffsetIncreaseTimer;

  @override
  void initState() {
    super.initState();
    periodicPlaceholderOffsetIncreaseTimer = Timer.periodic(
        const Duration(milliseconds: 1000),
        (timer) => setState(() => placeholderOffsetIndex++));
  }

  @override
  void dispose() {
    periodicPlaceholderOffsetIncreaseTimer.cancel();

    super.dispose();
  }

  Widget _buildAnimatedSwitcher({
    required Widget child,
    required int rowIndex,
  }) =>
      AnimatedSwitcher(
        key: _rowKeys.putIfAbsent(rowIndex, () => GlobalKey()),
        duration: const Duration(milliseconds: 200),
        child: RepaintBoundary(key: ValueKey(child.runtimeType), child: child),
      );

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final selectedTextStyle = textStyle?.copyWith(
        color: Theme.of(context).colorScheme.onPrimaryContainer);

    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: TableView(
        columns: [
          const TableColumn(
            width: 56.0,
            freezePriority: 1 * (_columnsPowerOfTwo + 1),
          ),
          for (var i = 1; i <= 1 << _columnsPowerOfTwo; i++)
            TableColumn(
              width: 64,
              freezePriority: 1 *
                  (_columnsPowerOfTwo -
                      (_getPowerOfTwo(i) ?? _columnsPowerOfTwo)),
            ),
        ],
        rowHeight: 48.0 + 4 * Theme.of(context).visualDensity.vertical,
        rowCount: _rowCount - 1,
        rowBuilder: (row) {
          final selected = selection.contains(row);
          return (row + placeholderOffsetIndex) % 32 < 4
              ? null
              : (context, column) => column == 0
                  ? Checkbox(
                      value: selection.contains(row),
                      onChanged: (value) => setState(() => (value ?? false)
                          ? selection.add(row)
                          : selection.remove(row)))
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          '${(row + 2) * column}',
                          style: selected ? selectedTextStyle : textStyle,
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    );
        },
        rowDecorator: (rowWidget, rowIndex) => _buildAnimatedSwitcher(
          rowIndex: rowIndex,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withAlpha(selection.contains(rowIndex) ? 0xFF : 0),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => setState(() {
                  selection.clear();
                  selection.add(rowIndex);
                }),
                child: rowWidget,
              ),
            ),
          ),
        ),
        placeholderBuilder: (context, column) => column == 0
            ? const Checkbox(value: false, onChanged: null)
            : Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Theme.of(context).dividerTheme.color!,
                        shape: BoxShape.rectangle,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16))),
                    child: const SizedBox(
                      height: 16.0,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
        placeholderDecorator: (placeholderWidget, rowIndex) =>
            _buildAnimatedSwitcher(
          rowIndex: rowIndex,
          child: placeholderWidget,
        ),
        placeholderContainerBuilder: (headerWidget) {
          final dividerColor = Theme.of(context).dividerTheme.color!;
          return Shimmer(
              period: const Duration(milliseconds: 1000),
              gradient: LinearGradient(
                begin: const FractionalOffset(.33, 0),
                end: const FractionalOffset(.66, 0),
                colors: [
                  dividerColor.withOpacity(.2),
                  dividerColor.withOpacity(1),
                  dividerColor.withOpacity(0.2),
                ],
              ),
              child: headerWidget);
        },
        headerBuilder: (context, column) => column == 0
            ? Checkbox(
                value: selection.isEmpty ? false : null,
                tristate: true,
                onChanged: (value) {
                  if (!(value ?? true)) {
                    setState(() => selection.clear());
                  }
                },
              )
            : Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("$column"),
                ),
              ),
        footerBuilder: (context, column) => Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Align(
            alignment: column == 0 ? Alignment.center : Alignment.centerLeft,
            child: Text(column == 0 ? '${selection.length}' : '$column'),
          ),
        ),
      ),
    );
  }

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
