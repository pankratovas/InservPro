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

  def self.summary_metrics(search_args)
    where(call_date: search_args[:start_date]..search_args[:stop_date],
          call_type: 'XFER_3WAY')
      .select('COUNT(*) AS transfered_calls_count')
  end


  def self.operator_transfers(search_args)
    @query = "SELECT
                SUM(IF(call_type = 'XFER_3WAY',1,0)) AS 'Transfer_total',
                SUM(IF(call_type = 'XFER_3WAY' AND  number_dialed LIKE 'Local/88%' ,1,0)) AS 'Transfer_oper'
              FROM user_call_log
              WHERE
                call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND
                user = '#{search_args[:operator]}'"
    find_by_sql(@query)
  end

end
