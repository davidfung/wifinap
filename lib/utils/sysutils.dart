extension PluralParsing on String {
  String plural(int qty) {
    if (qty <= 1) return this;
    if (this.toLowerCase() == 'minute') return 'minutes';
    return this;
  }
}

void dbgPrint(String msg, {String prefix: ""}) {
  print("$prefix[${DateTime.now()}] $msg");
}

void dbgPrint2(String msg, {int indent: 6, String mark: "="}) {
  dbgPrint(msg, prefix: mark * indent);
}
