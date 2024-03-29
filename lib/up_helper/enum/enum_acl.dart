enum AclScope {
  self,
  global,

  project_evs2_pa,

  sg_all,
  project_evs2_nus,
  project_evs2_sutd,
  project_evs2_ntu,

  project_ems_smrt,

  project_ems_cw_nus,

  site_pa_atp,

  site_nus_pgpr,
  site_nus_ync,
  site_nus_rvrc,
  site_sutd_campus,
  site_ntu_mr,

  site_smrt_clementi,
  site_smrt_dover,
  site_smrt_buona_vista,
  site_smrt_commonwealth,
  site_smrt_queenstown,
}

enum AclTarget {
  //acl v1
  // meter,
  // meter_info,
  // meter_rls,
  // meter_comm,
  // evs2user,
  // evs2_acl_role,
  // evs2_acl_permission,
  // meter_last_reading,
  // meter_kwh_history,
  // meter_reading_daily,
  // evs2user_profile,
  // credit_balance,
  // meter_month_to_date_usage,
  // meter_consumer_transaction_history,
  // meter_consumer_tariff_history,

  //acl v2
  meter_p_entity,
  meter_p_reading,
  meter_p_info,
  meter_p_detail,
  meter_p_rls,
  meter_p_credit_balance,
  meter_p_month_to_date_kwh_usage,
  meter_p_bypass_policy,
  meter_p_conc,
  meter_p_sn,
  meter_p_kiv,
  meter_p_tariff,
  meter_p_reading_daily,
  meter_p_reading_history_full,
  meter_p_daily_reading_history_full,
  meter_p_last_reading,
  meter_p_comm_status,
  meter_p_trending_est_option,
  meter_p_consumption,
  meter_p_batch_update,
  meter_p_cpc_policy,
  meter_p_aclock_status,
  meter_p_lc_status,

  concentrator_p_entity,
  concentrator_p_info,
  concentrator_p_tariff,

  sensor_p_entity,
  sensor_p_reading,
  sensor_p_info,
  sensor_p_reading_history_full,

  evs2user_p_entity,
  evs2user_p_role,
  evs2user_p_profile,
  evs2user_p_enabled,
  evs2user_p_password,
  evs2user_p_credit_balance,
  evs2user_p_topup_history_3months,
  evs2user_p_transaction_history_3months,
  evs2user_p_topup_history_full,
  evs2user_p_transaction_history_full,

  evs2_acl_role_p_entity,
  evs2_acl_scope_p_entity,
  evs2_acl_role_p_profile,
  evs2_acl_role_p_permission,

  evs2_ops_dashboard_p_entity,
  evs2_ops_dashboard_p_topup_history,
  evs2_ops_dashboard_p_top_kwh_rank,
  evs2_ops_dashboard_p_recent_total_topup,
  evs2_ops_dashboard_p_recent_total_kwh,
  evs2_ops_dashboard_p_recent_total_comm_data,
  evs2_ops_dashboard_p_active_count,
  evs2_ops_dashboard_p_mms_stat,
  evs2_ops_dashboard_p_kwh_history,
  evs2_ops_dashboard_p_comm_stat,
  evs2_ops_dashboard_p_active_count_history,
  evs2_ops_dashboard_p_recent_active_count,

  evs2_ops_meter_manager_p_entity,
  evs2_ops_meter_manager_p_meter_info_list_pane_switch,

  tenant_p_entity,
  tenant_p_info,
  tenant_p_usage,
  tenant_p_tariff,

  site_p_entity,
  site_p_info,

  meter_group_p_entity,
  meter_group_p_info,
  meter_group_p_usage,

  alarm_p_entity,
  alarm_p_info,

  job_type_p_entity,
  job_type_p_info,

  job_p_entity,
  job_p_info,

  job_type_subscriber_p_entity,
  job_type_subscriber_p_info,

  bill_p_entity,
  bill_p_info,
}

enum AclOperation {
  create,
  read,
  update,
  delete,
  list,
  full,
}
