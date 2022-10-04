# frozen_string_literal: true

# Roles controller
class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_permissions_campaigns, only: %i[create update]
  before_action :check_permissions_ingroups, only: %i[create update]
  before_action :check_permissions_reports, only: %i[create update]

  def index
    @roles = Role.all.paginate(page: params[:page], per_page: 20)
  end

  def new
    @role = Role.new
  end

  def create
    @role = Role.new(role_params)
    if @role.save
      redirect_to roles_path
    else
      render :new
    end
  end

  def edit
    @role = Role.find(params[:id])
  end

  def update
    @role = Role.find(params[:id])
    if @role.update(role_params)
      redirect_to roles_path
    else
      render :edit
    end
  end



  private

  def role_params
    params.require(:role).permit(:name, { permissions: {} }, :description)
  end

  def check_permissions_reports
    params[:role][:permissions][:reports] = [] if
      params[:role][:permissions][:reports].nil? || params[:role][:permissions][:reports].empty?
  end

  def check_permissions_campaigns
    params[:role][:permissions][:campaigns] = [] if
      params[:role][:permissions][:campaigns].nil? || params[:role][:permissions][:campaigns].empty?
  end

  def check_permissions_ingroups
    params[:role][:permissions][:ingroups] = [] if
      params[:role][:permissions][:ingroups].nil? || params[:role][:permissions][:ingroups].empty?
  end

end
