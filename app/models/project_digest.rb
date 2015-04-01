class ProjectDigest
  attr_accessor :project

  def initialize(project)
    @project = project
  end

  class << self
    def ending_in_a_week
      Project.active.between(end_at: (1.week.from_now - 1.day)..1.week.from_now)
    end

    def ending_or_starting_in(days)
      Project.where(
        '(kickoff BETWEEN ? AND ?) OR (end_at BETWEEN ? AND ?)',
        Time.now,
        days.days.from_now,
        Time.now,
        days.days.from_now
      )
    end

    def three_months_old
      Project.nonpotential.where(created_at: 3.months.ago.to_date)
    end

    def ending_in(days)
      Project.where('end_at BETWEEN ? AND ?', Time.now, days.days.from_now)
    end

    def starting_in(days)
      Project.where('kickoff BETWEEN ? AND ?', Time.now, days.days.from_now)
    end

    def starting_tommorow
      Project.potential.where('kickoff BETWEEN ? AND ?', Time.now, 1.day.from_now)
    end

    def upcoming_changes(days)
      projects = MembershipsRepository.new.upcoming_changes(days).map(&:project)
      projects << ProjectDigest.ending_or_starting_in(days).to_a
      projects.uniq.flatten
    end
  end

  def starting_in?(days)
    Project.starting_in(days).where(id: id).exists?
  end

  def ending_in?(days)
    Project.ending_in(days).where(id: id).exists?
  end

  def leaving_memberships(days)
    project.memberships.where('ends_at BETWEEN ? AND ?', Time.now, days.days.from_now)
  end

  def joining_memberships(days)
    project.memberships.where('starts_at BETWEEN ? AND ?', Time.now, days.days.from_now)
  end
end
