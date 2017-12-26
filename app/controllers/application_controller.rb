class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  http_basic_authenticate_with name: 'admin', password: 'Pa55w0rd', if: -> { Rails.env.staging? || Rails.env.production? }

  # Authenticate users
  def spree_authenticate_user
    return if spree_current_user
    session[:user_return_to] = request.env['PATH_INFO']
    flash.notice = Spree.t(:please_login)
    redirect_to(spree.login_path) && return
  end
end
