class ProjectMailer < BaseMailer
  def ending_soon(project)
    @project = project
    to = project.pm.try(:email) || [AppConfig.emails.pm]
    mail(to: to, subject: "Your project will end soon.", project: @project)
  end

  def three_months_old(project)
    @project = project
    to = project.pm.try(:email) || [AppConfig.emails.pm], AppConfig.emails.social
    mail(to: to, subject: "#{project.name}, references", project: @project)
  end

  def kickoff_tomorrow(project)
    @project = project
    to = [project.pm.try(:email), AppConfig.emails.pm].compact
    mail(to: to, subject: "#{ project.name } is starting tomorrow", project: @project)
  end

  def upcoming_changes(project, days)
    @project = ProjectDigest.new(project)
    @days = days
    @memberships_leaving = @project.leaving_memberships(days)
    @memberships_joining = @project.joining_memberships(days)
    @project_starting = @project.starting_in?(days)
    @project_ending = @project.ending_in?(days)
    to = project.pm.try(:email) || [AppConfig.emails.pm]
    subject = "#{ project.name }: the next #{ days } days"
    mail(to: to, subject: subject, project: @project)
  end

  def created(project, current_user)
    @project = project
    to = mail_receivers(current_user)
    mail(to: to, subject: "#{ project.name } has been created", project: @project)
  end
end
