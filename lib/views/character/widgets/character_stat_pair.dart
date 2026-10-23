/// A single labelled character stat (optionally with an icon), shared by the
/// character roster's mobile cards, desktop cards and desktop table.
class StatPair {
  final String label;
  final String value;
  final String? icon;

  const StatPair(this.label, this.value, {this.icon});
}
