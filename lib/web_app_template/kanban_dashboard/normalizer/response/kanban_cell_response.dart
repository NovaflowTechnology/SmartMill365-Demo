class KanbanCellResponse {
  final bool isLoading;
  final String? error;

  const KanbanCellResponse({
    this.isLoading = false,
    this.error,
  });
}
