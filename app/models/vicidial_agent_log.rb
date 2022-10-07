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

end
