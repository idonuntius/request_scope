/// Lifecycle status of an [HttpExchange].
enum ExchangeStatus {
  /// Request issued, awaiting response.
  pending,

  /// Response received successfully.
  completed,

  /// Exchange failed with an error.
  failed,
}
