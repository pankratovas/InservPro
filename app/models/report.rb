class Report < ApplicationRecord

  # TEST
  def test_report(user, filter = params[:filter])
    filter[:ingroup] = user.permitted_ingroups if filter[:ingroup].blank?
    @inbound_calls = VicidialCloserLog.get_metrics(filter).first
  end



  # Вызовы в реальном времени
  def realtime_report(user, filter = params[:filter])
    @result = 'ccenter'
  end

  # Входящие вызовы
  def inbound_calls(user, filter = params[:filter])
    filter[:ingroup] = user.permitted_ingroups.join('\',\'') if filter[:ingroup].blank?
    @search_params = filter.compact_blank!
    @result = VicidialCloserLog.inbound_calls_by_filter(@search_params)
  end

  # Исходящие вызовы
  def outbound_calls(user, filter = params[:filter])
    filter[:campaign] = user.permitted_campaigns.join('\',\'') if filter[:campaign].blank?
    @search_params = filter.compact_blank!
    @result = VicidialLog.outbound_calls_by_filter(@search_params)
  end

  # Общая статистика
  def summary_calls(user, filter = params[:filter])
    if filter[:campaign].blank?
      filter[:campaign] = user.permitted_campaigns
      filter[:ingroup] = user.permitted_ingroups if filter[:ingroup].blank?
    elsif !filter[:campaign].blank? && filter[:ingroup].blank?
      filter[:ingroup] = (VicidialCampaign.find(filter[:campaign]).ingroups.map(&:group_id) & user.permitted_ingroups)
    end
    @inbound_metrics = VicidialCloserLog.summary_metrics(filter).first
    @transfer_metrics = VicidialUserCallLog.summary_metrics(filter).first
    @outbound_metrics = VicidialLog.summary_metrics(filter).first
    @result = {
      date1: filter[:start_date],
      date2: filter[:stop_date],
      total_calls_count: @inbound_metrics[:total_calls_count],
      answered_calls_count: @inbound_metrics[:answered_calls_count],
      lcr: calc_percent(@inbound_metrics[:answered_calls_count], @inbound_metrics[:total_calls_count]),
      answered_20_calls_count: @inbound_metrics[:answered_20_calls_count],
      transfered_calls_count: @transfer_metrics[:transfered_calls_count],
      outbound_calls_count: @outbound_metrics[:outbound_calls_count],
      avg_total_sec: calc_avg(@inbound_metrics[:total_length_sec], @inbound_metrics[:total_calls_count]),
      avg_queue_sec: @inbound_metrics[:avg_queue_sec].to_i,
      max_queue_sec: @inbound_metrics[:max_queue_sec].to_i,
      min_queue_sec: @inbound_metrics[:min_queue_sec].to_i,
      queued_0_180_count: @inbound_metrics[:queued_0_180_count].to_i,
      queued_180_360_count: @inbound_metrics[:queued_180_360_count].to_i,
      queued_360_count: @inbound_metrics[:queued_360_count].to_i
    }
  end

  # Общая статистика за сутки
  def summary_calls_24(user, filter = params[:filter])
    if filter[:campaign].blank?
      filter[:campaign] = user.permitted_campaigns
      filter[:ingroup] = user.permitted_ingroups if filter[:ingroup].blank?
    elsif !filter[:campaign].blank? && filter[:ingroup].blank?
      filter[:ingroup] = (VicidialCampaign.find(filter[:campaign]).ingroups.map(&:group_id) & user.permitted_ingroups)
    end
    @result = {}
    [15, 30, 60, 1440].each do |min|
      @current_time = Time.now
      filter[:start_date] = (@current_time - min.minutes).strftime(date_time_format)
      filter[:stop_date] = @current_time.strftime(date_time_format)
      @inbound_metrics = VicidialCloserLog.summary_metrics(filter).first
      @transfer_metrics = VicidialUserCallLog.summary_metrics(filter).first
      @outbound_metrics = VicidialLog.summary_metrics(filter).first
      @result[min] = {
        total_calls_count: @inbound_metrics[:total_calls_count],
        answered_calls_count: @inbound_metrics[:answered_calls_count],
        lcr: calc_percent(@inbound_metrics[:answered_calls_count], @inbound_metrics[:total_calls_count]),
        answered_20_calls_count: @inbound_metrics[:answered_20_calls_count],
        transfered_calls_count: @transfer_metrics[:transfered_calls_count],
        outbound_calls_count: @outbound_metrics[:outbound_calls_count],
        avg_total_sec: calc_avg(@inbound_metrics[:total_length_sec], @inbound_metrics[:total_calls_count]),
        avg_queue_sec: @inbound_metrics[:avg_queue_sec].to_i,
        max_queue_sec: @inbound_metrics[:max_queue_sec].to_i,
        min_queue_sec: @inbound_metrics[:min_queue_sec].to_i,
        queued_0_180_count: @inbound_metrics[:queued_0_180_count].to_i,
        queued_180_360_count: @inbound_metrics[:queued_180_360_count].to_i,
        queued_360_count: @inbound_metrics[:queued_360_count].to_i
      }
    end
    @result
  end

  # Детальный по операторам
  def operators_detailed(user, filter = params[:filter])
    filter[:campaign] = user.permitted_campaigns if filter[:campaign].blank?
    @agent_details = VicidialAgentLog.agent_details(filter)
    @pause_codes = VicidialAgentLog.pause_codes_array(filter)
    @agent_pauses = VicidialAgentLog.agent_pauses(filter)
    @agent_non_pauses = VicidialAgentLog.agent_non_pauses(filter)
    apd1 = {}
    @agent_details.each do |row|
      apd1[row[:user]] = {
        user_calls: row[:total_calls_count].to_i,
        user_time: row[:total_pause_sec].to_i +
                   row[:total_wait_sec].to_i +
                   row[:total_talk_sec].to_i +
                   row[:total_dispo_sec].to_i +
                   row[:total_dead_sec].to_i,
        user_pause: row[:total_pause_sec].to_i,
        user_avg_pause: (row[:total_pause_sec] / row[:total_calls_count].to_f).round(0),
        user_wait: row[:total_wait_sec].to_i,
        user_avg_wait: (row[:total_wait_sec] / row[:total_calls_count].to_f).round(0),
        user_talk: row[:total_talk_sec].to_i,
        user_avg_talk: (row[:total_talk_sec] / row[:total_calls_count].to_f).round(0),
        user_dispo: row[:total_dispo_sec].to_i,
        user_avg_dispo: (row[:total_dispo_sec] / row[:total_calls_count].to_f).round(0),
        user_dead: row[:total_dead_sec].to_i,
        user_avg_dead: (row[:total_dead_sec] / row[:total_calls_count].to_f).round(0)
      }
    end
    apd1t = {
      total_calls: apd1.keys.each.map { |usr| apd1[usr][:user_calls] }.compact.inject { |sum, x| sum + x },
      total_time: apd1.keys.each.map { |usr| apd1[usr][:user_time] }.compact.inject { |sum, x| sum + x },
      total_pause: apd1.keys.each.map { |usr| apd1[usr][:user_pause] }.compact.inject { |sum, x| sum + x },
      total_avg_pause:
        begin (apd1.keys.each.map { |usr| apd1[usr][:user_pause] }.compact.inject { |sum, x| sum + x } /
               apd1.keys.each.map { |usr| apd1[usr][:user_calls] }.compact.inject { |sum, x| sum + x }.to_f).round(0)
        rescue 0
        end,
      total_wait: apd1.keys.each.map { |usr| apd1[usr][:user_wait] }.compact.inject { |sum, x| sum + x },
      total_avg_wait:
        begin (apd1.keys.each.map { |usr| apd1[usr][:user_wait] }.compact.inject { |sum, x| sum + x} /
               apd1.keys.each.map { |usr| apd1[usr][:user_calls] }.compact.inject { |sum, x| sum + x}.to_f).round(0)
        rescue 0
        end,
      total_talk: apd1.keys.each.map { |usr| apd1[usr][:user_talk] }.compact.inject { |sum, x| sum + x },
      total_avg_talk:
        begin (apd1.keys.each.map { |usr| apd1[usr][:user_talk] }.compact.inject { |sum, x| sum + x } /
               apd1.keys.each.map { |usr| apd1[usr][:user_calls] }.compact.inject { |sum, x| sum + x }.to_f).round(0)
        rescue 0
        end,
      total_dispo: apd1.keys.each.map { |usr| apd1[usr][:user_dispo] }.compact.inject { |sum, x| sum + x },
      total_avg_dispo:
        begin (apd1.keys.each.map { |usr| apd1[usr][:user_dispo] }.compact.inject { |sum, x| sum + x } /
               apd1.keys.each.map { |usr| apd1[usr][:user_calls] }.compact.inject { |sum, x| sum + x }.to_f).round(0)
        rescue 0
        end,
      total_dead: apd1.keys.each.map { |usr| apd1[usr][:user_dead] }.compact.inject { |sum, x| sum + x },
      total_avg_dead:
        begin (apd1.keys.each.map { |usr| apd1[usr][:user_dead] }.compact.inject { |sum, x| sum + x } /
               apd1.keys.each.map { |usr| apd1[usr][:user_calls] }.compact.inject { |sum, x| sum + x }.to_f).round(0)
        rescue 0
        end
    }
    apd2 = {}
    @agent_non_pauses.each do |row|
      apd2[row[:user]] = {
        user_time: row[:total_pause_sec].to_i + row[:total_non_pause_sec].to_i,
        user_pause: row[:total_pause_sec].to_i,
        user_nonpause: row[:total_non_pause_sec].to_i
      }
      @pause_codes.each do |pc|
        @agent_pauses.each do |str|
          apd2[row[:user]][pc] = str[:total_pause_sec] if (str[:user] == row[:user]) & (str[:pause_code] == pc)
        end
      end
    end
    apd2t = {
      total_time: apd2.keys.each.map { |usr| apd2[usr][:user_time] }.compact.inject { |sum, x| sum + x },
      total_pause: apd2.keys.each.map { |usr| apd2[usr][:user_pause] }.compact.inject { |sum, x| sum + x },
      total_nonpause: apd2.keys.each.map { |usr| apd2[usr][:user_nonpause] }.compact.inject { |sum, x| sum + x }
    }
    @pause_codes.each do |pc|
      apd2t[pc] = apd2.keys.each.map { |usr| apd2[usr][pc] }.compact.inject { |sum, x| sum + x }
    end
    @result = { apd1: apd1, apd1t: apd1t, apd2: apd2, apd2t: apd2t, codes: @pause_codes }
  end

  # Вызовы за день
  def calls_by_day(user, filter = params[:filter])
    filter[:start_date] = (filter[:start_date].to_time.beginning_of_day + 8.hours + 45.minutes).strftime(date_time_format)
    filter[:stop_date] = (filter[:start_date].to_time.beginning_of_day + 21.hours).strftime(date_time_format)
    filter[:ingroup] = user.permitted_ingroups if filter[:ingroup].blank?
    @start_date = filter[:start_date]
    @day_calls = VicidialCloserLog.day_calls(filter).first
    hash = {}
    time_intervals = %w[08:45:00-09:59:59 10:00:00-10:59:59 11:00:00-11:59:59 12:00:00-12:59:59
                        13:00:00-13:59:59 14:00:00-14:59:59 15:00:00-15:59:59 16:00:00-16:59:59
                        17:00:00-17:59:59 18:00:00-18:59:59 19:00:00-19:59:59 20:00:00-20:59:59]
    time_intervals.each do |i|
      t = i.split('-')
      filter[:start_date] = "#{@start_date.split(' ')[0]} #{t[0]}"
      filter[:stop_date] = "#{@start_date.split(' ')[0]} #{t[1]}"
      @interval_calls = VicidialCloserLog.interval_calls(filter).first
      hash[i] = { total_calls_count: @interval_calls[:total_calls_count],
                  answered_calls_count: @interval_calls[:answered_calls_count] }
    end
    @result = {
      date1: @start_date.split(' ').first,
      date2: @start_date.split(' ').first,
      total_calls_count: @day_calls[:total_calls_count],
      answered_calls_count: @day_calls[:answered_calls_count],
      lcr: calc_percent(@day_calls[:answered_calls_count], @day_calls[:total_calls_count]),
      answered_20_calls_count: @day_calls[:answered_20_calls_count],
      avg_total_sec: calc_avg(@day_calls[:total_length_sec], @day_calls[:total_calls_count]),
      avg_queue_sec: calc_avg(@day_calls[:total_queue_sec], @day_calls[:queued_calls_count]),
      max_queue_sec: @day_calls[:max_queue_sec].to_i,
      min_queue_sec: @day_calls[:min_queue_sec].to_i,
      hashdata: hash
    }
  end

  # Статусы по операторам
  def statuses_by_user(user, filter = params[:filter])
    @inbound_statuses = VicidialCloserLog.statuses_by_user(filter)
    @outbound_statuses = VicidialLog.statuses_by_user(filter)
    [@inbound_statuses, @outbound_statuses]
  end

  # Вызовы с разбивкой по интервалам
  def calls_by_interval(user, filter = params[:filter])
    @date = filter[:start_date].to_time.beginning_of_day.strftime(date_format)
    filter[:ingroup] = user.permitted_ingroups if filter[:ingroup].blank?
    data_hash = {}
    time_intervals = %w[00:00:00-08:59:59 09:00:00-11:59:59 12:00:00-14:59:59
                        15:00:00-17:59:59 18:00:00-20:59:59 21:00:00-23:59:59]
    time_intervals.each do |i|
      t = i.split('-')
      filter[:start_date] = "#{@date} #{t[0]}"
      filter[:stop_date] = "#{@date} #{t[1]}"
      @inbound_calls = VicidialCloserLog.summary_metrics(filter).first
      data_hash[i] = {
        min_queue_sec: @inbound_calls[:min_queue_sec].to_i.round(0),
        avg_queue_sec: @inbound_calls[:avg_queue_sec].to_i.round(0),
        max_queue_sec: @inbound_calls[:max_queue_sec].to_i.round(0),
        queued_0_180_count: @inbound_calls[:queued_0_180_count].to_i.round(0),
        queued_180_360_count: @inbound_calls[:queued_180_360_count].to_i.round(0),
        queued_360_count: @inbound_calls[:queued_360_count].to_i.round(0),
        avg_talk_sec: @inbound_calls[:avg_talk_sec].to_i.round(0),
        total_calls_count: @inbound_calls[:total_calls_count].to_i.round(0),
        answered_calls_count: @inbound_calls[:answered_calls_count].to_i.round(0),
        effectivity: calc_effectivity(@inbound_calls[:answered_calls_count], @inbound_calls[:total_talk_sec])
      }
    end
    @result = data_hash
  end

  # По оператору за период
  def operator_by_period(user, filter = params[:filter])
    filter[:operator] = VicidialUser.first.user if filter[:operator].blank?
    @inbound_calls = VicidialCloserLog.operator_calls(filter).first
    @outbound_calls = VicidialLog.operator_calls(filter).first
    @operator_metrics = VicidialAgentLog.agent_metrics(filter).first
    @operator_transfers = VicidialUserCallLog.operator_transfers(filter).first
    data_hash = {
      operator: filter[:operator],
      answered_calls_count: @inbound_calls[:answered_calls_count].to_i,
      outbound_calls_count: @outbound_calls[:outbound_calls_count].to_i,
      talked_300_sec: @operator_metrics[:talked_300_sec].to_i,
      max_talk_sec: @operator_metrics[:max_talk_sec].to_i,
      avg_talk_sec: @operator_metrics[:avg_talk_sec].to_i,
      term_by_oper: @inbound_calls[:term_by_oper],
      total_transfered_calls: @operator_transfers[:total_transfered_calls].to_i,
      operator_transfered_calls: @operator_transfers[:operator_transfered_calls].to_i,
      total_time_sec: @operator_metrics[:total_time_sec],
      total_talk_sec: @operator_metrics[:total_talk_sec],
      total_pause_sec: @operator_metrics[:total_pause_sec],
      o_pause: @operator_metrics[:o_pause],
      pp_pause: @operator_metrics[:pp_pause],
      og_pause: @operator_metrics[:og_pause],
      vd_pause: @operator_metrics[:vd_pause],
      ed_pause: @operator_metrics[:ed_pause],
      total_dispo_sec: @operator_metrics[:total_dispo_sec],
      effectivity: calc_effectivity(@inbound_calls[:answered_calls_count], @operator_metrics[:total_talk_sec])
    }
    @result = data_hash
  end

  # По операторам за период
  def operators_by_period(user, filter = params[:filter])
    data_hash = {}
    VicidialUser.all.order(:full_name).each do |operator|
      filter[:operator] = operator.user
      @inbound_calls = VicidialCloserLog.operator_calls(filter).first
      @outbound_calls = VicidialLog.operator_calls(filter).first
      @operator_metrics = VicidialAgentLog.agent_metrics(filter).first
      @operator_transfers = VicidialUserCallLog.operator_transfers(filter).first
      data_hash[operator.user] = {
        answered_calls_count: @inbound_calls[:answered_calls_count].to_i,
        outbound_calls_count: @outbound_calls[:outbound_calls_count].to_i,
        talked_300_sec: @operator_metrics[:talked_300_sec].to_i,
        max_talk_sec: @operator_metrics[:max_talk_sec].to_i,
        avg_talk_sec: @operator_metrics[:avg_talk_sec].to_i,
        term_by_oper: @inbound_calls[:term_by_oper],
        total_transfered_calls: @operator_transfers[:total_transfered_calls].to_i,
        operator_transfered_calls: @operator_transfers[:operator_transfered_calls].to_i,
        total_time_sec: @operator_metrics[:total_time_sec],
        total_talk_sec: @operator_metrics[:total_talk_sec],
        total_pause_sec: @operator_metrics[:total_pause_sec],
        o_pause: @operator_metrics[:o_pause],
        pp_pause: @operator_metrics[:pp_pause],
        og_pause: @operator_metrics[:og_pause],
        vd_pause: @operator_metrics[:vd_pause],
        ed_pause: @operator_metrics[:ed_pause],
        total_dispo_sec: @operator_metrics[:total_dispo_sec],
        effectivity: calc_effectivity(@inbound_calls[:answered_calls_count], @operator_metrics[:total_talk_sec])
      }
    end
    @result = data_hash
  end

  # Вызовы по часам
  def calls_by_hour(user, filter = params[:filter])
    filter[:start_date] = filter[:start_date].to_time.beginning_of_day.strftime(date_format)
    filter[:ingroup] = user.permitted_ingroups if filter[:ingroup].blank?
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
      @inbound_calls = VicidialCloserLog.summary_metrics(filter).first
      data_hash[i] = {
        min_queue_sec: @inbound_calls[:min_queue_sec].to_i.round(0),
        avg_queue_sec: @inbound_calls[:avg_queue_sec].to_i.round(0),
        max_queue_sec: @inbound_calls[:max_queue_sec].to_i.round(0),
        queued_0_180_count: @inbound_calls[:queued_0_180_count].to_i.round(0),
        queued_180_360_count: @inbound_calls[:queued_180_360_count].to_i.round(0),
        queued_360_count: @inbound_calls[:queued_360_count].to_i.round(0),
        avg_talk_sec: @inbound_calls[:avg_talk_sec].to_i.round(0),
        total_calls_count: @inbound_calls[:total_calls_count].to_i.round(0),
        answered_calls_count: @inbound_calls[:answered_calls_count].to_i.round(0),
        effectivity: calc_effectivity(@inbound_calls[:answered_calls_count], @inbound_calls[:total_talk_sec])
      }
    end
    @result = data_hash
  end

  # Колл-центр за сутки
  def call_center_24(user, filter = params[:filter])
    filter[:start_date] = filter[:start_date].to_time.beginning_of_day.strftime(date_format)
    filter[:ingroup] = user.permitted_ingroups if filter[:ingroup].blank?
    @date = filter[:start_date]
    data_hash = {}
    time_intervals = %w[00:00:00-08:59:59 09:00:00-17:59:59 18:00:00-23:59:59]
    time_intervals.each do |i|
      t = i.split('-')
      filter[:start_date] = "#{@date} #{t[0]}"
      filter[:stop_date] = "#{@date} #{t[1]}"
      @inbound_calls = VicidialCloserLog.summary_metrics(filter).first
      data_hash[i] = {
        min_queue_sec: @inbound_calls[:min_queue_sec].to_i.round(0),
        avg_queue_sec: @inbound_calls[:avg_queue_sec].to_i.round(0),
        max_queue_sec: @inbound_calls[:max_queue_sec].to_i.round(0),
        queued_0_180_count: @inbound_calls[:queued_0_180_count].to_i.round(0),
        queued_180_360_count: @inbound_calls[:queued_180_360_count].to_i.round(0),
        queued_360_count: @inbound_calls[:queued_360_count].to_i.round(0),
        avg_talk_sec: @inbound_calls[:avg_talk_sec].to_i.round(0),
        total_calls_count: @inbound_calls[:total_calls_count].to_i.round(0),
        answered_calls_count: @inbound_calls[:answered_calls_count].to_i.round(0),
        effectivity: calc_effectivity(@inbound_calls[:answered_calls_count], @inbound_calls[:total_talk_sec])
      }
    end
    @result = data_hash
  end

  # Навыки операторов
  def operators_skills(user, filter = params[:filter])
    filter[:ingroup] = user.permitted_ingroups if filter[:ingroup].blank?
    filter[:operator] = VicidialUser.pluck(:user) if filter[:operator].blank?
    @skills = VicidialInboundGroupAgent.get_skills(filter)
    data = {}
    VicidialUser.get_users_ingroups_array(filter).each do |line|
      operator = line.first
      ingroups_str = line.last
      ingroups = ingroups_str.nil? || ingroups_str.empty? ? [] : ingroups_str[1..-3].split(' ')
      data[operator] = {}
      @skills.each do |row|
        if operator == row[:user] && ingroups.include?(row[:group_id])
          data[operator][row[:group_id]] = { rank: row[:rank], grade: row[:group_grade] }
        end
      end
    end
    data
  end

  def calls_by_regions(user, filter = params[:filter])
    @result = VicidialCloserLog.inbound_by_regions(filter)
  end

  # Статусы по регионам !!!!!!!!!!! только ФСС
  def statuses_by_regions(user, filter = params[:filter])
    @start_date = if filter.blank? || filter[:start_date].blank?
      Time.now.beginning_of_day.strftime(date_time_format)
    else
      filter[:start_date]
                  end
    @stop_date = if filter.blank? || filter[:stop_date].blank?
      Time.now.end_of_day.strftime(date_time_format)
    else
      filter[:stop_date]
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
    total.positive? ? (part / (total / 3600)).round(1) : 0
  end

end
