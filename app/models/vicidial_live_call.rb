class VicidialLiveCall < Vicidial
  self.table_name = "vicidial_auto_calls"
  self.primary_key = "auto_call_id"
  
  def self.in_calls(user)
    where("call_type= ? AND status NOT IN (?) AND campaign_id IN (?)",'IN', ['XFER','CLOSER'], user.role.permissions[:ingroups])
    #where("call_type= ? AND status NOT IN (?)",'IN', ['XFER','CLOSER'])
  end

  def self.out_calls(user)
    where("call_type= ? AND status NOT IN (?)",'OUT', ['XFER','SENT'])
  end
  
end

