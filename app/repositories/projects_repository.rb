class ProjectsRepository
  def all
    # FIXME: we should have a 2nd level of eager-loading here: memberships: :role
    # but it's not available in Mongo
    @all ||= Project.all.includes(:memberships, :notes).to_a
  end

  def get(id)
    all.find { |p| p.id == id }
  end

  def all_by_name
    all.sort_by(&:name)
  end

  def with_notes
    all
  end

  def active
    all.select { |p| !p.archived }
  end

  def active_sorted
    active.sort_by { |project| project.name.downcase }
  end

  def ending_in_a_week
    Project.active.where(end_at: (1.week.from_now - 1.day)..1.week.from_now)
  end

  def find_or_create_by_name(name)
    Project.where(name: name).first_or_create project_type: 'regular'
  end
end
