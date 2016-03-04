require 'spec_helper'

describe 'Project show view', js: true do
  let!(:dev_role) { create(:role, name: 'developer', technical: true) }
  let!(:admin_user) { create(:user, :admin, primary_role: dev_role) }
  before do
    log_in_as(admin_user)
  end

  describe 'rendering timeline on profile' do
    let(:membership) { create(:membership) }
    let(:project) { create(:project, memberships: [membership]) }

    before do
      visit project_path(project.id)
    end

    it_behaves_like 'has timeline visible'
    it_behaves_like 'has timeline event visible'
  end
end
