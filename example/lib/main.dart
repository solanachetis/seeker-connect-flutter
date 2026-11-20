import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/widgets.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter.dart';

import 'base58.dart';
import 'memo_transaction.dart';

/// Demo identity. Replace with your own https domain and icon in a real app.
const _config = SeekerConnectConfig(
  identity: DappIdentity(name: 'Seeker Connect Flutter demo', uri: 'https://example.com', icon: 'favicon.ico'),
  chain: 'solana:devnet', // The example never uses mainnet.
);

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, _) => const SeekerConnectDialogs(child: HomeScreen()),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WalletAvailability? _availability;
  StoredAuthorization? _authorization;
  String _status = 'Ready.';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _run('Configured', () async {
      await SeekerConnect.configure(_config);
      _availability = await SeekerConnect.walletAvailability();
      _authorization = await SeekerConnect.restore();
      return _authorization == null ? 'Configured. Not connected.' : 'Restored previous connection.';
    });
  }

  Future<void> _run(String _, Future<String> Function() action) async {
    setState(() => _busy = true);
    String status;
    try {
      status = await action();
    } on SeekerConnectException catch (e) {
      status = 'Error ${e.code.name}: ${e.message}';
    } catch (e) {
      status = 'Error: $e';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = status;
      _authorization = SeekerConnect.currentAuthorization ?? _authorization;
    });
  }

  String? get _address => _authorization?.accounts.first.address;

  Future<String> _connect() async {
    final auth = await SeekerConnect.connect();
    _authorization = auth;
    return 'Connected as ${auth.accounts.first.address}';
  }

  Future<String> _signIn() async {
    final result = await SeekerConnect.signIn(
      const SeekerSignInPayload(domain: 'example.com', statement: 'Sign in to the Seeker Connect Flutter demo'),
    );
    final ok = await Ed25519().verify(
      result.signedMessage,
      signature: Signature(result.signature, publicKey: SimplePublicKey(result.publicKey, type: KeyPairType.ed25519)),
    );
    return 'Signed in as ${result.address} — signature ${ok ? 'valid ✓' : 'INVALID ✗'}';
  }

  Future<String> _signMessage() async {
    final account = (await SeekerConnect.connect()).accounts.first;
    final message = Uint8List.fromList(utf8.encode('Hello from Seeker Connect Flutter'));
    final signed = (await SeekerConnect.signMessages([account.address], [message])).single;
    final signature = extractSignature(message, signed);
    if (signature == null) return 'Unexpected signed message format (${signed.length} bytes)';
    final ok = await Ed25519().verify(
      message,
      signature: Signature(signature, publicKey: SimplePublicKey(account.publicKey, type: KeyPairType.ed25519)),
    );
    return 'Message signature ${ok ? 'valid ✓' : 'INVALID ✗'}: ${base58Encode(signature).substring(0, 16)}…';
  }

  Future<Uint8List> _memoTransaction() async {
    final account = (await SeekerConnect.connect()).accounts.first;
    return buildMemoTransaction(
      payer: account.publicKey,
      recentBlockhash: await fetchDevnetBlockhash(),
      memo: 'Seeker Connect Flutter demo',
    );
  }

  Future<String> _signTransaction() async {
    final signed = (await SeekerConnect.signTransactions([await _memoTransaction()])).single;
    // Signature slot follows the 1-byte signature count.
    final signature = signed.sublist(1, 65);
    return 'Devnet transaction signed (not sent): ${base58Encode(signature).substring(0, 16)}…';
  }

  Future<String> _signAndSend() async {
    // Never retry this automatically: on failure, check the explorer first.
    final signature = (await SeekerConnect.signAndSendTransactions([await _memoTransaction()])).single;
    return 'Sent on devnet: ${base58Encode(signature)} (check it on a devnet explorer)';
  }

  Future<String> _disconnect({required bool revoke}) async {
    await SeekerConnect.disconnect(revoke: revoke);
    _authorization = null;
    return revoke ? 'Disconnected and revoked in the wallet.' : 'Disconnected.';
  }

  @override
  Widget build(BuildContext context) {
    final address = _address;
    return ColoredBox(
      color: const Color(0xFFF5F6F6),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Seeker Connect for Flutter',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF000000)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Unofficial community demo · devnet only',
              style: TextStyle(fontSize: 13, color: Color(0xFF6C6C6C)),
            ),
            const SizedBox(height: 16),
            _Info('Wallet: ${_availability?.name ?? '…'}'),
            _Info(address == null ? 'Not connected' : 'Account: $address'),
            const SizedBox(height: 20),
            Center(
              child: SeekerConnectButton(
                enabled: !_busy,
                brightness: Brightness.light,
                onPressed: () => _run('connect', _connect),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SeekerConnectButton(
                enabled: !_busy,
                brightness: Brightness.light,
                variant: SeekerConnectButtonVariant.signIn,
                onPressed: () => _run('signIn', _signIn),
              ),
            ),
            const SizedBox(height: 20),
            _Action('Sign message', enabled: !_busy, onTap: () => _run('message', _signMessage)),
            _Action('Sign devnet memo transaction', enabled: !_busy, onTap: () => _run('tx', _signTransaction)),
            _Action('Sign & send devnet memo', enabled: !_busy, onTap: () => _run('send', _signAndSend)),
            _Action('Disconnect', enabled: !_busy, onTap: () => _run('disconnect', () => _disconnect(revoke: false))),
            _Action('Disconnect + revoke', enabled: !_busy, onTap: () => _run('revoke', () => _disconnect(revoke: true))),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(fontSize: 14, color: Color(0xFF000000))),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
      );
}

class _Action extends StatelessWidget {
  const _Action(this.label, {required this.enabled, required this.onTap});
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Semantics(
          button: true,
          enabled: enabled,
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Color(enabled ? 0xFF000000 : 0x66000000)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(enabled ? 0xFF000000 : 0x66000000)),
              ),
            ),
          ),
        ),
      );
}
