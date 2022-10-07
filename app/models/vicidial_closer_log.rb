class VicidialCloserLog < Vicidial
  self.table_name = 'vicidial_closer_log'
  self.primary_key = 'closecallid'

  # Метод для отчета 'Входящие вызовы' (inbound_calls)
  def self.inbound_calls_by_filter(search_args)
    @query_parts = []
    search_args.each do |key, val|
      @query_parts << " AND vicidial_closer_log.user = '#{val}'" if key == 'operator'
      @query_parts << " AND vicidial_closer_log.status = '#{val}'" if key == 'status'
      @query_parts << " AND vicidial_closer_log.phone_number LIKE '#{val}%'" if key == 'phone'
      @query_parts << " AND vicidial_closer_log.lead_id LIKE '#{val}%'" if key == 'lead'
    end
    @query_parts << ' ORDER BY call_date DESC'
    @query = "SELECT
                vicidial_closer_log.lead_id AS lead_id,
                vicidial_closer_log.phone_number AS phone_number,
                vicidial_closer_log.call_date AS call_date,
                vicidial_closer_log.status AS status,
                vicidial_closer_log.user AS user,
                vicidial_users.full_name AS user_name,
                vicidial_closer_log.campaign_id AS ingroup_id,
                vicidial_inbound_groups.group_name AS ingroup_name,
                recording_log.length_in_sec AS record_duration,
                recording_log.filename AS filename,
                recording_log.location AS location
              FROM vicidial_closer_log
              JOIN vicidial_inbound_groups ON
                vicidial_closer_log.campaign_id = vicidial_inbound_groups.group_id
              JOIN vicidial_users ON
                vicidial_closer_log.user = vicidial_users.user
              LEFT OUTER JOIN recording_log ON
                vicidial_closer_log.lead_id = recording_log.lead_id AND
                vicidial_closer_log.closecallid = recording_log.vicidial_id
              WHERE
                vicidial_closer_log.call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND
                vicidial_closer_log.campaign_id IN
                ('#{search_args[:ingroup]}')" + @query_parts.join
    find_by_sql(@query)
  end

  # Метод для отчета 'Общая статистика вызовов' (summary_calls)
  def self.summary_metric_by_filter(search_args)
    @query = "SELECT
                count(*) AS TotalCalls,
                SUM(length_in_sec) AS 'TotalLength',
                SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND'),1,0)) as 'Answered',
                SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND') AND queue_seconds < 20.0,1,0)) as 'Answered20',
                SUM(IF(queue_seconds > 0, 1,0)) AS 'Queued',
                MAX(queue_seconds) AS Max_queue,
                MIN(queue_seconds) AS Min_queue,
                SUM(IF(queue_seconds <= 180, 1,0)) AS 'Queued_03',
                SUM(IF((queue_seconds > 180 AND queue_seconds <= 360), 1,0)) AS 'Queued_36',
                SUM(IF(queue_seconds > 360, 1,0)) AS 'Queued_6',
                SUM(IF(queue_seconds > 0, queue_seconds,0)) AS 'QueueTime',
                SUM(wait_sec + talk_sec + dispo_sec) AS 'NonPause',
                sub_status AS 'PauseCode'
              FROM vicidial_closer_log
              WHERE
                vicidial_closer_log.call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND status NOT IN ('MAXCAL','TIMEOT') AND
                vicidial_closer_log.campaign_id IN
                ('#{search_args[:ingroup]}')"
    find_by_sql(@query)
  end

end
