class TableColumn {
  final String label;
  final String key;
  final double width;
  final bool sortable;

  const TableColumn(
    this.label,
    this.key,
    this.width, {
    this.sortable = false,
  });
}

/// Fixed widths for the non-data columns.
const double kCheckboxColumnWidth = 40;
const double kNumberColumnWidth = 36;
const double kActionColumnWidth = 80;

/// Computes the minimum table width for any given column list.
double minTableWidth(List<TableColumn> columns) =>
    kCheckboxColumnWidth + kNumberColumnWidth + columns.fold<double>(0, (sum, c) => sum + c.width) + kActionColumnWidth;
