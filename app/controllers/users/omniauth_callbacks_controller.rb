class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    # You need to implement the method below in your model
    @user = User.find_for_github_oauth(env["omniauth.auth"])

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: "Github"
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.github_data"] = env["omniauth.auth"]
      redirect_to root_path
    end
  end
end
