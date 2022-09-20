class ReportsController < ApplicationController
  before_action :authenticate_user!

  def show
    @report = Report.find(params[:id])
    @filter = params[:filter]
    @layout = @report.name
    @user = current_user
    @result = @report.send(@report.name, @filter, @user)
    respond_to do |format|
      format.html
      #format.xls { convert_to_xls(@filter, @report, @user) }
    end
  end

  def realtime_statistics
    @campaign = 'ccenter'
    render partial: "reports/realtime_statistics", object: @campaign
  end
end
