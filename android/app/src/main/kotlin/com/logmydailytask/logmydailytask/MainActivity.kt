package com.logmydailytask.logmydailytask

import android.os.Build
import android.os.Bundle
import android.system.Os
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.HARDWARE == "ranchu" && Build.SUPPORTED_ABIS.firstOrNull() == "arm64-v8a") {
            // Some ARM emulators advertise SVE2 but cannot execute SVE instructions.
            // Use OpenSSL's portable code paths before SQLCipher is loaded.
            Os.setenv("OPENSSL_armcap", "0", false)
        }
        super.onCreate(savedInstanceState)
    }
}
