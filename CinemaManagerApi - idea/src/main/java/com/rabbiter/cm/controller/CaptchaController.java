package com.rabbiter.cm.controller;

import com.rabbiter.cm.common.response.ResponseResult;
import com.rabbiter.cm.common.utils.CaptchaUtil;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class CaptchaController extends BaseController {

    @GetMapping("/captcha")
    public ResponseResult getCaptcha() {
        Map<String, String> captcha = CaptchaUtil.generate();
        return getResult(captcha);
    }
}