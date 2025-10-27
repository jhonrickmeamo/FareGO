package com.example.farego;


import java.net.URI;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
     
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

    }

    @Override
    protected void onNewIntent(Intent intent){
        super.onNewIntent(intent);

        if (intent != null && intent.getData() != null){
            URI data = intent.getData();
            Log.d("MainActivity", "Received deep link: " + data.toString());
        }
    }
}
