FactoryGirl.define do
  factory :membership do
    starts_at { Time.now - 5.weeks }
    ends_at { Time.now + 1.month }
    user
    project
    role
    billable 0

    factory :membership_without_ends_at do
      ends_at nil
    end

    factory :membership_billable do
      billable 1
    end

    trait :without_end do
      ends_at nil
    end

    trait :booked do
      booked true
    end

    trait :billable do
      billable true
    end
  end
end
