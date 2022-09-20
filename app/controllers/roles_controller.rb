class RolesController < ApplicationController
  before_action :authenticate_user!

  def index
    @roles = Role.all.paginate(page: params[:page], per_page: 20)
  end

  def new
    @role = Role.new
  end

  def create
    if params[:role][:permissions][:reports].nil? || params[:role][:permissions][:reports].empty?
      params[:role][:permissions][:reports] = []
    end
    if params[:role][:permissions][:campaigns].nil? || params[:role][:permissions][:campaigns].empty?
      params[:role][:permissions][:campaigns] = []
    end
    if params[:role][:permissions][:ingroups].nil? || params[:role][:permissions][:ingroups].empty?
      params[:role][:permissions][:ingroups] = []
    end
    @role = Role.new(role_params)
    if @role.save
      redirect_to roles_path
    else
      flash.now[:error] = "#{@role.errors.full_messages.join(', ')}"
      render action: :new
    end
  end

  def edit
    @role = Role.find(params[:id])
  end

  def update
    @role = Role.find(params[:id])
    if params[:role][:permissions][:reports].nil? || params[:role][:permissions][:reports].empty?
      params[:role][:permissions][:reports] = []
    end
    if params[:role][:permissions][:campaigns].nil? || params[:role][:permissions][:campaigns].empty?
      params[:role][:permissions][:campaigns] = []
    end
    if params[:role][:permissions][:ingroups].nil? || params[:role][:permissions][:ingroups].empty?
      params[:role][:permissions][:ingroups] = []
    end
    if @role.update(role_params)
      redirect_to roles_path
    else
      flash.now[:error] = "#{@role.errors.full_messages.join(', ')}"
      render action: :edit
    end
  end



  private

  def role_params
    params.require(:role).permit(:name, {:permissions => {}}, :description)
  end
end
