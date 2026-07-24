package com.cinema.controller;

import com.cinema.common.exception.DataNotFoundException;
import com.cinema.common.response.ResponseResult;
import com.cinema.common.utils.ApplicationContextUtils;
import com.cinema.common.utils.JwtUtil;
import com.cinema.domain.SysBill;
import com.cinema.domain.SysMovie;
import com.cinema.domain.SysSession;
import com.cinema.domain.vo.SysBillVo;
import com.cinema.service.impl.SysBillServiceImpl;
import com.cinema.service.impl.SysMovieServiceImpl;
import com.cinema.service.impl.SysSessionServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 订单管理
 */
@RestController
public class SysBillController extends BaseController {

    @Autowired
    private SysBillServiceImpl sysBillService;

    @Autowired
    private SysSessionServiceImpl sysSessionService;

    @Autowired
    private SysMovieServiceImpl sysMovieService;

    @GetMapping("/sysBill")
    public ResponseResult findAllBills(SysBill sysBill) {
        // 自动根据当前登录用户过滤订单（管理员可看全部）
        String token = (String) SecurityUtils.getSubject().getPrincipal();
        if (token != null) {
            Long roleId = JwtUtil.getRoleId(token);
            // 非管理员用户，强制只查询自己的订单
            if (roleId == null || roleId != 1L) {
                Long userId = JwtUtil.getUserId(token);
                if (userId != null) {
                    sysBill.setUserId(userId);
                }
            }
        }
        startPage();
        // 取消所有超时订单并释放占座资源
        ApplicationContextUtils.getBean("cancelTimeoutBill");
        List<SysBill> data = sysBillService.findAllBills(sysBill);
        return getResult(data);
    }

    @GetMapping("/sysBill/{id}")
    public ResponseResult findBillById(@PathVariable Long id) {
        return getResult(sysBillService.findBillById(id));
    }

    @PostMapping("/sysBill")
    public ResponseResult addBill(@Validated @RequestBody SysBillVo sysBillVo) {
        // 获取当前场次信息
        SysSession curSession = sysSessionService.findOneSession(sysBillVo.getSysBill().getSessionId());
        if (curSession == null) {
            throw new DataNotFoundException("添加订单的场次没找到");
        }
        System.out.println(curSession.getSessionSeats());
        curSession.setSessionSeats(sysBillVo.getSessionSeats());

        int addSallNums = sysBillVo.getSysBill().getSeats().split(",").length;
        curSession.setSallNums(curSession.getSallNums() + addSallNums);
        // 更新场次座位信息
        sysSessionService.updateSession(curSession);

        Object obj = sysBillService.addBill(sysBillVo.getSysBill());
        if (obj instanceof Integer) {
            return getResult((Integer) obj);
        }
        return getResult(obj);
    }

    @PutMapping("/sysBill")
    public ResponseResult pay(@RequestBody SysBill sysBill) {
        int rows = sysBillService.updateBill(sysBill);
        if (rows > 0 && sysBill.getPayState()) {
            //更新场次的座位状态
            SysSession curSession = sysSessionService.findOneSession(sysBill.getSessionId());
            if (curSession == null) {
                throw new DataNotFoundException("支付订单的场次没找到");
            }
            //更新电影票房
            SysMovie curMovie = sysMovieService.findOneMovie(curSession.getMovieId());
            if (curMovie == null) {
                throw new DataNotFoundException("支付订单的电影没找到");
            }
            //订单的座位数
            int seatNum = sysBill.getSeats().split(",").length;
            double price = curSession.getSessionPrice();
            curMovie.setMovieBoxOffice(curMovie.getMovieBoxOffice() + seatNum * price);
            sysMovieService.updateMovie(curMovie);
        }
        return getResult(rows);
    }

    @PutMapping("/sysBill/cancel")
    public ResponseResult cancel(@RequestBody SysBillVo sysBillVo) {
        // 订单取消，更新订单状态
        int rows = sysBillService.updateBill(sysBillVo.getSysBill());
        if (rows > 0 && sysBillVo.getSysBill().getCancelState()) {
            // 订单取消座位不再占用，更新场次的座位状态
            SysSession curSession = sysSessionService.findOneSession(sysBillVo.getSysBill().getSessionId());
            // 取消的订单座位数
            int cancelSallNums = sysBillVo.getSysBill().getSeats().split(",").length;
            curSession.setSallNums(curSession.getSallNums() - cancelSallNums);
            if (curSession == null) {
                throw new DataNotFoundException("添加订单的场次没找到");
            }
            curSession.setSessionSeats(sysBillVo.getSessionSeats());
            sysSessionService.updateSession(curSession);
        }
        return getResult(rows);
    }

    @DeleteMapping("/sysBill/{ids}")
    public ResponseResult deleteBill(@PathVariable Long[] ids) {
        return getResult(sysBillService.deleteBill(ids));
    }

}
