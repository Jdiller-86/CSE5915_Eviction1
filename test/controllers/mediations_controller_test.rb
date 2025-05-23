require "test_helper"

class MediationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = users(:tenant1)
    @landlord = users(:landlord1)
    @mediation = primary_message_groups(:one)
  end

  def log_in_as(user)
    post login_path, params: { session: { email: user.Email, password: user.Password } }
  end

  test "should redirect to messages path on index access" do
    log_in_as(@tenant)
    get mediations_path
    assert_redirected_to messages_path
    assert_equal "Mediation index is not available. Please use the messages page.", flash[:alert]
  end

  test "tenant can create mediation" do
    log_in_as(@tenant)
    assert_difference("PrimaryMessageGroup.count") do
    post mediations_path, params: { mediation: { LandlordID: @landlord.UserID, TenantID: @tenant.UserID } }
    end
    assert_redirected_to mediation_path(@mediation)
  end

  test "non-tenant cannot create mediation" do
    log_in_as(@landlord)
    post mediations_path, params: { landlord_id: @landlord.UserID }
    assert_redirected_to login_path
    assert_equal "You must be logged in to access the mediations.", flash[:alert]
  end

  test "landlord can accept mediation" do
    patch accept_mediation_path(@mediation)
    assert @mediation.reload.accepted_by_landlord
    assert_redirected_to mediations_path
    assert_equal "Mediation accepted. You can now view and respond to the mediation.", flash[:notice]
  end

  test "unauthorized landlord cannot accept mediation" do
    another_landlord = users(:landlord2)
    log_in_as(another_landlord)
    patch accept_mediation_path(@mediation)
    assert_redirected_to mediations_path
    assert_equal "You are not authorized to accept this mediation.", flash[:alert]
  end

  test "require login to access mediations" do
    get mediations_path
    assert_redirected_to login_path
    assert_equal "You must be logged in to access the mediations.", flash[:alert]
  end
end
