extension PluralParsing on String {
  String plural(int qty) {
    if (qty <= 1) return this;
    if (this.toLowerCase() == 'minute') return 'minutes';
    return this;
  }
}
