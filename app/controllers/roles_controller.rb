# frozen_string_literal: true

# Roles controller
class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_permissions_params, only: %i[create update]

  def index
    @roles = Role.all.paginate(page: params[:page], per_page: 20)
  end

  def new
    @role = Role.new
  end

  def create
    @role = Role.new(role_params)
    if @role.save
      redirect_to roles_path, notice: t(:role_created)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @role = Role.find(params[:id])
  end

  def update
    @role = Role.find(params[:id])
    if @role.update(role_params)
      redirect_to roles_path, notice: t(:role_updated)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @role = Role.find(params[:id])
    if @role.users.empty?
      @role.destroy
      redirect_to roles_path, notice: t(:role_deleted)
    else
      redirect_to roles_path, alert: t(:role_cant_be_deleted)
    end
  end



  private

  def role_params
    params.require(:role).permit(:name, { permissions: {} }, :description)
  end

  def set_permissions_params
    set_reports_params
    set_campaigns_params
    set_ingroups_params
  end

  def set_reports_params
    params[:role][:permissions][:reports] = [] if
      params[:role][:permissions][:reports].nil? || params[:role][:permissions][:reports].empty?
  end

  def set_campaigns_params
    params[:role][:permissions][:campaigns] = [] if
      params[:role][:permissions][:campaigns].nil? || params[:role][:permissions][:campaigns].empty?
  end

  def set_ingroups_params
    params[:role][:permissions][:ingroups] = [] if
      params[:role][:permissions][:ingroups].nil? || params[:role][:permissions][:ingroups].empty?
  end

end
