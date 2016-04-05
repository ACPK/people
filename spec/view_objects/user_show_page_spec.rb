require 'spec_helper'

describe UserShowPage do
  let(:user) { create(:developer_in_project) }
  let(:active_project) { create(:project) }
  let(:booked_project) { create(:project, end_at: nil) }
  let(:archived_project) { create(:project, :archived) }
  let!(:active_membership) do
    create(:membership, user: user, project: active_project, role: user.roles.first)
  end
  let!(:archived_membership) do
    create(
      :membership,
      user: user,
      project: archived_project,
      role: user.roles.first,
      project_archived: true
    )
  end
  let!(:booked_membership) do
    create(
      :membership,
      :booked,
      user: user,
      project: booked_project,
      role: user.roles.first,
      starts_at: Time.current + 12.months,
      ends_at: nil
    )
  end

  describe '#user_all_memberships' do
    let(:instance) do
      described_class.new(user: user, projects_repository: nil, user_projects_repository: nil)
    end

    it 'returns all memberships of the user' do
      expected_memberships = Membership.where(user: user)
      memberships = instance.user_all_memberships

      expect(memberships.map(&:id).sort).to eql(expected_memberships.map(&:id).sort)
    end
  end

  describe '#user_active_memberships' do
    let(:instance) do
      described_class.new(user: user, projects_repository: nil, user_projects_repository: nil)
    end

    it 'returns collection of memberships with active projects' do
      expected_memberships = Membership.active.where(user: user)
      memberships = instance.user_active_memberships

      expect(memberships.size).to eql(2)
      expect(memberships.map(&:id).sort).to eql(expected_memberships.map(&:id).sort)
    end
  end

  describe '#user_archived_memberships' do
    let(:instance) do
      described_class.new(user: user, projects_repository: nil, user_projects_repository: nil)
    end

    it 'returns collection of memberships with archived projects' do
      expected_memberships = Membership.archived.where(user: user)

      memberships = instance.user_archived_memberships

      expect(memberships.size).to eql(1)
      expect(memberships.map(&:id).sort).to eql(expected_memberships.map(&:id).sort)
    end
  end

  describe '#user_booked_memberships' do
    let(:instance) do
      described_class.new(user: user, projects_repository: nil, user_projects_repository: nil)
    end

    it 'returns collection of memberships with booked projects' do
      expected_memberships = Membership.booked.where(user: user)

      memberships = instance.user_booked_memberships

      expect(memberships.size).to eql(1)
      expect(memberships.map(&:id).sort).to eql(expected_memberships.map(&:id).sort)
    end
  end
end
