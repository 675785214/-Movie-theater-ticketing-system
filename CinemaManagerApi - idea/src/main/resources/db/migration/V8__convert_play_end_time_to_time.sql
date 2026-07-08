-- ============================================
-- V8: sys_session.play_time, end_time VARCHAR → TIME
-- 'HH:mm' 格式字符串可直接转换为 TIME 类型
-- ============================================

ALTER TABLE sys_session MODIFY COLUMN play_time TIME NOT NULL COMMENT '播放时间';
ALTER TABLE sys_session MODIFY COLUMN end_time TIME NOT NULL COMMENT '散场时间';
