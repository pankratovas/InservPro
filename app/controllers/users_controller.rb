# frozen_string_literal: true

# Users controller
class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.find(params[:id])
  end

  def index
    @users = User.search(params[:filter]).paginate(page: params[:page], per_page: 20)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path, notice: t(:user_created)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to users_path, notice: t(:user_updated)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user = User.find(params[:id])
    if @user[:id] == 1
      redirect_to users_path, alert: t(:user_cant_be_deleted)
    else
      @user.destroy
      redirect_to users_path, notice: t(:user_deleted)
    end
  end



  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :middle_name, :role_id, :sip_number, :phone_number,
                                 :phone_number_s, :phone_number_t, :cell_number, :occupation, :email, :password,
                                 :password_confirmation, :activated)
  end

end
