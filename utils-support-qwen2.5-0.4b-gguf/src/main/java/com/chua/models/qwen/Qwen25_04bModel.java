package com.chua.models.qwen;

import com.chua.common.support.text.json.Json;
import lombok.Data;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * Qwen2.5-0.4B-Instruct-GGUF 模型信息
 */
@Data
public class Qwen25_04bModel {

    private static final String MODEL_PATH = "/models/model.json";
    private static Qwen25_04bModel INSTANCE;

    private String id;
    private String name;
    private String family;
    private String version;
    private String size;
    private String format;
    private String quantization;
    private String license;
    private String source;
    private Map<String, String> files;
    private int contextLength;
    private int embeddingLength;

    public static synchronized Qwen25_04bModel getInstance() {
        if (INSTANCE == null) {
            INSTANCE = loadModel();
        }
        return INSTANCE;
    }

    private static Qwen25_04bModel loadModel() {
        try (InputStream is = Qwen25_04bModel.class.getResourceAsStream(MODEL_PATH)) {
            if (is != null) {
                String json = new String(is.readAllBytes(), StandardCharsets.UTF_8);
                return Json.fromJson(json, Qwen25_04bModel.class);
            }
        } catch (Exception e) {
            // 忽略，使用默认模型
        }
        Qwen25_04bModel model = new Qwen25_04bModel();
        model.setId("Qwen2.5-0.4B-Instruct-GGUF");
        model.setFamily("qwen");
        model.setSize("0.4B");
        model.setFormat("GGUF");
        return model;
    }

    public String getModelFileName() {
        return files != null ? files.get("model") : null;
    }
}
