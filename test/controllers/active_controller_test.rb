require 'test_helper'

class ActiveControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
