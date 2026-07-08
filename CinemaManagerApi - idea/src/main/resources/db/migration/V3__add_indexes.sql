-- ============================================
-- V3: 添加数据库索引
-- 为高频查询列添加索引，提升查询性能
-- ============================================

-- ----------------------------
-- sys_user: 登录 + 角色过滤
-- ----------------------------
CREATE INDEX idx_user_name ON sys_user(user_name);
CREATE INDEX idx_user_role_id ON sys_user(role_id);

-- ----------------------------
-- sys_bill: 订单查询 + 超时检测
-- ----------------------------
CREATE INDEX idx_bill_user_id ON sys_bill(user_id);
CREATE INDEX idx_bill_session_id ON sys_bill(session_id);
CREATE INDEX idx_bill_pay_cancel ON sys_bill(pay_state, cancel_state);

-- ----------------------------
-- sys_session: 场次查询 + 电影/影厅关联
-- ----------------------------
CREATE INDEX idx_session_hall_id ON sys_session(hall_id);
CREATE INDEX idx_session_movie_id ON sys_session(movie_id);
CREATE INDEX idx_session_date ON sys_session(session_date);
CREATE INDEX idx_session_del_state ON sys_session(del_state);

-- ----------------------------
-- sys_movie: 票房排行过滤
-- ----------------------------
CREATE INDEX idx_movie_release_date ON sys_movie(release_date);
CREATE INDEX idx_movie_area ON sys_movie(movie_area);

-- ----------------------------
-- sys_hall: 影院关联 + 软删除过滤
-- ----------------------------
CREATE INDEX idx_hall_cinema_id ON sys_hall(cinema_id);
CREATE INDEX idx_hall_del_state ON sys_hall(del_state);

-- ----------------------------
-- sys_resource: 权限树自连接
-- ----------------------------
CREATE INDEX idx_resource_parent_id ON sys_resource(parent_id);
CREATE INDEX idx_resource_level ON sys_resource(level);
