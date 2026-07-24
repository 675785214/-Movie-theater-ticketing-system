package com.cinema.mapper;

import com.cinema.domain.SysBill;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface SysBillMapper {

    List<SysBill> findAllBills(SysBill sysBill);

    /** 优化版：JOIN查询，消除N+1 */
    List<SysBill> findAllBillsJoin(SysBill sysBill);

    SysBill findBillById(Long id);

    int addBill(SysBill sysBill);

    int updateBill(SysBill sysBill);

    int deleteBill(Long id);

    List<SysBill> findTimeoutBill();

}
