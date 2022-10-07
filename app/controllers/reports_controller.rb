# frozen_string_literal: true

# Reports controller
class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_default_filter, only: :show

  def show
    @report = Report.find(params[:id])
    @filter = params[:filter]
    @layout = @report.name
    @user = current_user
    @result = @report.send(@report.name, @user, @filter)
    respond_to do |format|
      format.html
      # format.xls { convert_to_xls(@filter, @report, @user) }
    end
  end

  def realtime_statistics
    @campaign = 'ccenter'
    render partial: 'reports/realtime_statistics', object: @campaign
  end




  private

  def set_default_filter
    params[:filter] ||= {}
    params[:filter][:start_date] ||= Time.now.beginning_of_day.strftime('%Y-%m-%d %H:%M:%S')
    params[:filter][:stop_date] ||= Time.now.end_of_day.strftime('%Y-%m-%d %H:%M:%S')
  end

end
