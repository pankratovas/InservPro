class VicidialCloserLog < Vicidial
  self.table_name = 'vicidial_closer_log'
  self.primary_key = 'closecallid'

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

  def self.summary_metric_by_filter(search_args)
    @query = "SELECT
                count(*) AS TotalCalls,
                SUM(length_in_sec) AS 'TotalLength',
                SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND'),1,0)) as 'Answered',
                SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND') AND queue_seconds < 20.0,1,0)) as 'Answered20',
                SUM(IF(queue_seconds > 0, 1,0)) AS 'Queued',
                MAX(queue_seconds) AS Max_queue,
                AVG(queue_seconds) AS Avg_queue,
                MIN(queue_seconds) AS Min_queue,
                AVG(length_in_sec - queue_seconds) AS 'Avg_talk',
                SUM(length_in_sec - queue_seconds) AS 'Sum_talk',
                SUM(IF(queue_seconds BETWEEN 0 AND 180, 1,0)) AS 'Queued_03',
                SUM(IF(queue_seconds BETWEEN 180 AND 360, 1,0)) AS 'Queued_36',
                SUM(IF(queue_seconds > 360, 1,0)) AS 'Queued_6',
                SUM(IF(queue_seconds > 0, queue_seconds,0)) AS 'QueueTime'
              FROM vicidial_closer_log
              WHERE
                vicidial_closer_log.call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND status NOT IN ('MAXCAL','TIMEOT') AND
                vicidial_closer_log.campaign_id IN
                ('#{search_args[:ingroup]}')"
    find_by_sql(@query)
  end

  def self.day_calls(search_args)
    @query = "SELECT
                count(*) AS TotalCalls,
                SUM(length_in_sec) AS 'TotalLength',
                SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL',
                                      'HOLDTO','LIVE','QUEUE','TIMEOT',
                                      'AFTHRS','NANQUE','INBND'),1,0)) as 'Answered',
                SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL',
                                      'HOLDTO','LIVE','QUEUE','TIMEOT',
                                      'AFTHRS','NANQUE','INBND') AND queue_seconds < 20.0,1,0)) as 'Answered20',
                SUM(IF(queue_seconds > 0, 1,0)) AS 'Queued',
                MAX(queue_seconds) AS Max_queue,
                MIN(queue_seconds) AS Min_queue,
                SUM(IF(queue_seconds > 0, queue_seconds,0)) AS 'QueueTime'
              FROM vicidial_closer_log
              WHERE
                call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND
                status NOT IN ('MAXCAL','TIMEOT') AND
                vicidial_closer_log.campaign_id IN
                ('#{search_args[:ingroup]}')"
    find_by_sql(@query)
  end

  def self.interval_calls(search_args)
    @query = "SELECT
                count(*) AS TotalCalls,
                SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL',
                                      'HOLDTO','LIVE','QUEUE','TIMEOT',
                                      'AFTHRS','NANQUE','INBND'),1,0)) as 'Answered'
              FROM vicidial_closer_log
              WHERE
                call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND
                status NOT IN ('MAXCAL','TIMEOT') AND
                vicidial_closer_log.campaign_id IN
                ('#{search_args[:ingroup]}')"
    find_by_sql(@query)
  end

  def self.statuses_by_user(search_args)
    @query = "SELECT
                user,
                status,
                count(*) AS count
              FROM vicidial_closer_log
              WHERE call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND status NOT IN
                ('MAXCAL','TIMEOT','INCALL','DROP', 'DISPO') AND
                user != 'VDCL' GROUP BY user, status ORDER BY status"
    find_by_sql(@query)
  end

  def self.operator_calls(search_args)
    @query = "SELECT
                SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND'),1,0)) AS 'Answered',
                SUM(IF(term_reason = 'AGENT',1,0)) AS 'Term_by_oper'
              FROM
                vicidial_closer_log
              WHERE
                call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND
                status NOT IN ('MAXCAL','TIMEOT') AND
                user = '#{search_args[:operator]}'"
    find_by_sql(@query)
  end


  def self.summary_metrics(search_args)
    statuses = "'DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND'"
    where(call_date: search_args[:start_date]..search_args[:stop_date], campaign_id: search_args[:ingroup])
      .select('COUNT(*) AS total_calls_count',
              'SUM(length_in_sec) AS total_length_sec',
              "SUM(IF(status NOT IN (#{statuses}),1,0)) AS answered_calls_count",
              "SUM(IF(status NOT IN (#{statuses}) AND queue_seconds < 20.0,1,0)) AS answered_20_calls_count",
              'SUM(IF(queue_seconds > 0, 1,0)) AS queued_calls_count',
              'MAX(queue_seconds) AS max_queue_sec',
              'AVG(queue_seconds) AS avg_queue_sec',
              'MIN(queue_seconds) AS min_queue_sec',
              'AVG(length_in_sec - queue_seconds) AS avg_talk_sec',
              'SUM(length_in_sec - queue_seconds) AS total_talk_sec',
              'SUM(IF(queue_seconds BETWEEN 0 AND 180, 1,0)) AS queued_0_180_count',
              'SUM(IF(queue_seconds BETWEEN 180 AND 360, 1,0)) AS queued_180_360_count',
              'SUM(IF(queue_seconds > 360, 1,0)) AS queued_360_count',
              'SUM(IF(queue_seconds > 0, queue_seconds,0)) AS total_queue_sec')
  end

end
