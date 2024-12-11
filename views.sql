
CREATE or replce
VIEW `v_item_master` AS
    SELECT 
        `mim`.`itm_id` AS `itm_id`,
        `mim`.`cat_id` AS `cat_id`,
        `mim`.`itm_item_no` AS `itm_item_no`,
        `mim`.`itm_name` AS `itm_name`,
        `mim`.`itsg_id` AS `itsg_id`,
        `misg`.`itsg_name` AS `itsg_name`,
        `mim`.`itg_id` AS `itg_id`,
        `mig`.`itg_name` AS `itg_name`,
        `mim`.`uom_id` AS `uom_id`,
        `mim`.`itm_opening_stock` AS `itm_opening_stock`,
        `mim`.`itm_is_active` AS `itm_is_active`
    FROM
        ((`test1` `mim`
        LEFT JOIN `test3` `mig` ON (`mim`.`itg_id` = `mig`.`itg_id`))
        LEFT JOIN `test2` `misg` ON (`mim`.`itsg_id` = `misg`.`itsg_id`))
    WHERE
        `mim`.`itm_active_flag` = 1
            AND `mim`.`cat_id` = 1
            AND `mim`.`itm_approved_status` = 'A';


CREATE or replce
VIEW `v_cip_object_details` AS
    SELECT 
        `objd`.`cipobjdet_id` AS `id`,
        `objd`.`cipobj_date` AS `date`,
        `objd`.`cipobj_end_date` AS `end_date`,
        `pro`.`cippro_name` AS `program_name`,
        `objd`.`cippro_id` AS `program_id`,
        `cir`.`cipcir_id` AS `circuit_id`,
        `cir`.`cipcir_name` AS `circuit_name`,
        `objd`.`cipobj_id` AS `object_id`,
        `obj`.`cipobj_name` AS `object_no`,
        `obj`.`cipobj_description` AS `object_name`,
        `objd`.`cip_not_done_rsn` AS `reason_id`,
        `rson`.`ciprsn_reason` AS `reason`,
        `objd`.`cipobj_start_time` AS `start_time`,
        `objd`.`cipobj_end_time` AS `end_time`,
        `objd`.`lye_supply_temp` AS `lye_supply_temp`,
        `objd`.`lye_return_temp` AS `lye_return_temp`,
        `objd`.`lye_conductivity` AS `lye_conductivity`,
        `objd`.`acid_supply_temp` AS `acid_supply_temp`,
        `objd`.`acid_return_temp` AS `acid_return_temp`,
        `objd`.`acid_conductivity` AS `acid_conductivity`,
        `objd`.`cipobj_final_conductivity` AS `final_conductivity`,
        `objd`.`cip_condition_flag` AS `flag`,
        `objd`.`schedule_type` AS `sche_id`,
        `sche`.`sche_type` AS `sche_type`,
        TIMEDIFF(COALESCE(CAST(`objd`.`cipobj_end_time` AS TIME),
                        '00:00:00'),
                COALESCE(CAST(`objd`.`cipobj_start_time` AS TIME),
                        '00:00:00')) AS `time_difference`
    FROM
        (((((`test4` `objd`
        LEFT JOIN `test5` `obj` ON (`obj`.`cipobj_id` = `objd`.`cipobj_id`))
        LEFT JOIN `test6` `cir` ON (`obj`.`cipcir_id` = `cir`.`cipcir_id`))
        LEFT JOIN `test7` `pro` ON (`pro`.`cippro_id` = `objd`.`cippro_id`))
        LEFT JOIN `test8` `sche` ON (`sche`.`sche_id` = `objd`.`schedule_type`))
        LEFT JOIN `test9` `rson` ON (`rson`.`ciprsn_id` = `objd`.`cip_not_done_rsn`))
    WHERE
        `objd`.`cipobj_end_time` IS NOT NULL
    ORDER BY `objd`.`cipobj_date` , `objd`.`cipobj_start_time`;


--- combination of two views
CREATE 
VIEW `test15` AS
    SELECT 
        `pro`.`prdpln_id` AS `prdpln_id`,
        ROUND(SUM(`pro`.`prdi_production`), 2) AS `prdi_actual_production`,
        ROUND(SUM(`pro`.`prdi_actual_production`), 2) AS `prdi_production`,
        ROUND(SUM(`pro`.`prdi_production_box_qty`), 2) AS `production_nos`
    FROM
        `production_items` `pro`
    GROUP BY `pro`.`prdpln_id`;

CREATE or replace
VIEW `batchwise_logbook` AS
    SELECT 
        IFNULL(`pd`.`prd_date`, '') AS `date`,
        IFNULL(`pd`.`prd_batch_no`, 0) AS `batch`,
        ROUND(IFNULL(`br`.`prdrfp_quantity`, 0.0), 2) AS `ecf`,
        ROUND(IFNULL(`pd`.`prd_leftover`, 0.0), 2) AS `leftover`,
        ROUND(IFNULL(`brq`.`prdreq_quantity`, 0.0), 2) AS `production_requisition`,
        ROUND(IFNULL(`br`.`prdrfp_quantity`, 0.0) + IFNULL(`brq`.`prdreq_quantity`, 0.0),
                2) AS `production_planning_total`,
        ROUND(IFNULL(IFNULL(`bp`.`prdi_actual_production`, 0.0) + IFNULL(`pd`.`prd_leftover`, 0.0),
                        0.0),
                2) AS `total_production`,
        ROUND(IFNULL(`br`.`prdrfp_quantity`, 0.0) + IFNULL(`brq`.`prdreq_quantity`, 0.0) - (IFNULL(`bp`.`prdi_actual_production`, 0.0) + IFNULL(`pd`.`prd_leftover`, 0.0)),
                2) AS `losses_in_kg`,
        ROUND((IFNULL(`br`.`prdrfp_quantity`, 0.0) + IFNULL(`brq`.`prdreq_quantity`, 0.0) - (IFNULL(`bp`.`prdi_actual_production`, 0.0) + IFNULL(`pd`.`prd_leftover`, 0.0))) / IFNULL(IFNULL(`bp`.`prdi_actual_production`, 0.0) + IFNULL(`pd`.`prd_leftover`, 0.0),
                        1) * 100,
                2) AS `losses_in_per`,
        ROUND((IFNULL(`bp`.`prdi_actual_production`, 0.0) + IFNULL(`pd`.`prd_leftover`, 0.0)) / (IFNULL(`br`.`prdrfp_quantity`, 0.0) + IFNULL(`brq`.`prdreq_quantity`, 0.0)) * 100,
                2) AS `yield_in_per`,
        IFNULL(`bp`.`production_nos`, 0.0) AS `production_nos`,
        `itsg`.`itsg_id` AS `itsg_id`,
        `itsg`.`itg_id` AS `itg_id`,
        `itsg`.`itsg_name` AS `itsg_name`,
        `pd`.`prdpln_id` AS `prdpln_id`
    FROM
        (((((`test11` `pd`
        LEFT JOIN `test12` `pp` ON (`pp`.`prdpln_id` = `pd`.`prdpln_id`))
        LEFT JOIN `test13` `itsg` ON (`itsg`.`itsg_id` = `pp`.`itsg_id`))
        LEFT JOIN `test14` `br` ON (`br`.`prdpln_id` = `pp`.`prdpln_id`))
        LEFT JOIN `test15` `bp` ON (`bp`.`prdpln_id` = `pp`.`prdpln_id`))
        LEFT JOIN `test16` `brq` ON (`brq`.`prdpln_id` = `pp`.`prdpln_id`));


