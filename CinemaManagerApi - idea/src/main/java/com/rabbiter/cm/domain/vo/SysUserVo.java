package com.rabbiter.cm.domain.vo;

import java.io.Serializable;

/**
 * 封装用户登录输入的信息
 */
public class SysUserVo implements Serializable {

    private String userName;

    private String password;

    private String captchaKey;

    private String captchaCode;

    public SysUserVo() {
    }

    public SysUserVo(String userName, String password) {
        this.userName = userName;
        this.password = password;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getCaptchaKey() {
        return captchaKey;
    }

    public void setCaptchaKey(String captchaKey) {
        this.captchaKey = captchaKey;
    }

    public String getCaptchaCode() {
        return captchaCode;
    }

    public void setCaptchaCode(String captchaCode) {
        this.captchaCode = captchaCode;
    }

    @Override
    public String toString() {
        return "SysUserVo{" +
                "userName='" + userName + '\'' +
                ", password='" + password + '\'' +
                ", captchaKey='" + captchaKey + '\'' +
                ", captchaCode='" + captchaCode + '\'' +
                '}';
    }
}
