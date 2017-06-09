class Elasticsearch::Hit
  attr_reader :record

  def initialize response, record
    @response = response
    @record = record
  end

end