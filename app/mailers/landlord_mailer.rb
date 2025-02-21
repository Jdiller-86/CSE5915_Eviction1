class LandlordMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.landlord_mailer.invitation_email.subject
  #
  default from: ENV["GMAIL_USERNAME"]

  def invitation_email(email, invited_by)

    @invited_by = invited_by
    @signup_url = signup_url(role: 'Landlord', email: email)
    
    mail(to: email, subject: 'You are invited to join the Mediation Platform')
  end

  def signup_url(role:, email:)
    "#{root_url}signup?role=#{role}&email=#{CGI.escape(email)}"
  end
end
