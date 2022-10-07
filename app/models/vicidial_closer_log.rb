class VicidialCloserLog < Vicidial
  self.table_name = 'vicidial_closer_log'
  self.primary_key = 'closecallid'

  def self.inbound_calls_by_filter(search_args)
    @query_parts = []
    search_args.each do |key, val|
      @query_parts << " AND vicidial_closer_log.user = '#{val}'" if key == 'operator'
      @query_parts << " AND vicidial_closer_log.status = '#{val}'" if key == 'status'
      @query_parts << " AND vicidial_closer_log.phone_number LIKE '#{val}%'" if key == 'phone'
      @query_parts << " AND vicidial_closer_log.lead_id LIKE '#{val}%'" if key == 'lead'
    end
    @query_parts << ' ORDER BY call_date DESC'
    @query = "SELECT
                vicidial_closer_log.lead_id AS lead_id,
                vicidial_closer_log.phone_number AS phone_number,
                vicidial_closer_log.call_date AS call_date,
                vicidial_closer_log.status AS status,
                vicidial_closer_log.user AS user,
                vicidial_users.full_name AS user_name,
                vicidial_closer_log.campaign_id AS ingroup_id,
                vicidial_inbound_groups.group_name AS ingroup_name,
                recording_log.length_in_sec AS record_duration,
                recording_log.filename AS filename,
                recording_log.location AS location
              FROM vicidial_closer_log
              JOIN vicidial_inbound_groups ON
                vicidial_closer_log.campaign_id = vicidial_inbound_groups.group_id
              JOIN vicidial_users ON
                vicidial_closer_log.user = vicidial_users.user
              LEFT OUTER JOIN recording_log ON
                vicidial_closer_log.lead_id = recording_log.lead_id AND
                vicidial_closer_log.closecallid = recording_log.vicidial_id
              WHERE
                vicidial_closer_log.call_date BETWEEN
                '#{search_args[:start_date]}' AND
                '#{search_args[:stop_date]}' AND
                vicidial_closer_log.campaign_id IN
                ('#{search_args[:ingroup]}')" + @query_parts.join
    find_by_sql(@query)
  end

end
