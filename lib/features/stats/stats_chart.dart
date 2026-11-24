import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../core/tokens.dart';
import 'stats_providers.dart';

/// Margem vertical interna comum ao gráfico e ao eixo Y fixo.
const double statsVerticalInset = 14;

/// Preenchimento nas pontas da área rolável, para não cortar o último rótulo.
const double statsHorizontalInset = 16;

/// Largura da coluna dos rótulos numéricos (cabe "1.000" sem apertar).
const double statsYAxisWidth = 56;

/// Espaço reservado para o nome do eixo Y, girado junto à origem.
const double statsYTitleWidth = 18;

/// Espaço reservado para o nome do eixo X abaixo dos rótulos.
const double statsXTitleHeight = 18;

/// Altura aproximada de uma linha de 10 dp, usada ao limitar os rótulos das
/// extremidades do eixo Y para dentro da área desenhável.
const double statsTickTextHeight = 14;

/// Posição superior do rótulo de um tick do eixo Y, já limitada à área útil.
double statsAxisLabelTop(double tick, NiceAxis axis, double plotHeight) {
  if (axis.maxY <= 0 || plotHeight <= statsTickTextHeight) return 0;
  final center = (1 - tick / axis.maxY) * plotHeight;
  final raw = center - statsTickTextHeight / 2;
  final maxTop = plotHeight - statsTickTextHeight;
  return raw < 0
      ? 0
      : raw > maxTop
      ? maxTop
      : raw;
}

/// Configuração de eixo Y compartilhada por todos os gráficos de barras.
typedef NiceAxis = ({double maxY, double interval});

/// Retorna um teto "bonito" (1, 2, 5, 10, 20, 50...) e um intervalo regular
/// que deixa no máximo cinco rótulos no eixo Y, incluindo o zero.
NiceAxis niceAxis(double maxValue) {
  if (!maxValue.isFinite || maxValue <= 0) {
    return (maxY: 1, interval: 1);
  }
  final maxY = _niceCeiling(maxValue);
  final interval = _niceCeiling(maxY / 4);
  return (maxY: maxY, interval: interval < 1 ? 1 : interval);
}

/// Valores que recebem rótulo/linha no eixo Y, de zero até [axis.maxY].
List<double> statsAxisValues(NiceAxis axis) {
  final values = <double>[];
  for (var value = 0.0; value <= axis.maxY + 1e-9; value += axis.interval) {
    values.add(value);
  }
  return values;
}

