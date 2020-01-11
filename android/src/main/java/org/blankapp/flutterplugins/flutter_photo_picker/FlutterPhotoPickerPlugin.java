package org.blankapp.flutterplugins.flutter_photo_picker;

import android.app.Activity;
import android.content.ContentProvider;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.graphics.Point;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.webkit.MimeTypeMap;

import com.zhihu.matisse.Matisse;
import com.zhihu.matisse.MimeType;
import com.zhihu.matisse.engine.impl.GlideEngine;
import com.zhihu.matisse.filter.Filter;
import com.zhihu.matisse.internal.utils.PhotoMetadataUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static android.app.Activity.RESULT_CANCELED;
import static android.app.Activity.RESULT_OK;

/**
 * FlutterPhotoPickerPlugin
 */
public class FlutterPhotoPickerPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {
    private static final int REQUEST_CODE_PHOTO_PICKER = 9191;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_photo_picker");
        final FlutterPhotoPickerPlugin instance = new FlutterPhotoPickerPlugin(registrar);

        registrar.addActivityResultListener(instance);

        channel.setMethodCallHandler(instance);
    }

    private Registrar registrar;
    private Object arguments;
    private Result result;

    public FlutterPhotoPickerPlugin(Registrar registrar) {
        this.registrar = registrar;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (this.result != null) {
            this.result.error("multiple_request", "Cancelled by a second request", null);
            this.result = null;
            return;
        }

        if (call.method.equals("openPicker")) {
            this.arguments = call.arguments;
            this.result = result;

            this.openPicker();
        } else {
            result.notImplemented();
        }
    }

    private void openPicker() {
        Matisse.from(registrar.activity())
                .choose(MimeType.ofAll())
                .countable(true)
                .maxSelectable(9)
                .restrictOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED)
                .thumbnailScale(0.85f)
                .imageEngine(new GlideEngine())
                .showPreview(false) // Default is `true`
                .forResult(REQUEST_CODE_PHOTO_PICKER);
    }

    @Override
    public boolean onActivityResult(final int requestCode, final int resultCode, final Intent data) {
        if (requestCode != REQUEST_CODE_PHOTO_PICKER) return false;

        if (resultCode == RESULT_CANCELED) {
            this.result.error("cancelled", "Operation cancelled by user", null);
            this.result = null;
        } else if (resultCode == RESULT_OK) {
            Activity activity = registrar.activity();
            ContentResolver contentProvider = registrar.activeContext().getContentResolver();


            List<Uri> selectedUris = Matisse.obtainResult(data);

            List<Map<String, Object>> assets = new ArrayList<>();
            for (int i = 0; i < selectedUris.size(); i++) {
                Uri uri = selectedUris.get(i);
                Map<String, Object> asset = new HashMap<>();

                asset.put("selectedOrder", i + 1);
                asset.put("identifier", uri.toString());
                asset.put("type", getMimeType(uri).split("/")[0]);
                asset.put("mimeType", getMimeType(uri));
//                String mimeType;

                String url = PhotoMetadataUtils.getPath(contentProvider, uri);
                Point point = PhotoMetadataUtils.getBitmapSize(uri, activity);

                asset.put("url", "file://" + url);
                asset.put("width", point.x);
                asset.put("height", point.y);
//                num width;
//                num height;
//                String thumbnailUrl;
//                num thumbnailWidth;
//                num thumbnailHeight;

                assets.add(asset);
            }

            this.result.success(assets);
            this.result = null;
        }
        return true;
    }

    private String getMimeType(Uri uri) {
        String mimeType = null;
        if (uri.getScheme().equals(ContentResolver.SCHEME_CONTENT)) {
            ContentResolver cr = registrar.activeContext().getContentResolver();
            mimeType = cr.getType(uri);
        } else {
            String fileExtension = MimeTypeMap.getFileExtensionFromUrl(uri
                    .toString());
            mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(
                    fileExtension.toLowerCase());
        }
        return mimeType;
    }
}
