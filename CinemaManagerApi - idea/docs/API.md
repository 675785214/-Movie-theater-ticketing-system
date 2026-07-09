# CinemaManagerApi 接口文档

> 电影院管理系统后端 API 文档  
> 版本：0.0.1-SNAPSHOT  
> 最后更新：2026-07-09

---

## 目录

- [1. 概述](#1-概述)
- [2. 通用规范](#2-通用规范)
- [3. 认证与安全](#3-认证与安全)
- [4. 错误码说明](#4-错误码说明)
- [5. 数据模型](#5-数据模型)
- [6. API 端点详细说明](#6-api-端点详细说明)
  - [6.1 验证码模块](#61-验证码模块)
  - [6.2 文件上传模块](#62-文件上传模块)
  - [6.3 用户管理模块](#63-用户管理模块)
  - [6.4 角色管理模块](#64-角色管理模块)
  - [6.5 菜单资源模块](#65-菜单资源模块)
  - [6.6 影院管理模块](#66-影院管理模块)
  - [6.7 影厅管理模块](#67-影厅管理模块)
  - [6.8 电影管理模块](#68-电影管理模块)
  - [6.9 电影分类模块](#69-电影分类模块)
  - [6.10 场次管理模块](#610-场次管理模块)
  - [6.11 订单模块](#611-订单模块)
- [附录](#附录)

---

## 1. 概述

### 1.1 项目简介

CinemaManagerApi 是电影院管理系统的后端 RESTful API 服务，提供影院、影厅、电影、场次、订单、用户、角色、菜单权限的完整管理能力。

### 1.2 技术栈

| 技术 | 说明 |
|------|------|
| Spring Boot 2.4.0 | 核心框架 |
| MyBatis 2.1.3 | ORM 框架 |
| Apache Shiro 1.5.3 | 安全认证框架 |
| auth0 java-jwt 3.4.0 | JWT 令牌管理 |
| PageHelper 1.3.0 | MyBatis 分页插件 |
| Alibaba Druid 1.2.2 | 数据库连接池 |
| Flyway | 数据库迁移管理 |
| Quartz | 定时任务调度 |
| MySQL | 关系型数据库 |

### 1.3 基础信息

| 项目 | 值 |
|------|-----|
| 服务端口 | `9231` |
| 字符编码 | `UTF-8` |
| 请求格式 | `application/json`（文件上传使用 `multipart/form-data`） |
| 响应格式 | `application/json` |
| 时间格式 | `yyyy-MM-dd HH:mm:ss`（日期时间）、`HH:mm`（时间）、`yyyy-MM-dd`（日期） |
| 时区 | `GMT+8` |

---

## 2. 通用规范

### 2.1 基础 URL

```
http://{host}:9231
```

开发环境默认：`http://localhost:9231`

### 2.2 统一响应格式

所有接口统一返回 `ResponseResult`（继承自 `HashMap`），Json 结构如下：

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {}
}
```

根据返回数据类型，响应分为三种结构：

**（1）分页列表响应** — 当返回分页数据时：

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [ ... ],
  "pageNum": 1,
  "pageSize": 1000,
  "total": 50
}
```

**（2）单对象响应** — 当返回单个对象时：

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": { ... }
}
```

**（3）操作结果响应** — 当只返回操作是否成功时：

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

### 2.3 分页参数

所有支持分页的查询接口（GET 请求），通过 Query String 传递以下参数：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `pageNum` | Integer | 否 | 1 | 当前页码 |
| `pageSize` | Integer | 否 | 1000 | 每页记录数 |
| `orderByColumn` | String | 否 | - | 排序字段 |
| `isAsc` | String | 否 | - | 排序方向，`asc` 或 `desc` |

> **注意：** 这些参数不会出现在 Controller 方法签名中，而是由 `PageBuilder` 从 `HttpServletRequest` 中提取。

### 2.4 请求头

| Header | 值 | 说明 |
|--------|-----|------|
| `Content-Type` | `application/json` | JSON 请求体 |
| `Content-Type` | `multipart/form-data` | 文件上传 |
| `Token` | `<jwt_token>` | 认证令牌（需认证的接口必传） |

### 2.5 HTTP 方法约定

| 方法 | 用途 |
|------|------|
| `GET` | 查询资源 |
| `POST` | 新增资源、批量删除（部分接口）、关联操作 |
| `PUT` | 更新资源、支付、取消订单 |
| `DELETE` | 删除资源（支持批量，ID 逗号分隔） |

---

## 3. 认证与安全

### 3.1 认证机制概述

系统采用 **Apache Shiro + JWT** 的无状态认证方案：

1. 禁用 Shiro 自带的 Session，每次请求通过 JWT Token 独立验证
2. 请求到达后，`JwtFilter` 从 HTTP Header `Token` 中提取 JWT 字符串
3. 将 JWT 包装为 `JwtToken` 交给 `CustomerRealm` 完成身份认证
4. `CustomerRealm` 解码 Token 中的用户名，从数据库查找用户，使用用户密码作为 HMAC256 密钥验证签名

### 3.2 登录流程

```
1. GET  /captcha              → 获取验证码（返回 key + base64 图片）
2. POST /sysUser/login        → 提交用户名、密码、验证码，获取 Token
```

**步骤说明：**
1. 调用验证码接口，获取 `captchaKey` 和 base64 编码的验证码图片
2. 用户识别验证码后，将 `userName`、`password`、`captchaKey`、`captchaCode` 提交到登录接口
3. 服务端校验验证码 → 校验用户名密码 → 签发 JWT Token
4. 登录成功返回 `LoginUser` 对象，其中包含用户信息、管理影院信息、Token

### 3.3 Token 使用方式

- 所有需要认证的接口，在 HTTP Header 中携带：`Token: <jwt_token>`
- Token 有效期：**60 分钟**
- 目前无 Refresh Token 机制，过期后需重新登录
- Token 签名算法：HMAC256，密钥为用户密码

### 3.4 公开接口清单

以下接口无需携带 Token，可直接访问：

| 路径 | 方法 | 说明 |
|------|------|------|
| `/sysUser/register` | POST | 用户注册 |
| `/sysUser/login` | ALL | 用户登录 |
| `/captcha` | GET | 获取验证码 |
| `/images/**` | ALL | 静态图片资源 |
| `/sysCinema/**` | ALL | 影院查询（除 `/sysCinema/update`） |
| `/sysMovie/find/**` | ALL | 电影查询 |
| `/sysMovieCategory/find/**` | ALL | 电影分类查询 |
| `/sysSession/find/**` | ALL | 场次查询 |

> **例外：** `/sysCinema/update` 虽然匹配 `/sysCinema/**`，但在 Shiro 配置中该路径单独配置为 `jwt` 过滤器，因此需要认证。

### 3.5 权限矩阵

| 模块 | 查询类 | 新增/修改/删除类 |
|------|--------|-----------------|
| 验证码 | 公开 | - |
| 文件上传 | - | 需JWT |
| 用户管理 | 需JWT | 需JWT |
| 登录/注册 | 公开 | 公开 |
| 角色管理 | 需JWT | 需JWT |
| 菜单资源 | 需JWT | 需JWT |
| 影院管理 | 公开 | 需JWT |
| 影厅管理 | 需JWT | 需JWT |
| 电影管理 | 公开 | 需JWT |
| 电影分类 | 公开 | 需JWT |
| 场次管理 | 公开 | 需JWT |
| 订单管理 | 需JWT | 需JWT |

---

## 4. 错误码说明

### 4.1 业务状态码

| 状态码 | 常量 | 说明 |
|--------|------|------|
| `200` | `SUCCESS` | 操作成功 |
| `400` | `BAD_REQUEST` | 请求参数错误 |
| `403` | `FORBIDDEN` | 访问受限，授权过期 |
| `404` | `NOT_FOUND` | 资源或服务未找到 |
| `500` | `ERROR` | 系统内部错误 |

### 4.2 全局异常处理

当系统发生未捕获的异常时，`GlobalExceptionHandler` 会捕获并返回 HTTP 500 响应。根据异常信息的不同，返回特定的错误提示：

| 异常特征 | 返回消息 | HTTP 状态码 | 含义 |
|----------|----------|-------------|------|
| `(using password: YES)` + 非 root@localhost | `PU Request failed with status code 500` | 500 | 远程数据库密码错误 |
| `(using password: YES)` + root@localhost | `P Request failed with status code 500` | 500 | 本地数据库密码错误 |
| `Unknown database` | `U Request failed with status code 500` | 500 | 数据库不存在 |
| `edis`（Redis） | `R Request failed with status code 500` | 500 | Redis 连接失败 |
| `Failed to obtain JDBC Connection` | `C Request failed with status code 500` | 500 | JDBC 连接失败 |
| `SQLSyntaxErrorException` | `S Request failed with status code 500` | 500 | SQL 语法错误 |

### 4.3 常见错误场景

| 场景 | 响应 |
|------|------|
| Token 过期或无效 | Shiro 抛出 `AuthenticationException`，返回认证失败 |
| 用户名或密码错误 | `{"code": 500, "msg": "操作失败"}` |
| 验证码错误 | `{"code": 500, "msg": "操作失败"}` |
| 参数校验失败 | Spring 返回 400 及校验错误信息 |
| 用户名已存在 | `{"code": 500, "msg": "操作失败"}` |
| 资源不存在 | `{"code": 500, "msg": "操作失败"}` |

---

## 5. 数据模型

### 5.1 SysUser（用户）

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|----------|------|
| `userId` | Long | - | - | 用户 ID |
| `userName` | String | 是 | `@NotBlank` | 用户名 |
| `password` | String | 是 | `@NotBlank` | 密码（MD5 + 8 位随机盐 + 1024 次哈希存储） |
| `salt` | String | - | - | 密码盐值 |
| `email` | String | 否 | `@Email` | 邮箱 |
| `phoneNumber` | String | 否 | `@Pattern("^1[3\|4\|5\|7\|8]\\d{9}$")` | 手机号 |
| `sex` | Boolean | 否 | - | 性别（`true`=男，`false`=女） |
| `userPicture` | String | 否 | - | 用户头像文件名 |
| `roleId` | Long | 否 | - | 角色 ID（用户与角色一对一） |
| `birthday` | String | 否 | - | 生日 |
| `autograph` | String | 否 | - | 个性签名 |
| `sysRole` | SysRole | 否 | - | 关联角色对象（多表连接） |

**JSON 示例：**

```json
{
  "userId": 1,
  "userName": "admin",
  "password": null,
  "salt": null,
  "email": "admin@cinema.com",
  "phoneNumber": "13800138000",
  "sex": true,
  "userPicture": "avatar_admin.jpg",
  "roleId": 1,
  "birthday": "1990-01-01",
  "autograph": "管理员",
  "sysRole": { "roleId": 1, "roleName": "系统管理员", "roleDesc": "拥有所有权限" }
}
```

> **注意：** 响应中的 `password` 和 `salt` 字段通常不返回（由 SQL 映射控制），此处展示仅为模型完整性。

### 5.2 SysRole（角色）

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|----------|------|
| `roleId` | Long | - | - | 角色 ID |
| `roleName` | String | 是 | `@NotBlank` | 角色名称 |
| `roleDesc` | String | 是 | `@NotBlank` | 角色描述 |
| `children` | List\<SysResource\> | 否 | - | 角色拥有的权限列表 |

**JSON 示例：**

```json
{
  "roleId": 1,
  "roleName": "系统管理员",
  "roleDesc": "拥有所有权限",
  "children": [
    { "id": 1, "name": "影院管理", "path": "/cinema", "level": 1, "parentId": 0 }
  ]
}
```

### 5.3 SysResource（菜单资源）

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|----------|------|
| `id` | Long | - | - | 资源 ID |
| `name` | String | 是 | `@NotBlank` | 菜单名称 |
| `path` | String | 否 | - | 路由路径 |
| `level` | Integer | 否 | - | 菜单层级 |
| `parentId` | Long | 否 | - | 父菜单 ID |
| `parent` | SysResource | 否 | - | 父菜单对象 |
| `children` | List\<SysResource\> | 否 | - | 子菜单列表（树形结构） |

**JSON 示例：**

```json
{
  "id": 1,
  "name": "影院管理",
  "path": "/cinema",
  "level": 1,
  "parentId": 0,
  "parent": null,
  "children": [
    {
      "id": 2,
      "name": "影厅管理",
      "path": "/cinema/hall",
      "level": 2,
      "parentId": 1,
      "parent": null,
      "children": []
    }
  ]
}
```

### 5.4 SysCinema（影院）

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|----------|------|
| `cinemaId` | Long | - | - | 影院 ID |
| `cinemaName` | String | 是 | `@NotBlank` | 影院名称 |
| `hallCategoryList` | String | 否 | - | 影厅类别列表（JSON 字符串） |
| `cinemaPicture` | String | 否 | - | 影院图片文件名 |
| `cinemaAddress` | String | 否 | - | 影院地址 |
| `cinemaPhone` | String | 否 | - | 影院电话 |
| `workStartTime` | LocalTime | 否 | - | 营业开始时间，格式 `HH:mm` |
| `workEndTime` | LocalTime | 否 | - | 营业结束时间，格式 `HH:mm` |
| `sysMovieList` | List\<SysMovie\> | 否 | - | 上映电影列表（含未来 5 天有场次的影片） |

**JSON 示例：**

```json
{
  "cinemaId": 1,
  "cinemaName": "万象影城",
  "hallCategoryList": "[\"IMAX\",\"4K激光\",\"普通厅\"]",
  "cinemaPicture": "cinema_1.jpg",
  "cinemaAddress": "市中心商业广场5楼",
  "cinemaPhone": "010-12345678",
  "workStartTime": "09:00",
  "workEndTime": "23:59",
  "sysMovieList": []
}
```

### 5.5 SysHall（影厅）

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|----------|------|
| `cinemaId` | Long | - | - | 所属影院 ID |
| `hallId` | Long | - | - | 影厅 ID |
| `hallName` | String | 是 | `@NotBlank` | 影厅名称 |
| `hallCategory` | String | 否 | - | 影厅类别（如 IMAX） |
| `rowStart` | String | 否 | - | 排号起始值，如 `"1"`（数字）或 `"A"`（字母） |
| `rowNums` | Integer | 是 | `@Min(3)` `@Max(50)` | 排数（3~50） |
| `seatNumsRow` | Integer | 是 | `@Min(3)` `@Max(50)` | 每排座位数（3~50） |
| `seatNums` | Integer | 是 | `@Min(9)` `@Max(2500)` | 总可用座位数 |
| `seatState` | String | 否 | - | 座位状态 JSON。`0`=可用，`2`=禁用（`1`=售出在场次中统计） |
| `delState` | Boolean | 否 | - | 删除状态 |
| `sysCinema` | SysCinema | 否 | - | 关联影院对象 |

**JSON 示例：**

```json
{
  "cinemaId": 1,
  "hallId": 1,
  "hallName": "1号IMAX厅",
  "hallCategory": "IMAX",
  "rowStart": "1",
  "rowNums": 10,
  "seatNumsRow": 20,
  "seatNums": 200,
  "seatState": "[[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],...]",
  "delState": false,
  "sysCinema": null
}
```

**座位状态说明：** `seatState` 为 JSON 二维数组，外层数组代表排，内层数组代表该排的各座位。座位值：`0`=可用，`2`=禁用。购票售出的座位（`1`）在场次层面的 `sessionSeats` 中记录。

### 5.6 SysMovie（电影）

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|----------|------|
| `movieId` | Long | - | - | 电影 ID |
| `movieName` | String | 是 | `@NotBlank` | 电影名称 |
| `movieLength` | Integer | 否 | - | 电影时长（分钟） |
| `moviePoster` | String | 否 | - | 电影海报文件名 |
| `movieArea` | String | 否 | - | 制片地区 |
| `releaseDate` | Date | 否 | - | 上映日期 |
| `movieBoxOffice` | Double | 否 | - | 电影票房 |
| `movieIntroduction` | String | 否 | - | 电影简介 |
| `moviePictures` | String | 否 | - | 电影图集（多个图片文件名） |
| `movieCategoryList` | List\<SysMovieCategory\> | 否 | - | 电影分类列表 |

**JSON 示例：**

```json
{
  "movieId": 1,
  "movieName": "流浪地球",
  "movieLength": 125,
  "moviePoster": "poster_1.jpg",
  "movieArea": "中国大陆",
  "releaseDate": "2023-01-22 00:00:00",
  "movieBoxOffice": 4688000000.00,
  "movieIntroduction": "太阳即将毁灭，人类在地球表面建造出巨大的推进器，寻找新的家园。",
  "moviePictures": "pic1.jpg,pic2.jpg",
  "movieCategoryList": [
    { "movieCategoryId": 1, "movieCategoryName": "科幻" },
    { "movieCategoryId": 2, "movieCategoryName": "冒险" }
  ]
}
```

### 5.7 SysMovieCategory（电影分类）

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|----------|------|
| `movieCategoryId` | Long | - | - | 分类 ID |
| `movieCategoryName` | String | 是 | `@NotBlank` | 分类名称 |

**JSON 示例：**

```json
{
  "movieCategoryId": 1,
  "movieCategoryName": "科幻"
}
```

### 5.8 SysMovieToCategory（电影-分类关联）

多对多关系中间表，不直接暴露为接口返回对象。

| 字段 | 类型 | 说明 |
|------|------|------|
| `movieId` | Long | 电影 ID |
| `movieCategoryId` | Long | 分类 ID |

### 5.9 SysSession（场次）

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|----------|------|
| `sessionId` | Long | - | - | 场次 ID |
| `hallId` | Long | 是 | `@NotNull` | 影厅 ID |
| `languageVersion` | String | 是 | `@NotBlank` | 语言版本（如"国语2D"、"英语3D"） |
| `movieId` | Long | 是 | `@NotNull` | 电影 ID |
| `playTime` | LocalTime | 否 | - | 播放时间，格式 `HH:mm` |
| `endTime` | LocalTime | 否 | - | 结束时间，格式 `HH:mm` |
| `deadline` | LocalDateTime | 否 | - | 截止时间，此时间前不可修改，格式 `yyyy-MM-dd HH:mm:ss` |
| `sessionDate` | LocalDate | 是 | `@NotNull` | 场次日期，格式 `yyyy-MM-dd` |
| `sessionPrice` | Double | 是 | `@NotNull` `@Size(min=0)` | 票价 |
| `sessionTips` | String | 否 | - | 场次提示 |
| `sessionSeats` | String | 是 | `@NotBlank` | 场次座位信息（JSON），`0`=可用，`1`=已售 |
| `seatNums` | Integer | 否 | - | 总座位数 |
| `sallNums` | Integer | 否 | - | 已售座位数 |
| `sysHall` | SysHall | 否 | - | 关联影厅对象 |
| `sysMovie` | SysMovie | 否 | - | 关联电影对象 |

**JSON 示例：**

```json
{
  "sessionId": 1,
  "hallId": 1,
  "languageVersion": "国语3D",
  "movieId": 1,
  "playTime": "14:30",
  "endTime": "16:35",
  "deadline": "2026-07-08 14:30:00",
  "sessionDate": "2026-07-09",
  "sessionPrice": 49.90,
  "sessionTips": "请提前10分钟入场",
  "sessionSeats": "[[0,0,1,0,...],[0,0,0,0,...],...]",
  "seatNums": 200,
  "sallNums": 1,
  "sysHall": { "hallId": 1, "hallName": "1号IMAX厅" },
  "sysMovie": { "movieId": 1, "movieName": "流浪地球" }
}
```

### 5.10 SysBill（订单）

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|----------|------|
| `billId` | Long | - | - | 订单 ID |
| `payState` | Boolean | - | - | 支付状态（`false`=未支付，`true`=已支付） |
| `userId` | Long | 是 | `@NotNull` | 下单用户 ID |
| `sessionId` | Long | 是 | `@NotNull` | 所属场次 ID |
| `seats` | String | 是 | `@NotBlank` | 座位，格式如 `"1排10号,A排5号"` |
| `cancelState` | Boolean | 否 | - | 取消状态 |
| `cancelRole` | Boolean | 否 | - | 取消操作角色（管理员/用户） |
| `createTime` | Date | 否 | - | 创建时间 |
| `deadline` | Date | 否 | - | 支付截止时间 |
| `cancelTime` | Date | 否 | - | 取消时间 |
| `queryByUserName` | String | 否 | - | 用户名搜索条件（仅作查询参数） |
| `remark` | String | 否 | - | 管理员备注 |
| `delState` | Boolean | 否 | - | 删除状态 |
| `sysSession` | SysSession | 否 | - | 关联场次对象 |
| `sysUser` | SysUser | 否 | - | 关联用户对象 |

**JSON 示例：**

```json
{
  "billId": 1,
  "payState": true,
  "userId": 2,
  "sessionId": 1,
  "seats": "1排10号",
  "cancelState": false,
  "cancelRole": null,
  "createTime": "2026-07-09 10:30:00",
  "deadline": "2026-07-09 10:45:00",
  "cancelTime": null,
  "delState": false,
  "remark": null,
  "sysSession": {
    "sessionId": 1,
    "sessionDate": "2026-07-09",
    "playTime": "14:30",
    "sessionPrice": 49.90,
    "sysMovie": { "movieId": 1, "movieName": "流浪地球" },
    "sysHall": { "hallId": 1, "hallName": "1号IMAX厅" }
  },
  "sysUser": { "userId": 2, "userName": "testuser" }
}
```

### 5.11 LoginUser（登录用户）

登录成功后返回的复合对象。

| 字段 | 类型 | 说明 |
|------|------|------|
| `sysUser` | SysUser | 登录用户信息 |
| `cinemaId` | Long | 用户管理的影院 ID |
| `cinemaName` | String | 用户管理的影院名称 |
| `token` | String | JWT 令牌 |

**JSON 示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "sysUser": {
      "userId": 1,
      "userName": "admin",
      "email": "admin@cinema.com",
      "phoneNumber": "13800138000",
      "sex": true,
      "userPicture": "avatar_admin.jpg",
      "roleId": 1,
      "sysRole": { "roleId": 1, "roleName": "系统管理员", "roleDesc": "拥有所有权限" }
    },
    "cinemaId": 1,
    "cinemaName": "万象影城",
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  }
}
```

### 5.12 VO 对象

#### SysUserVo（登录请求）

| 字段 | 类型 | 说明 |
|------|------|------|
| `userName` | String | 用户名 |
| `password` | String | 密码 |
| `captchaKey` | String | 验证码 Key（从 `/captcha` 获取） |
| `captchaCode` | String | 验证码内容（用户识别结果） |

#### SysMovieVo（电影查询条件）

| 字段 | 类型 | 说明 |
|------|------|------|
| `movieName` | String | 电影名称（模糊搜索） |
| `movieArea` | String | 制片地区 |
| `movieCategoryId` | Long | 分类 ID |
| `startDate` | Date | 上映日期起始 |
| `endDate` | Date | 上映日期截止 |

#### SysSessionVo（场次查询条件）

| 字段 | 类型 | 说明 |
|------|------|------|
| `hallId` | Long | 影厅 ID |
| `movieId` | Long | 电影 ID |
| `sessionDate` | LocalDate | 场次日期，格式 `yyyy-MM-dd` |

#### SysBillVo（订单创建/取消请求）

| 字段 | 类型 | 说明 |
|------|------|------|
| `sysBill` | SysBill | 订单信息 |
| `sessionSeats` | String | 更新后的场次座位信息（JSON） |

---

## 6. API 端点详细说明

### 6.1 验证码模块

#### GET /captcha

- **接口描述：** 获取登录验证码
- **认证要求：** 公开

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "image": "data:image/png;base64,iVBORw0KGgo...",
    "key": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  }
}
```

| 响应字段 | 类型 | 说明 |
|----------|------|------|
| `data.image` | String | Base64 编码的验证码图片，可直接作为 `<img>` src |
| `data.key` | String | 验证码唯一标识，登录时需回传 |

---

### 6.2 文件上传模块

> 所有文件上传接口需要认证。

#### POST /upload/user

- **接口描述：** 上传用户头像
- **认证要求：** 需JWT
- **Content-Type：** `multipart/form-data`

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `file` | form-data | File | 是 | 用户头像图片 |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": "avatar_20260709103025.jpg"
}
```

#### POST /upload/movie

- **接口描述：** 上传电影海报
- **认证要求：** 需JWT
- **Content-Type：** `multipart/form-data`

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `file` | form-data | File | 是 | 电影海报图片 |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": "poster_20260709.jpg"
}
```

#### POST /upload/cinema

- **接口描述：** 上传影院图片
- **认证要求：** 需JWT
- **Content-Type：** `multipart/form-data`

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `file` | form-data | File | 是 | 影院图片 |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": "cinema_banner.jpg"
}
```

#### POST /upload/actor

- **接口描述：** 上传演员照片
- **认证要求：** 需JWT
- **Content-Type：** `multipart/form-data`

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `file` | form-data | File | 是 | 演员照片 |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": "actor_zhang.jpg"
}
```

#### DELETE /upload/delete

- **接口描述：** 删除已上传的文件
- **认证要求：** 需JWT
- **注意：** 此接口使用 `@RequestMapping` 无 HTTP 方法限制，支持所有请求方法

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `filePath` | Query | String | 是 | 要删除的文件路径/文件名 |

**请求示例：**

```
DELETE /upload/delete?filePath=old_poster.jpg
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

> **注意：** 无论文件删除是否成功，接口始终返回成功。实际删除结果需通过检查文件系统确认。

---

### 6.3 用户管理模块

#### GET /sysUser

- **接口描述：** 获取用户列表（支持分页和条件筛选）
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `userName` | Query | String | 否 | 用户名（模糊搜索） |
| `email` | Query | String | 否 | 邮箱（模糊搜索） |
| `phoneNumber` | Query | String | 否 | 手机号（模糊搜索） |
| `sex` | Query | Boolean | 否 | 性别筛选 |
| `roleId` | Query | Long | 否 | 角色 ID 筛选 |
| `pageNum` | Query | Integer | 否 | 页码，默认 1 |
| `pageSize` | Query | Integer | 否 | 每页数量，默认 1000 |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "userId": 1,
      "userName": "admin",
      "email": "admin@cinema.com",
      "phoneNumber": "13800138000",
      "sex": true,
      "userPicture": "avatar_admin.jpg",
      "roleId": 1,
      "birthday": "1990-01-01",
      "autograph": "管理员",
      "sysRole": {
        "roleId": 1,
        "roleName": "系统管理员",
        "roleDesc": "拥有所有权限"
      }
    }
  ],
  "pageNum": 1,
  "pageSize": 1000,
  "total": 1
}
```

#### GET /sysUser/{id}

- **接口描述：** 根据 ID 获取单个用户
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `id` | Path | Long | 是 | 用户 ID |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "userId": 2,
    "userName": "testuser",
    "email": "test@cinema.com",
    "phoneNumber": "13900139000",
    "sex": false,
    "userPicture": "avatar_default.jpg",
    "roleId": 2,
    "birthday": "2000-06-15",
    "autograph": "普通用户",
    "sysRole": {
      "roleId": 2,
      "roleName": "普通用户",
      "roleDesc": "仅可购票"
    }
  }
}
```

#### POST /sysUser

- **接口描述：** 新增用户
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| - | Body | SysUser | - | 用户信息 JSON |

**请求示例：**

```json
{
  "userName": "newuser",
  "password": "123456",
  "email": "newuser@cinema.com",
  "phoneNumber": "13700137000",
  "sex": true,
  "roleId": 2,
  "birthday": "1995-08-20",
  "autograph": "电影爱好者"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### PUT /sysUser

- **接口描述：** 更新用户信息
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| - | Body | SysUser | - | 用户信息 JSON（需包含 `userId`） |

**请求示例：**

```json
{
  "userId": 2,
  "userName": "testuser",
  "email": "updated@cinema.com",
  "phoneNumber": "13900139001",
  "sex": false,
  "roleId": 2,
  "birthday": "2000-06-15",
  "autograph": "更新后的签名"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### DELETE /sysUser/{ids}

- **接口描述：** 批量删除用户
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `ids` | Path | Long[] | 是 | 用户 ID 数组，多个以逗号分隔 |

**请求示例：**

```
DELETE /sysUser/2,3,4
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### POST /sysUser/login

- **接口描述：** 用户登录
- **认证要求：** 公开
- **注意：** 此接口使用 `@RequestMapping` 无 HTTP 方法限制

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| - | Body | SysUserVo | - | 登录信息 JSON |

**请求示例：**

```json
{
  "userName": "admin",
  "password": "123456",
  "captchaKey": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "captchaCode": "A3x9"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "sysUser": {
      "userId": 1,
      "userName": "admin",
      "email": "admin@cinema.com",
      "phoneNumber": "13800138000",
      "sex": true,
      "userPicture": "avatar_admin.jpg",
      "roleId": 1,
      "sysRole": {
        "roleId": 1,
        "roleName": "系统管理员",
        "roleDesc": "拥有所有权限"
      }
    },
    "cinemaId": 1,
    "cinemaName": "万象影城",
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6ImFkbWluIiwiZXhwIjoxNjkyMDk2MjAwfQ.signature"
  }
}
```

**登录流程说明：**
1. 先调用 `GET /captcha` 获取验证码 key 和图片
2. 用户识别验证码后，提交 `userName`、`password`、`captchaKey`、`captchaCode`
3. 服务端校验验证码正确性
4. 校验用户名和密码
5. 签发 JWT Token，有效期 60 分钟
6. 返回用户信息、影院信息和 Token

#### POST /sysUser/register

- **接口描述：** 用户注册
- **认证要求：** 公开

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| - | Body | SysUser | - | 注册信息（仅使用以下字段） |

**请求示例：**

```json
{
  "userName": "newuser",
  "password": "123456",
  "sex": true,
  "phoneNumber": "13700137000"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

> **注意：** 注册接口仅使用 `userName`、`password`、`sex`、`phoneNumber` 四个字段。密码在服务端经 MD5 + 随机盐 + 1024 次哈希处理后存储。

---

### 6.4 角色管理模块

#### GET /sysRole

- **接口描述：** 获取角色列表（支持分页）
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `pageNum` | Query | Integer | 否 | 页码，默认 1 |
| `pageSize` | Query | Integer | 否 | 每页数量，默认 1000 |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "roleId": 1,
      "roleName": "系统管理员",
      "roleDesc": "拥有所有权限",
      "children": []
    },
    {
      "roleId": 2,
      "roleName": "普通用户",
      "roleDesc": "仅可购票",
      "children": []
    }
  ],
  "pageNum": 1,
  "pageSize": 1000,
  "total": 2
}
```

#### GET /sysRole/{id}

- **接口描述：** 根据 ID 获取单个角色
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `id` | Path | Long | 是 | 角色 ID |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "roleId": 1,
    "roleName": "系统管理员",
    "roleDesc": "拥有所有权限",
    "children": [
      { "id": 1, "name": "影院管理", "path": "/cinema", "level": 1, "parentId": 0 },
      { "id": 2, "name": "影厅管理", "path": "/cinema/hall", "level": 2, "parentId": 1 }
    ]
  }
}
```

#### POST /sysRole

- **接口描述：** 新增角色
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "roleName": "影院经理",
  "roleDesc": "管理影院日常运营"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### PUT /sysRole

- **接口描述：** 更新角色信息
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "roleId": 3,
  "roleName": "影院经理",
  "roleDesc": "管理影院日常运营（已更新）"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### DELETE /sysRole/{ids}

- **接口描述：** 批量删除角色
- **认证要求：** 需JWT

**请求示例：**

```
DELETE /sysRole/3,4
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### POST /sysRole/{roleId}

- **接口描述：** 为角色分配权限
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `roleId` | Path | Long | 是 | 角色 ID |
| - | Body | Long[] | 是 | 权限资源 ID 数组 |

**请求示例：**

```
POST /sysRole/1
Content-Type: application/json

[1, 2, 3, 4, 5]
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

---

### 6.5 菜单资源模块

#### GET /sysResource

- **接口描述：** 获取所有资源列表（平铺结构，支持分页）
- **认证要求：** 需JWT

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    { "id": 1, "name": "影院管理", "path": "/cinema", "level": 1, "parentId": 0 },
    { "id": 2, "name": "影厅管理", "path": "/cinema/hall", "level": 2, "parentId": 1 },
    { "id": 3, "name": "电影管理", "path": "/movie", "level": 1, "parentId": 0 }
  ],
  "pageNum": 1,
  "pageSize": 1000,
  "total": 3
}
```

#### GET /sysResource/children

- **接口描述：** 获取资源列表（含一层子级）
- **认证要求：** 需JWT

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "id": 1,
      "name": "影院管理",
      "path": "/cinema",
      "level": 1,
      "parentId": 0,
      "children": [
        { "id": 2, "name": "影厅管理", "path": "/cinema/hall", "level": 2, "parentId": 1, "children": null }
      ]
    }
  ]
}
```

#### GET /sysResource/tree

- **接口描述：** 获取完整资源树（含所有嵌套子级）
- **认证要求：** 需JWT

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "id": 1,
      "name": "系统管理",
      "path": "/system",
      "level": 1,
      "parentId": 0,
      "children": [
        {
          "id": 4,
          "name": "用户管理",
          "path": "/system/user",
          "level": 2,
          "parentId": 1,
          "children": []
        },
        {
          "id": 5,
          "name": "角色管理",
          "path": "/system/role",
          "level": 2,
          "parentId": 1,
          "children": []
        }
      ]
    }
  ]
}
```

#### GET /sysResource/{id}

- **接口描述：** 根据 ID 获取单个资源
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `id` | Path | Long | 是 | 资源 ID |

#### POST /sysResource

- **接口描述：** 新增资源
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "name": "订单管理",
  "path": "/bill",
  "level": 1,
  "parentId": 0
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### PUT /sysResource

- **接口描述：** 更新资源信息
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "id": 1,
  "name": "影院管理",
  "path": "/cinema",
  "level": 1,
  "parentId": 0
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### DELETE /sysResource/{ids}

- **接口描述：** 批量删除资源
- **认证要求：** 需JWT

**请求示例：**

```
DELETE /sysResource/7,8
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

---

### 6.6 影院管理模块

#### GET /sysCinema

- **接口描述：** 获取影院信息（系统仅维护一个影院）
- **认证要求：** 公开

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "cinemaId": 1,
    "cinemaName": "万象影城",
    "hallCategoryList": "[\"IMAX\",\"4K激光\",\"普通厅\"]",
    "cinemaPicture": "cinema_1.jpg",
    "cinemaAddress": "市中心商业广场5楼",
    "cinemaPhone": "010-12345678",
    "workStartTime": "09:00",
    "workEndTime": "23:59",
    "sysMovieList": []
  }
}
```

#### PUT /sysCinema/update

- **接口描述：** 更新影院信息
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "cinemaId": 1,
  "cinemaName": "万象影城（旗舰店）",
  "hallCategoryList": "[\"IMAX\",\"4K激光\",\"普通厅\",\"VIP厅\"]",
  "cinemaPicture": "cinema_new.jpg",
  "cinemaAddress": "市中心商业广场6楼",
  "cinemaPhone": "010-87654321",
  "workStartTime": "08:00",
  "workEndTime": "23:59"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### GET /sysCinema/find/{cinemaId}

- **接口描述：** 按影院 ID 获取影院信息及场次列表
- **认证要求：** 公开

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `cinemaId` | Path | Long | 是 | 影院 ID |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "cinema": {
      "cinemaId": 1,
      "cinemaName": "万象影城",
      "cinemaAddress": "市中心商业广场5楼"
    },
    "sessions": [
      {
        "sessionId": 1,
        "movieId": 1,
        "sessionDate": "2026-07-09",
        "playTime": "14:30",
        "sessionPrice": 49.90,
        "languageVersion": "国语3D",
        "sysMovie": { "movieId": 1, "movieName": "流浪地球", "moviePoster": "poster_1.jpg" },
        "sysHall": { "hallId": 1, "hallName": "1号IMAX厅" }
      }
    ]
  }
}
```

#### GET /sysCinema/find/{cinemaId}/{movieId}

- **接口描述：** 按影院 ID 和电影 ID 获取影院信息及该电影的场次列表
- **认证要求：** 公开

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `cinemaId` | Path | Long | 是 | 影院 ID |
| `movieId` | Path | Long | 否 | 电影 ID（可选，为可选路径变量） |

> **注意：** `movieId` 是可选路径变量。不传 `movieId` 时访问 `/sysCinema/find/{cinemaId}`，返回该影院所有场次。

---

### 6.7 影厅管理模块

#### GET /sysHall

- **接口描述：** 获取影厅列表（支持分页和条件筛选）
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `cinemaId` | Query | Long | 否 | 影院 ID 筛选 |
| `hallName` | Query | String | 否 | 影厅名称筛选 |
| `hallCategory` | Query | String | 否 | 影厅类别筛选 |
| `pageNum` | Query | Integer | 否 | 页码，默认 1 |
| `pageSize` | Query | Integer | 否 | 每页数量，默认 1000 |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "cinemaId": 1,
      "hallId": 1,
      "hallName": "1号IMAX厅",
      "hallCategory": "IMAX",
      "rowStart": "1",
      "rowNums": 10,
      "seatNumsRow": 20,
      "seatNums": 200,
      "seatState": "[[0,0,0,...],[0,0,0,...],...]",
      "delState": false,
      "sysCinema": { "cinemaId": 1, "cinemaName": "万象影城" }
    }
  ],
  "pageNum": 1,
  "pageSize": 1000,
  "total": 5
}
```

#### GET /sysHall/{hallId}

- **接口描述：** 根据 ID 获取单个影厅
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `hallId` | Path | Long | 是 | 影厅 ID |

#### POST /sysHall

- **接口描述：** 新增影厅
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "cinemaId": 1,
  "hallName": "3号普通厅",
  "hallCategory": "普通厅",
  "rowStart": "1",
  "rowNums": 8,
  "seatNumsRow": 15,
  "seatNums": 120,
  "seatState": "[[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],...]"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### PUT /sysHall

- **接口描述：** 更新影厅信息
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "cinemaId": 1,
  "hallId": 3,
  "hallName": "3号VIP厅",
  "hallCategory": "VIP厅",
  "rowStart": "A",
  "rowNums": 6,
  "seatNumsRow": 10,
  "seatNums": 60,
  "seatState": "[[0,0,0,0,0,0,0,0,0,0],...]"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### POST /sysHall/delete

- **接口描述：** 批量删除影厅
- **认证要求：** 需JWT
- **注意：** 此接口使用 POST 方法（非 DELETE），以支持请求体传递数组

**请求示例：**

```json
[
  { "hallId": 3 },
  { "hallId": 4 }
]
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

---

### 6.8 电影管理模块

#### GET /sysMovie/find

- **接口描述：** 获取电影列表（支持分页和多条件筛选）
- **认证要求：** 公开

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `movieName` | Query | String | 否 | 电影名称（模糊搜索） |
| `movieArea` | Query | String | 否 | 制片地区 |
| `movieCategoryId` | Query | Long | 否 | 分类 ID |
| `startDate` | Query | Date | 否 | 上映日期起始，格式 `yyyy-MM-dd HH:mm:ss` |
| `endDate` | Query | Date | 否 | 上映日期截止，格式 `yyyy-MM-dd HH:mm:ss` |
| `pageNum` | Query | Integer | 否 | 页码，默认 1 |
| `pageSize` | Query | Integer | 否 | 每页数量，默认 1000 |

**请求示例：**

```
GET /sysMovie/find?movieName=流浪&movieArea=中国大陆&pageNum=1&pageSize=10
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "movieId": 1,
      "movieName": "流浪地球",
      "movieLength": 125,
      "moviePoster": "poster_1.jpg",
      "movieArea": "中国大陆",
      "releaseDate": "2023-01-22 00:00:00",
      "movieBoxOffice": 4688000000.00,
      "movieIntroduction": "太阳即将毁灭...",
      "moviePictures": "pic1.jpg,pic2.jpg",
      "movieCategoryList": [
        { "movieCategoryId": 1, "movieCategoryName": "科幻" },
        { "movieCategoryId": 2, "movieCategoryName": "冒险" }
      ]
    }
  ],
  "pageNum": 1,
  "pageSize": 10,
  "total": 1
}
```

#### GET /sysMovie/find/{id}

- **接口描述：** 根据 ID 获取单部电影详情
- **认证要求：** 公开

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `id` | Path | Long | 是 | 电影 ID |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "movieId": 1,
    "movieName": "流浪地球",
    "movieLength": 125,
    "moviePoster": "poster_1.jpg",
    "movieArea": "中国大陆",
    "releaseDate": "2023-01-22 00:00:00",
    "movieBoxOffice": 4688000000.00,
    "movieIntroduction": "太阳即将毁灭...",
    "moviePictures": "pic1.jpg,pic2.jpg",
    "movieCategoryList": [
      { "movieCategoryId": 1, "movieCategoryName": "科幻" },
      { "movieCategoryId": 2, "movieCategoryName": "冒险" }
    ]
  }
}
```

#### GET /sysMovie/find/rankingList/{listId}

- **接口描述：** 获取电影排行榜
- **认证要求：** 公开

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `listId` | Path | Integer | 是 | 排行榜类型：`1`=总票房排行，`2`=国内票房排行，`3`=国外票房排行 |

**请求示例：**

```
GET /sysMovie/find/rankingList/1
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "movieId": 1,
      "movieName": "流浪地球",
      "moviePoster": "poster_1.jpg",
      "movieArea": "中国大陆",
      "movieBoxOffice": 4688000000.00,
      "releaseDate": "2023-01-22 00:00:00"
    }
  ],
  "pageNum": 1,
  "pageSize": 1000,
  "total": 1
}
```

#### POST /sysMovie

- **接口描述：** 新增电影
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "movieName": "新电影",
  "movieLength": 120,
  "moviePoster": "new_poster.jpg",
  "movieArea": "中国大陆",
  "releaseDate": "2026-08-01 00:00:00",
  "movieIntroduction": "这是一部新电影的介绍",
  "moviePictures": "pic_a.jpg,pic_b.jpg"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### PUT /sysMovie

- **接口描述：** 更新电影信息
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "movieId": 2,
  "movieName": "新电影（改名）",
  "movieLength": 120,
  "moviePoster": "updated_poster.jpg",
  "movieArea": "中国大陆",
  "releaseDate": "2026-08-01 00:00:00",
  "movieIntroduction": "更新后的电影介绍",
  "moviePictures": "pic_a.jpg,pic_b.jpg,pic_c.jpg"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### DELETE /sysMovie/{ids}

- **接口描述：** 批量删除电影
- **认证要求：** 需JWT

**请求示例：**

```
DELETE /sysMovie/2,3
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

---

### 6.9 电影分类模块

#### GET /sysMovieCategory/find

- **接口描述：** 获取所有电影分类列表（支持分页）
- **认证要求：** 公开

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    { "movieCategoryId": 1, "movieCategoryName": "科幻" },
    { "movieCategoryId": 2, "movieCategoryName": "冒险" },
    { "movieCategoryId": 3, "movieCategoryName": "喜剧" }
  ],
  "pageNum": 1,
  "pageSize": 1000,
  "total": 3
}
```

#### GET /sysMovieCategory/{id}

- **接口描述：** 根据 ID 获取单个分类
- **认证要求：** 公开

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `id` | Path | Long | 是 | 分类 ID |

#### POST /sysMovieCategory

- **接口描述：** 新增电影分类
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "movieCategoryName": "纪录片"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### PUT /sysMovieCategory

- **接口描述：** 更新电影分类
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "movieCategoryId": 4,
  "movieCategoryName": "纪录短片"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### DELETE /sysMovieCategory/{ids}

- **接口描述：** 批量删除电影分类
- **认证要求：** 需JWT

**请求示例：**

```
DELETE /sysMovieCategory/4,5
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### POST /sysMovieToCategory/{movieId}/{movieCategoryId}

- **接口描述：** 为电影添加分类关联
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `movieId` | Path | Long | 是 | 电影 ID |
| `movieCategoryId` | Path | Long | 是 | 分类 ID |

**请求示例：**

```
POST /sysMovieToCategory/1/3
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### DELETE /sysMovieToCategory/{movieId}/{movieCategoryId}

- **接口描述：** 移除电影与分类的关联
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `movieId` | Path | Long | 是 | 电影 ID |
| `movieCategoryId` | Path | Long | 是 | 分类 ID |

**请求示例：**

```
DELETE /sysMovieToCategory/1/3
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

---

### 6.10 场次管理模块

#### GET /sysSession

- **接口描述：** 获取场次列表（支持分页和条件筛选）
- **认证要求：** 公开

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `hallId` | Query | Long | 否 | 影厅 ID |
| `movieId` | Query | Long | 否 | 电影 ID |
| `sessionDate` | Query | LocalDate | 否 | 场次日期，格式 `yyyy-MM-dd` |
| `pageNum` | Query | Integer | 否 | 页码，默认 1 |
| `pageSize` | Query | Integer | 否 | 每页数量，默认 1000 |

**请求示例：**

```
GET /sysSession?movieId=1&sessionDate=2026-07-09&pageNum=1&pageSize=10
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "sessionId": 1,
      "hallId": 1,
      "languageVersion": "国语3D",
      "movieId": 1,
      "playTime": "14:30",
      "endTime": "16:35",
      "deadline": "2026-07-08 14:30:00",
      "sessionDate": "2026-07-09",
      "sessionPrice": 49.90,
      "sessionTips": "请提前10分钟入场",
      "sessionSeats": "[[0,0,0,...],[0,0,1,...],...]",
      "seatNums": 200,
      "sallNums": 1,
      "sysHall": {
        "hallId": 1,
        "hallName": "1号IMAX厅",
        "cinemaId": 1
      },
      "sysMovie": {
        "movieId": 1,
        "movieName": "流浪地球",
        "moviePoster": "poster_1.jpg",
        "movieLength": 125
      }
    }
  ],
  "pageNum": 1,
  "pageSize": 10,
  "total": 1
}
```

#### GET /sysSession/find/{id}

- **接口描述：** 根据 ID 获取场次详情（同时触发超时订单自动取消）
- **认证要求：** 公开

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `id` | Path | Long | 是 | 场次 ID |

> **业务逻辑：** 查询场次时会检查未支付且超时的订单，自动取消并释放座位。

#### GET /sysSession/isAbleEdit

- **接口描述：** 检查场次是否可编辑
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `sessionId` | Query | Long | 否 | 场次 ID |
| `hallId` | Query | Long | 否 | 影厅 ID |
| `movieId` | Query | Long | 否 | 电影 ID |

**请求示例：**

```
GET /sysSession/isAbleEdit?sessionId=1&hallId=1&movieId=1
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": true
}
```

#### POST /sysSession

- **接口描述：** 新增场次
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "hallId": 1,
  "movieId": 1,
  "languageVersion": "英语原声3D",
  "playTime": "19:00",
  "endTime": "21:05",
  "sessionDate": "2026-07-10",
  "sessionPrice": 59.90,
  "sessionTips": "英语原声，中文字幕",
  "sessionSeats": "[[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],...]"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### PUT /sysSession

- **接口描述：** 更新场次信息
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "sessionId": 2,
  "hallId": 1,
  "movieId": 1,
  "languageVersion": "英语原声3D",
  "playTime": "20:00",
  "endTime": "22:05",
  "sessionDate": "2026-07-10",
  "sessionPrice": 69.90,
  "sessionTips": "英语原声，中文字幕，含映前广告",
  "sessionSeats": "[[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],...]"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

#### DELETE /sysSession/{ids}

- **接口描述：** 批量删除场次
- **认证要求：** 需JWT

**请求示例：**

```
DELETE /sysSession/2,3
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

---

### 6.11 订单模块

#### GET /sysBill

- **接口描述：** 获取订单列表（支持分页和条件筛选）
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `userId` | Query | Long | 否 | 用户 ID |
| `sessionId` | Query | Long | 否 | 场次 ID |
| `payState` | Query | Boolean | 否 | 支付状态（`false`=未支付，`true`=已支付） |
| `cancelState` | Query | Boolean | 否 | 取消状态 |
| `queryByUserName` | Query | String | 否 | 用户名（模糊搜索） |
| `pageNum` | Query | Integer | 否 | 页码，默认 1 |
| `pageSize` | Query | Integer | 否 | 每页数量，默认 1000 |

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "billId": 1,
      "payState": true,
      "userId": 2,
      "sessionId": 1,
      "seats": "1排10号",
      "cancelState": false,
      "cancelRole": null,
      "createTime": "2026-07-09 10:30:00",
      "deadline": "2026-07-09 10:45:00",
      "cancelTime": null,
      "delState": false,
      "remark": null,
      "sysSession": {
        "sessionId": 1,
        "sessionDate": "2026-07-09",
        "playTime": "14:30",
        "languageVersion": "国语3D",
        "sessionPrice": 49.90,
        "sysMovie": { "movieId": 1, "movieName": "流浪地球" },
        "sysHall": { "hallId": 1, "hallName": "1号IMAX厅" }
      },
      "sysUser": { "userId": 2, "userName": "testuser" }
    }
  ],
  "pageNum": 1,
  "pageSize": 1000,
  "total": 1
}
```

#### GET /sysBill/{id}

- **接口描述：** 根据 ID 获取单个订单详情
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `id` | Path | Long | 是 | 订单 ID |

#### POST /sysBill

- **接口描述：** 创建订单（购票）
- **认证要求：** 需JWT

**请求参数：**

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| - | Body | SysBillVo | - | 订单信息 |

**请求示例：**

```json
{
  "sysBill": {
    "userId": 2,
    "sessionId": 1,
    "seats": "1排10号"
  },
  "sessionSeats": "[[0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0],...]"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": 3
}
```

> **业务逻辑：** 创建订单时需同时提供更新后的场次座位信息（`sessionSeats`）。若应购票座位数超过剩余座位数，创建会失败。

#### PUT /sysBill

- **接口描述：** 支付订单
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "billId": 1,
  "payState": true
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

> **业务逻辑：**
> - 支付成功后，系统自动更新对应影片的票房：`movieBoxOffice += 座位数 × 票价`
> - 座位数由订单中的 `seats` 字段解析得出（以逗号分隔计数）

#### PUT /sysBill/cancel

- **接口描述：** 取消订单
- **认证要求：** 需JWT

**请求示例：**

```json
{
  "sysBill": {
    "billId": 1,
    "cancelState": true,
    "cancelRole": false
  },
  "sessionSeats": "[[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],...]"
}
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

> **业务逻辑：**
> - 取消订单时需同时提供释放座位后的场次座位信息（`sessionSeats`，将座位从 `1` 改为 `0`）
> - `cancelRole` 标识取消操作角色：`false`=用户自己取消，`true`=管理员取消

#### DELETE /sysBill/{ids}

- **接口描述：** 批量删除订单
- **认证要求：** 需JWT

**请求示例：**

```
DELETE /sysBill/1,2
```

**响应示例：**

```json
{
  "code": 200,
  "msg": "操作成功"
}
```

---

## 附录

### A. 数据库表结构速查

| 表名 | 对应实体 | 说明 |
|------|----------|------|
| `sys_user` | SysUser | 用户表 |
| `sys_role` | SysRole | 角色表 |
| `sys_resource` | SysResource | 菜单资源表 |
| `sys_role_resource` | - | 角色-资源关联表 |
| `sys_cinema` | SysCinema | 影院表 |
| `sys_hall` | SysHall | 影厅表 |
| `sys_movie` | SysMovie | 电影表 |
| `sys_movie_category` | SysMovieCategory | 电影分类表 |
| `sys_movie_to_category` | SysMovieToCategory | 电影-分类关联表 |
| `sys_session` | SysSession | 场次表 |
| `sys_bill` | SysBill | 订单表 |

### B. MyBatis Mapper XML 位置

所有 Mapper XML 文件位于：`src/main/resources/mapper/`

| 文件 | 说明 |
|------|------|
| `SysBillMapper.xml` | 订单 SQL |
| `SysCinemaMapper.xml` | 影院 SQL |
| `SysHallMapper.xml` | 影厅 SQL |
| `SysMovieMapper.xml` | 电影 SQL |
| `SysMovieCategoryMapper.xml` | 电影分类 SQL |
| `SysResourceMapper.xml` | 资源 SQL |
| `SysRoleMapper.xml` | 角色 SQL |
| `SysSessionMapper.xml` | 场次 SQL |
| `SysUserMapper.xml` | 用户 SQL |

### C. 运行环境要求

| 依赖 | 版本要求 |
|------|----------|
| JDK | 1.8+ |
| MySQL | 5.7+ |
| Redis | 任意版本 |
| Maven | 3.6+ |

数据库初始化使用 Flyway，迁移脚本位于 `src/main/resources/db/migration/`，首次启动自动执行。

### D. 图片资源访问

上传的图片文件通过静态资源映射访问：

```
GET http://{host}:9231/images/{filename}
```

例如：`http://localhost:9231/images/poster_1.jpg`
