class UsersController < ApplicationController
  def new
    @user = User.new
  end

    def create
      # Create a new user using strong parameters.
      @user = User.new(user_params)
      if @user.save
        # Automatically log the user in after signup
        session[:user_id] = @user.UserID

        UserMailer.welcome_email(@user).deliver_later

        redirect_to dashboard_path, notice: "Account created successfully!"
      else
        render :new
      end
    end

    private

    # Adjust the permitted parameters to match your Users table column names.
    def user_params
      params.require(:user).permit(:Email, :password, :password_confirmation, :FName, :LName, :Role, :CompanyName, :TenantAddress, :PhoneNumber, :ProfileDisclaimer)
    end
end
