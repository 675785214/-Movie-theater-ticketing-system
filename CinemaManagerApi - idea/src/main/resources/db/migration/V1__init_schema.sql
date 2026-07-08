-- ============================================
-- V1: 初始化数据库表结构
-- 电影院售票系统 - 所有建表语句
-- ============================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- 订单表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `sys_bill` (
  `bill_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '订单编号',
  `pay_state` tinyint(4) NOT NULL DEFAULT 0 COMMENT '支付状态，0未支付，1已支付',
  `cancel_state` tinyint(4) NOT NULL DEFAULT 0 COMMENT '取消状态，0未取消，1取消',
  `user_id` bigint(20) UNSIGNED NOT NULL COMMENT '用户编号',
  `session_id` bigint(20) UNSIGNED NOT NULL COMMENT '场次编号',
  `seats` varchar(1600) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '购买的座位号',
  `create_time` datetime(0) NULL DEFAULT NULL COMMENT '创建时间',
  `deadline` datetime(0) NULL DEFAULT NULL COMMENT '失效时间',
  `cancel_time` datetime(0) NULL DEFAULT NULL COMMENT '取消时间',
  PRIMARY KEY (`bill_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 84 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 影院表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `sys_cinema` (
  `cinema_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '影院编号',
  `cinema_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '影院名称',
  `hall_category_list` varchar(1600) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '拥有影厅类别',
  `cinema_picture` varchar(1600) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '影院图片',
  `cinema_phone` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '影院电话',
  `cinema_address` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '影院地址',
  `work_start_time` varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '开始营业时间',
  `work_end_time` varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '结束营业时间',
  PRIMARY KEY (`cinema_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 影厅表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `sys_hall` (
  `hall_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '影厅编号',
  `cinema_id` bigint(20) UNSIGNED NOT NULL DEFAULT 1 COMMENT '影院编号',
  `hall_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '影厅名称',
  `hall_category` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '影厅类别',
  `row_start` varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '1' COMMENT '排开始编号',
  `row_nums` smallint(5) UNSIGNED NOT NULL DEFAULT 10 COMMENT '总排数',
  `seat_nums_row` smallint(5) UNSIGNED NOT NULL DEFAULT 18 COMMENT '每排的座位数',
  `seat_nums` smallint(5) UNSIGNED NOT NULL DEFAULT 180 COMMENT '总可用座位数',
  `seat_state` varchar(1600) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '所有座位的状态',
  `del_state` tinyint(4) NOT NULL DEFAULT 0 COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`hall_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 41 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 电影表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `sys_movie` (
  `movie_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '电影编号',
  `movie_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '电影名称',
  `movie_length` int(11) NULL DEFAULT NULL COMMENT '电影时长(单位: 分钟)',
  `movie_poster` varchar(1600) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '电影海报',
  `movie_area` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '电影区域',
  `release_date` datetime(0) NULL DEFAULT NULL COMMENT '上映时间',
  `movie_box_office` decimal(20, 2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT '电影总票房',
  `movie_introduction` varchar(1600) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '电影简介',
  `movie_pictures` varchar(1600) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '电影图集',
  `del_state` tinyint(4) NOT NULL DEFAULT 0 COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`movie_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 32 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 电影类别表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `sys_movie_category` (
  `movie_category_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '电影类别编号',
  `movie_category_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '电影类别名称',
  PRIMARY KEY (`movie_category_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 30 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 电影-类别关联表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `sys_movie_to_category` (
  `movie_id` bigint(20) UNSIGNED NOT NULL COMMENT '电影编号',
  `movie_category_id` bigint(20) UNSIGNED NOT NULL COMMENT '电影类别编号',
  PRIMARY KEY (`movie_id`, `movie_category_id`) USING BTREE,
  INDEX `movie_category_id`(`movie_category_id`) USING BTREE,
  CONSTRAINT `sys_movie_to_category_ibfk_1` FOREIGN KEY (`movie_category_id`) REFERENCES `sys_movie_category` (`movie_category_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 资源权限表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `sys_resource` (
  `resource_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '资源编号',
  `resource_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '菜单名称',
  `path` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单路径',
  `level` int(10) UNSIGNED NOT NULL DEFAULT 1 COMMENT '资源权限等级',
  `parent_id` bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '当前菜单父菜单编号',
  PRIMARY KEY (`resource_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 623 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 角色表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `sys_role` (
  `role_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '角色编号',
  `role_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '角色名称',
  `role_desc` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '角色描述',
  PRIMARY KEY (`role_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 角色-资源关联表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `sys_role_resource` (
  `role_id` bigint(20) UNSIGNED NOT NULL COMMENT '角色编号',
  `resource_id` bigint(20) UNSIGNED NOT NULL COMMENT '资源编号',
  PRIMARY KEY (`role_id`, `resource_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 场次表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `sys_session` (
  `session_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '场次编号',
  `hall_id` bigint(20) UNSIGNED NOT NULL COMMENT '影厅编号',
  `language_version` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '语言版本',
  `movie_id` bigint(20) UNSIGNED NOT NULL COMMENT '电影编号',
  `play_time` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '播放时间',
  `end_time` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '散场时间',
  `deadline` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '截止时间',
  `session_date` date NOT NULL COMMENT '场次日期',
  `session_price` decimal(10, 2) NOT NULL COMMENT '票价',
  `session_tips` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '影厅提示',
  `session_seats` varchar(1600) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '座位信息',
  `seat_nums` smallint(5) UNSIGNED NULL DEFAULT 0 COMMENT '总座位数',
  `sall_nums` smallint(6) NOT NULL DEFAULT 0 COMMENT '售出座位数',
  `del_state` tinyint(4) NOT NULL DEFAULT 0 COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`session_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 61 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 用户表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `sys_user` (
  `user_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户编号',
  `user_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '用户名称',
  `password` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '用户密码(密文存储)',
  `salt` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '盐',
  `email` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '用户邮箱',
  `phone_number` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '用户电话号码',
  `sex` tinyint(3) UNSIGNED NOT NULL COMMENT '用户性别，1为男性0为女性',
  `user_picture` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '用户头像',
  `role_id` bigint(20) UNSIGNED NOT NULL DEFAULT 3 COMMENT '角色编号',
  `birthday` date NULL DEFAULT NULL COMMENT '生日',
  `autograph` varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '个性签名',
  `del_state` tinyint(4) NOT NULL DEFAULT 0 COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`user_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 30 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;
