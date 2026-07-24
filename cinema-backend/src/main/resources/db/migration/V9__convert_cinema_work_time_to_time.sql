-- ============================================
-- V9: sys_cinema.work_start_time, work_end_time VARCHAR → TIME
-- 'HH:mm' 格式字符串可直接转换为 TIME 类型
-- ============================================

ALTER TABLE sys_cinema MODIFY COLUMN work_start_time TIME NULL COMMENT '开始营业时间';
ALTER TABLE sys_cinema MODIFY COLUMN work_end_time TIME NULL COMMENT '结束营业时间';
