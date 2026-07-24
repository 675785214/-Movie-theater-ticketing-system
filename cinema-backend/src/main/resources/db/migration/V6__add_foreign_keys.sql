-- ============================================
-- V6: 清理孤儿数据 + 添加外键约束
-- 先清理引用不存在父记录的脏数据，再添加外键
-- ============================================

SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Step 1: 清理孤儿数据
-- ----------------------------

-- sys_role_resource 中 role_id=10 的记录（role 表没有 id=10）
DELETE FROM sys_role_resource WHERE role_id NOT IN (SELECT role_id FROM sys_role);

-- sys_role_resource 中引用不存在 resource 的记录
DELETE FROM sys_role_resource WHERE resource_id NOT IN (SELECT resource_id FROM sys_resource);

-- sys_movie_to_category 中引用不存在 movie 的记录
DELETE FROM sys_movie_to_category WHERE movie_id NOT IN (SELECT movie_id FROM sys_movie);

-- ----------------------------
-- Step 2: 添加外键约束
-- ----------------------------

-- 影厅 → 影院
ALTER TABLE sys_hall ADD CONSTRAINT fk_hall_cinema
    FOREIGN KEY (cinema_id) REFERENCES sys_cinema(cinema_id) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 场次 → 影厅
ALTER TABLE sys_session ADD CONSTRAINT fk_session_hall
    FOREIGN KEY (hall_id) REFERENCES sys_hall(hall_id) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 场次 → 电影
ALTER TABLE sys_session ADD CONSTRAINT fk_session_movie
    FOREIGN KEY (movie_id) REFERENCES sys_movie(movie_id) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 订单 → 用户
ALTER TABLE sys_bill ADD CONSTRAINT fk_bill_user
    FOREIGN KEY (user_id) REFERENCES sys_user(user_id) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 订单 → 场次
ALTER TABLE sys_bill ADD CONSTRAINT fk_bill_session
    FOREIGN KEY (session_id) REFERENCES sys_session(session_id) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 用户 → 角色
ALTER TABLE sys_user ADD CONSTRAINT fk_user_role
    FOREIGN KEY (role_id) REFERENCES sys_role(role_id) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 电影-类别关联 → 电影（级联删除：删电影时自动清除关联）
ALTER TABLE sys_movie_to_category ADD CONSTRAINT fk_mtc_movie
    FOREIGN KEY (movie_id) REFERENCES sys_movie(movie_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- 角色-资源 → 角色（级联删除）
ALTER TABLE sys_role_resource ADD CONSTRAINT fk_rr_role
    FOREIGN KEY (role_id) REFERENCES sys_role(role_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- 角色-资源 → 资源（级联删除）
ALTER TABLE sys_role_resource ADD CONSTRAINT fk_rr_resource
    FOREIGN KEY (resource_id) REFERENCES sys_resource(resource_id) ON DELETE CASCADE ON UPDATE CASCADE;

SET FOREIGN_KEY_CHECKS = 1;
