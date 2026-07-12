package com.chua.models.onnx.whisper;

import com.chua.deeplearning.support.core.download.ModelDownloadProvider;
import com.chua.deeplearning.support.core.download.ModelDownloadRequest;
import com.chua.deeplearning.support.core.download.ModelDownloadResult;
import com.chua.deeplearning.support.utils.ModelManagementUtil;
import com.chua.common.support.core.annotation.Spi;
import com.chua.common.support.io.download.DownloadFile;
import lombok.extern.slf4j.Slf4j;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

/**
 * Whisper ASR ONNX 模型下载提供者。
 * <p>
 * 通过 SPI 机制注册 {@link ModelDownloadProvider}，当此 jar 在 classpath 上时，
 * 自动提供 Xenova/whisper-tiny 模型的下载能力。
 * </p>
 *
 * @author CH
 */
@Slf4j
@Spi("whisper")
public class WhisperModelDownloadProvider implements ModelDownloadProvider {

    private static final String HF_ENDPOINT = System.getenv().getOrDefault("HF_ENDPOINT", "https://hf-mirror.com").replaceAll("/+$", "");
    private static final Map<String, DownloadManifest> MANIFESTS = createManifests();

    @Override
    public boolean supports(ModelDownloadRequest request) {
        return resolveManifest(request) != null;
    }

    @Override
    public ModelDownloadResult download(ModelDownloadRequest request) {
        DownloadManifest manifest = resolveManifest(request);
        if (manifest == null) {
            return ModelDownloadResult.failure("Whisper 下载提供者不支持该模型");
        }

        Path modelRoot = ModelManagementUtil.preferredModelRoot(request.getBasePath());
        List<String> preparedPaths = new ArrayList<>();
        try {
            for (DownloadAsset asset : manifest.assets()) {
                Path target = modelRoot.resolve(asset.relativePath()).normalize();
                if (Files.exists(target)) {
                    preparedPaths.add(target.toString());
                    continue;
                }

                boolean downloaded = false;
                for (String url : asset.urls()) {
                    try {
                        Files.createDirectories(target.getParent());
                        DownloadFile downloadFile = ModelManagementUtil.downloadModel(url, target.getParent().toString());
                        if (downloadFile != null && downloadFile.exists()) {
                            Path downloadedPath = downloadFile.asFile().toPath();
                            if (!downloadedPath.normalize().equals(target)) {
                                Files.move(downloadedPath, target, StandardCopyOption.REPLACE_EXISTING);
                            }
                            downloaded = true;
                            break;
                        }
                    } catch (Exception e) {
                        log.trace("[WhisperModel] 下载失败 {}: {}", url, e.getMessage());
                    }
                }

                if (!downloaded) {
                    if (asset.optional()) continue;
                    return ModelDownloadResult.failure("下载失败: " + asset.relativePath());
                }
                preparedPaths.add(target.toString());
            }

            Path primary = modelRoot.resolve(manifest.primaryRelativePath()).normalize();
            if (!Files.exists(primary)) {
                return ModelDownloadResult.failure("主模型文件不存在: " + primary);
            }
            return ModelDownloadResult.success(primary.toString(), preparedPaths);
        } catch (Exception e) {
            log.warn("[WhisperModel] 处理 {} 失败", request.getModelName(), e);
            return ModelDownloadResult.failure("Whisper 模型下载失败: " + e.getMessage());
        }
    }

    private DownloadManifest resolveManifest(ModelDownloadRequest request) {
        if (request == null) return null;
        DownloadManifest byName = MANIFESTS.get(normalizeKey(request.getModelName()));
        if (byName != null) return byName;
        return MANIFESTS.get(normalizeKey(request.getModelRelativePath()));
    }

    private static String hf(String repo, String relativePath) {
        return HF_ENDPOINT + "/" + repo + "/resolve/main/" + relativePath;
    }

    private static String normalizeKey(String value) {
        if (value == null || value.isBlank()) return "";
        return value.trim()
                .replace('\\', '/')
                .replaceAll("/+", "/")
                .toLowerCase();
    }

    private static Map<String, DownloadManifest> createManifests() {
        Map<String, DownloadManifest> manifests = new LinkedHashMap<>();

        register(manifests,
                manifest("audio/asr/whisper-tiny/onnx/encoder_model_quantized.onnx",
                        asset("audio/asr/whisper-tiny/onnx/encoder_model_quantized.onnx",
                                hf("Xenova/whisper-tiny", "onnx/encoder_model_quantized.onnx")),
                        asset("audio/asr/whisper-tiny/onnx/decoder_model_merged_quantized.onnx",
                                hf("Xenova/whisper-tiny", "onnx/decoder_model_merged_quantized.onnx")),
                        asset("audio/asr/whisper-tiny/vocab.json",
                                hf("Xenova/whisper-tiny", "vocab.json")),
                        asset("audio/asr/whisper-tiny/mel_80_filters.json",
                                hf("Xenova/whisper-tiny", "mel_80_filters.json")),
                        optional("audio/asr/whisper-tiny/byte_decoder.json",
                                hf("Xenova/whisper-tiny", "byte_decoder.json")),
                        optional("audio/asr/whisper-tiny/config.json",
                                hf("Xenova/whisper-tiny", "config.json")),
                        optional("audio/asr/whisper-tiny/tokenizer_config.json",
                                hf("Xenova/whisper-tiny", "tokenizer_config.json"))
                ),
                "whisper-tiny",
                "whisper",
                "whisper-tiny-onnx",
                "audio/asr/whisper-tiny/onnx/encoder_model_quantized.onnx");

        return manifests;
    }

    private static DownloadManifest manifest(String primaryRelativePath, DownloadAsset... assets) {
        return new DownloadManifest(primaryRelativePath, List.of(assets));
    }

    private static DownloadAsset asset(String relativePath, String... urls) {
        return new DownloadAsset(relativePath, List.of(urls), false);
    }

    private static DownloadAsset optional(String relativePath, String... urls) {
        return new DownloadAsset(relativePath, List.of(urls), true);
    }

    private static void register(Map<String, DownloadManifest> manifests, DownloadManifest manifest, String... aliases) {
        LinkedHashSet<String> keys = new LinkedHashSet<>();
        for (String alias : aliases) {
            keys.add(normalizeKey(alias));
        }
        keys.add(normalizeKey(manifest.primaryRelativePath()));
        for (String key : keys) {
            manifests.put(key, manifest);
        }
    }

    private record DownloadManifest(String primaryRelativePath, List<DownloadAsset> assets) {}

    private record DownloadAsset(String relativePath, List<String> urls, boolean optional) {}
}
