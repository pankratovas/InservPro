class VicidialAgentLog < Vicidial
  self.table_name = 'vicidial_agent_log'
  self.primary_key = 'agent_log_id'

  def self.agent_details(search_args)
    where(event_time: search_args[:start_date]..search_args[:stop_date], campaign_id: search_args[:campaign])
      .where('pause_sec < ? AND wait_sec < ? AND talk_sec < ? AND dispo_sec < ?', 65000, 65000, 65000, 65000)
      .where.not(status: nil)
      .select('COUNT(*) AS total_calls_count',
              'SUM(talk_sec) AS total_talk_sec',
              :user,
              :status,
              'SUM(pause_sec) AS total_pause_sec',
              'SUM(dispo_sec) AS total_dispo_sec',
              'SUM(wait_sec) AS total_wait_sec',
              'SUM(dead_sec) AS total_dead_sec')
      .group(:user)
  end

  def self.pause_codes_array(search_args)
    where(event_time: search_args[:start_date]..search_args[:stop_date], campaign_id: search_args[:campaign])
      .where('pause_sec < ? AND wait_sec < ? AND talk_sec < ? AND dispo_sec < ?', 65000, 65000, 65000, 65000)
      .select('sub_status AS pause_code').map(&:pause_code).uniq
  end

  def self.agent_non_pauses(search_args)
    where(event_time: search_args[:start_date]..search_args[:stop_date], campaign_id: search_args[:campaign])
      .where('pause_sec < ?', 65000)
      .select(:user,
              'SUM(pause_sec) AS total_pause_sec',
              'SUM(wait_sec + talk_sec + dispo_sec) AS total_non_pause_sec',
              'sub_status AS pause_code')
      .group(:user)

  end

  def self.agent_pauses(search_args)
    where(event_time: search_args[:start_date]..search_args[:stop_date], campaign_id: search_args[:campaign])
      .where('pause_sec < ?', 65000)
      .select('user AS user',
              'SUM(pause_sec) AS total_pause_sec',
              'sub_status AS pause_code')
      .group(:user, :sub_status)
  end

  def self.agent_metrics(search_args)
    where(event_time: search_args[:start_date]..search_args[:stop_date], user: search_args[:operator])
      .where('pause_sec < ? AND wait_sec < ? AND talk_sec < ? AND dispo_sec < ?', 65000, 65000, 65000, 65000)
      .where.not(status: nil)
      .select('SUM(IF(talk_sec > 300, 1,0)) AS talked_300_count',
              'MAX(talk_sec) AS max_talk_sec',
              'AVG(talk_sec) AS ag_talk_sec',
              'SUM(talk_sec+pause_sec+dispo_sec+wait_sec+dead_sec) AS total_time_sec',
              'SUM(talk_sec) AS total_talk_sec',
              'SUM(pause_sec) AS total_pause_sec',
              "SUM(IF(sub_status = 'O',pause_sec,0)) AS  o_pause",
              "SUM(IF(sub_status = 'PP',pause_sec,0)) AS pp_pause",
              "SUM(IF(sub_status = 'OG',pause_sec,0)) AS og_pause",
              "SUM(IF(sub_status = 'VD',pause_sec,0)) AS vd_pause",
              "SUM(IF(sub_status = 'ED',pause_sec,0)) AS ed_pause",
              'SUM(dispo_sec) AS total_dispo_sec')
  end

end
