class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.find(params[:id])
  end

  def index
    @users = User.all.order(:last_name).paginate(page: params[:page], per_page: 20)
    unless params[:filter].nil?
      unless params[:filter][:first_name].blank?
        @users = @users.where("first_name LIKE ?", "%#{params[:filter][:first_name]}%")
      end
      unless params[:filter][:middle_name].blank?
        @users = @users.where("middle_name LIKE ?", "%#{params[:filter][:middle_name]}%")
      end
      unless params[:filter][:last_name].blank?
        @users = @users.where("last_name LIKE ?", "%#{params[:filter][:last_name]}%")
      end
      unless params[:filter][:email].blank?
        @users = @users.where("email LIKE ?", "%#{params[:filter][:email]}%")
      end
      unless params[:filter][:phone_number].blank?
        @users = @users.where("phone_number LIKE ?", "%#{params[:filter][:phone_number]}%")
      end
      unless params[:filter][:cell_number].blank?
        @users = @users.where("cell_number LIKE ?", "%#{params[:filter][:cell_number]}%")
      end
      unless params[:filter][:sip_number].blank?
        @users = @users.where("sip_number LIKE ?", "%#{params[:filter][:sip_number]}%")
      end
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path
    else
      flash.now[:error] = "#{@user.errors.full_messages.join(', ')}"
      render action: :new
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to users_path
    else
      flash.now[:error] = "#{@user.errors.full_messages.join(', ')}"
      render action: :edit
    end
  end



  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :middle_name, :role_id, :sip_number, :phone_number, :phone_number_s, :phone_number_t, :cell_number, :occupation, :email, :password, :password_confirmation, :activated)
  end
end
