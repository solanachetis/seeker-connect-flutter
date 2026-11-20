import 'dart:typed_data';

const _alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

/// Bitcoin-alphabet base58, as used for Solana addresses and signatures.
String base58Encode(List<int> bytes) {
  var value = BigInt.zero;
  for (final b in bytes) {
    value = (value << 8) | BigInt.from(b);
  }
  final out = StringBuffer();
  final base = BigInt.from(58);
  while (value > BigInt.zero) {
    out.write(_alphabet[(value % base).toInt()]);
    value ~/= base;
  }
  for (final b in bytes) {
    if (b != 0) break;
    out.write('1');
  }
  return out.toString().split('').reversed.join();
}

Uint8List base58Decode(String text) {
  var value = BigInt.zero;
  final base = BigInt.from(58);
  for (final c in text.split('')) {
    final digit = _alphabet.indexOf(c);
    if (digit < 0) throw FormatException('Invalid base58 character', text);
    value = value * base + BigInt.from(digit);
  }
  final bytes = <int>[];
  while (value > BigInt.zero) {
    bytes.add((value & BigInt.from(0xff)).toInt());
    value >>= 8;
  }
  for (final c in text.split('')) {
    if (c != '1') break;
    bytes.add(0);
  }
  return Uint8List.fromList(bytes.reversed.toList());
}
