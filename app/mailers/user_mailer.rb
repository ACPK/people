class UserMailer < BaseMailer
  def notify_operations(email)
    @email = email
    to = [AppConfig.emails.pm]
    mail(to: to, subject: "New user in the application.", email: @email)
  end
end
