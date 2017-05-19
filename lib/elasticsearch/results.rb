class Elasticsearch::Results
  attr_reader :response

  def initialize response, model, options
    @response = response
    @model = model
    @options = options
  end

  def total_count
    @response["hits"]["total"]
  end

  def results
    result_ids = @response["hits"]["hits"].map{|x| x["_id"].to_i}
    record_hash = @model.where(id: result_ids).map{|x| [x.id, x]}.to_h
    result_ids.map{|x| record_hash[x]}.compact
  end

  def hits
    @response["hits"]["hits"].map{|x| (@options[:hit_class] || Elasticsearch::Results::Hit).new(x)}
  end
end