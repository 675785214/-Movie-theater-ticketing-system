# 电影院售票系统

基于 Spring Boot + Vue 2 + Element UI 的电影院在线售票系统。

## 项目结构

```
├── CinemaManagerApi - idea/      # 后端 API（Spring Boot 2.4.0 + MyBatis + Shiro + JWT）
├── CinemaManagerAdminVue/        # 管理端前端（Vue 2 + Element UI）
├── CinemaManagerUserVue/         # 用户端前端（Vue 2 + Element UI）
├── docker-compose.yml            # Docker 编排配置
├── Dockerfile.backend            # 后端 Docker 镜像
├── Dockerfile.admin              # 管理端 Docker 镜像
├── Dockerfile.user               # 用户端 Docker 镜像
├── nginx/                        # Nginx 配置文件
└── .env.example                  # 环境变量模板
```

## 快速开始（推荐：Docker 一键部署）

### 前置条件

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) 20.x+
- （国内用户建议配置 [Docker 镜像加速器](https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors)）

### 启动步骤

```bash
# 1. 克隆项目
git clone <your-repo-url>
cd Movie\ theater\ ticketing\ system

# 2. 创建环境变量文件
cp .env.example .env

# 3. 编辑 .env，设置你的数据库密码
#    Windows: notepad .env
#    Mac/Linux: vim .env
#    必填项：MYSQL_ROOT_PASSWORD=你的密码

# 4. 一键启动所有服务
docker-compose up -d --build
```

> 首次启动会下载 Docker 镜像并编译项目，可能需要 5-10 分钟，后续启动会很快。

### 访问地址

| 服务 | 地址 | 说明 |
|------|------|------|
| 管理端 | http://localhost:9233 | 管理员登录（admin / 123456） |
| 用户端 | http://localhost:9232 | 用户浏览购票 |
| 后端 API | http://localhost:9231 | REST API 接口 |

### 停止服务

```bash
docker-compose down          # 停止所有服务（保留数据卷）
docker-compose down -v       # 停止并删除数据卷（清空数据库）
```

---

## 本地开发模式（不使用 Docker）

如果你需要在本地直接运行项目进行开发调试：

### 后端

```bash
cd "CinemaManagerApi - idea"

# 使用 Maven Wrapper（无需安装 Maven）
./mvnw spring-boot:run        # Mac/Linux/Git Bash
mvnw.cmd spring-boot:run      # Windows CMD/PowerShell

# 或者使用系统 Maven
mvn spring-boot:run
```

### 前端

```bash
# 管理端（端口 9233）
cd CinemaManagerAdminVue
yarn install
yarn dev

# 用户端（端口 9232）
cd CinemaManagerUserVue
yarn install
yarn dev
```

> 开发模式下 vue.config.js 已配置代理，前端请求会自动转发到 http://127.0.0.1:9231 的后端。

### 本地数据库

本地开发需要在 MySQL 中创建 `cinema_manager` 数据库，Flyway 会在应用启动时自动执行数据库迁移脚本。

`application.yml` 中的默认数据库配置：
- 地址：`localhost:3306`
- 用户名：`root`
- 密码：`675785214`

---

## 环境变量说明

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `MYSQL_ROOT_PASSWORD` | 必填 | MySQL root 密码 |
| `MYSQL_DATABASE` | `cinema_manager` | 数据库名 |
| `MYSQL_PORT` | `3306` | 数据库端口 |
| `BACKEND_PORT` | `9231` | 后端 API 端口 |
| `ADMIN_PORT` | `9233` | 管理端端口 |
| `USER_PORT` | `9232` | 用户端端口 |

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 后端框架 | Spring Boot 2.4.0 |
| ORM | MyBatis + PageHelper |
| 安全认证 | Apache Shiro + JWT |
| 数据库连接池 | Alibaba Druid |
| 数据库迁移 | Flyway |
| 定时任务 | Quartz |
| 数据库 | MySQL 5.7 |
| 前端框架 | Vue 2.6 + Vue Router + Vuex |
| UI 组件库 | Element UI |
| 图表 | ECharts 5 |
| 构建工具 | Maven + Yarn |
| 容器化 | Docker + Docker Compose |

## 常见问题

### 端口冲突

修改 `.env` 文件中的端口配置即可：

```bash
BACKEND_PORT=9231
ADMIN_PORT=9233
USER_PORT=9232
```

### Docker 镜像下载慢

配置 Docker 镜像加速器（阿里云/腾讯云/中科大），然后重启 Docker Desktop。

### 后端启动失败（MySQL 连接错误）

首次启动时 MySQL 需要初始化，后端可能会在 MySQL 就绪前尝试连接。Docker Compose 配置了 `restart: unless-stopped`，后端会自动重启直到连接成功。等待 1-2 分钟即可。

### Windows Git Bash 换行符问题

`mvnw` 脚本在 Windows 克隆后可能换行符不对，使用 `mvnw.cmd` 代替，或者在 Git 中配置 `core.autocrlf=input`。
