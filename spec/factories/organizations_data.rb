# frozen_string_literal: true

FactoryBot.define do
  factory :organization_data, class: Hash do
    skip_create

    sequence(:id) { |n| format('%03d', n) }
    sequence(:name) { |n| "Organization #{n}" }
    corporate_name { '' }
    address1 { '' }
    address2 { '' }
    zip_code { '' }
    city { '' }
    country { '' }
    contact_firstname { '' }
    contact_lastname { '' }
    contact_email { '' }
    contact_phone_number { '' }
    created_at { Time.now }
    parent_organization_id { 'global' }
    updated_at { Time.now }

    initialize_with do
      {
        'corporate_name' => corporate_name,
        'address1' => address1,
        'address2' => address2,
        'zip_code' => zip_code,
        'city' => city,
        'country' => country,
        'contact_firstname' => contact_firstname,
        'contact_lastname' => contact_lastname,
        'contact_email' => contact_email,
        'contact_phone_number' => contact_phone_number,
        'created_at' => created_at.iso8601,
        'id' => id,
        'name' => name,
        'parent_organization_id' => parent_organization_id,
        'updated_at' => updated_at.iso8601
      }
    end

    trait :child do
      sequence(:id) do |n|
        format(
          '%<code>s%<sequence>04d',
          code: parent_organization_id,
          sequence: n
        )
      end
      sequence(:parent_organization_id) { format('%03d', n) }
    end
  end
end
