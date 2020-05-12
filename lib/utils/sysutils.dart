extension PluralParsing on String {
  String plural(int qty) {
    if (qty <= 1) return this;
    if (this.toLowerCase() == 'minute') return 'minutes';
    return this;
  }
}

void syPrint(String msg, {String prefix: ""}) {
  print("$prefix[${DateTime.now()}] $msg");
}

void syPrint2(String msg, {int indent: 6, String mark: "="}) {
  syPrint(msg, prefix: mark * indent);
}
