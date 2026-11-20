package io.github.seekerconnectflutter.seeker_connect_flutter_example

import io.flutter.embedding.android.FlutterFragmentActivity

// Seeker Connect launches the wallet from an androidx ComponentActivity,
// so the host app must use FlutterFragmentActivity instead of FlutterActivity.
class MainActivity : FlutterFragmentActivity()
