import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../core/tokens.dart';
import 'stats_providers.dart';

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

/// Dias do mês que recebem rótulo no eixo X.
///
/// Mantém 1, 5, 10, 15, 20, 25 e o último dia, descartando qualquer rótulo
/// que ficasse a menos de três posições do anterior (meses curtos).
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
String statsSummaryText(StatsValueKind kind, List<StatsDatum> data) {
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
  return AppStrings.chartSummary(AppStrings.chartTotalLabel, formatted);
}

/// Gráfico de barras único para todas as telas de estatísticas.
///
/// Centraliza eixos, grade, tooltips, largura das barras e arredondamento das
/// pontas. Com [horizontal], o gráfico é girado 90 graus e as categorias passam
/// para o eixo esquerdo, evitando rótulos longos sobrepostos.
class StatsBarChart extends StatefulWidget {
  const StatsBarChart({
    super.key,
    required this.data,
    required this.kind,
    this.mode = StatsXAxisMode.categories,
    this.horizontal = false,
    this.maxInitialItems = 8,
    this.height = 220,
    this.tooltipLabelBuilder,
  });

  final List<StatsDatum> data;
  final StatsValueKind kind;
  final StatsXAxisMode mode;
  final bool horizontal;
  final int maxInitialItems;
  final double height;

  /// Permite usar "21 de nov" no tooltip enquanto o eixo mostra apenas "21".
  final String Function(StatsDatum item, int index)? tooltipLabelBuilder;

  @override
  State<StatsBarChart> createState() => _StatsBarChartState();
}

class _StatsBarChartState extends State<StatsBarChart> {
  bool _showAll = false;

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
    // nos gráficos por período a navegação já é feita pelo seletor Mês/Ano.
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
    final dayLabels = widget.mode == StatsXAxisMode.days
        ? visibleMonthDayLabels(visible.length)
        : const <int>{};

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
          final day = index + 1;
          if (!dayLabels.contains(day)) return const SizedBox.shrink();
          text = item.label;
        case StatsXAxisMode.months:
          text = item.label;
        case StatsXAxisMode.categories:
          text = abbreviatedLabel(
            item.label,
            maxLength: widget.horizontal ? 14 : 8,
          );
      }
      return SideTitleWidget(
        meta: meta,
        space: 4,
        fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
        child: Text(
          text,
          style: labelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final bottomReserved = switch (widget.mode) {
      StatsXAxisMode.days => 32.0,
      StatsXAxisMode.months => 44.0,
      StatsXAxisMode.categories => widget.horizontal ? 100.0 : 56.0,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final extent = widget.horizontal
                  ? constraints.maxHeight
                  : constraints.maxWidth;
              final barWidth = _clamp(extent / visible.length * 0.62, 4, 18);
              final minVisibleHeight = axis.maxY * 0.02;

              return BarChart(
                BarChartData(
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
                        value >= 0 &&
                        value <= axis.maxY + 1e-6 &&
                        (value - value.round()).abs() < 1e-6,
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
                        showTitles: true,
                        reservedSize: 48,
                        interval: axis.interval,
                        getTitlesWidget: valueTitle,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: bottomReserved,
                        // Garante que todas as posições sejam avaliadas; o
                        // filtro de dias acontece em categoryTitle.
                        interval: 1,
                        getTitlesWidget: categoryTitle,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
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
                      tooltipBorderRadius: BorderRadius.circular(
                        AppTokens.radius / 2,
                      ),
                      tooltipBorder: BorderSide(
                        color: colors.outline,
                        width: AppTokens.borderWidth,
                      ),
                      maxContentWidth: 200,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (_) => colors.surface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final index = group.x;
                        if (index < 0 ||
                            index >= visible.length ||
                            rod.toY <= 0) {
                          return null;
                        }
                        final item = visible[index];
                        final label =
                            widget.tooltipLabelBuilder?.call(item, index) ??
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
                              toY: math.max(
                                visible[index].value,
                                minVisibleHeight,
                              ),
                              color: colors.primary,
                              width: barWidth,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                duration: Duration.zero,
              );
            },
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
}

double _clamp(double value, double min, double max) => value < min
    ? min
    : value > max
    ? max
    : value;
