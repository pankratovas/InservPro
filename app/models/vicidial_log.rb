class VicidialLog < Vicidial
  self.table_name = 'vicidial_log'
  self.primary_key = 'uniqueid'

  # Метод для отчета 'Исходящие вызовы' (outbound_calls)
  def self.outbound_calls_by_filter(search_args)
    @query_parts = []
    search_args.each do |key, val|
      @query_parts << " AND vicidial_log.user = '#{val}'" if key == 'operator'
      @query_parts << " AND vicidial_log.status = '#{val}'" if key == 'status'
      @query_parts << " AND vicidial_log.phone_number LIKE '#{val}%'" if key == 'phone'
      @query_parts << " AND vicidial_log.lead_id LIKE '#{val}%'" if key == 'lead'
    end
    @query_parts << ' ORDER BY vicidial_log.call_date DESC'
    @query = "SELECT
                vicidial_log.lead_id AS lead_id,
                vicidial_log.phone_number AS phone_number,
                vicidial_log.call_date AS call_date,
                vicidial_log.status AS status,
                vicidial_log.user AS user,
                vicidial_users.full_name AS user_name,
                vicidial_log.campaign_id AS campaign_id,
                vicidial_campaigns.campaign_name AS campaign_name,
                recording_log.filename AS filename,
                recording_log.length_in_sec AS record_duration,
                recording_log.location AS location
              FROM vicidial_log
              JOIN vicidial_campaigns ON
                vicidial_log.campaign_id = vicidial_campaigns.campaign_id
              JOIN vicidial_users ON
                vicidial_log.user = vicidial_users.user
              LEFT OUTER JOIN recording_log ON
                vicidial_log.lead_id = recording_log.lead_id AND
                vicidial_log.uniqueid = recording_log.vicidial_id
              WHERE
                vicidial_log.call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND
                vicidial_log.campaign_id IN
                ('#{search_args[:campaign]}')" + @query_parts.join
    find_by_sql(@query)
  end

  # Метод для отчета 'Общая статистика вызовов' (summary_calls)
  def self.summary_metric_by_filter(search_args)
    @query = "SELECT
                COUNT(*) AS OutboundCalls
              FROM vicidial_log
              WHERE
                call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND
                status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE',
                'QUEUE','TIMEOT','AFTHRS','NANQUE','INBND') AND
                vicidial_log.campaign_id IN
                ('#{search_args[:campaign]}')"
    find_by_sql(@query)
  end

end
