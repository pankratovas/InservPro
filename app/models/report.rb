class Report < ApplicationRecord

  # TEST
  def test_report(user, filter = params[:filter])
    filter
  end

  # Входящие вызовы КЦ
  def inbound_calls(user, filter = params[:filter])
    filter[:ingroup] = user.permitted_ingroups.join('\',\'') if filter[:ingroup].blank?
    @search_params = filter.compact_blank!
    @result = VicidialCloserLog.inbound_calls_by_filter(@search_params)
  end

  # Исходящие вызовы КЦ
  def outbound_calls(user, filter = params[:filter])
    filter[:campaign] = user.permitted_campaigns.join('\',\'') if filter[:campaign].blank?
    @search_params = filter.compact_blank!
    @result = VicidialLog.outbound_calls_by_filter(@search_params)
  end

  # Общая статистика вызовов КЦ
  def summary_calls(user, filter = params[:filter])
    if filter[:campaign].blank?
      filter[:campaign] = user.permitted_campaigns.join('\',\'')
      filter[:ingroup] = user.permitted_ingroups.join('\',\'') if filter[:ingroup].blank?
    elsif !filter[:campaign].blank? && filter[:ingroup].blank?
      filter[:ingroup] = (VicidialCampaign.find(filter[:campaign]).ingroups.map(&:group_id) &
                          user.permitted_ingroups).join('\',\'')
    end
    @search_params = filter.compact_blank!
    @inbound_calls = VicidialCloserLog.summary_metric_by_filter(@search_params).first
    @transfer_calls = VicidialUserCallLog.summary_metric_by_filter(@search_params).first
    @outbound_calls = VicidialLog.summary_metric_by_filter(@search_params).first
    @result = {
      date1: filter[:start_date],
      date2: filter[:stop_date],
      total_calls: @inbound_calls['TotalCalls'],
      answered_calls: @inbound_calls['Answered'],
      lcr: calc_percent(@inbound_calls['Answered'], @inbound_calls['TotalCalls']),
      answered_in_20: @inbound_calls['Answered20'],
      transfered: @transfer_calls['Transfered'],
      outbound: @outbound_calls['OutboundCalls'],
      avg_total_length: calc_percent(@inbound_calls['TotalLength'], @inbound_calls['TotalCalls']),
      avg_queue_length: calc_percent(@inbound_calls['QueueTime'], @inbound_calls['Queued']),
      max_queue_length: @inbound_calls['Max_queue'].to_i,
      min_queue_length: @inbound_calls['Min_queue'].to_i,
      queue_0_3: @inbound_calls['Queued_03'].to_i,
      queue_3_6: @inbound_calls['Queued_36'].to_i,
      queue_6: @inbound_calls['Queued_6'].to_i
    }
  end

  # Быстрая общая статистика вызовов КЦ
  def summary_calls_preset(user, filter = params[:filter])
    if filter[:campaign].blank?
      filter[:campaign] = user.permitted_campaigns.join('\',\'')
      filter[:ingroup] = user.permitted_ingroups.join('\',\'') if filter[:ingroup].blank?
    elsif !filter[:campaign].blank? && filter[:ingroup].blank?
      filter[:ingroup] = (VicidialCampaign.find(filter[:campaign]).ingroups.map(&:group_id) &
        user.permitted_ingroups).join('\',\'')
    end
    @search_params = filter.compact_blank!
    @result = {}
    [15, 30, 60, 1440].each do |min|
      @current_time = Time.now
      filter[:start_date] = (@current_time - min.minutes).strftime(date_time_format)
      filter[:stop_date] = @current_time.strftime(date_time_format)
      @inbound_calls = VicidialCloserLog.summary_metric_by_filter(@search_params).first
      @transfer_calls = VicidialUserCallLog.summary_metric_by_filter(@search_params).first
      @outbound_calls = VicidialLog.summary_metric_by_filter(@search_params).first
      @result[min] = {
        total_calls: @inbound_calls['TotalCalls'],
        answered_calls: @inbound_calls['Answered'],
        lcr: calc_percent(@inbound_calls['Answered'], @inbound_calls['TotalCalls']),
        answered_in_20: @inbound_calls['Answered20'],
        transfered: @transfer_calls['Transfered'],
        outbound: @outbound_calls['OutboundCalls'],
        avg_total_length: calc_percent(@inbound_calls['TotalLength'], @inbound_calls['TotalCalls']),
        avg_queue_length: calc_percent(@inbound_calls['QueueTime'], @inbound_calls['Queued']),
        max_queue_length: @inbound_calls['Max_queue'].to_i,
        min_queue_length: @inbound_calls['Min_queue'].to_i,
        queue_0_3: @inbound_calls['Queued_03'].to_i,
        queue_3_6: @inbound_calls['Queued_36'].to_i,
        queue_6: @inbound_calls['Queued_6'].to_i
      }
    end
    @result
  end

  # Детальная по операторам КЦ
  def agent_detailed(user, filter = params[:filter])
    filter[:campaign] = user.permitted_campaigns.join('\',\'') if filter[:campaign].blank?
    @search_params = filter.compact_blank!
    @agent_details = VicidialAgentLog.agent_details(@search_params)
    @pause_codes = VicidialAgentLog.get_pause_codes(@search_params).map(&:PauseCode)
    @agent_pauses = VicidialAgentLog.agent_pauses(@search_params)
    apd1 = {}
    @agent_details.each do |row|
      apd1[row['SIP']] = {
        user_calls: row['TotalCalls'].to_i,
        user_time: row['PauseDur'].to_i +
                   row['WaitDur'].to_i +
                   row['TalkDur'].to_i +
                   row['DispoDur'].to_i +
                   row['DeadDur'].to_i,
        user_pause: row['PauseDur'].to_i,
        user_avg_pause: (row['PauseDur'] / row['TotalCalls'].to_f).round(0),
        user_wait: row['WaitDur'].to_i,
        user_avg_wait: (row['WaitDur'] / row['TotalCalls'].to_f).round(0),
        user_talk: row['TalkDur'].to_i,
        user_avg_talk: (row['TalkDur'] / row['TotalCalls'].to_f).round(0),
        user_dispo: row['DispoDur'].to_i,
        user_avg_dispo: (row['DispoDur'] / row['TotalCalls'].to_f).round(0),
        user_dead: row['DeadDur'].to_i,
        user_avg_dead: (row['DeadDur'] / row['TotalCalls'].to_f).round(0)
      }
    end
    apd1t = {
      total_calls: apd1.keys.each.map { |user| apd1[user][:user_calls] }.compact.inject { |sum, x| sum + x },
      total_time: apd1.keys.each.map { |user| apd1[user][:user_time] }.compact.inject { |sum, x| sum + x },
      total_pause: apd1.keys.each.map { |user| apd1[user][:user_pause] }.compact.inject { |sum, x| sum + x },
      total_avg_pause:
        begin (apd1.keys.each.map { |user| apd1[user][:user_pause] }.compact.inject { |sum, x| sum + x } /
               apd1.keys.each.map { |user| apd1[user][:user_calls] }.compact.inject { |sum, x| sum + x }.to_f).round(0)
        rescue 0
        end,
      total_wait: apd1.keys.each.map { |user| apd1[user][:user_wait] }.compact.inject { |sum, x| sum + x },
      total_avg_wait:
        begin (apd1.keys.each.map { |user| apd1[user][:user_wait] }.compact.inject { |sum, x| sum + x} /
               apd1.keys.each.map { |user| apd1[user][:user_calls] }.compact.inject { |sum, x| sum + x}.to_f).round(0)
        rescue 0
        end,
      total_talk: apd1.keys.each.map { |user| apd1[user][:user_talk] }.compact.inject { |sum, x| sum + x },
      total_avg_talk:
        begin (apd1.keys.each.map { |user| apd1[user][:user_talk] }.compact.inject { |sum, x| sum + x } /
               apd1.keys.each.map { |user| apd1[user][:user_calls] }.compact.inject { |sum, x| sum + x}.to_f).round(0)
        rescue 0
        end,
      total_dispo: apd1.keys.each.map { |user| apd1[user][:user_dispo] }.compact.inject { |sum, x| sum + x },
      total_avg_dispo:
        begin (apd1.keys.each.map { |user| apd1[user][:user_dispo] }.compact.inject { |sum, x| sum + x } /
               apd1.keys.each.map { |user| apd1[user][:user_calls] }.compact.inject { |sum, x| sum + x }.to_f).round(0)
        rescue 0
        end,
      total_dead: apd1.keys.each.map { |user| apd1[user][:user_dead] }.compact.inject { |sum, x| sum + x },
      total_avg_dead:
        begin (apd1.keys.each.map { |user| apd1[user][:user_dead] }.compact.inject{ |sum,x| sum + x } /
               apd1.keys.each.map { |user| apd1[user][:user_calls] }.compact.inject { |sum, x| sum + x }.to_f).round(0)
        rescue 0
        end
    }
    apd2 = {}
    @agent_details.each do |row|
      apd2[row['SIP']] = {
        user_time: row['Pause'].to_i + row['NonPause'].to_i,
        user_pause: row['Pause'].to_i,
        user_nonpause: row['NonPause'].to_i
      }
      @pause_codes.each do |pc|
        @agent_pauses.each do |str|
          apd2[row['SIP']][pc] = str['Pause'] if (str['SIP'] == row['SIP']) & (str['PauseCode'] == pc)
        end
      end
    end
    apd2t = {
      total_time: apd2.keys.each.map { |user| apd2[user][:user_time] }.compact.inject { |sum, x| sum + x },
      total_pause: apd2.keys.each.map { |user| apd2[user][:user_pause] }.compact.inject { |sum, x| sum + x },
      total_nonpause: apd2.keys.each.map { |user| apd2[user][:user_nonpause] }.compact.inject { |sum, x| sum + x }
    }
    @pause_codes.each do |pc|
      apd2t[pc] = apd2.keys.each.map { |user| apd2[user][pc] }.compact.inject { |sum, x| sum + x }
    end
    @result = { apd1: apd1, apd1t: apd1t, apd2: apd2, apd2t: apd2t, codes: @pause_codes }
  end

  # Статистика за день
  def yesterday_report(user, filter = params[:filter])
    if filter.blank? || filter[:start_date].blank?
      @start_date = (Time.now.beginning_of_day+8.hours+45.minutes).strftime(date_time_format)
      @stop_date = (Time.now.beginning_of_day+21.hours).strftime(date_time_format)
    else
      @start_date = (filter[:start_date].to_time.beginning_of_day+8.hours+45.minutes).strftime(date_time_format)
      @stop_date = (filter[:start_date].to_time.beginning_of_day+21.hours).strftime(date_time_format)
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
  def statuses_by_user(user, filter = params[:filter])
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime(date_time_format)
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime(date_time_format)
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
  def calls_by_interval(user, filter = params[:filter])
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
  def operator_statistics(user, filter = params[:filter])
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime(date_time_format)
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime(date_time_format)
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
  def all_operator_statistics(user, filter = params[:filter])
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime(date_time_format)
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime(date_time_format)
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
  def calls_by_hour(user, filter = params[:filter])
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
  def cc_daily(user, filter = params[:filter])
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
  def agent_skills(user, filter = params[:filter])
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
  def calls_by_regions(user, filter = params[:filter])
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime(date_time_format)
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime(date_time_format)
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
  def statuses_by_regions(user, filter = params[:filter])
    if filter.blank? || filter[:start_date].blank?
      @start_date = Time.now.beginning_of_day.strftime(date_time_format)
    else
      @start_date = filter[:start_date]
    end
    if filter.blank? || filter[:stop_date].blank?
      @stop_date = Time.now.end_of_day.strftime(date_time_format)
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
    [result_hash, @statuses]
  end

  # Статистика реального времени КЦ
  def realtime_report(user, filter = params[:filter])
    @result = 'ccenter'
  end



  private

  def date_time_format
    '%Y-%m-%d %H:%M:%S'
  end

  def calc_percent(part, total)
    total = total.to_f
    part = part.to_f
    total.positive? ? (part / total * 100).round(0) : 0
  end

end
