class VicidialInboundGroupAgent < Vicidial
  self.table_name = 'vicidial_inbound_group_agents'
  self.primary_key = 'user'

  def self.get_skills(search_arg)
    # !!! ключ :group_rank зарезервирован? Выдает вместо релаьных int значений true/false
    where(group_id: search_arg[:ingroup], user: search_arg[:operator])
      .select(:user, :group_id, 'group_rank AS rank', :group_grade)
      .group(:user, :group_id)
  end

end