double _niceCeiling(double value) {
  if (!value.isFinite || value <= 1) return 1;
  final exponent = (math.log(value) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  for (final multiplier in const <double>[1, 2, 5, 10]) {
    final candidate = multiplier * magnitude;
    if (candidate >= value - 1e-9) return candidate;
  }
  return 10 * magnitude;
}

/// Dias do mês que recebem rótulo no eixo X quando a escala é compartilhada
/// por vários meses. Com rolagem, todas as posições recebem rótulo próprio.
Set<int> visibleMonthDayLabels(int daysInMonth) {
  if (daysInMonth <= 0) return const <int>{};
  final candidates = <int>{
    for (final day in const <int>[1, 5, 10, 15, 20, 25])
      if (day <= daysInMonth) day,
    daysInMonth,
  };
  final sorted = candidates.toList()..sort();
  final selected = <int>[];
  for (final day in sorted) {
    if (selected.isEmpty || day - selected.last >= 3) {
      selected.add(day);
    }
  }
  return selected.toSet();
}

bool shouldShowMonthDayLabel(int day, int daysInMonth) =>
    visibleMonthDayLabels(daysInMonth).contains(day);

/// Rótulos longos de categorias nunca se sobrepõem: são abreviados.
String abbreviatedLabel(String label, {int maxLength = 10}) {
  final trimmed = label.trim();
  if (trimmed.length <= maxLength) return trimmed;
  return '${trimmed.substring(0, maxLength - 1).trimRight()}…';
}

enum StatsXAxisMode { days, months, categories }

enum StatsValueKind { pages, readings, works, ratings }

/// Texto completo usado no tooltip (o rótulo do eixo pode estar abreviado).
String statsValueText(StatsValueKind kind, double value, {String? detail}) {
  switch (kind) {
    case StatsValueKind.pages:
      return AppStrings.pageCountLabel(value.round());
    case StatsValueKind.readings:
      return AppStrings.readingCountLabel(value.round());
    case StatsValueKind.works:
      return AppStrings.workCountLabel(value.round());
    case StatsValueKind.ratings:
      final rating = formatRating(value);
      final count = detail?.trim();
      return count == null || count.isEmpty ? rating : '$rating ($count)';
  }
}

/// Texto do eixo Y: somente inteiros nos gráficos de contagem.
String statsAxisText(StatsValueKind kind, double value) =>
    kind == StatsValueKind.ratings ? formatRating(value) : formatInteger(value);

/// Linha de resumo exibida no cabeçalho de cada card.
String statsSummaryText(
  StatsValueKind kind,
  List<StatsDatum> data, {
  String label = AppStrings.chartTotalLabel,
}) {
  if (kind == StatsValueKind.ratings) {
    return AppStrings.chartSummary(
      AppStrings.chartItemCountLabel,
      formatInteger(data.length.toDouble()),
    );
  }
  final total = data.fold<double>(0, (sum, item) => sum + item.value);
  final formatted = switch (kind) {
    StatsValueKind.pages => AppStrings.pageCountLabel(total.round()),
    StatsValueKind.readings => AppStrings.readingCountLabel(total.round()),
    StatsValueKind.works => AppStrings.workCountLabel(total.round()),
    StatsValueKind.ratings => '',
  };
  return AppStrings.chartSummary(label, formatted);
}

/// Gráfico de barras único para todas as telas de estatísticas.
///
/// Centraliza eixos, grade, tooltips, largura das barras e arredondamento das
/// pontas. Com [horizontal], o gráfico é girado 90 graus e as categorias passam
/// para o eixo esquerdo. Com [scrollable], as barras ficam em uma área rolável
/// com largura fixa por item e o eixo Y permanece visível do lado de fora.
class StatsBarChart extends StatefulWidget {
  const StatsBarChart({
    super.key,
    required this.data,
    required this.kind,
    this.mode = StatsXAxisMode.categories,
    this.horizontal = false,
    this.scrollable = false,
    this.barSlotWidth = 40,
    this.maxInitialItems = 8,
    this.height = 220,
    this.tooltipLabelBuilder,
  });

  final List<StatsDatum> data;
  final StatsValueKind kind;
  final StatsXAxisMode mode;
  final bool horizontal;
  final bool scrollable;

  /// Espaço reservado para cada barra quando o gráfico é rolável (36 a 48 dp).
  final double barSlotWidth;
  final int maxInitialItems;
  final double height;

  /// Permite usar o rótulo completo da data no tooltip.
  final String Function(StatsDatum item, int index)? tooltipLabelBuilder;

  @override
  State<StatsBarChart> createState() => _StatsBarChartState();
}

class _StatsBarChartState extends State<StatsBarChart> {
  final ScrollController _scrollController = ScrollController();
  bool _didJumpToLatest = false;
  bool _showAll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StatsBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.length != oldWidget.data.length ||
        widget.scrollable != oldWidget.scrollable) {
      _didJumpToLatest = false;
    }
  }

  void _scheduleScrollToLatest() {
    if (_didJumpToLatest || !widget.scrollable) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didJumpToLatest) return;
      final controller = _scrollController;
      if (!controller.hasClients) return;
      final target = controller.position.maxScrollExtent;
      // Evita notificar rolagem quando toda a série já cabe na tela.
      if (target > 0) controller.jumpTo(target);
      _didJumpToLatest = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelStyle = theme.textTheme.bodySmall!.copyWith(fontSize: 10);
    final ordered = List<StatsDatum>.of(widget.data);
    if (widget.horizontal) {
      // Ordenação apenas visual; a lista recebida não é alterada.
      ordered.sort((a, b) => b.value.compareTo(a.value));
    }
    if (ordered.isEmpty) return const SizedBox.shrink();

    // "Ver todos" só faz sentido em gráficos horizontais de categorias;
    // nos gráficos por período a rolagem já percorre toda a linha do tempo.
    final canCollapse =
        widget.horizontal && ordered.length > widget.maxInitialItems;
    final visible = canCollapse && !_showAll
        ? ordered.sublist(0, widget.maxInitialItems)
        : ordered;

    final maxValue = visible.fold<double>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );
    final axis = niceAxis(maxValue);
    final integerValues = widget.kind != StatsValueKind.ratings;
    // A margem vertical fica fora da área do fl_chart, mas dentro da altura
    // total do widget, para que rótulos de topo e base não sejam cortados.
    final chartHeight = widget.height - 2 * statsVerticalInset;
    final bottomReserved = widget.scrollable
        ? 44.0
        : switch (widget.mode) {
            StatsXAxisMode.days => 32.0,
            StatsXAxisMode.months => 44.0,
            StatsXAxisMode.categories => widget.horizontal ? 100.0 : 56.0,
          };

    Widget valueTitle(double value, TitleMeta meta) {
      if (value < 0 || value > axis.maxY + 1e-6) {
        return const SizedBox.shrink();
      }
      if (integerValues && (value - value.round()).abs() > 1e-6) {
        return const SizedBox.shrink();
      }
      return SideTitleWidget(
        meta: meta,
        space: 4,
        fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
        child: Text(
          statsAxisText(widget.kind, value),
          style: labelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Widget categoryTitle(double value, TitleMeta meta) {
      final index = value.round();
      if (index < 0 || index >= visible.length) {
        return const SizedBox.shrink();
      }
      final item = visible[index];
      late final String text;
      switch (widget.mode) {
        case StatsXAxisMode.days:
          text = item.label;
        case StatsXAxisMode.months:
          text = item.label;
        case StatsXAxisMode.categories:
          text = abbreviatedLabel(
            item.label,
            maxLength: widget.horizontal ? 14 : 8,
          );
      }
      final group = item.groupLabel;
      final child = widget.scrollable
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (group != null && group.isNotEmpty)
                  Text(
                    group,
                    style: labelStyle.copyWith(
                      fontSize: 9,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  text,
                  style: labelStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Text(
              text,
              style: labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
      return SideTitleWidget(
        meta: meta,
        space: 4,
        // Na rolagem cada rótulo já tem seu próprio slot; forçá-los para dentro
        // de um gráfico estreito (uma única barra) gera laço de layout.
        fitInside: widget.scrollable
            ? SideTitleFitInsideData.disable()
            : SideTitleFitInsideData.fromTitleMeta(meta),
        child: child,
      );
    }

    BarChartData chartData(double barWidth) => BarChartData(
      minY: 0,
      maxY: axis.maxY,
      alignment: BarChartAlignment.spaceAround,
      rotationQuarterTurns: widget.horizontal ? 1 : 0,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: axis.interval,
        checkToShowHorizontalLine: (value) =>
            statsAxisValues(axis).any((tick) => (tick - value).abs() < 1e-6),
        getDrawingHorizontalLine: (_) => FlLine(
          color: colors.outline.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.55 : 0.4,
          ),
          strokeWidth: AppTokens.borderWidth,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: !widget.scrollable,
            reservedSize: widget.scrollable ? 0 : statsYAxisWidth,
            interval: axis.interval,
            getTitlesWidget: valueTitle,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: bottomReserved,
            // Cada barra tem sua própria posição; o filtro de dias era feito
            // aqui antes da rolagem e não se aplica mais.
            interval: 1,
            getTitlesWidget: categoryTitle,
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchExtraThreshold: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 4,
        ),
        touchTooltipData: BarTouchTooltipData(
          tooltipMargin: 8,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          tooltipBorderRadius: BorderRadius.circular(AppTokens.radius / 2),
          tooltipBorder: BorderSide(
            color: colors.outline,
            width: AppTokens.borderWidth,
          ),
          maxContentWidth: 220,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipColor: (_) => colors.surface,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final index = group.x;
            if (index < 0 || index >= visible.length || rod.toY <= 0) {
              return null;
            }
            final item = visible[index];
            final label =
                widget.tooltipLabelBuilder?.call(item, index) ??
                item.fullLabel ??
                item.label;
            return BarTooltipItem(
              '$label\n'
              '${statsValueText(widget.kind, item.value, detail: item.detail)}',
              theme.textTheme.bodySmall!.copyWith(
                color: colors.onSurface,
                fontSize: 11,
              ),
            );
          },
        ),
      ),
      barGroups: [
        for (var index = 0; index < visible.length; index++)
          BarChartGroupData(
            x: index,
            barRods: [
              if (visible[index].value > 0)
                BarChartRodData(
                  toY: math.max(visible[index].value, axis.maxY * 0.02),
                  color: colors.primary,
                  width: barWidth,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
            ],
          ),
      ],
    );

    Widget chart(double barWidth) =>
        BarChart(chartData(barWidth), duration: Duration.zero);

    if (widget.scrollable) {
      _scheduleScrollToLatest();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: statsVerticalInset),
        child: SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fixedYAxis(axis, labelStyle, bottomReserved, chartHeight),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  clipBehavior: Clip.hardEdge,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: statsHorizontalInset,
                    ),
                    child: SizedBox(
                      width: visible.length * widget.barSlotWidth,
                      height: chartHeight,
                      child: chart(widget.barSlotWidth * 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: statsVerticalInset),
          child: SizedBox(
            width: double.infinity,
            height: chartHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = _clamp(
                  constraints.maxWidth / visible.length * 0.62,
                  4,
                  18,
                );
                return chart(barWidth);
              },
            ),
          ),
        ),
        if (canCollapse)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(_showAll ? AppStrings.showLess : AppStrings.showAll),
            ),
          ),
      ],
    );
  }

  /// Eixo Y desenhado fora da área rolável, com os mesmos ticks da grade.
  Widget _fixedYAxis(
    NiceAxis axis,
    TextStyle labelStyle,
    double bottomReserved,
    double chartHeight,
  ) {
    final color = Theme.of(context).colorScheme;
    final plotHeight = chartHeight - bottomReserved;
    return Container(
      width: statsYAxisWidth,
      height: chartHeight,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: color.outlineVariant, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomReserved),
        child: Stack(
          children: [
            for (final tick in statsAxisValues(axis))
              Positioned(
                top: statsAxisLabelTop(tick, axis, plotHeight),
                left: 0,
                right: 4,
                child: Text(
                  statsAxisText(widget.kind, tick),
                  textAlign: TextAlign.right,
                  style: labelStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

double _clamp(double value, double min, double max) => value < min
    ? min
    : value > max
    ? max
    : value;
