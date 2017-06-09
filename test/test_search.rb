require 'minitest/autorun'
require_relative './test_helper'

class TestSearch < Minitest::Test
  def test_results
    Product.__elasticsearch__.recreate_index

    product = Product.create(name: 'humanity')
    Product.__elasticsearch__.refresh

    assert_includes Product.__elasticsearch__.search({
      query: {
        match: {name: 'humanity'}
      }
    }).records, product
  end

  def test_results_preload
    Product.__elasticsearch__.recreate_index

    product = Product.create(name: 'humanity', catalog: Catalog.create(name: 'items'))
    Product.__elasticsearch__.refresh

    records = Product.__elasticsearch__.search({
      query: {
        match_all: {}
      }
    }).preload_with{ includes(:catalog) }.records

    assert_includes records, product
    assert records.first.association(:catalog).loaded?
  end

  def test_hits
    Product.__elasticsearch__.recreate_index

    product = Product.create(name: 'humanity', catalog: Catalog.create(name: 'items'))
    Product.__elasticsearch__.refresh

    hits = Product.__elasticsearch__.search({
      query: {
        match_all: {}
      }
    }).preload_with(:preload_catalog).hits

    assert_equal product, hits.first.record
    assert hits.first.record.association(:catalog).loaded?
  end
end