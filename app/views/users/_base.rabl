cache ["base", root_object]

attributes :id, :name, :email, :admin_role_id, :employment, :phone, :location_id, :contract_type, :archived, :abilities, :info, :months_in_current_project

node(:role) { |user| user.primary_role }
node(:role_id) { |user| user.primary_role.try(:id) }
node(:roles) { |user| user.positions.map(&:role) }
