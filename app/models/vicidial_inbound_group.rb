class VicidialInboundGroup < Vicidial
  self.table_name = "vicidial_inbound_groups"
  self.primary_key = "group_id"
  
  def self.all_ingroups
    VicidialInboundGroup.select(:group_id, :group_name)
  end
  
  def campaign
    VicidialCampaign.all.each do |camp|
      @campaign = camp if (camp.closer_campaigns.split(" ")-["-"]).include?(self.group_id)
    end
    return @campaign
  end
  
  def statuses
    self.campaign.statuses_hash
  end
  
end