
require 'active_record'
require_relative '../lib/unfancy-elasticsearch'

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

ActiveRecord::Migration.create_table :products do |t|
  t.string :name
end

module Rails
  def self.env
    'development'
  end
end

$ELASTICSEARCH_CLIENT = Elasticsearch::Client.new url: 'http://elastic:changeme@localhost:9200'

class Product < ActiveRecord::Base
  include Elasticsearch::Model

  def self.index_data
    {}
  end

  def document_data
    {
      name: name
    }
  end
end