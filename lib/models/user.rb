require "active_record"

class User < ActiveRecord::Base
  validates :username, {
    :presence => {
      :message => "is required"
    },
    :uniqueness => {
      :message => "has already been taken"
    }
  }
  validates :password, {
    :presence => {
      :message => "is required"
    },
    :length => {
      :minimum => 4,
      :message => "must be at least 4 characters"
    }
  }

  def self.login_errors(username, password)
    if username != "" && password != ""
      return false
    end

    error_messages = []

    if username == ""
      error_messages.push("Username is required")
    end

    if password == ""
      error_messages.push("Password is required")
    end

    error_messages.join(", ")

  end
end