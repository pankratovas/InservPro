module ReportsHelper
  def row_color(status)
    colors_hash = {
      park: "background: rgba(251,239,239,1);",
      queue: "background: rgba(232,223,248,1);",
      tway: "background: rgba(206,236,245,1);",
      dead: "background: rgba(189,189,189,1);",
      paused: "background: rgba(247,248,224,1)",
      dispo: "background: rgba(247,248,224,1);",
      incall: "background: rgba(246,206,206,1);",
      live: "background: rgba(246,206,206,1);",
      ready: "background: rgba(224,248,224,1);",
      closer: "background: rgba(224,248,224,1);",
      ivr: "background: rgba(206,236,245,1);",
      ring: "background: rgba(206,236,245,1);"
    }
    colors_hash[status.downcase.to_sym]
  end

  def status_name(status)
    @translation_hash = {incall: 'Разговор', xfer: 'Разговор', tway: 'Конференция', ring: 'Звонок', ready: 'Готов',
                         paused: 'Пауза', dispo: 'Постобработка', park: 'Удержание', dead: 'Отбой', closer: 'Готов', queue: 'Соединение',
                         inbound: 'Входящий', outbound: 'Исходящий', live: 'Очередь', ivr: 'Меню'}
    @translation_hash[status.downcase.to_sym]
  end

  def status_cname(status)
    @translation_hash = {incall: 'Разговор', xfer: 'Разговор', tway: 'Конференция', ring: 'Звонок', ready: 'Готов',
                         paused: 'Пауза', dispo: 'Постобработка', park: 'Удержание', dead: 'Отбой', closer: 'Разговор', queue: 'Соединение',
                         inbound: 'Входящий', outbound: 'Исходящий', live: 'Очередь', ivr: 'Меню'}
    @translation_hash[status.downcase.to_sym]
  end

  def detect_agent_status(agent)
    @status = agent.status
    if agent.lead_id != 0
      if VicidialLiveAgent.where(status: 'INCALL', lead_id: agent.lead_id).count > 1
        @status = 'TWAY'
      end
    end
    if agent.on_hook_agent == 'Y' && agent.ring_callerid.length > 18
      @status = "RING"
    end
    if (@status == 'READY' || @status == 'PAUSED') && agent.lead_id > 0
      @status = "DISPO"
    end
    if @status == 'INCALL'
      if VicidialParkedChannel.where(channel_group: agent.callerid).count > 0
        @status = 'PARK'
      else
        if VicidialLiveCall.where(callerid: agent.callerid).empty?
          @status = 'DEAD'
        end
      end
    end
    return @status
  end

  def detect_status_time(agent, status)
    if !['INCAL','QUEUE','PARK','TWAY'].include? status
      @status_time =  Time.at((Time.now - (agent.last_state_change.utc.strftime("%Y-%m-%d %H:%M:%S +0300").to_time)).to_i).utc.strftime("%H:%M:%S")
    elsif agent.status == 'TWAY'
      @recent_time = VicidialLiveAgent.where(status: 'INCALL', lead_id: agent.lead_id).first.last_call_time
      @status_time = Time.at((Time.now - (@recent_time.utc.strftime("%Y-%m-%d %H:%M:%S +0300").to_time)).to_i).utc.strftime("%H:%M:%S")
    else
      @status_time = Time.at((Time.now - (agent.last_call_time.utc.strftime("%Y-%m-%d %H:%M:%S +0300").to_time)).to_i).utc.strftime("%H:%M:%S")
    end
    return @status_time
  end

  def pause_code(pc)
    @pause_codes = {
      'ED' => 'Обучение',
      'PP' => 'Плановый перерыв',
      'VD' => 'Внесение данных',
      'LOGIN' => 'Вход в систему',
      'O' => 'Обед',
      'PRECAL' => 'Раб. перед вызовом',
      'LAGGED' => 'Зависшее сост.',
      'OG' => 'Опрос граждан'
    }
    @pause_codes[pc]
  end

  def record_path(call, direction)
    @sub_path = "\/"+call.location.to_s
    case direction
    when 'in'
      @record_path = "/STORAGE"+"#{@sub_path}"+"/"+"#{call.call_date.utc.strftime("%Y-%m-%d")}"+"/#{call.ingroup_id}"+"/#{call.filename}"+"-all.mp3"
    when 'out'
      @record_path = "/STORAGE"+"#{@sub_path}"+"/"+"#{call.call_date.utc.strftime("%Y-%m-%d")}"+"/#{call.campaign_id}"+"/#{call.filename}"+"-all.mp3"
    end
    return @record_path
  end

  def available_campaigns(user)
    VicidialCampaign.where(campaign_id: user.role.permissions[:campaigns]).order(:campaign_name).collect{|vc| [vc.campaign_name, vc.campaign_id]}
  end

  def available_ingroups(user)
    VicidialInboundGroup.where(group_id: user.role.permissions[:ingroups]).order(:group_name).collect{|vig| [vig.group_name, vig.group_id]}
  end

  def available_operators
    VicidialUser.all.order(:full_name).collect{|vu| [vu.full_name+" ("+vu.user+")", vu.user]}
  end

  def available_statuses(user)
    (VicidialCampaignStatus.where(campaign_id: user.role.permissions[:campaigns]).select(:status_name, :status).order(:status_name)+
      VicidialStatus.select(:status_name, :status).order(:status_name)).map{|s| [s.status_name+" ("+s.status+")", s.status]}
  end
end
