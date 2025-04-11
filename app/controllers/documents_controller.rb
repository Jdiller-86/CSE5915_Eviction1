require "docx_templater"
require "docsplit"

class DocumentsController < ApplicationController
  before_action :require_login
  before_action :set_user
  before_action :check_mediation_status, only: [ :generate, :select_template, :proposal_generation ]
  before_action :prevent_generation_without_screening, only: [ :generate, :select_template, :proposal_generation ]







  # Renders a document template (like Agreement to Vacate) with a prefilled form from intake data, this form can be updated to change the agreement generation.
  def intake_template_view
    @conversation = PrimaryMessageGroup.find_by(ConversationID: params[:conversation_id])
    @landlord = User.find_by(UserID: @conversation.LandlordID)
    @tenant = User.find_by(UserID: @conversation.TenantID)
    @intake = IntakeQuestion.find_by(IntakeID: @conversation.IntakeID)
    render :intake_template_view
  end

  # Handles submission of the form and generates the filled document
  def generate_filled_template
    conversation = PrimaryMessageGroup.find_by(ConversationID: params[:conversation_id])
    landlord = User.find_by(UserID: conversation.LandlordID)
    intake = IntakeQuestion.find_by(IntakeID: conversation.IntakeID)
    user_role = @user.Role

    # This was is just a test, to see how it would work.
    file_id = SecureRandom.uuid

    # Choose correct template
    if intake.BestOption == "Move Out"
      template_name = "Formatted Agreement to Vacate.docx"
    elsif intake.BestOption == "Pay Missed Rent"
      template_name = "Formatted Pay and Stay Negotiated Agreement.docx"
    else
      render plain: "No template available for this intake option.", status: :unprocessable_entity
      return
    end

    template_path = Rails.root.join("public", "templates", template_name)
    filled_docx_path = Rails.root.join("public", "userFiles", "#{file_id}.docx")
    filled_pdf_path = Rails.root.join("public", "userFiles", "#{file_id}.pdf")

    # Build data for the docx template
    data = {
      landlord_name: params[:landlord_name],
      tenant_name: params[:fname],
      tenant_address: params[:address],
      landlord_company: landlord.CompanyName.to_s,
      negotiation_date: params[:negotiation_date],
      additional_provisions: params[:additional_provisions]
    }

    if user_role == "Tenant"
      data[:tenant_signature] = params[:tenant_signature]
    else
      data[:landlord_signature] = params[:landlord_signature]
    end

    j = 5

    if intake.BestOption == "Move Out"
      j = 6
    end

    # Payment plan
    (1..j).each do |i|
      data[:"amount#{i}"] = params[:"amount#{i}"].to_s
      data[:"date#{i}"] = params[:"date#{i}"].to_s
    end

    # Fill the DOCX template using the gem's API
    buffer = DocxTemplater.new.replace_file_with_content(template_path.to_s, data)

    # Save filled document
    File.open(filled_docx_path.to_s, "wb") { |f| f.write(buffer.string) }
    # unless File.exist?(filled_docx_path)
    # logger.error "DOCX generation failed"
    # render plain: "Document generation failed", status: :internal_server_error
    # return
    # end

    Docsplit.extract_pdf("public/userFiles/#{file_id}.docx", output: "public/userFiles")

    FileDraft.create!(
      FileName: "#{file_id}",
      FileTypes: "pdf",
      FileURLPath: "userFiles/#{file_id}.pdf",
      CreatorID: @user.UserID
    )

    redirect_to user_role == "Tenant" ? documents_path : landlord_documents_path, notice: "Document generated successfully."
  end





  def index
    case @user.Role
    when "Tenant"
      @files = FileDraft.where(CreatorID: @user.UserID, UserDeletedAt: nil)# Fetch files not labeled as deleted
      render "documents/tenant_index"
    when "Landlord"
      @files = FileDraft.where(CreatorID: @user.UserID, UserDeletedAt: nil)# Fetch files not labeled as deleted
      render "documents/landlord_index"
    else
      render plain: "Access Denied", status: :forbidden
    end
  end

  # Alot of errors in the file paths/linking in the show and download methods, I am going to leave the loggers in for now just in case we hit the issues again later - They are not doing any harm anyways
  # For the most part, my take aways are that the file paths need to be handled in different ways between the inline html presentation and the controllers
  def download
    file = FileDraft.find_by(FileID: params[:id], CreatorID: @user.UserID)

    if file
      # Ensure the path is scoped to 'public' and cleaned
      sanitized_path = Pathname.new(file.FileURLPath).cleanpath
      base_path = Rails.root.join("public")
      file_path = base_path.join(sanitized_path)

      # Prevent directory traversal and ensure the file exists
      if file_path.to_s.start_with?(base_path.to_s) && File.exist?(file_path)

        # We think this should not be a real threat as long as we sanatize the other input areas.
        send_file file_path, filename: file.FileURLPath.sub(/^userFiles\//, ""), disposition: "attachment"
      else
        logger.error "File not found at path: #{file_path}"
        render plain: "File not found", status: :not_found
      end
    else
      logger.error "FileDraft not found for ID: #{params[:id]} and CreatorID: #{@user.UserID}"
      render plain: "File not found", status: :not_found
    end
  end


  def show
    @file = FileDraft.find_by(FileID: params[:id])

    if @file
      # Correct file path by joining with 'public' (no leading / needed)
      file_path = Rails.root.join("public", @file.FileURLPath)

      if File.exist?(file_path)
        render "documents/show"
      else
        render plain: "File not found", status: :not_found
      end
    else
      render plain: "File not found", status: :not_found
    end
  end


  # I think something is wrong with this set of methods (generate, select_template, and proposal_generation) but I am unsure what to do here
  def generate
    render "documents/generate"
  end

  def select_template
    # Get the template selected by the user
    @template = params[:template]

    # Depending on the template, you can now load the appropriate form or questions
    case @template
    when "a"
      @template_name = "Payment Plan Proposal A"
      # You can also define the questions or data needed to generate the PDF here.
    when "b"
      @template_name = "Payment Plan Proposal B"
    when "c"
      @template_name = "Payment Plan Proposal C"
    else
      @template_name = "Unknown Template"
    end

    # Render a view to ask financial questions to generate a proposal
    redirect_to proposal_generation_path(template: @template)
  end

  def proposal_generation
    @template = params[:template]

    case @template
    when "a"
      @template_name = "Payment Plan Proposal A"
    when "b"
      @template_name = "Payment Plan Proposal B"
    when "c"
      @template_name = "Payment Plan Proposal C"
    else
      @template_name = "Unknown Template"
    end

    # Here we can add logic to actually begin the payment plan info filling
  end

  private

  # Prevent user from creating document if mediation has ended (edge case)
  def check_mediation_status
    mediation = PrimaryMessageGroup.find_by(TenantID: @user.UserID) ||
                       PrimaryMessageGroup.find_by(LandlordID: @user.UserID)
    if mediation.deleted_at.nil?
      redirect_to mediation_ended_prompt_path(mediation.ConversationID)
    end
  end


  # Prevents a user from generating a file prior to filling out screening questions if mediator is assigned
  def prevent_generation_without_screening
    if @user.Role == "Tenant"
      mediation = PrimaryMessageGroup.where(TenantID: @user.UserID, deleted_at: nil).first
    elsif @user.Role == "Landlord"
      mediation = PrimaryMessageGroup.where(LandlordID: @user.UserID, deleted_at: nil).first
    end
    if mediation && (mediation.MediatorRequested || mediation.MediatorAssigned)
      if (@user.Role == "Tenant" && mediation.TenantScreeningID.nil?) ||
         (@user.Role == "Landlord" && mediation.LandlordScreeningID.nil?)
        redirect_to message_path(mediation.ConversationID)
      end
    end
  end

  def require_login
    unless session[:user_id]
      redirect_to login_path, alert: "You must be logged in to access the dashboard."
    end
  end

  def set_user
    @user = User.find(session[:user_id])
  end
end
