package org.blankapp.flutterplugins.flutter_photo_picker;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;

import androidx.core.app.ActivityCompat;

import io.flutter.plugin.common.PluginRegistry;

public class PermissionManager implements PluginRegistry.RequestPermissionsResultListener {
    private static final int REQUEST_CODE_PHOTO_PICKER_ASK_PERMISSION = 9192;

    private Activity activity;
    private Callback pendingCallback;

    public PermissionManager(Activity activity) {
        this.activity = activity;
    }

    public void askPermission(String[] permissionNames, Callback callback) {
        pendingCallback = callback;

        boolean permissionGranted = true;

        for (String permissionName : permissionNames) {
            if (!(ActivityCompat.checkSelfPermission(activity, permissionName) == PackageManager.PERMISSION_GRANTED)) {
                permissionGranted = false;
                break;
            }
        }

        if (permissionGranted) {
            pendingCallback.onGranted();
            pendingCallback = null;
        } else {
            ActivityCompat.requestPermissions(activity, permissionNames, REQUEST_CODE_PHOTO_PICKER_ASK_PERMISSION);
        }
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode != REQUEST_CODE_PHOTO_PICKER_ASK_PERMISSION) return false;
        if (pendingCallback == null) return false;

        boolean permissionGranted = true;

        for (int grantResult : grantResults) {
            if (grantResult != PackageManager.PERMISSION_GRANTED) {
                permissionGranted = false;
                break;
            }
        }

        if (permissionGranted) {
            pendingCallback.onGranted();
        } else {
            pendingCallback.onDenied();
        }

        pendingCallback = null;

        return true;
    }

    interface Callback {
        void onGranted();

        void onDenied();
    }
}
