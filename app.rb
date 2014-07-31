require "sinatra"
require "gschool_database_connection"
require "rack-flash"
require_relative "lib/models/fish"
require_relative "lib/models/user"

class App < Sinatra::Application
  enable :sessions
  use Rack::Flash

  def initialize
    super
    @database_connection = GschoolDatabaseConnection::DatabaseConnection.establish(ENV["RACK_ENV"])
  end

  get "/" do
    user = current_user

    if current_user
      users = User.where('id <> ?', user.id)
      fish = Fish.where(:user_id => user.id)
      erb :signed_in, locals: {current_user: user, users: users, fish_list: fish}
    else
      erb :signed_out
    end
  end

  get "/register" do
    erb :register
  end

  post "/registrations" do
    user = User.new(
      :username => params[:username],
      :password => params[:password]
    )

    if user.save
      flash[:notice] = "Thanks for registering"
      redirect "/"
    else
      flash[:notice] = ""
      user.errors.full_messages.each { |error| flash[:notice] += error }
      redirect back
    end
  end

  post "/sessions" do
    errors = User.login_errors(params[:username], params[:password])
    unless errors
      user = User.find_by(
        :username => params[:username],
        :password => params[:password]
      )
      if user
        session[:user_id] = user.id
      else
        flash[:notice] = "Username/password is invalid"
      end
    end
    flash[:notice] = errors
    redirect "/"
  end

  delete "/sessions" do
    session[:user_id] = nil
    redirect "/"
  end

  delete "/users/:id" do
    User.find(params[:id]).destroy

    redirect "/"
  end

  get "/fish/new" do
    erb :"fish/new"
  end

  get "/fish/:id" do
    fish = User.find(params[:id])
    erb :"fish/show", locals: {fish: fish}
  end

  post "/fish" do
    if validate_fish_params
      fish = Fish.new(
        :name => params[:name],
        :wikipedia_page => params[:wikipedia_page],
        :user_id => current_user.id
      )
      fish.save
      flash[:notice] = "Fish Created"

      redirect "/"
    else
      erb :"fish/new"
    end
  end

  private

  def validate_fish_params
    if params[:name] != "" && params[:wikipedia_page] != ""
      return true
    end

    error_messages = []

    if params[:name] == ""
      error_messages.push("Name is required")
    end

    if params[:wikipedia_page] == ""
      error_messages.push("Wikipedia page is required")
    end

    flash[:notice] = error_messages.join(", ")

    false
  end

  def validate_authentication_params

  end

  def username_available?(username)
    existing_users = @database_connection.sql("SELECT * FROM users where username = '#{username}'")

    existing_users.length == 0
  end

  def authenticate_user
    select_sql = <<-SQL
    SELECT * FROM users
    WHERE username = '#{params[:username]}' AND password = '#{params[:password]}'
    SQL

    @database_connection.sql(select_sql).first
  end

  def current_user
    if session[:user_id]
      User.find(session[:user_id])
    else
      nil
    end
  end

end
