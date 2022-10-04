class VicidialInboundGroup < Vicidial
  self.table_name = 'vicidial_inbound_groups'
  self.primary_key = 'group_id'

  def self.all_ingroups
    VicidialInboundGroup.select(:group_id, :group_name)
  end

  def campaign
    VicidialCampaign.all.each do |camp|
      @campaign = camp if (camp[:closer_campaigns].split(' ') - ['-']).include?(self[:group_id])
    end
    @campaign
  end

  def statuses
    campaign.statuses_hash
  end

  def self.all_map_hash
    hash = {}
    all.select(:group_id, :group_name).map do |i|
      hash[i[:group_id]] = { name: i[:group_name], campaign: i.campaign.nil? ? '-' : i.campaign[:campaign_id] }
    end
    hash
  end

end
