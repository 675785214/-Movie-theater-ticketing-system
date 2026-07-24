-- ============================================
-- V7: sys_session.deadline VARCHAR → DATETIME
-- 数据类型修正，MySQL 隐式转换 'yyyy-MM-dd HH:mm:ss' 格式兼容
-- ============================================

-- 现有数据格式为 'yyyy-MM-dd HH:mm:ss'，可直接 MODIFY
ALTER TABLE sys_session MODIFY COLUMN deadline DATETIME NULL COMMENT '截止时间，此时间之前不可删不可改';
