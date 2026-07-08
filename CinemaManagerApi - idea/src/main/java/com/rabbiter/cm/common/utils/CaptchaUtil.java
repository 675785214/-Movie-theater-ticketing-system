package com.rabbiter.cm.common.utils;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Base64;
import java.util.Map;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

public class CaptchaUtil {

    private static final int WIDTH = 120;
    private static final int HEIGHT = 40;
    private static final int CODE_COUNT = 4;
    private static final int LINE_COUNT = 5;
    private static final long EXPIRE_TIME = 60 * 1000;

    private static final Map<String, CaptchaInfo> CAPTCHA_MAP = new ConcurrentHashMap<>();

    static {
        Thread cleanupThread = new Thread(() -> {
            while (true) {
                try {
                    Thread.sleep(60 * 1000);
                    long now = System.currentTimeMillis();
                    CAPTCHA_MAP.entrySet().removeIf(entry -> now > entry.getValue().expireTime);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        });
        cleanupThread.setDaemon(true);
        cleanupThread.start();
    }

    public static class CaptchaInfo {
        public String code;
        public long expireTime;

        public CaptchaInfo(String code, long expireTime) {
            this.code = code;
            this.expireTime = expireTime;
        }
    }

    public static Map<String, String> generate() {
        String code = generateCode();
        String key = UUID.randomUUID().toString().replace("-", "");
        long expireTime = System.currentTimeMillis() + EXPIRE_TIME;
        
        CAPTCHA_MAP.put(key, new CaptchaInfo(code, expireTime));
        
        String imageBase64 = generateImage(code);
        
        Map<String, String> result = new java.util.HashMap<>();
        result.put("captchaKey", key);
        result.put("captchaImage", imageBase64);
        
        return result;
    }

    public static boolean validate(String key, String inputCode) {
        if (key == null || inputCode == null) {
            return false;
        }
        
        CaptchaInfo info = CAPTCHA_MAP.get(key);
        if (info == null) {
            return false;
        }
        
        if (System.currentTimeMillis() > info.expireTime) {
            CAPTCHA_MAP.remove(key);
            return false;
        }
        
        boolean valid = info.code.equalsIgnoreCase(inputCode);
        CAPTCHA_MAP.remove(key);
        
        return valid;
    }

    private static String generateCode() {
        String chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjklmnpqrstuvwxyz23456789";
        StringBuilder sb = new StringBuilder();
        Random random = new Random();
        for (int i = 0; i < CODE_COUNT; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }

    private static String generateImage(String code) {
        BufferedImage image = new BufferedImage(WIDTH, HEIGHT, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();
        
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, WIDTH, HEIGHT);
        
        Random random = new Random();
        
        for (int i = 0; i < LINE_COUNT; i++) {
            int x1 = random.nextInt(WIDTH);
            int y1 = random.nextInt(HEIGHT);
            int x2 = random.nextInt(WIDTH);
            int y2 = random.nextInt(HEIGHT);
            g.setColor(new Color(random.nextInt(256), random.nextInt(256), random.nextInt(256)));
            g.drawLine(x1, y1, x2, y2);
        }
        
        for (int i = 0; i < 30; i++) {
            int x = random.nextInt(WIDTH);
            int y = random.nextInt(HEIGHT);
            g.setColor(new Color(random.nextInt(256), random.nextInt(256), random.nextInt(256)));
            g.drawOval(x, y, 1, 1);
        }
        
        Font font = new Font("Arial", Font.BOLD, 28);
        g.setFont(font);
        
        for (int i = 0; i < code.length(); i++) {
            char c = code.charAt(i);
            g.setColor(new Color(random.nextInt(100) + 50, random.nextInt(100) + 50, random.nextInt(100) + 50));
            g.drawString(String.valueOf(c), 25 + i * 22, 30);
        }
        
        g.dispose();
        
        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            ImageIO.write(image, "png", baos);
            return "data:image/png;base64," + Base64.getEncoder().encodeToString(baos.toByteArray());
        } catch (IOException e) {
            throw new RuntimeException("生成验证码图片失败", e);
        }
    }
}