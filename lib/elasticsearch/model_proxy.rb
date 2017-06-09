class Elasticsearch::ModelProxy
  attr_accessor :document_data_method_name, :index_data_method_name, :namespace

  def initialize model, options = {}
    @model = model
    @document_data_method_name = options[:document_data_method_name] || :document_data
    @index_data_method_name = options[:index_data_method_name] || :index_data
    @namespace = nil

    @type_name = model.name.gsub(/::/, '__').gsub(/([a-z])([A-Z])/){$1 + '_' + $2}.downcase
    @alias_name = @type_name + '_' + Rails.env
  end

  def client
    $ELASTICSEARCH_CLIENT
  end

  def reindex_scope(scope, batch_size: 500, keep_old: false, recreate: true)
    if scope.respond_to? :search_import
      scope = scope.search_import
    end

    if recreate
      index_name = create_index
    end

    scope.find_in_batches(batch_size: batch_size) do |records|
      to_index = records.select(&:should_index?)
      client.bulk body: (to_index.map do |record|
        {
          index: {_index: index_name, _type: @type_name, _id: record.id, data: record.send(@document_data_method_name)}
        }
      end)
    end

    if recreate
      alias_index index_name
    end

    unless keep_old
      clean_indices
    end

    index_name
  end

  def create_index
    timestamp = Time.now.strftime("%Y%m%d%H%M%S%L")
    index_name = "#{@alias_name}_#{timestamp}"
    client.indices.create index: index_name, body: @model.send(@index_data_method_name)
    index_name
  end

  def alias_index index_name
    old_indices =
      begin
        client.indices.get_alias(name: @alias_name).keys
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        {}
      end
    actions = old_indices.map { |old_name| {remove: {index: old_name, alias: @alias_name}} } + [{add: {index: index_name, alias: @alias_name}}]
    client.indices.update_aliases body: {actions: actions}
  end

  def recreate_index
    index_name = create_index
    alias_index index_name
    clean_indices
    index_name
  end

  def clean_indices
    to_delete = client.indices.get_aliases.select{|k, v| k.start_with? @alias_name}.reject{|k, v| v["aliases"].include?(@alias_name)}.keys
    to_delete.each do |name|
      client.indices.delete index: name
    end
  end

  def reindex_record record
    client.index index: @alias_name, type: @type_name, id: record.id, body: record.send(@document_data_method_name)
  end

  def search params
    response = client.search index: @alias_name, type: @type_name, body: params
    Elasticsearch::Results.new(response, @model, {})
  end

  def tokens analyzer, text
    client.indices.analyze index: @alias_name, text: text, analyzer: analyzer
  end

  def delete_record_index record
    client.delete(index: @alias_name, type: @type_name, id: record.id)
  end

  def record_exists? id
    client.exists? index: @alias_name, type: @type_name, id: id
  end

  def get_record id
    client.get index: @alias_name, type: @type_name, id: id
  end

  def refresh
    client.indices.refresh index: @alias_name
  end
end