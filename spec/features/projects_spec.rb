require 'spec_helper'

describe 'Projects page', js: true do
  let!(:dev_role) { create(:role, name: 'developer', technical: true, billable: true) }
  let!(:active_project) { create(:project) }
  let!(:potential_project) { create(:project, :potential) }
  let!(:archived_project) { create(:project, :archived) }
  let!(:potential_archived_project) { create(:project, :potential, :archived) }
  let!(:admin_user) { create(:user, :admin, primary_role: dev_role) }
  let!(:dev_position) { create(:position, :primary, user: admin_user, role: dev_role) }
  let!(:note) { create(:note) }

  before do
    allow_any_instance_of(SendMailJob).to receive(:perform)
    page.set_rack_session 'warden.user.user.key' => User
      .serialize_into_session(admin_user).unshift('User')

    visit '/dashboard'
  end

  describe 'tabs' do
    it 'has Active/Potential/Archived tabs' do
      within(find('.projects-types')) do
        page.find('li.active').click
        page.find('li.potential').click
        page.find('li.archived').click
      end
    end
  end

  describe 'project row' do
    context 'when on Active tab' do
      before do
        within('.projects-types') { page.find('li.active').click }
      end

      it 'displays action icon (archive) when hovered' do
        expect(page.find('.archive')).to be_visible
      end

      it 'displays proper projects' do
        expect(page).to have_content(active_project.name)
        expect(page).not_to have_content(potential_project.name)
        expect(page).not_to have_content(archived_project.name)
        expect(page).not_to have_content(potential_archived_project.name)
      end

      it 'allows adding memberships to an active project' do
        within('.project-details') do
          expect(page).to have_selector('.Select-placeholder')
        end
      end

      describe 'show next' do
        let!(:future_membership) do
          create(:membership, starts_at: 1.month.from_now, user: admin_user)
        end

        context 'when checked' do
          it 'shows future memberships' do
            visit '/dashboard'
            check 'show-next'
            time_elements = all('time')
            expect(time_elements.size).to_not eq 0
          end
        end

        context 'when unchecked' do
          it 'does not show future memberships' do
            visit '/dashboard'
            uncheck 'show-next'
            time_elements = all('time.from-date')
            expect(time_elements.size).to eq 0
          end
        end
      end

      describe 'people in project' do
        let!(:project_membership) { create(:membership, project: active_project) }
        let!(:future_project_membership) do
          create(:membership, project: active_project, starts_at: Time.now + 2.weeks)
        end

        it 'shows number of present people in project' do
          visit '/dashboard'
          non_billable_count = find('.non-billable .count')
          expect(non_billable_count).to have_content('1')
        end
      end
    end

    context 'when on Potential tab' do
      before { page.find('li.potential').click }

      it 'displays action icon (archive) when hovered' do
        expect(page.find('.archive')).to be_visible
      end

      it 'displays proper projects' do
        page.find('li.potential').click
        expect(page).not_to have_content(active_project.name)
        expect(page).to have_content(potential_project.name)
        expect(page).not_to have_content(archived_project.name)
        expect(page).not_to have_content(potential_archived_project.name)
      end

      it 'allows adding memberships to a potential project' do
        within('.project-details') do
          expect(page).to have_selector('.Select-placeholder')
        end
      end
    end

    context 'when on Archived tab' do
      before { page.find('li.archived').click }

      it 'displays all archived projects' do
        expect(page.find_link(archived_project.name)).to be_visible
        expect(page.find_link(potential_archived_project.name)).to be_visible
      end

      it 'does not display active and potential non-archived projects' do
        expect(page).not_to have_content(active_project.name)
        expect(page).not_to have_content(potential_project.name)
      end

      it 'displays action icon (unarchive) when hovered' do
        expect(page).to have_selector('.unarchive')
      end

      it 'does not allow adding memberships to an archived project' do
        within('#projects-users') do
          expect(page).to have_no_selector('.Select-placeholder')
        end
      end
    end
  end

  describe 'project adding' do
    before { visit new_project_path }

    context 'when adding a valid project' do
      context 'with complete data' do
        it 'creates a new project' do
          fill_in('project_name', with: 'Project1')
          fill_in('project_kickoff', with: Date.today)
          fill_in('project_end_at', with: Date.parse(1.year.from_now.to_s))
          check('Potential')
          find('.btn-success').click

          expect(page).to have_content('Project1')
        end
      end
    end

    context 'when adding invalid project' do
      context 'when name is not present' do
        it 'fails with error message' do
          find('.btn-success').click
          expect(page).to have_content('can\'t be blank')
        end
      end
    end
  end

  describe 'project editing' do
    let(:project) { create(:project) }
    before { visit edit_project_path(project) }

    it 'allows to edit project' do
      check('Synchronize with profile?')
      fill_in('project_name', with: 'Edited project')
      fill_in('project_kickoff', with: Date.today)
      fill_in('project_end_at', with: Date.parse(1.year.from_now.to_s))
      find('.btn-success').click
      expect(page).to have_content('Edited project')
    end
  end

  describe 'managing people in project' do
    describe 'adding member to project' do
      it 'adds member to project correctly' do
        within('.projects-types') do
          find('li.active').click
        end

        react_select('.project', admin_user.decorate.name)

        billable_count = find('.billable .count')
        expect(billable_count).to have_content('1')
      end
    end

    describe 'ending membership in a regular project' do
      let!(:membership) { create(:membership, user: admin_user, project: active_project, ends_at: nil) }

      before { visit '/dashboard' }

      it 'sets and end date for a membership' do
        within('.projects-types') do
          find('li.active').click
        end

        expect(page).to_not have_selector('.label.label-default.time-to')

        within('div.project') do
          find('.member-name').hover
          find('.icons .remove').click
        end

        expect(page).to have_selector('.label.label-default.time-to')
      end
    end
  end

  describe 'managing notes' do
    describe 'add a new note' do
      before do
        find('.projects-types li.active').click
        find('.show-notes').click
      end

      it 'add a note to the project' do
        expect(page).not_to have_selector('div.note-group')
        find('input.new-project-note-text').set('Test note')
        find('a.new-project-note-submit').click
        expect(page.find('div.note-group', text: 'Test note')).to be_visible
      end
    end

    describe 'remove note' do
      before do
        create(:note, user: admin_user, project: active_project)
        find('.projects-types li.active').click
        find('.show-notes').click
      end

      it 'remove a note' do
        expect(page).to have_selector('div.note-group')
        expect(page).to have_content(note.text)

        find('.note-remove').click()
        expect(page).not_to have_selector('project-notes-wrapper')
        expect(page).not_to have_content(note.text)
      end
    end
  end
end
