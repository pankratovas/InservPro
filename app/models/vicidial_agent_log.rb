class VicidialAgentLog < Vicidial
  self.table_name = 'vicidial_agent_log'
  self.primary_key = 'agent_log_id'

  def self.agent_details(search_args)
    @query = "SELECT
                COUNT(*) AS 'TotalCalls',
                SUM(talk_sec) AS 'TalkDur',
                user AS 'SIP',
                SUM(pause_sec) AS 'PauseDur',
                SUM(dispo_sec) AS 'DispoDur',
                SUM(wait_sec) AS 'WaitDur',
                SUM(dead_sec) AS 'DeadDur',
                status AS 'Status'
              FROM vicidial_agent_log
              WHERE
                event_time BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND
                pause_sec<65000 AND wait_sec<65000 AND talk_sec<65000 AND
                dispo_sec<65000 AND campaign_id IN ('#{search_args[:campaign]}')
                AND status IS NOT NULL
              GROUP BY
                user"
    find_by_sql(@query)
  end

  def self.get_pause_codes(search_args)
    @query = "SELECT DISTINCT
                sub_status AS 'PauseCode'
              FROM vicidial_agent_log
              WHERE
                event_time BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND
                pause_sec<65000 AND wait_sec<65000 AND talk_sec<65000 AND
                dispo_sec<65000 AND campaign_id IN ('#{search_args[:campaign]}')"
    find_by_sql(@query)
  end

  def self.agent_pauses(search_args)
    @query = "SELECT
                user AS 'SIP',
                SUM(pause_sec) AS 'Pause',
                sub_status AS 'PauseCode'
              FROM vicidial_agent_log
              WHERE
                event_time BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND pause_sec<65000 AND
                campaign_id IN ('#{search_args[:campaign]}')
              GROUP BY
                user, sub_status"
    find_by_sql(@query)
  end

  def self.agent_metrics(search_args)
    @query = "SELECT
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
              FROM vicidial_agent_log
              WHERE
                event_time BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND pause_sec<65000 AND wait_sec<65000 AND talk_sec<65000 AND
                dispo_sec<65000 AND campaign_id = 'CCENTER' AND status IS NOT NULL AND
                user = '#{search_args[:operator]}'"
    find_by_sql(@query)
  end

end
