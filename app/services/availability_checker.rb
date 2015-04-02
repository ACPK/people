class AvailabilityChecker
  def initialize(user)
    @user = user
  end

  def run!
    return unless @user.primary_role.technical?
    find_memberships_gaps
    @user.update_attributes(available: available?, available_since: available_since)
  end

  private

  def available?
    free_right_now? ||
      has_billable_memberships_with_end_date? ||
      has_memberships_with_gaps? ||
      has_only_nonbillable_memberships?
  end

  def available_since
    return unless available?

    if free_right_now? || has_only_nonbillable_memberships_without_end_data?
      return Date.today
    end

    if has_memberships_with_gaps?
      first_gap_in_memberships
    else
      next_working_day(memberships.last.ends_at)
    end
  end

  def find_memberships_gaps
    @memberships_with_gaps = []

    memberships_dates.each_with_index do |range, i|
      break if range[:ends].nil?
      break if i == memberships_dates.size - 1 # skip last run

      ends_with_buffer = range[:ends] + 1.day
      next_starts = memberships_dates[i + 1][:starts]

      if ends_with_buffer < next_starts
        @memberships_with_gaps << range
      end
    end
  end

  def has_no_memberships?
    memberships.empty?
  end

  def free_right_now?
    has_no_memberships? || first_membership_starts_after_today?
  end

  def has_only_nonbillable_memberships_without_end_data?
    return false unless has_only_nonbillable_memberships?
    memberships.where(billable: false).all? { |membership| membership.ends_at.nil? }
  end

  def first_membership_starts_after_today?
    memberships.reorder(starts_at: :asc).first.starts_at > Date.today
  end

  def has_only_nonbillable_memberships?
    memberships.billable.empty?
  end

  def has_billable_memberships_with_end_date?
    current_billable_memberships_without_end_date.blank?
  end

  def has_memberships_with_gaps?
    @memberships_with_gaps.any?
  end

  def first_gap_in_memberships
    end_date = @memberships_with_gaps.first[:ends]
    next_working_day(end_date)
  end

  def current_billable_memberships_without_end_date
    @current_billable_memberships_without_end_date ||= memberships.billable.where(ends_at: nil)
  end

  def current_memberships
    @current_memberships ||= @user.current_memberships.order(:ends_at)
  end

  def memberships
    @user.memberships.unfinished.without_bookings.order(ends_at: :asc)
  end

  def memberships_dates
    @memberships_dates = memberships
      .reorder(starts_at: :asc)
      .map{ |membership| { starts: membership.starts_at, ends: membership.ends_at } }
  end

  def next_working_day(date)
    date ||= Time.now

    loop do
      date += 1.day
      break unless date.saturday? || date.sunday?
    end

    date
  end
end
