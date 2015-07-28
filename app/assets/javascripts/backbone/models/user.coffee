class Hrguru.Models.User extends Backbone.Model

  visibleBy:
    users: true
    roles: true
    projects: true
    abilities: true
    months_in_current_project: true
    availabilityTime: true

  membership: null

  initialize: ->
    super
    @next_projects = new Hrguru.Models.Project(@get('next_projects'))
    @listenTo(EventAggregator, 'users:updateVisibility', @updateVisibility)

  updateVisibility: (data) ->
    @visibleBy.availabilityTime = @visibleByAvailabilityTime(parseInt(data.availability_time))
    @visibleBy.roles = @visibleByRoles(data.roles)
    @visibleBy.projects = @visibleByProjects(data.projects)
    @visibleBy.users = @visibleByUsers(data.users)
    @visibleBy.abilities = @visibleByAbilities(data.abilities)
    @visibleBy.months_in_current_project = @visibleByMonthsInCurrentProject(parseInt(data.months))
    @trigger 'toggle_visible', @isVisible()

  isAvailableNow: ->
    H.currentTime() > moment(@get('available_since'))

  daysToAvailable: ->
    return -1 unless @get('available_since')?
    moment(@get('available_since')).diff(H.currentTime(), 'days')

  isVisible: ->
    @visibleBy.availabilityTime && @visibleBy.roles && @visibleBy.projects && @visibleBy.users &&
      @visibleBy.abilities && @isActive() && @visibleBy.months_in_current_project

  visibleByUsers: (users = '') ->
    return true if users.length == 0
    String(@id) in users

  visibleByRoles: (roles = '') ->
    return true if roles.length == 0
    return false unless @get('role')?
    _.contains roles, @myRole()

  visibleByProjects: (projects = '') ->
    return true if projects.length == 0
    return false unless @get('projects')?
    myProjects = @myProjects()
    (_.difference myProjects, projects).length < myProjects.length

  visibleByAbilities: (abilities = '') ->
    return true if abilities.length == 0
    return false unless @get('abilities')?
    myAbilities = @myAbilities()
    (_.union myAbilities, abilities).length == myAbilities.length

  visibleByAvailabilityTime: (availability_time) ->
    return false unless @daysToAvailable()?
    return true if isNaN(availability_time)
    @daysToAvailable() <= availability_time

  visibleByMonthsInCurrentProject: (months = '') ->
    return true if months == 0
    @isInProjectForMoreThanMonths(months)

  myProjects: ->
    _.map @get("projects"), (p) -> String(p.project.id)

  myRole: ->
    String(@get("role").id)

  myAbilities: ->
    _.map @get("abilities"), (a) -> String(a.id)

  isActive: ->
    !@get('archived')

  hasRole: ->
    @get('role_id') != null

  isInProjectForMoreThanMonths: (months) ->
    return true if isNaN(months)
    @get('months_in_current_project') > months

  hasTechnicalRole: ->
    @get('role').technical

  isPotential: ->
    return false unless @hasTechnicalRole()
    if @get('has_project') && !@hasProjectsOnlyPotentialOrNotbillable()
      return false unless @daysToAvailable()? < 30 && @membership.hasEndDate()
    (!@hasNextProjects() || @nextProjectsOnlyPotentialOrNotbillable())

  hasNextProjects: ->
    @next_projects?

  hasProjectsOnlyPotentialOrNotbillable: ->
    @areOnlyPotenialOrNotbillable(@get('projects'))

  nextProjectsOnlyPotentialOrNotbillable: ->
    @areOnlyPotenialOrNotbillable(@next_projects)

  areOnlyPotenialOrNotbillable: (projects) ->
    _.all projects, (project) =>
      @userProjectIsPotential(project) or !@userProjectIsBillable(project)

  userProjectIsPotential: (next_project) ->
    next_project.project.potential

  userProjectIsBillable: (current_project) ->
    current_project.billable

class Hrguru.Collections.Users extends Backbone.Collection
  model: Hrguru.Models.User
  url: Routes.users_path()

  sortAttribute: 'available_since'
  sortDirection: 1

  sortUsers: (attr, direction) ->
    @sortAttribute = attr
    @sortDirection = direction
    @sort()
    return

  comparator: (a, b) ->
    a = a.get(@sortAttribute)
    b = b.get(@sortAttribute)

    a = '' unless a
    b = '' unless b

    if isNaN(a) && isNaN(b)
      @compareStrings(a, b)
    else
      @compareNumbers(a, b)

  compareStrings: (a, b) ->
    if @sortDirection is 1
      a.localeCompare(b)
    else
      -a.localeCompare(b)

  compareNumbers: (a, b) ->
    result = 0

    if a >= b then result = 1 else result = -1
    if @sortDirection is 1 then result else -result

  numbers_comparator: (a, b) ->
    if a >= b then 1 else -1

  active: ->
    filtered = @filter((user) ->
      user.isActive()
    )
    new Hrguru.Collections.Users(filtered)

  withRole: ->
    filtered = @filter((user) ->
      user.hasRole()
    )
    new Hrguru.Collections.Users(filtered)
