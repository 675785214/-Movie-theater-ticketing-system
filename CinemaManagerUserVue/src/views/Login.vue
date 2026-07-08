<template>
    <div class="login_container">
        <div class="login_box">
            <div class="title_box">
                <p>
                    <i class="iconfont icon-r-team" style="font-size: 36px">
                    </i>
                    登录影院用户端
                </p>
            </div>
            <!-- 登录表单区域 -->
            <el-form
                class="login_form"
                :model="loginForm"
                :rules="loginFormRules"
                ref="loginFormRef"
            >
                <!-- 用户名 -->
                <el-form-item prop="userName">
                    <el-row>
                        <el-col :span="2">
                            <i
                                class="iconfont icon-r-user1"
                                style="font-size: 28px; color: grey"
                            ></i>
                        </el-col>
                        <el-col :span="22">
                            <el-input
                                v-model="loginForm.userName"
                                placeholder="请输入用户名"
                                clearable
                            ></el-input>
                        </el-col>
                    </el-row>
                </el-form-item>
                <!-- 密码 -->
                <el-form-item prop="password">
                    <el-row>
                        <el-col :span="2">
                            <i
                                class="iconfont icon-r-lock"
                                style="font-size: 28px; color: grey"
                            ></i>
                        </el-col>
                        <el-col :span="22">
                            <el-input
                                v-model="loginForm.password"
                                type="password"
                                placeholder="请输入密码"
                                show-password
                            ></el-input>
                        </el-col>
                    </el-row>
                </el-form-item>
                <!-- 验证码 -->
                <el-form-item prop="captchaCode">
                    <el-row>
                        <el-col :span="2">
                            <i
                                class="iconfont icon-r-lock"
                                style="font-size: 28px; color: grey"
                            ></i>
                        </el-col>
                        <el-col :span="14">
                            <el-input
                                v-model="loginForm.captchaCode"
                                placeholder="请输入验证码"
                                clearable
                            ></el-input>
                        </el-col>
                        <el-col :span="8">
                            <img
                                :src="captchaImage"
                                @click="refreshCaptcha"
                                class="captcha-img"
                                alt="验证码"
                            />
                        </el-col>
                    </el-row>
                </el-form-item>
                <!-- 按扭区域 -->
                <el-form-item class="btns">
                    <el-button :round="true" type="primary" @click="login" style="font-size: 20px">
                        <i
                            class="iconfont icon-r-yes"
                            style="font-size: 24px"
                        ></i>
                        登录</el-button
                    >
                    <el-button
                         style="font-size: 20px"
                        :round="true"
                        type="info"
                        @click="registerAccount"
                    >
                      <i
                            class="iconfont icon-r-add"
                            style="font-size: 24px"
                        ></i>
                        注册新用户</el-button
                    >
                </el-form-item>
            </el-form>
        </div>
    </div>
</template>

<script>
export default {
    name: "Login",
    data() {
        return {
            loginForm: {
                userName: "",
                password: "",
                captchaKey: "",
                captchaCode: "",
            },
            captchaImage: "",
            loginFormRules: {
                userName: [
                    {
                        required: true,
                        message: "请输入用户名称",
                        trigger: "blur",
                    },
                    {
                        min: 2,
                        max: 20,
                        message: "用户名称长度在2到20个字符之间",
                        trigger: "blur",
                    },
                ],
                password: [
                    { required: true, message: "请输入密码", trigger: "blur" },
                    {
                        min: 6,
                        max: 16,
                        message: "登录密码长度在6到16个字符之间",
                        trigger: "blur",
                    },
                ],
                captchaCode: [
                    { required: true, message: "请输入验证码", trigger: "blur" },
                    {
                        min: 4,
                        max: 4,
                        message: "验证码长度为4个字符",
                        trigger: "blur",
                    },
                ],
            },
            sessionId: 0,
        };
    },
    created() {
        this.sessionId = window.sessionStorage.getItem("sessionId");
        console.log("this sessionId is : " + this.sessionId);
        window.sessionStorage.setItem("sessionId", 0);
        this.refreshCaptcha();
    },
    methods: {
        success(params) {
            this.login();
        },
        async refreshCaptcha() {
            const resData = await axios.get("captcha");
            if (resData && resData.data && resData.data.code === 200) {
                this.loginForm.captchaKey = resData.data.data.captchaKey;
                this.captchaImage = resData.data.data.captchaImage;
            }
        },
        login() {
            this.$refs.loginFormRef.validate(async (valid) => {
                if (!valid) return;
                axios.defaults.headers.post["Content-Type"] =
                    "application/json";
                try {
                    const { data: res } = await axios.post(
                        "sysUser/login",
                        JSON.stringify(this.loginForm)
                    );
                    if (res.code !== 200) {
                        this.refreshCaptcha();
                        return this.$message.error(res.msg);
                    }

                    this.$message.success({ message: "登录成功", duration: 1000 });
                    console.log(res.data);
                    window.sessionStorage.setItem("token", res.data.token);
                    res.data.sysUser.sysRole = null;
                    window.sessionStorage.setItem(
                        "loginUser",
                        JSON.stringify(res.data.sysUser)
                    );
                    if (
                        this.sessionId !== 0 &&
                        this.sessionId !== "0" &&
                        this.sessionId !== null
                    ) {
                        this.$router.push("/chooseSeat/" + this.sessionId);
                        return;
                    }
                    this.$router.push("/welcome");
                } catch (e) {
                    this.refreshCaptcha();
                    console.log(e);
                    if (e.response && e.response.data) {
                        this.$message.error(e.response.data);
                    } else {
                        this.$message.error("网络错误");
                    }
                }
            });
        },
        registerAccount() {
            this.$router.push("/register");
        },
    },
};
</script>

<style scoped>
.login_container {
    background: url("../assets/login-background.jpg");
    background-size: cover;
    height: 100%;
}

.login_box {
    width: 450px;
    height: 380px;
    background-color: #fff;
    border-radius: 3px;
    position: absolute;
    left: 50%;
    top: 50%;
    transform: translate(-50%, -50%);
    border: 1px solid grey;
}

.avatar_box {
    height: 130px;
    width: 130px;
    border: 1px solid #eee;
    border-radius: 50%;
    padding: 10px;
    box-shadow: 0 0 10px #ddd;
    position: absolute;
    left: 50%;
    transform: translate(-50%, -50%);
    background-color: #fff;
}

.avatar_box > img {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    background-color: #eee;
}

.title_box {
    text-align: center;
    font-size: 180%;
}

.login_form {
    position: absolute;
    bottom: 0;
    width: 100%;
    padding: 0 20px;
    box-sizing: border-box;
}

.btns {
    display: flex;
    justify-content: center;
}

.captcha-img {
    width: 100%;
    height: 38px;
    cursor: pointer;
    border-radius: 4px;
}
</style>
