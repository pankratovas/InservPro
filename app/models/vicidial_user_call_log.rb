class VicidialUserCallLog < Vicidial
  self.table_name = 'user_call_log'
  self.primary_key = 'user_call_log_id'

  def self.summary_metrics(search_args)
    where(call_date: search_args[:start_date]..search_args[:stop_date],
          call_type: 'XFER_3WAY')
      .select('COUNT(*) AS transfered_calls_count')
  end


  def self.operator_transfers(search_args)
    where(call_date: search_args[:start_date]..search_args[:stop_date], user: search_args[:operator])
      .select("SUM(IF(call_type = 'XFER_3WAY',1,0)) AS total_transfered_calls",
              "SUM(IF(call_type = 'XFER_3WAY' AND  number_dialed LIKE 'Local/88%' ,1,0)) AS operator_transfered_calls")
  end

end
