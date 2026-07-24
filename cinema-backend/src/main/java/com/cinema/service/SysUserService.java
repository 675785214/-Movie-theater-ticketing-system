package com.cinema.service;

import com.cinema.domain.LoginUser;
import com.cinema.domain.SysUser;
import com.cinema.domain.vo.SysUserVo;

import java.util.List;


public interface SysUserService {
    List<SysUser> findAllUsers(SysUser sysUser);

    SysUser findUserById(Long id);

    SysUser findUserByName(String userName);

    int addUser(SysUser sysUser);

    int updateUser(SysUser sysUser);

    int deleteUser(Long[] ids);

    LoginUser login(SysUserVo sysUserVo);

    LoginUser findLoginUser(SysUserVo sysUserVo);

    boolean isUserNameUnique(String userName, Long userId);
}
