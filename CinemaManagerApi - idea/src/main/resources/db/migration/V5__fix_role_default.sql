-- ============================================
-- V5: 修复 role_id 默认值 bug
-- 问题：sys_user.role_id DEFAULT 3，但不存在 role_id=3 的角色
-- 修复：修正现有用户 → 改默认值为 2（普通用户）
-- ============================================

-- 1. 修正 seed 用户 user (id=2) 的 role_id=3 → 2
UPDATE sys_user SET role_id = 2 WHERE role_id = 3;

-- 2. 修改列默认值
ALTER TABLE sys_user MODIFY COLUMN role_id bigint(20) UNSIGNED NOT NULL DEFAULT 2 COMMENT '角色编号';
