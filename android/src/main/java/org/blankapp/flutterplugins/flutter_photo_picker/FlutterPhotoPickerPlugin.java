package org.blankapp.flutterplugins.flutter_photo_picker;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.graphics.Point;
import android.net.Uri;

import com.zhihu.matisse.Matisse;
import com.zhihu.matisse.MimeType;
import com.zhihu.matisse.engine.impl.GlideEngine;
import com.zhihu.matisse.internal.entity.CaptureStrategy;

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
public class FlutterPhotoPickerPlugin implements MethodCallHandler,
        PluginRegistry.ActivityResultListener {
    private static final int REQUEST_CODE_PHOTO_PICKER = 9191;

    private static final String CALL_METHOD_OPEN_PICKER = "openPicker";

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_photo_picker");
        final FlutterPhotoPickerPlugin instance = new FlutterPhotoPickerPlugin(registrar);

        registrar.addActivityResultListener(instance);
        registrar.addRequestPermissionsResultListener(instance.permissionManager);

        channel.setMethodCallHandler(instance);
    }

    private PermissionManager permissionManager;

    private Registrar registrar;

    private Result pendingResult;
    private Map<String, Object> pendingArguments;

    public FlutterPhotoPickerPlugin(Registrar registrar) {
        this.registrar = registrar;
        this.permissionManager = new PermissionManager(registrar.activity());
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (this.pendingResult != null) {
            finishWithAlreadyActiveError(result);
            return;
        }

        if (call.method.equals(CALL_METHOD_OPEN_PICKER)) {
            pendingResult = result;
            pendingArguments = (HashMap<String, Object>) call.arguments;

            permissionManager.askPermission(new String[]{
                    Manifest.permission.WRITE_EXTERNAL_STORAGE,
                    Manifest.permission.CAMERA,
            }, new PermissionManager.Callback() {
                @Override
                public void onGranted() {
                    openPicker();
                }

                @Override
                public void onDenied() {
                    finishWithError("permission_request_denied", "Permission request denied");
                }
            });
        } else {
            result.notImplemented();
        }
    }

    private void openPicker() {
        String mediaType = "any";
        boolean multiple = true;
        int limit = 9;
        int numberOfColumn = 3;

        if (pendingArguments.containsKey("mediaType"))
            mediaType = (String) pendingArguments.get("mediaType");
        if (pendingArguments.containsKey("multiple"))
            multiple = (boolean) pendingArguments.get("multiple");
        if (pendingArguments.containsKey("limit"))
            limit = (int) pendingArguments.get("limit");
        if (pendingArguments.containsKey("numberOfColumn"))
            numberOfColumn = (int) pendingArguments.get("numberOfColumn");

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
                .capture(!"video".equals(mediaType))
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
        if (pendingResult == null) return false;

        if (resultCode == RESULT_CANCELED) {
            finishWithError("cancelled", "Operation cancelled by user");
        } else if (resultCode == RESULT_OK) {
            Context context = registrar.activeContext();

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

                    if (pendingArguments.containsKey("thumbnailMaxWidth"))
                        thumbnailMaxWidth = (int) pendingArguments.get("thumbnailMaxWidth");
                    if (pendingArguments.containsKey("thumbnailMaxHeight"))
                        thumbnailMaxHeight = (int) pendingArguments.get("thumbnailMaxHeight");

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

            finishWithSuccess(assets);
        }
        return true;
    }

    private void finishWithSuccess(Object data) {
        if (pendingResult == null) {
            return;
        }
        pendingResult.success(data);
        pendingResult = null;
        pendingArguments = null;
    }

    private void finishWithAlreadyActiveError(MethodChannel.Result result) {
        result.error("already_active", "Photo picker is already active", null);
    }

    private void finishWithError(String errorCode, String errorMessage) {
        if (pendingResult == null) {
            return;
        }
        pendingResult.error(errorCode, errorMessage, null);
        pendingResult = null;
        pendingArguments = null;
    }
}
