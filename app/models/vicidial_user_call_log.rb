class VicidialUserCallLog < Vicidial
  self.table_name = 'user_call_log'
  self.primary_key = 'user_call_log_id'

  # Метод для отчета 'Общая статистика вызовов' (summary_calls)
  def self.summary_metric_by_filter(search_args)
    @query = "SELECT
                COUNT(*) AS Transfered
              FROM user_call_log
              WHERE
                call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND call_type = 'XFER_3WAY'"
    find_by_sql(@query)
  end

end
