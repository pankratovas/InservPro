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
      avg_total_length: calc_avg(@inbound_calls['TotalLength'], @inbound_calls['TotalCalls']),
      avg_queue_length: calc_avg(@inbound_calls['QueueTime'], @inbound_calls['Queued']),
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
        avg_total_length: calc_avg(@inbound_calls['TotalLength'], @inbound_calls['TotalCalls']),
        avg_queue_length: calc_avg(@inbound_calls['QueueTime'], @inbound_calls['Queued']),
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
    filter[:start_date] = (filter[:start_date].to_time.beginning_of_day + 8.hours + 45.minutes).strftime(date_time_format)
    filter[:stop_date] = (filter[:start_date].to_time.beginning_of_day + 21.hours).strftime(date_time_format)
    filter[:ingroup] = user.permitted_ingroups.join('\',\'') if filter[:ingroup].blank?
    @search_params = filter.compact_blank!
    @start_date = filter[:start_date]
    @day_calls = VicidialCloserLog.day_calls(@search_params).first
    hash = {}
    time_intervals = %w[08:45:00-09:59:59 10:00:00-10:59:59 11:00:00-11:59:59 12:00:00-12:59:59
                        13:00:00-13:59:59 14:00:00-14:59:59 15:00:00-15:59:59 16:00:00-16:59:59
                        17:00:00-17:59:59 18:00:00-18:59:59 19:00:00-19:59:59 20:00:00-20:59:59]
    time_intervals.each do |i|
      t = i.split('-')
      filter[:start_date] = "#{@start_date.split(' ')[0]} #{t[0]}"
      filter[:stop_date] = "#{@start_date.split(' ')[0]} #{t[1]}"
      @search_params_intervals = filter
      @interval_calls = VicidialCloserLog.interval_calls(@search_params_intervals).first
      hash[i] = { total_calls: @interval_calls['TotalCalls'], answered_calls: @interval_calls['Answered'] }
    end
    @result = {
      date1: @start_date.split(' ').first,
      date2: @start_date.split(' ').first,
      total_calls: @day_calls['TotalCalls'],
      answered_calls: @day_calls['Answered'],
      lcr: calc_percent(@day_calls['Answered'], @day_calls['TotalCalls']),
      answered_in_20: @day_calls['Answered20'],
      avg_total_length: calc_avg(@day_calls['TotalLength'], @day_calls['TotalCalls']),
      avg_queue_length: calc_avg(@day_calls['QueueTime'], @day_calls['Queued']),
      max_queue_length: @day_calls['Max_queue'].to_i,
      min_queue_length: @day_calls['Min_queue'].to_i,
      hashdata: hash
    }
  end

  # Статусы по операторам
  def statuses_by_user(user, filter = params[:filter])
    @search_params = filter.compact_blank!
    @inbound_statuses = VicidialCloserLog.statuses_by_user(@search_params)
    @outbound_statuses = VicidialLog.statuses_by_user(@search_params)
    [@inbound_statuses, @outbound_statuses]
  end

  # Вызовы с разбивкой по интервалам
  def calls_by_interval(user, filter = params[:filter])
    @date = filter[:start_date].to_time.beginning_of_day.strftime(date_format)
    filter[:ingroup] = user.permitted_ingroups.join('\',\'') if filter[:ingroup].blank?
    data_hash = {}
    time_intervals = %w[00:00:00-08:59:59 09:00:00-11:59:59 12:00:00-14:59:59
                        15:00:00-17:59:59 18:00:00-20:59:59 21:00:00-23:59:59]
    time_intervals.each do |i|
      t = i.split('-')
      filter[:start_date] = "#{@date} #{t[0]}"
      filter[:stop_date] = "#{@date} #{t[1]}"
      @search_params = filter.compact_blank!
      @inbound_calls = VicidialCloserLog.summary_metric_by_filter(@search_params).first
      data_hash[i] = {
        min_queue: @inbound_calls['Min_queue'].to_i.round(0),
        avg_queue: @inbound_calls['Avg_queue'].to_i.round(0),
        max_queue: @inbound_calls['Max_queue'].to_i.round(0),
        queue_0_3: @inbound_calls['Queued_03'].to_i.round(0),
        queue_3_6: @inbound_calls['Queued_36'].to_i.round(0),
        queue_m6: @inbound_calls['Queued_6'].to_i.round(0),
        avg_talk: @inbound_calls['Avg_talk'].to_i.round(0),
        total_calls: @inbound_calls['TotalCalls'].to_i.round(0),
        answered: @inbound_calls['Answered'].to_i.round(0),
        effectivity: calc_effectivity(@inbound_calls['Answered'], @inbound_calls['Sum_talk'])
      }
    end
    @result = data_hash
  end

  # Статистика по оператору за период
  def operator_statistics(user, filter = params[:filter])
    filter[:operator] = VicidialUser.first.user if filter[:operator].blank?
    @search_params = filter.compact_blank!
    @inbound_calls = VicidialCloserLog.operator_calls(@search_params).first
    @outbound_calls = VicidialLog.operator_calls(@search_params).first
    @operator_metrics = VicidialAgentLog.agent_metrics(@search_params).first
    @operator_transfers = VicidialUserCallLog.operator_transfers(@search_params).first
    data_hash = {
      user: filter[:operator],
      answered: @inbound_calls['Answered'].to_i,
      outbound: @outbound_calls['Outbound'].to_i,
      talk_m5: @operator_metrics['Talk_m5'].to_i,
      max_talk: @operator_metrics['Max_talk'].to_i,
      avg_talk: @operator_metrics['Avg_talk'].to_i,
      term_by_oper: @inbound_calls['Term_by_oper'],
      transfer_total: @operator_transfers['Transfer_total'].to_i,
      transfer_oper: @operator_transfers['Transfer_oper'].to_i,
      total_time: @operator_metrics['Total_time'],
      talk_time: @operator_metrics['Talk_time'],
      pause_time: @operator_metrics['Pause_time'],
      o_pause: @operator_metrics['O_pause'],
      pp_pause: @operator_metrics['PP_pause'],
      og_pause: @operator_metrics['OG_pause'],
      vd_pause: @operator_metrics['VD_pause'],
      ed_pause: @operator_metrics['ED_pause'],
      dispo_time: @operator_metrics['Dispo_time'],
      effectivity: calc_effectivity(@inbound_calls['Answered'], @operator_metrics['Talk_time'])
    }
    @result = data_hash
  end

  # Сводная статистика по операторам
  def all_operator_statistics(user, filter = params[:filter])
    data_hash = {}
    VicidialUser.all.order(:full_name).each do |operator|
      filter[:operator] = operator.user
      @search_params = filter.compact_blank!
      @inbound_calls = VicidialCloserLog.operator_calls(@search_params).first
      @outbound_calls = VicidialLog.operator_calls(@search_params).first
      @operator_metrics = VicidialAgentLog.agent_metrics(@search_params).first
      @operator_transfers = VicidialUserCallLog.operator_transfers(@search_params).first
      data_hash[operator.user] = {
        answered: @inbound_calls['Answered'].to_i,
        outbound: @outbound_calls['Outbound'].to_i,
        talk_m5: @operator_metrics['Talk_m5'].to_i,
        max_talk: @operator_metrics['Max_talk'].to_i,
        avg_talk: @operator_metrics['Avg_talk'].to_i,
        term_by_oper: @inbound_calls['Term_by_oper'],
        transfer_total: @operator_transfers['Transfer_total'].to_i,
        transfer_oper: @operator_transfers['Transfer_oper'].to_i,
        total_time: @operator_metrics['Total_time'],
        talk_time: @operator_metrics['Talk_time'],
        pause_time: @operator_metrics['Pause_time'],
        o_pause: @operator_metrics['O_pause'],
        pp_pause: @operator_metrics['PP_pause'],
        og_pause: @operator_metrics['OG_pause'],
        vd_pause: @operator_metrics['VD_pause'],
        ed_pause: @operator_metrics['ED_pause'],
        dispo_time: @operator_metrics['Dispo_time'],
        effectivity: calc_effectivity(@inbound_calls['Answered'], @operator_metrics['Talk_time'])
      }
    end
    @result = data_hash
  end

  # Почасовой отчет по вызовам за день
  def calls_by_hour(user, filter = params[:filter])
    filter[:start_date] = filter[:start_date].to_time.beginning_of_day.strftime(date_format)
    filter[:ingroup] = user.permitted_ingroups.join('\',\'') if filter[:ingroup].blank?
    @date = filter[:start_date]
    data_hash = {}
    time_intervals = %w[00:00:00-00:59:59 01:00:00-01:59:59 02:00:00-02:59:59
                        03:00:00-03:59:59 04:00:00-04:59:59 05:00:00-05:59:59
                        06:00:00-06:59:59 07:00:00-07:59:59 08:00:00-08:59:59
                        09:00:00-09:59:59 10:00:00-10:59:59 11:00:00-11:59:59
                        12:00:00-12:59:59 13:00:00-13:59:59 14:00:00-14:59:59
                        15:00:00-15:59:59 16:00:00-16:59:59 17:00:00-17:59:59
                        18:00:00-18:59:59 19:00:00-19:59:59 20:00:00-20:59:59
                        21:00:00-21:59:59 22:00:00-22:59:59 23:00:00-23:59:59]
    time_intervals.each do |i|
      t = i.split('-')
      filter[:start_date] = "#{@date} #{t[0]}"
      filter[:stop_date] = "#{@date} #{t[1]}"
      @search_params = filter.compact_blank!
      @inbound_calls = VicidialCloserLog.summary_metric_by_filter(@search_params).first
      data_hash[i] = {
        min_queue: @inbound_calls['Min_queue'].to_i.round(0),
        avg_queue: @inbound_calls['Avg_queue'].to_i.round(0),
        max_queue: @inbound_calls['Max_queue'].to_i.round(0),
        queue_0_3: @inbound_calls['Queued_03'].to_i.round(0),
        queue_3_6: @inbound_calls['Queued_36'].to_i.round(0),
        queue_m6: @inbound_calls['Queued_6'].to_i.round(0),
        avg_talk: @inbound_calls['Avg_talk'].to_i.round(0),
        total_calls: @inbound_calls['TotalCalls'].to_i.round(0),
        answered: @inbound_calls['Answered'].to_i.round(0),
        effectivity: calc_effectivity(@inbound_calls['Answered'], @inbound_calls['Sum_talk'])
      }
    end
    @result = data_hash
  end

  # Отчет по КЦ за сутки
  def cc_daily(user, filter = params[:filter])
    filter[:start_date] = filter[:start_date].to_time.beginning_of_day.strftime(date_format)
    filter[:ingroup] = user.permitted_ingroups.join('\',\'') if filter[:ingroup].blank?
    @date = filter[:start_date]
    data_hash = {}
    time_intervals = %w[00:00:00-08:59:59 09:00:00-17:59:59 18:00:00-23:59:59]
    time_intervals.each do |i|
      t = i.split('-')
      filter[:start_date] = "#{@date} #{t[0]}"
      filter[:stop_date] = "#{@date} #{t[1]}"
      @search_params = filter.compact_blank!
      @inbound_calls = VicidialCloserLog.summary_metric_by_filter(@search_params).first
      data_hash[i] = {
        min_queue: @inbound_calls['Min_queue'].to_i.round(0),
        avg_queue: @inbound_calls['Avg_queue'].to_i.round(0),
        max_queue: @inbound_calls['Max_queue'].to_i.round(0),
        queue_0_3: @inbound_calls['Queued_03'].to_i.round(0),
        queue_3_6: @inbound_calls['Queued_36'].to_i.round(0),
        queue_m6: @inbound_calls['Queued_6'].to_i.round(0),
        avg_talk: @inbound_calls['Avg_talk'].to_i.round(0),
        total_calls: @inbound_calls['TotalCalls'].to_i.round(0),
        answered: @inbound_calls['Answered'].to_i.round(0),
        effectivity: calc_effectivity(@inbound_calls['Answered'], @inbound_calls['Sum_talk'])
      }
    end
    @result = data_hash
  end

  # Навыки операторов !!!!!!!!!! только ФСС
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

  # Вызовы по регионам !!!!!!!!! только ФСС
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

  # Статусы по регионам !!!!!!!!!!! только ФСС
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

  def date_format
    '%Y-%m-%d'
  end

  def date_time_format
    '%Y-%m-%d %H:%M:%S'
  end

  def calc_percent(part, total)
    total = total.to_f
    part = part.to_f
    total.positive? ? (part / total * 100).round(0) : 0
  end

  def calc_avg(part, total)
    total = total.to_f
    part = part.to_f
    total.positive? ? (part / total).round(0) : 0
  end

  def calc_effectivity(part, total)
    total = total.to_f
    part = part.to_f
    total.positive? ? (part / total / 3600).round(1) : 0
  end

end
