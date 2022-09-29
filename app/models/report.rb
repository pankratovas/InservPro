class Report < ApplicationRecord

  # Статистика реального времени КЦ
  def realtime_report(filter = params[:filter], user)
    @result = 'ccenter'
  end

  # Входящие вызовы КЦ
  def inbound_calls(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @stop_date = filter[:stop_date]
    end
    if filter.blank? || filter[:ingroup].blank?
      @ingroup_query = " AND vicidial_closer_log.campaign_id IN (#{user.role.permissions["ingroups"].to_s[1..-2]})"
    else
      @ingroup_query = " AND vicidial_closer_log.campaign_id = '#{filter[:ingroup]}'"
    end
    if filter.blank? || filter[:operator].blank?
      @operator_query = ""
    else
      @operator_query = " AND vicidial_closer_log.user = '#{filter[:operator]}'"
    end
    if filter.blank? || filter[:status].blank?
      @status_query = ""
    else
      @status_query = " AND vicidial_closer_log.status = '#{filter[:status]}'"
    end
    if filter.blank? || filter[:phone].blank?
      @phone_query = ""
    else
      @phone_query = " AND vicidial_closer_log.phone_number LIKE '#{filter[:phone]}%'"
    end
    if filter.blank? || filter[:lead].blank?
      @lead_query = ""
    else
      @lead_query = " AND vicidial_closer_log.lead_id LIKE '#{filter[:lead]}%'"
    end
    @order_query = " ORDER BY vicidial_closer_log.call_date DESC"
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
                     recording_log.server_ip AS location
              FROM
                     vicidial_closer_log
              JOIN
                     vicidial_inbound_groups ON vicidial_closer_log.campaign_id = vicidial_inbound_groups.group_id
              JOIN
                     vicidial_users ON vicidial_closer_log.user = vicidial_users.user
              LEFT OUTER JOIN
                     recording_log ON vicidial_closer_log.lead_id = recording_log.lead_id AND vicidial_closer_log.closecallid = recording_log.vicidial_id
              WHERE
                     vicidial_closer_log.call_date BETWEEN '#{@start_date}' AND '#{@stop_date}'"+

      @ingroup_query+@operator_query+@status_query+@phone_query+@lead_query+@order_query
    @result = VicidialCloserLog.find_by_sql(@query)
    return @result
  end

  # Исходящие вызовы КЦ
  def outbound_calls(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @stop_date = filter[:stop_date]
    end
    if filter.blank? || filter[:campaign].blank?
      @campaign_query = " AND vicidial_log.campaign_id IN (#{user.role.permissions["campaigns"].to_s[1..-2]})"
    else
      @campaign_query = " AND vicidial_log.campaign_id = '#{filter[:campaign]}'"
    end
    if filter.blank? || filter[:operator].blank?
      @operator_query = ""
    else
      @operator_query = " AND vicidial_log.user = '#{filter[:operator]}'"
    end
    if filter.blank? || filter[:status].blank?
      @status_query = ""
    else
      @status_query = " AND vicidial_log.status = '#{filter[:status]}'"
    end
    if filter.blank? || filter[:phone].blank?
      @phone_query = ""
    else
      @phone_query = " AND vicidial_log.phone_number LIKE '#{filter[:phone]}%'"
    end
    if filter.blank? || filter[:lead].blank?
      @lead_query = ""
    else
      @lead_query = " AND vicidial_log.lead_id LIKE '#{filter[:lead]}%'"
    end
    @order_query = " ORDER BY vicidial_log.call_date DESC"
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
                     recording_log.server_ip AS location
              FROM
                     vicidial_log
              JOIN
                     vicidial_campaigns ON vicidial_log.campaign_id = vicidial_campaigns.campaign_id
              JOIN
                     vicidial_users ON vicidial_log.user = vicidial_users.user
              LEFT OUTER JOIN
                     recording_log ON vicidial_log.lead_id = recording_log.lead_id AND vicidial_log.uniqueid = recording_log.vicidial_id
              WHERE
                     vicidial_log.call_date BETWEEN '#{@start_date}' AND '#{@stop_date}'"+
      @campaign_query+@operator_query+@status_query+@phone_query+@lead_query+@order_query
    @result = VicidialLog.find_by_sql(@query)
    return @result

  end

  # Общая статистика вызовов КЦ
  def summary_calls(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @stop_date = filter[:stop_date]
    end
    if filter.blank? || filter[:campaign].blank?
      @campaign_query = " AND vicidial_log.campaign_id IN (#{user.role.permissions["campaigns"].to_s[1..-2]})"
      if filter.blank? || filter[:ingroup].blank?
        @ingroup_query = " AND vicidial_closer_log.campaign_id IN (#{user.role.permissions["ingroups"].to_s[1..-2]})"
      else
        @ingroup_query = " AND vicidial_closer_log.campaign_id = '#{filter[:ingroup]}'"
      end
    else
      @campaign_query = " AND vicidial_log.campaign_id = '#{filter[:campaign]}'"
      if filter.blank? || filter[:ingroup].blank?
        @ingroup_query = " AND vicidial_closer_log.campaign_id IN (#{(VicidialCampaign.find(filter[:campaign]).ingroups & user.role.permissions["ingroups"]).to_s[1..-2]})"
      else
        @ingroup_query = " AND vicidial_closer_log.campaign_id = '#{filter[:ingroup]}'"
      end
    end
    @query1 = "SELECT
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
                      SUM(IF(queue_seconds > 0, queue_seconds,0)) AS 'QueueTime'
               FROM
                      vicidial_closer_log
               WHERE
                      call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND status NOT IN ('MAXCAL','TIMEOT')"+@ingroup_query
    @query2 = "SELECT
                       COUNT(*) AS Transfered
                FROM
                       user_call_log
                WHERE
                       call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND call_type = 'XFER_3WAY'"
    @query3 = "SELECT
                       COUNT(*) AS OutboundCalls
                FROM
                       vicidial_log
                WHERE
                       call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND')"+@campaign_query
    @result1 = VicidialCloserLog.find_by_sql(@query1)
    @result2 = VicidialCloserLog.find_by_sql(@query2)
    @result3 = VicidialCloserLog.find_by_sql(@query3)
    @result = {
      date1: @start_date,
      date2: @stop_date,
      total_calls: @result1[0]["TotalCalls"],
      answered_calls: @result1[0]["Answered"],
      lcr: @result1[0]["TotalCalls"].to_f > 0 ? ((@result1[0]["Answered"].to_f/@result1[0]["TotalCalls"].to_f)*100).round(0) : 0,
      answered_in_20: @result1[0]["Answered20"],
      transfered: @result2[0]["Transfered"],
      outbound: @result3[0]["OutboundCalls"],
      avg_total_length: @result1[0]["TotalCalls"].to_f > 0 ? (@result1[0]["TotalLength"].to_f/@result1[0]["TotalCalls"].to_f).round(0) : 0,
      avg_queue_length: @result1[0]["Queued"].to_f > 0 ? (@result1[0]["QueueTime"].to_f/@result1[0]["Queued"].to_f).round(0) : 0,
      max_queue_length: @result1[0]["Max_queue"].to_i,
      min_queue_length: @result1[0]["Min_queue"].to_i,
      queue_0_3: @result1[0]["Queued_03"].to_i,
      queue_3_6: @result1[0]["Queued_36"].to_i,
      queue_6: @result1[0]["Queued_6"].to_i
    }
    return @result
  end

  # Быстрая общая статистика вызовов КЦ
  def summary_calls_preset(filter = params[:filter], user)
    if filter.blank? || filter[:campaign].blank?
      @campaign_query = " AND vicidial_log.campaign_id IN (#{user.role.permissions["campaigns"].to_s[1..-2]})"
      if filter.blank? || filter[:ingroup].blank?
        @ingroup_query = " AND vicidial_closer_log.campaign_id IN (#{user.role.permissions["ingroups"].to_s[1..-2]})"
      else
        @ingroup_query = " AND vicidial_closer_log.campaign_id = '#{filter[:ingroup]}'"
      end
    else
      @campaign_query = " AND vicidial_log.campaign_id = '#{filter[:campaign]}'"
      if filter.blank? || filter[:ingroup].blank?
        @ingroup_query = " AND vicidial_closer_log.campaign_id IN (#{(VicidialCampaign.find(filter[:campaign]).ingroups & user.role.permissions["ingroups"]).to_s[1..-2]})"
      else
        @ingroup_query = " AND vicidial_closer_log.campaign_id = '#{filter[:ingroup]}'"
      end
    end
    @result = {}
    [15, 30, 60, 1440].each do |min|
      @current_time = Time.now
      @start_date = (@current_time-min.minutes).strftime("%y-%m-%d %H:%M:%S")
      @stop_date = @current_time.strftime("%y-%m-%d %H:%M:%S")
      @query1 = "SELECT
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
                         SUM(IF(queue_seconds > 0, queue_seconds,0)) AS 'QueueTime'
                  FROM
                         vicidial_closer_log
                  WHERE
                         call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND status NOT IN ('MAXCAL','TIMEOT')"+@ingroup_query
      @query2 = "SELECT
                         COUNT(*) AS Transfered
                   FROM
                         user_call_log
                   WHERE
                         call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND call_type = 'XFER_3WAY'"
      @query3 = "SELECT
                         COUNT(*) AS OutboundCalls
                   FROM
                         vicidial_log
                   WHERE
                         call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND')"+@campaign_query
      @result1 = VicidialCloserLog.find_by_sql(@query1)
      @result2 = VicidialCloserLog.find_by_sql(@query2)
      @result3 = VicidialCloserLog.find_by_sql(@query3)
      @result[min]={
        total_calls: @result1[0]["TotalCalls"],
        answered_calls: @result1[0]["Answered"],
        lcr: @result1[0]["TotalCalls"].to_f > 0 ? ((@result1[0]["Answered"].to_f/@result1[0]["TotalCalls"].to_f)*100).round(0) : 0,
        answered_in_20: @result1[0]["Answered20"],
        transfered: @result2[0]["Transfered"],
        outbound: @result3[0]["OutboundCalls"],
        avg_total_length: @result1[0]["TotalCalls"].to_f > 0 ? (@result1[0]["TotalLength"].to_f/@result1[0]["TotalCalls"].to_f).round(0) : 0,
        avg_queue_length: @result1[0]["Queued"].to_f > 0 ? (@result1[0]["QueueTime"].to_f/@result1[0]["Queued"].to_f).round(0) : 0,
        max_queue_length: @result1[0]["Max_queue"].to_i,
        min_queue_length: @result1[0]["Min_queue"].to_i,
        queue_0_3: @result1[0]["Queued_03"].to_i,
        queue_3_6: @result1[0]["Queued_36"].to_i,
        queue_6: @result1[0]["Queued_6"].to_i
      }
    end
    return @result
  end

  # Детальная по операторам КЦ
  def agent_detailed(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @stop_date = filter[:stop_date]
    end
    @query1 = "SELECT
                        COUNT(*) AS 'TotalCalls',
                        SUM(talk_sec) AS 'TalkDur',
                        user AS 'SIP',
                        SUM(pause_sec) AS 'PauseDur',
                        SUM(dispo_sec) AS 'DispoDur',
                        SUM(wait_sec) AS 'WaitDur',
                        SUM(dead_sec) AS 'DeadDur',
                        status AS 'Status'
               FROM
                        vicidial_agent_log
               WHERE
                        event_time BETWEEN '#{@start_date}' AND '#{@stop_date}' AND pause_sec<65000 AND wait_sec<65000 AND talk_sec<65000 AND dispo_sec<65000 AND campaign_id = 'CCENTER' AND status IS NOT NULL
               GROUP BY
                        user"
    @query2 = "SELECT
                        user AS 'SIP',
                        SUM(pause_sec) AS 'Pause',
                        SUM(wait_sec + talk_sec + dispo_sec) AS 'NonPause',
                        sub_status AS 'PauseCode'
                FROM
                        vicidial_agent_log
                WHERE
                        event_time BETWEEN '#{@start_date}' AND '#{@stop_date}' AND pause_sec<65000 AND campaign_id = 'CCENTER'
                GROUP BY
                        user"
    @query3 = "SELECT DISTINCT sub_status AS 'PauseCode' FROM vicidial_agent_log WHERE event_time BETWEEN '#{@start_date}' AND '#{@stop_date}' AND pause_sec<65000 AND campaign_id = 'CCENTER'"
    @query4 = "SELECT
                        user AS 'SIP',
                        SUM(pause_sec) AS 'Pause',
                        sub_status AS 'PauseCode'
                FROM
                        vicidial_agent_log
                WHERE
                        event_time BETWEEN '#{@start_date}' AND '#{@stop_date}' AND pause_sec<65000 AND campaign_id = 'CCENTER'
                GROUP BY
                        user, sub_status"
    @result1 = VicidialCloserLog.find_by_sql(@query1)
    apd1 = {}
    @result1.each do |row|
      apd1[row['SIP']] = {
        user_calls: row['TotalCalls'].to_i,
        user_time: row['PauseDur'].to_i+row['WaitDur'].to_i+row['TalkDur'].to_i+row['DispoDur'].to_i+row['DeadDur'].to_i,
        user_pause: row['PauseDur'].to_i,
        user_avg_pause: (row['PauseDur'].to_f/row['TotalCalls'].to_f).round(0),
        user_wait: row['WaitDur'].to_i,
        user_avg_wait: (row['WaitDur'].to_f/row['TotalCalls'].to_f).round(0),
        user_talk: row['TalkDur'].to_i,
        user_avg_talk: (row['TalkDur'].to_f/row['TotalCalls'].to_f).round(0),
        user_dispo: row['DispoDur'].to_i,
        user_avg_dispo: (row['DispoDur'].to_f/row['TotalCalls'].to_f).round(0),
        user_dead: row['DeadDur'].to_i,
        user_avg_dead: (row['DeadDur'].to_f/row['TotalCalls'].to_f).round(0)
      }
    end
    apd1t= {
      total_calls: apd1.keys.each.map {|user| apd1[user][:user_calls] }.compact.inject{|sum,x| sum+x},
      total_time: apd1.keys.each.map {|user| apd1[user][:user_time] }.compact.inject{|sum,x| sum+x},
      total_pause: apd1.keys.each.map {|user| apd1[user][:user_pause] }.compact.inject{|sum,x| sum+x},
      total_avg_pause: begin (apd1.keys.each.map {|user| apd1[user][:user_pause] }.compact.inject{|sum,x| sum+x}.to_f/apd1.keys.each.map {|user| apd1[user][:user_calls] }.compact.inject{|sum,x| sum+x}.to_f).round(0) rescue 0 end,
      total_wait: apd1.keys.each.map {|user| apd1[user][:user_wait] }.compact.inject{|sum,x| sum+x},
      total_avg_wait: begin (apd1.keys.each.map {|user| apd1[user][:user_wait] }.compact.inject{|sum,x| sum+x}.to_f/apd1.keys.each.map {|user| apd1[user][:user_calls] }.compact.inject{|sum,x| sum+x}.to_f).round(0) rescue 0 end,
      total_talk: apd1.keys.each.map {|user| apd1[user][:user_talk] }.compact.inject{|sum,x| sum+x},
      total_avg_talk: begin (apd1.keys.each.map {|user| apd1[user][:user_talk] }.compact.inject{|sum,x| sum+x}.to_f/apd1.keys.each.map {|user| apd1[user][:user_calls] }.compact.inject{|sum,x| sum+x}.to_f).round(0) rescue 0 end,
      total_dispo: apd1.keys.each.map {|user| apd1[user][:user_dispo] }.compact.inject{|sum,x| sum+x},
      total_avg_dispo: begin (apd1.keys.each.map {|user| apd1[user][:user_dispo] }.compact.inject{|sum,x| sum+x}.to_f/apd1.keys.each.map {|user| apd1[user][:user_calls] }.compact.inject{|sum,x| sum+x}.to_f).round(0) rescue 0 end,
      total_dead: apd1.keys.each.map {|user| apd1[user][:user_dead] }.compact.inject{|sum,x| sum+x},
      total_avg_dead: begin (apd1.keys.each.map {|user| apd1[user][:user_dead] }.compact.inject{|sum,x| sum+x}.to_f/apd1.keys.each.map {|user| apd1[user][:user_calls] }.compact.inject{|sum,x| sum+x}.to_f).round(0) rescue 0 end
    }
    @result2 = VicidialCloserLog.find_by_sql(@query2)
    @pause_codes = VicidialCloserLog.find_by_sql(@query3).map { |x| x['PauseCode'] }
    @result4 = VicidialCloserLog.find_by_sql(@query4)
    apd2 = {}
    @result2.each do |row|
      apd2[row['SIP']] = {
        user_time: row['Pause'].to_i + row['NonPause'].to_i,
        user_pause: row['Pause'].to_i,
        user_nonpause: row['NonPause'].to_i,
      }
      @pause_codes.each do |pc|
        @result4.each do |str|
          apd2[row['SIP']][pc] = str['Pause'] if ((str['SIP'] == row['SIP']) & (str['PauseCode'] == pc))
        end
      end
    end
    apd2t = {}
    apd2t = {
      total_time: apd2.keys.each.map {|user| apd2[user][:user_time] }.compact.inject{|sum,x| sum+x},
      total_pause: apd2.keys.each.map {|user| apd2[user][:user_pause] }.compact.inject{|sum,x| sum+x},
      total_nonpause: apd2.keys.each.map {|user| apd2[user][:user_nonpause] }.compact.inject{|sum,x| sum+x}
    }
    @pause_codes.each do |pc|
      apd2t[pc] = apd2.keys.each.map {|user| apd2[user][pc] }.compact.inject{|sum,x| sum+x}
    end
    @result = {apd1: apd1, apd1t: apd1t, apd2: apd2, apd2t: apd2t, codes: @pause_codes }
    return @result
  end

  # Статистика за день
  def yesterday_report(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @start_date = (Time.now.beginning_of_day+8.hours+45.minutes).strftime("%Y-%m-%d %H:%M:%S")
      @stop_date = (Time.now.beginning_of_day+21.hours).strftime("%Y-%m-%d %H:%M:%S")
    else
      @start_date = (filter[:start_date].to_time.beginning_of_day+8.hours+45.minutes).strftime("%Y-%m-%d %H:%M:%S")
      @stop_date = (filter[:start_date].to_time.beginning_of_day+21.hours).strftime("%Y-%m-%d %H:%M:%S")
    end
    @ingroup_query = " AND campaign_id IN (#{user.role.permissions["ingroups"].to_s[1..-2]})"
    @query1 = "SELECT
                      count(*) AS TotalCalls,
                      SUM(length_in_sec) AS 'TotalLength',
                      SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND'),1,0)) as 'Answered',
                      SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND') AND queue_seconds < 20.0,1,0)) as 'Answered20',
                      SUM(IF(queue_seconds > 0, 1,0)) AS 'Queued',
                      MAX(queue_seconds) AS Max_queue,
                      MIN(queue_seconds) AS Min_queue,
                      SUM(IF(queue_seconds > 0, queue_seconds,0)) AS 'QueueTime'
               FROM
                      vicidial_closer_log
               WHERE
                      call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND status NOT IN ('MAXCAL','TIMEOT')"+@ingroup_query
    @result1 = VicidialCloserLog.find_by_sql(@query1)
    hash = {}
    ["08:45:00-09:59:59","10:00:00-10:59:59","11:00:00-11:59:59","12:00:00-12:59:59","13:00:00-13:59:59","14:00:00-14:59:59","15:00:00-15:59:59","16:00:00-16:59:59","17:00:00-17:59:59","18:00:00-18:59:59","19:00:00-19:59:59","20:00:00-20:59:59"].each do |i|
      t = i.split('-')
      start_date = @start_date.split(" ")[0]+" "+t[0]
      stop_date = @start_date.split(" ")[0]+" "+t[1]
      @query2 = "SELECT
                            count(*) AS TotalCalls,
                            SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND'),1,0)) as 'Answered'
                         FROM
                            vicidial_closer_log
                         WHERE
                            call_date BETWEEN '#{start_date}' AND '#{stop_date}' AND status NOT IN ('MAXCAL','TIMEOT')"+@ingroup_query
      @result2 = VicidialCloserLog.find_by_sql(@query2)
      hash[i] = {total_calls: @result2[0]["TotalCalls"], answered_calls: @result2[0]["Answered"]}
    end
    @result = {
      date1: @start_date.split(" ")[0],
      date2: @start_date.split(" ")[0],
      total_calls: @result1[0]["TotalCalls"],
      answered_calls: @result1[0]["Answered"],
      lcr: @result1[0]["TotalCalls"].to_f > 0 ? ((@result1[0]["Answered"].to_f/@result1[0]["TotalCalls"].to_f)*100).round(0) : 0,
      answered_in_20: @result1[0]["Answered20"],
      avg_total_length: @result1[0]["TotalCalls"].to_f > 0 ? (@result1[0]["TotalLength"].to_f/@result1[0]["TotalCalls"].to_f).round(0) : 0,
      avg_queue_length: @result1[0]["Queued"].to_f > 0 ? (@result1[0]["QueueTime"].to_f/@result1[0]["Queued"].to_f).round(0) : 0,
      max_queue_length: @result1[0]["Max_queue"].to_i,
      min_queue_length: @result1[0]["Min_queue"].to_i,
      hashdata: hash
    }
    return @result
  end

  # Статусы по операторам
  def statuses_by_user(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @stop_date = filter[:stop_date]
    end
    @query1 = "SELECT user, status, count(*) AS count FROM vicidial_closer_log WHERE call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND status NOT IN ('MAXCAL','TIMEOT','INCALL','DROP', 'DISPO') AND user != 'VDCL' GROUP BY user, status ORDER BY status"
    @query2 = "SELECT user, status, count(*) AS count FROM vicidial_log WHERE call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND status NOT IN ('MAXCAL','TIMEOT','INCALL','DROP', 'DISPO') AND user != 'VDAD' GROUP BY user, status ORDER BY status"
    @result1 = VicidialLog.find_by_sql(@query1)
    @result2 = VicidialLog.find_by_sql(@query2)
    result = [@result1, @result2]
    return result
  end

  # Вызовы с разбивкой по интервалам
  def calls_by_interval(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @date = (Time.now.beginning_of_day).strftime("%Y-%m-%d")
    else
      @date = (filter[:start_date].to_time.beginning_of_day).strftime("%Y-%m-%d")
    end
    @ingroup_query = " AND campaign_id IN (#{user.role.permissions["ingroups"].to_s[1..-2]})"
    data_hash = {}
    time_intervals = ["00:00:00-08:59:59","09:00:00-11:59:59","12:00:00-14:59:59","15:00:00-17:59:59","18:00:00-20:59:59","21:00:00-23:59:59"]
    time_intervals.each do |i|
      t = i.split('-')
      start_date = @date+" "+t[0]
      stop_date = @date+" "+t[1]
      @query1 = "SELECT
                        MIN(queue_seconds) AS Min_queue,
                        AVG(queue_seconds) AS Avg_queue,
                        MAX(queue_seconds) AS Max_queue,
                        SUM(IF(queue_seconds BETWEEN 0 AND 180, 1,0)) AS 'Queued_0_3',
                        SUM(IF(queue_seconds BETWEEN 180 AND 360, 1,0)) AS 'Queued_3_6',
                        SUM(IF(queue_seconds > 360, 1,0)) AS 'Queued_m6',
                        AVG(length_in_sec - queue_seconds) AS 'Avg_talk',
                        SUM(length_in_sec - queue_seconds) AS 'Sum_talk',
                        count(*) AS 'TotalCalls',
                        SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND'),1,0)) as 'Answered'
                 FROM
                        vicidial_closer_log
                 WHERE
                        call_date BETWEEN '#{start_date}' AND '#{stop_date}' AND status NOT IN ('MAXCAL','TIMEOT')"+@ingroup_query
      @result1 = VicidialCloserLog.find_by_sql(@query1)
      data_hash[i] = {
        min_queue: @result1[0]["Min_queue"].nil? ? 0 : @result1[0]["Min_queue"].round(0),
        avg_queue: @result1[0]["Avg_queue"].nil? ? 0 : @result1[0]["Avg_queue"].round(0),
        max_queue: @result1[0]["Max_queue"].nil? ? 0 : @result1[0]["Max_queue"].round(0),
        queue_0_3: @result1[0]["Queued_0_3"].nil? ? 0 : @result1[0]["Queued_0_3"].round(0),
        queue_3_6: @result1[0]["Queued_3_6"].nil? ? 0 : @result1[0]["Queued_3_6"].round(0),
        queue_m6: @result1[0]["Queued_m6"].nil? ? 0 : @result1[0]["Queued_m6"].round(0),
        avg_talk: @result1[0]["Avg_talk"].nil? ? 0 : @result1[0]["Avg_talk"].round(0),
        total_calls: @result1[0]["TotalCalls"].nil? ? 0 : @result1[0]["TotalCalls"].round(0),
        answered: @result1[0]["Answered"].nil? ? 0 : @result1[0]["Answered"].round(0),
        effectivity: @result1[0]["Sum_talk"].nil? ? 0 : (@result1[0]["Answered"].to_f/(@result1[0]["Sum_talk"].to_f/3600)).round(1)
      }
    end
    @result = data_hash
    return @result
  end

  # Статистика по оператору за период
  def operator_statistics(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @stop_date = filter[:stop_date]
    end
    if filter.blank? || filter[:operator].blank?
      @operator = VicidialUser.first.user
    else
      @operator = filter[:operator]
    end
    @query1 = "SELECT
                        SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND'),1,0)) AS 'Answered',
                        SUM(IF(term_reason = 'AGENT',1,0)) AS 'Term_by_oper'
               FROM
                        vicidial_closer_log
               WHERE
                        call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND status NOT IN ('MAXCAL','TIMEOT') AND user = '#{@operator}'"
    @query2 = "SELECT
                        COUNT(*) AS 'Outbound'
               FROM
                        vicidial_log
               WHERE
                        call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND user = '#{@operator}'"
    @query3 = "SELECT
                        SUM(IF(talk_sec > 300, 1,0)) AS 'Talk_m5',
                        MAX(talk_sec) AS 'Max_talk',
                        AVG(talk_sec) AS 'Avg_talk',
                        SUM(talk_sec+pause_sec+dispo_sec+wait_sec+dead_sec) AS 'Total_time',
                        SUM(talk_sec) AS 'Talk_time',
                        SUM(pause_sec) AS 'Pause_time',
                        SUM(IF(sub_status = 'O',pause_sec,0)) AS  'O_pause',
                        SUM(IF(sub_status = 'PP',pause_sec,0)) AS 'PP_pause',
                        SUM(IF(sub_status = 'OG',pause_sec,0)) AS 'OG_pause',
                        SUM(IF(sub_status = 'VD',pause_sec,0)) AS 'VD_pause',
                        SUM(IF(sub_status = 'ED',pause_sec,0)) AS 'ED_pause',
                        SUM(dispo_sec) AS 'Dispo_time'
                FROM
                        vicidial_agent_log
                WHERE
                        event_time BETWEEN '#{@start_date}' AND '#{@stop_date}' AND pause_sec<65000 AND wait_sec<65000 AND talk_sec<65000 AND dispo_sec<65000 AND campaign_id = 'CCENTER' AND status IS NOT NULL AND user = '#{@operator}'"
    @query4 = "SELECT
                        SUM(IF(call_type = 'XFER_3WAY',1,0)) AS 'Transfer_total',
                        SUM(IF(call_type = 'XFER_3WAY' AND  number_dialed LIKE 'Local/88%' ,1,0)) AS 'Transfer_oper'
               FROM
                        user_call_log
               WHERE
                        call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND user='#{@operator}'"
    @result1 = VicidialCloserLog.find_by_sql(@query1)
    @result2 = VicidialCloserLog.find_by_sql(@query2)
    @result3 = VicidialCloserLog.find_by_sql(@query3)
    @result4 = VicidialCloserLog.find_by_sql(@query4)
    data_hash = {
      user: @operator,
      answered: @result1[0]["Answered"].to_i,
      outbound: @result2[0]["Outbound"].to_i,
      talk_m5: @result3[0]["Talk_m5"].to_i,
      max_talk: @result3[0]["Max_talk"].to_i,
      avg_talk: @result3[0]["Avg_talk"].to_i,
      term_by_oper: @result1[0]["Term_by_oper"],
      transfer_total: @result4[0]["Transfer_total"].to_i,
      transfer_oper: @result4[0]["Transfer_oper"].to_i,
      total_time: @result3[0]["Total_time"],
      talk_time: @result3[0]["Talk_time"],
      pause_time: @result3[0]["Pause_time"],
      o_pause: @result3[0]["O_pause"],
      pp_pause: @result3[0]["PP_pause"],
      og_pause: @result3[0]["OG_pause"],
      vd_pause: @result3[0]["VD_pause"],
      ed_pause: @result3[0]["ED_pause"],
      dispo_time: @result3[0]["Dispo_time"],
      effectivity: @result3[0]["Talk_time"].nil? ? 0 : (@result1[0]["Answered"].to_f/(@result3[0]["Talk_time"].to_f/3600)).round(1)
    }
    @result = data_hash
    return @result
  end

  # Сводная статистика по операторам
  def all_operator_statistics(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @stop_date = filter[:stop_date]
    end
    data_hash = {}
    VicidialUser.all.order(:full_name).each do |operator|
      @query1 = "SELECT
                          SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND'),1,0)) AS 'Answered',
                          SUM(IF(term_reason = 'AGENT',1,0)) AS 'Term_by_oper'
                 FROM
                          vicidial_closer_log
                 WHERE
                          call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND status NOT IN ('MAXCAL','TIMEOT') AND user = '#{operator.user}'"
      @query2 = "SELECT
                          COUNT(*) AS 'Outbound'
                 FROM
                          vicidial_log
                 WHERE
                          call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND user = '#{operator.user}'"
      @query3 = "SELECT
                          SUM(IF(talk_sec > 300, 1,0)) AS 'Talk_m5',
                          MAX(talk_sec) AS 'Max_talk',
                          AVG(talk_sec) AS 'Avg_talk',
                          SUM(talk_sec+pause_sec+dispo_sec+wait_sec+dead_sec) AS 'Total_time',
                          SUM(talk_sec) AS 'Talk_time',
                          SUM(pause_sec) AS 'Pause_time',
                          SUM(IF(sub_status = 'O',pause_sec,0)) AS  'O_pause',
                          SUM(IF(sub_status = 'PP',pause_sec,0)) AS 'PP_pause',
                          SUM(IF(sub_status = 'OG',pause_sec,0)) AS 'OG_pause',
                          SUM(IF(sub_status = 'VD',pause_sec,0)) AS 'VD_pause',
                          SUM(IF(sub_status = 'ED',pause_sec,0)) AS 'ED_pause',
                          SUM(dispo_sec) AS 'Dispo_time'
                  FROM
                          vicidial_agent_log
                  WHERE
                          event_time BETWEEN '#{@start_date}' AND '#{@stop_date}' AND pause_sec<65000 AND wait_sec<65000 AND talk_sec<65000 AND dispo_sec<65000 AND campaign_id = 'CCENTER' AND status IS NOT NULL AND user = '#{operator.user}'"
      @query4 = "SELECT
                          SUM(IF(call_type = 'XFER_3WAY',1,0)) AS 'Transfer_total',
                          SUM(IF(call_type = 'XFER_3WAY' AND  number_dialed LIKE 'Local/88%' ,1,0)) AS 'Transfer_oper'
                 FROM
                          user_call_log
                 WHERE
                          call_date BETWEEN '#{@start_date}' AND '#{@stop_date}' AND user='#{operator.user}'"
      @result1 = VicidialCloserLog.find_by_sql(@query1)
      @result2 = VicidialCloserLog.find_by_sql(@query2)
      @result3 = VicidialCloserLog.find_by_sql(@query3)
      @result4 = VicidialCloserLog.find_by_sql(@query4)
      data_hash[operator.user] = {
        answered: @result1[0]["Answered"].to_i,
        outbound: @result2[0]["Outbound"].to_i,
        talk_m5: @result3[0]["Talk_m5"].to_i,
        max_talk: @result3[0]["Max_talk"].to_i,
        avg_talk: @result3[0]["Avg_talk"].to_i,
        term_by_oper: @result1[0]["Term_by_oper"].to_i,
        transfer_total: @result4[0]["Transfer_total"].to_i,
        transfer_oper: @result4[0]["Transfer_oper"].to_i,
        total_time: @result3[0]["Total_time"],
        talk_time: @result3[0]["Talk_time"],
        pause_time: @result3[0]["Pause_time"],
        o_pause: @result3[0]["O_pause"],
        pp_pause: @result3[0]["PP_pause"],
        og_pause: @result3[0]["OG_pause"],
        vd_pause: @result3[0]["VD_pause"],
        ed_pause: @result3[0]["ED_pause"],
        dispo_time: @result3[0]["Dispo_time"],
        effectivity: @result3[0]["Talk_time"].nil? ? 0 : (@result1[0]["Answered"].to_f/(@result3[0]["Talk_time"].to_f/3600)).round(1)
      }
    end
    @result = data_hash
    return @result
  end

  # Почасовой отчет по вызовам за день
  def calls_by_hour(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @date = (Time.now.beginning_of_day).strftime("%Y-%m-%d")
    else
      @date = (filter[:start_date].to_time.beginning_of_day).strftime("%Y-%m-%d")
    end
    @ingroup_query = " AND campaign_id IN (#{user.role.permissions["ingroups"].to_s[1..-2]})"
    data_hash = {}
    time_intervals = ["00:00:00-00:59:59","01:00:00-01:59:59","02:00:00-02:59:59","03:00:00-03:59:59","04:00:00-04:59:59","05:00:00-05:59:59",
                      "06:00:00-06:59:59","07:00:00-07:59:59","08:00:00-08:59:59","09:00:00-09:59:59","10:00:00-10:59:59","11:00:00-11:59:59",
                      "12:00:00-12:59:59","13:00:00-13:59:59","14:00:00-14:59:59","15:00:00-15:59:59","16:00:00-16:59:59","17:00:00-17:59:59",
                      "18:00:00-18:59:59","19:00:00-19:59:59","20:00:00-20:59:59","21:00:00-21:59:59","22:00:00-22:59:59","23:00:00-23:59:59"]
    time_intervals.each do |i|
      t = i.split('-')
      start_date = @date+" "+t[0]
      stop_date = @date+" "+t[1]
      @query1 = "SELECT
                        MIN(queue_seconds) AS Min_queue,
                        AVG(queue_seconds) AS Avg_queue,
                        MAX(queue_seconds) AS Max_queue,
                        SUM(IF(queue_seconds BETWEEN 0 AND 180, 1,0)) AS 'Queued_0_3',
                        SUM(IF(queue_seconds BETWEEN 180 AND 360, 1,0)) AS 'Queued_3_6',
                        SUM(IF(queue_seconds > 360, 1,0)) AS 'Queued_m6',
                        AVG(length_in_sec - queue_seconds) AS 'Avg_talk',
                        SUM(length_in_sec - queue_seconds) AS 'Sum_talk',
                        count(*) AS 'TotalCalls',
                        SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND'),1,0)) as 'Answered'
                 FROM
                        vicidial_closer_log
                 WHERE
                        call_date BETWEEN '#{start_date}' AND '#{stop_date}' AND status NOT IN ('MAXCAL','TIMEOT')"+@ingroup_query
      @result1 = VicidialCloserLog.find_by_sql(@query1)
      data_hash[i] = {
        min_queue: @result1[0]["Min_queue"].nil? ? 0 : @result1[0]["Min_queue"].round(0),
        avg_queue: @result1[0]["Avg_queue"].nil? ? 0 : @result1[0]["Avg_queue"].round(0),
        max_queue: @result1[0]["Max_queue"].nil? ? 0 : @result1[0]["Max_queue"].round(0),
        queue_0_3: @result1[0]["Queued_0_3"].nil? ? 0 : @result1[0]["Queued_0_3"].round(0),
        queue_3_6: @result1[0]["Queued_3_6"].nil? ? 0 : @result1[0]["Queued_3_6"].round(0),
        queue_m6: @result1[0]["Queued_m6"].nil? ? 0 : @result1[0]["Queued_m6"].round(0),
        avg_talk: @result1[0]["Avg_talk"].nil? ? 0 : @result1[0]["Avg_talk"].round(0),
        total_calls: @result1[0]["TotalCalls"].nil? ? 0 : @result1[0]["TotalCalls"].round(0),
        answered: @result1[0]["Answered"].nil? ? 0 : @result1[0]["Answered"].round(0),
        effectivity: @result1[0]["Sum_talk"].nil? ? 0 : (@result1[0]["Answered"].to_f/(@result1[0]["Sum_talk"].to_f/3600)).round(1)
      }
    end
    @result = data_hash
    return @result
  end

  # Отчет по КЦ за сутки
  def cc_daily(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @date = (Time.now.beginning_of_day).strftime("%Y-%m-%d")
    else
      @date = (filter[:start_date].to_time.beginning_of_day).strftime("%Y-%m-%d")
    end
    @ingroup_query = " AND campaign_id IN (#{user.role.permissions["ingroups"].to_s[1..-2]})"
    data_hash = {}
    time_intervals = ["00:00:00-08:59:59","09:00:00-17:59:59","18:00:00-23:59:59"]
    time_intervals.each do |i|
      t = i.split('-')
      start_date = @date+" "+t[0]
      stop_date = @date+" "+t[1]
      @query1 = "SELECT
                        MIN(queue_seconds) AS Min_queue,
                        AVG(queue_seconds) AS Avg_queue,
                        MAX(queue_seconds) AS Max_queue,
                        SUM(IF(queue_seconds BETWEEN 0 AND 180, 1,0)) AS 'Queued_0_3',
                        SUM(IF(queue_seconds BETWEEN 180 AND 360, 1,0)) AS 'Queued_3_6',
                        SUM(IF(queue_seconds > 360, 1,0)) AS 'Queued_m6',
                        AVG(length_in_sec - queue_seconds) AS 'Avg_talk',
                        SUM(length_in_sec - queue_seconds) AS 'Sum_talk',
                        count(*) AS 'TotalCalls',
                        SUM(IF(status NOT IN ('DROP','XDROP','HXFER','QVMAIL','HOLDTO','LIVE','QUEUE','TIMEOT','AFTHRS','NANQUE','INBND'),1,0)) as 'Answered'
                 FROM
                        vicidial_closer_log
                 WHERE
                        call_date BETWEEN '#{start_date}' AND '#{stop_date}' AND status NOT IN ('MAXCAL','TIMEOT')"+@ingroup_query
      @result1 = VicidialCloserLog.find_by_sql(@query1)
      data_hash[i] = {
        min_queue: @result1[0]["Min_queue"].nil? ? 0 : @result1[0]["Min_queue"].round(0),
        avg_queue: @result1[0]["Avg_queue"].nil? ? 0 : @result1[0]["Avg_queue"].round(0),
        max_queue: @result1[0]["Max_queue"].nil? ? 0 : @result1[0]["Max_queue"].round(0),
        queue_0_3: @result1[0]["Queued_0_3"].nil? ? 0 : @result1[0]["Queued_0_3"].round(0),
        queue_3_6: @result1[0]["Queued_3_6"].nil? ? 0 : @result1[0]["Queued_3_6"].round(0),
        queue_m6: @result1[0]["Queued_m6"].nil? ? 0 : @result1[0]["Queued_m6"].round(0),
        avg_talk: @result1[0]["Avg_talk"].nil? ? 0 : @result1[0]["Avg_talk"].round(0),
        total_calls: @result1[0]["TotalCalls"].nil? ? 0 : @result1[0]["TotalCalls"].round(0),
        answered: @result1[0]["Answered"].nil? ? 0 : @result1[0]["Answered"].round(0),
        effectivity: @result1[0]["Sum_talk"].nil? ? 0 : (@result1[0]["Answered"].to_f/(@result1[0]["Sum_talk"].to_f/3600)).round(1)
      }
    end
    @result = data_hash
    return @result
  end

  # Навыки операторов
  def agent_skills(filter = params[:filter], user)
    @ingroups = ['78122412000','callbk_oper','common','COVID2019','inbound','JE','KARELIYA','LENOBLAST','MEDIKI','SURDO','TSR','VNIM']
    @agents = VicidialUser.pluck(:user)
    data = {}
    @agents.each do |agent|
      data[agent] = {}
      @ingroups.each do |ingroup|
        @query1 = "SELECT group_rank AS 'rank',
                         group_grade AS 'grade'
                  FROM
                         vicidial_inbound_group_agents
                  WHERE
                         user = '#{agent}' AND group_id = '#{ingroup}'"
        @result1 = VicidialCloserLog.find_by_sql(@query1)
        data[agent][ingroup] = {
          rank: @result1.empty? ? '-' : @result1[0]["rank"],
          grade: @result1.empty? ? '-' : @result1[0]["grade"]
        }
      end
    end
    @result = [@agents, @ingroups, data]
    return @result
  end

  # Вызовы по регионам
  def calls_by_regions(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @stop_date = filter[:stop_date]
    end
    @order_query = " GROUP BY region_name ORDER BY campaign_id, region_name"
    @query = "SELECT t1.campaign_id,
                     COUNT(*) as count,
                     t3.region_name
              FROM vicidial_closer_log t1
              JOIN vicidial_list t2 on t1.lead_id= t2.lead_id left
              JOIN dict_regions t3 on t2.state=t3.id
              WHERE t1.call_date BETWEEN '#{@start_date}' AND '#{@stop_date}'"+@order_query
    @result = VicidialCloserLog.find_by_sql(@query)
    return @result
  end

  # Статусы по регионам
  def statuses_by_regions(filter = params[:filter], user)
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    else
      @stop_date = filter[:stop_date]
    end
    @group_query = "  GROUP BY region_name, status"
    @query1 = "SELECT
                     COUNT(*) as count,
                     t1.status,
                     t3.region_name
              FROM vicidial_closer_log t1
              JOIN vicidial_list t2 on t1.lead_id= t2.lead_id left
              JOIN dict_regions t3 on t2.state=t3.id
              WHERE t1.call_date BETWEEN '#{@start_date}' AND '#{@stop_date}'"+@group_query
    @query2 = "SELECT region_name FROM dict_regions ORDER BY region_name"
    @query3 = "SELECT status, status_name FROM vicidial_campaign_statuses WHERE campaign_id = 'ccenter' ORDER BY status"
    @data = VicidialCloserLog.find_by_sql(@query1)
    @regions = VicidialCloserLog.find_by_sql(@query2)
    @statuses = VicidialCloserLog.find_by_sql(@query3)
    result_hash = {}
    @regions.each do |r|
      region_hash = {}
      region_hash[r.region_name] = @data.each.map{ |d| {d['status'] => d['count']} if d['region_name'] == r.region_name }.compact
      total = @data.each.map{ |d| d['count'] if d['region_name'] == r.region_name }.compact.sum
      result_hash[r.region_name] = {}
      @statuses.each do |s|
        result_hash[r.region_name][s.status.to_sym] = region_hash[r.region_name].each.map{ |x| x[s.status] }.compact.sum
      end
      result_hash[r.region_name][:total] = total
    end
    return [result_hash,@statuses]
  end

end
