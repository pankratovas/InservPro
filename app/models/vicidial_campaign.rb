class VicidialCampaign < Vicidial
  self.table_name = 'vicidial_campaigns'
  self.primary_key = 'campaign_id'

  def self.all_campaigns
    VicidialCampaign.select(:campaign_id, :campaign_name, :closer_campaigns)
  end

  def ingroups
    VicidialInboundGroup.select(:group_id, :group_name).where(group_id: (self.closer_campaigns.split(' ')-['-']))
  end

  def statuses
    VicidialCampaignStatus.select(:status, :status_name).where(campaign_id: self.campaign_id) +
      VicidialStatus.select(:status, :status_name)
  end

  def statuses_hash
    hash = {}
    statuses.map { |s| hash[s.status] = s.status_name }
    hash
  end

  def self.all_statuses_map
    hash = {}
    all.map { |c| hash[c[:campaign_id]] = c.statuses_hash }
    hash
  end

end
