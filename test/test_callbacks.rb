require 'minitest/autorun'
require_relative './test_helper'

class TestCallbacks < Minitest::Test
  def test_update_index_on_create_and_update
    Product.__elasticsearch__.recreate_index

    product = Product.create(name: 'humanity')
    assert_equal product.name, Product.__elasticsearch__.get_record(product.id)["_source"]["name"]

    product.update(name: 'ember')
    assert_equal product.name, Product.__elasticsearch__.get_record(product.id)["_source"]["name"]
  end

  def test_delete_index_on_destroy
    Product.__elasticsearch__.recreate_index

    product = Product.create(name: 'humanity')
    assert Product.__elasticsearch__.record_exists? product.id

    product.destroy
    refute Product.__elasticsearch__.record_exists? product.id
  end
end