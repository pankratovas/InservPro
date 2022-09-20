class VicidialCampaign < VicidialRecord
  self.table_name = "vicidial_campaigns"
  self.primary_key = "campaign_id"

  def self.all_campaigns
    VicidialCampaign.select(:campaign_id, :campaign_name, :closer_campaigns)
  end

  def ingroups
    VicidialInboundGroup.select(:group_id, :group_name).where(group_id: (self.closer_campaigns.split(" ")-["-"]))
  end

  def statuses
    VicidialCampaignStatus.select(:status, :status_name).where(campaign_id: self.campaign_id) +
      VicidialStatus.select(:status, :status_name)
  end

  def statuses_hash
    h = {}
    self.statuses.map{|s| h[s.status]=s.status_name}
    return h
  end
end
