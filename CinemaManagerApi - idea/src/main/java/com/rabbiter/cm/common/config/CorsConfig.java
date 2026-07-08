package com.rabbiter.cm.common.config;

import com.rabbiter.cm.common.utils.PathUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.Collections;

@Configuration
public class CorsConfig implements WebMvcConfigurer {

    @Value("${app.upload-path:#{null}}")
    private String uploadPath;

    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(Collections.singletonList("*"));
        config.addAllowedMethod("*");
        config.addAllowedHeader("*");
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);

        return new CorsFilter(source);
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String path;
        if (StringUtils.hasText(uploadPath)) {
            path = uploadPath + "/images/";
        } else {
            path = PathUtils.getClassLoadRootPath() + "/images/";
        }

        //第一个方法设置访问路径前缀，第二个方法设置资源路径
        registry.addResourceHandler("/images/**").
                addResourceLocations("file:" + path);
        WebMvcConfigurer.super.addResourceHandlers(registry);
    }
}
