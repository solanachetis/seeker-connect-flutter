import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'base58.dart';

/// SPL Memo program v2.
const memoProgramId = 'MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr';

/// Public Solana devnet RPC. The example never touches mainnet.
const devnetRpc = 'https://api.devnet.solana.com';

/// A legacy, unsigned transaction with one memo instruction, paid by [payer].
Uint8List buildMemoTransaction({
  required Uint8List payer,
  required Uint8List recentBlockhash,
  required String memo,
}) {
  if (payer.length != 32) throw ArgumentError.value(payer.length, 'payer', 'must be 32 bytes');
  if (recentBlockhash.length != 32) {
    throw ArgumentError.value(recentBlockhash.length, 'recentBlockhash', 'must be 32 bytes');
  }
  final data = utf8.encode(memo);
  final message = BytesBuilder()
    ..add([1, 0, 1]) // 1 required signature, 0 read-only signed, 1 read-only unsigned (memo program)
    ..add(_compactU16(2))
    ..add(payer)
    ..add(base58Decode(memoProgramId))
    ..add(recentBlockhash)
    ..add(_compactU16(1)) // one instruction
    ..addByte(1) // program id index
    ..add(_compactU16(0)) // no accounts
    ..add(_compactU16(data.length))
    ..add(data);
  return (BytesBuilder()
        ..add(_compactU16(1))
        ..add(Uint8List(64)) // signature slot, filled by the wallet
        ..add(message.takeBytes()))
      .takeBytes();
}

/// Fetches a recent devnet blockhash.
Future<Uint8List> fetchDevnetBlockhash() async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(devnetRpc));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'getLatestBlockhash',
      'params': [
        {'commitment': 'finalized'},
      ],
    }));
    final response = await request.close();
    final body = jsonDecode(await response.transform(utf8.decoder).join()) as Map<String, dynamic>;
    final value = (body['result'] as Map<String, dynamic>)['value'] as Map<String, dynamic>;
    return base58Decode(value['blockhash'] as String);
  } finally {
    client.close();
  }
}

/// Wallets return either a detached 64-byte signature or the message with the
/// signature appended. Returns the signature, or null if neither shape matches.
Uint8List? extractSignature(Uint8List message, Uint8List signed) {
  if (signed.length == 64) return signed;
  if (signed.length == message.length + 64) {
    for (var i = 0; i < message.length; i++) {
      if (signed[i] != message[i]) return null;
    }
    return Uint8List.sublistView(signed, message.length);
  }
  return null;
}

List<int> _compactU16(int value) {
  final out = <int>[];
  var v = value;
  while (true) {
    var byte = v & 0x7f;
    v >>= 7;
    if (v == 0) {
      out.add(byte);
      return out;
    }
    byte |= 0x80;
    out.add(byte);
  }
}
