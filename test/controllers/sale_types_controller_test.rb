require "test_helper"

class SaleTypesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get sale_types_index_url
    assert_response :success
  end

  test "should get new" do
    get sale_types_new_url
    assert_response :success
  end

  test "should get create" do
    get sale_types_create_url
    assert_response :success
  end

  test "should get edit" do
    get sale_types_edit_url
    assert_response :success
  end

  test "should get update" do
    get sale_types_update_url
    assert_response :success
  end

  test "should get destroy" do
    get sale_types_destroy_url
    assert_response :success
  end
end
