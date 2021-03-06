require 'rubygems'
require 'test/unit'
require 'logger'
require 'bundler'

Bundler.setup
Bundler.require

Paperclip.configure
Paperclip::Railtie.insert

class User < ActiveRecord::Base
  has_attached_file        :avatar,
                           :path => File.dirname(__FILE__) + "/avatars/:id_partition/:attachment/:style.:extension",
                           :url =>  "/users/:id.:extension"
  encode_attachment_in_xml :avatar
  
  has_attached_file        :avatar_remote,
                           :path => File.dirname(__FILE__) + "/avatars/:id_partition/:attachment/:style.:extension",
                           :url =>  "/users/:id.:extension"
  encode_attachment_in_xml :avatar_remote, :send_urls => true, :root_url => "http://localhost/"
end

module Api
  class User < ActiveResource::Base
    self.site = "http://localhost/"
    
    has_encoded_attachment :avatar
    has_encoded_attachment :avatar_remote
    
    schema do
      string "name"
    end
  end
end

class ActiveSupport::TestCase
  def self.load_schema
    config = YAML::load(IO.read(File.dirname(__FILE__) + '/config/database.yml'))
    ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/log/debug.log")

    db_adapter = ENV['DB']

    # no db passed, try one of these fine config-free DBs before bombing.
    db_adapter ||=
      begin
        require 'rubygems'
        require 'sqlite'
        'sqlite'
      rescue MissingSourceFile
        begin
          require 'sqlite3'
          'sqlite3'
        rescue MissingSourceFile
        end
      end

    if db_adapter.nil?
      raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3."
    end
  
    ActiveRecord::Base.establish_connection(config[db_adapter])
    load(File.dirname(__FILE__) + "/config/schema.rb")
  end
  
  def self.user_with_encoded_files
    User.encode_attachment_in_xml :avatar
  end
  
  def self.user_urls
    User.encode_attachment_in_xml :avatar, :send_urls => true, :root_url => "http://localhost/"
  end
end