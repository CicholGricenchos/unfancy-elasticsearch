
module Elasticsearch::Model
  extend ActiveSupport::Concern

  included do
    after_commit on: [:create, :update] do
      __elasticsearch__.reindex_record self
    end

    after_commit on: :destroy do
      __elasticsearch__.delete_record_index self
    end
  end

  class_methods do
    def __elasticsearch__
      @@__elasticsearch__ ||= Elasticsearch::ModelProxy.new self
    end

    def index_data
      {}
    end
  end

  def __elasticsearch__
    self.class.__elasticsearch__
  end

  def should_index?
    true
  end

end