import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_connect_flutter_example/base58.dart';
import 'package:seeker_connect_flutter_example/memo_transaction.dart';

void main() {
  test('base58 round-trips the memo program id', () {
    final bytes = base58Decode(memoProgramId);
    expect(bytes, hasLength(32));
    expect(base58Encode(bytes), memoProgramId);
  });

  test('base58 keeps leading zero bytes', () {
    final bytes = Uint8List.fromList([0, 0, 1, 2]);
    expect(base58Decode(base58Encode(bytes)), bytes);
    expect(base58Encode(bytes), startsWith('11'));
  });

  test('memo transaction has the legacy layout with an empty signature slot', () {
    final payer = Uint8List.fromList(List.filled(32, 1));
    final blockhash = Uint8List.fromList(List.filled(32, 2));
    final memo = utf8.encode('hi');
    final tx = buildMemoTransaction(payer: payer, recentBlockhash: blockhash, memo: 'hi');

    var o = 0;
    expect(tx[o++], 1, reason: 'one signature');
    expect(tx.sublist(o, o + 64), everyElement(0), reason: 'unsigned');
    o += 64;
    expect(tx.sublist(o, o + 3), [1, 0, 1], reason: 'header: 1 signer, 0 ro signed, 1 ro unsigned');
    o += 3;
    expect(tx[o++], 2, reason: 'two account keys');
    expect(tx.sublist(o, o + 32), payer);
    o += 32;
    expect(tx.sublist(o, o + 32), base58Decode(memoProgramId));
    o += 32;
    expect(tx.sublist(o, o + 32), blockhash);
    o += 32;
    expect(tx[o++], 1, reason: 'one instruction');
    expect(tx[o++], 1, reason: 'program id index');
    expect(tx[o++], 0, reason: 'no accounts');
    expect(tx[o++], memo.length);
    expect(tx.sublist(o), memo);
  });

  test('rejects malformed keys', () {
    expect(
      () => buildMemoTransaction(payer: Uint8List(31), recentBlockhash: Uint8List(32), memo: 'x'),
      throwsArgumentError,
    );
  });

  test('detached or appended message signatures are extracted', () {
    final message = Uint8List.fromList([1, 2, 3]);
    final sig = Uint8List.fromList(List.filled(64, 7));
    expect(extractSignature(message, sig), sig);
    expect(extractSignature(message, Uint8List.fromList([...message, ...sig])), sig);
    expect(extractSignature(message, Uint8List.fromList([9, 9])), isNull);
  });
}
