class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    # You need to implement the method below in your model
    @user = User.find_for_github_oauth(env["omniauth.auth"])

    if @user.persisted?
      if @user.fakemail?
        flash[:notice] = I18n.t("devise.omniauth_callbacks.success", kind: "Github") + " Please set your email first."
        sign_in @user, event: :authentication
        redirect_to edit_user_registration_path
      else
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: "Github"
        sign_in_and_redirect @user, event: :authentication
      end
    else
      session["devise.github_data"] = env["omniauth.auth"]
      redirect_to root_path
    end
  end
end
