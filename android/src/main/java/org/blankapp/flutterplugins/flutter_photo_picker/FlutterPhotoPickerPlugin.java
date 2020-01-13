package org.blankapp.flutterplugins.flutter_photo_picker;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.graphics.Point;
import android.net.Uri;

import com.zhihu.matisse.Matisse;
import com.zhihu.matisse.MimeType;
import com.zhihu.matisse.engine.impl.GlideEngine;
import com.zhihu.matisse.internal.entity.CaptureStrategy;
import com.zhihu.matisse.internal.utils.PathUtils;
import com.zhihu.matisse.internal.utils.PhotoMetadataUtils;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

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
    private Map<String, Object> arguments;
    private Result result;

    public FlutterPhotoPickerPlugin(Registrar registrar) {
        this.registrar = registrar;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (this.result != null) {
            this.result.error("multiple_request", "Cancelled by a second request", null);
            this.result = null;
            this.arguments = null;
            return;
        }

        if (call.method.equals("openPicker")) {
            this.result = result;
            this.arguments = (HashMap<String, Object>) call.arguments;

            this.openPicker();
        } else {
            result.notImplemented();
        }
    }

    private void openPicker() {
        String mediaType = "any";
        boolean multiple = true;
        int limit = 9;
        int numberOfColumn = 3;

        if (arguments.containsKey("mediaType"))
            mediaType = (String) arguments.get("mediaType");
        if (arguments.containsKey("multiple"))
            multiple = (boolean) arguments.get("multiple");
        if (arguments.containsKey("limit"))
            limit = (int) arguments.get("limit");
        if (arguments.containsKey("numberOfColumn"))
            numberOfColumn = (int) arguments.get("numberOfColumn");

        if (!multiple) limit = 1;

        Set<MimeType> mimeTypes = new HashSet<>();
        if ("image".equals(mediaType)) {
            mimeTypes = MimeType.ofImage();
        } else if ("video".equals(mediaType)) {
            mimeTypes = MimeType.ofVideo();
        } else {
            mimeTypes = MimeType.ofAll();
        }

        final String packageName = registrar.activeContext().getPackageName();
        CaptureStrategy captureStrategy = new CaptureStrategy(
                true,
                new StringBuilder(packageName).append(".provider").toString(),
                "."
        );

        Matisse.from(registrar.activity())
                .choose(mimeTypes)
                .countable(true)
                .capture(true)
                .captureStrategy(captureStrategy)
                .maxSelectable(limit)
                .showSingleMediaType(!multiple)
                .restrictOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED)
                .thumbnailScale(0.85f)
                .imageEngine(new GlideEngine())
                .spanCount(numberOfColumn)
                .showPreview(false) // Default is `true`
                .forResult(REQUEST_CODE_PHOTO_PICKER);
    }

    @Override
    public boolean onActivityResult(final int requestCode, final int resultCode, final Intent data) {
        if (requestCode != REQUEST_CODE_PHOTO_PICKER) return false;
        if (result == null) return false;

        if (resultCode == RESULT_CANCELED) {
            this.result.error("cancelled", "Operation cancelled by user", null);
            this.result = null;
        } else if (resultCode == RESULT_OK) {
            Context context= registrar.activeContext();

            List<Uri> selectedUris = Matisse.obtainResult(data);

            List<Map<String, Object>> assets = new ArrayList<>();
            for (int i = 0; i < selectedUris.size(); i++) {
                Uri uri = selectedUris.get(i);
                Map<String, Object> asset = new HashMap<>();

                String mimeType = FlutterPhotoPickerUtils.getMimeType(context, uri);
                String type = mimeType.split("/")[0];

                asset.put("selectedOrder", i + 1);
                asset.put("identifier", uri.toString());
                asset.put("type", type);
                asset.put("mimeType", mimeType);

                // Original Image
                String url = FlutterPhotoPickerUtils.getRealFilePath(context, uri);
                Point point;

                if ("video".equals(type)) {
                     point = FlutterPhotoPickerUtils.getVideoSize(context, uri);
                } else {
                     point = FlutterPhotoPickerUtils.getImageSize(context, uri);
                }

                asset.put("url", "file://" + url);
                asset.put("width", point.x);
                asset.put("height", point.y);

                // Thumbnail Image
                try {
                    int thumbnailMaxWidth = 320;
                    int thumbnailMaxHeight = 320;

                    if (arguments.containsKey("thumbnailMaxWidth"))
                        thumbnailMaxWidth = (int) arguments.get("thumbnailMaxWidth");
                    if (arguments.containsKey("thumbnailMaxHeight"))
                        thumbnailMaxHeight = (int) arguments.get("thumbnailMaxHeight");

                    File thumbnailFile = FlutterPhotoPickerUtils.createThumbnail(context, url, thumbnailMaxWidth, thumbnailMaxHeight, 100);
                    Point thumbnailPoint = FlutterPhotoPickerUtils.getImageSize(context, Uri.fromFile(thumbnailFile));

                    asset.put("thumbnailUrl", "file://" + thumbnailFile.getAbsolutePath());
                    asset.put("thumbnailWidth", thumbnailPoint.x);
                    asset.put("thumbnailHeight", thumbnailPoint.y);
                } catch (IOException e) {
                    break;
                }

                assets.add(asset);
            }

            if (this.result != null) {
                this.result.success(assets);
                this.result = null;
                this.arguments = null;
            }
        }
        return true;
    }
}
