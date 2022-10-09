class VicidialUser < Vicidial
  self.table_name = 'vicidial_users'
  self.primary_key = 'user_id'

  def self.get_users_ingroups_array(search_args)
    where(user: search_args[:operator]).pluck(:user, :closer_campaigns)
  end

end
