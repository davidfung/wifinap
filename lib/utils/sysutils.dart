extension PluralParsing on String {
  String plural(int qty) {
    if (qty <= 1) return this;
    if (this.toLowerCase() == 'minute') return 'minutes';
    return this;
  }
}

void utPrint(String msg, {String prefix: ""}) {
  print("$prefix[${DateTime.now()}] $msg");
}

void utPrint2(String msg, {int indent: 6, String mark: "="}) {
  utPrint(msg, prefix: mark * indent);
}
