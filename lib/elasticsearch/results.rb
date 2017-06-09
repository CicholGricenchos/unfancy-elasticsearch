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

  def preload_with scope = nil, &block
    if block_given?
      @preload_block = block
    else
      @preload_block = proc{ send(scope) }
    end
    self
  end

  def record_hash
    return @record_hash if @record_hash
    result_ids = @response["hits"]["hits"].map{|x| x["_id"].to_i}
    relation = @model.where(id: result_ids)
    relation = relation.instance_eval(&@preload_block) if @preload_block
    @record_hash = relation.map{|x| [x.id, x]}.to_h
  end

  def records
    @records ||= @response["hits"]["hits"].map{|x| x["_id"].to_i}.map{|x| record_hash[x]}.compact
  end

  def hits
    @hits ||= @response["hits"]["hits"].map{|x| Elasticsearch::Hit.new(x, record_hash[x["_id"].to_i])}
  end

  def aggregations
    @response["aggregations"]
  end
end