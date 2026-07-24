package com.cinema.service;

import com.cinema.domain.SysSession;
import com.cinema.domain.vo.SysSessionVo;

import java.util.List;


public interface SysSessionService {

    List<SysSession> findByVo(SysSessionVo sysSessionVo);

    List<SysSession> findSessionByMovieIdOrHallId(SysSession sysSession);

    SysSession findSessionById(Long id);

    SysSession findOneSession(Long id);

    int addSession(SysSession sysSession);

    int updateSession(SysSession sysSession);

    int deleteSession(Long[] id);

    List<SysSession> findSessionByMovieId(Long movieId);

}
