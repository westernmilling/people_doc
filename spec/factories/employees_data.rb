# frozen_string_literal: true

FactoryBot.define do
  factory :employee_data, class: Hash do
    skip_create

    email_address { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    organization_code { Faker::Lorem.characters(3).upcase }
    registration_number { technical_id }
    technical_id { Faker::Lorem.unique.characters(9).upcase }

    initialize_with do
      {
        'gone' => false,
        'electronic_payslips_opt_out_origin' => nil,
        'filters' => {
          'worker_category' => '',
          'Manager_1' => '',
          'Manager_2' => '',
          'Manager_3' => '',
          'Manager_4' => '',
          'Manager_5' => '',
          'Manager_6' => '',
          'Manager_7' => '',
          'Manager_8' => '',
          'Manager_9' => ''
        },
        'disable_elec_distribution' => false,
        'disable_paper_distribution' => false,
        'maiden_name' => '',
        'mobile_phone_number' => '',
        'address1' => '',
        'email' => email_address,
        'zip_code' => '',
        'phone_number' => '',
        'registration_references' => [
          {
            'active' => true,
            'registration_number' => registration_number,
            'organization_code' => organization_code
          }
        ],
        'firstname' => first_name,
        'city' => '',
        'lastname' => last_name,
        'address2' => '',
        'address3' => '',
        'dob' => nil,
        'country' => '',
        'electronic_payslips_opt_out_date' => nil,
        'electronic_payslips_opted_out' => false,
        'disable_vault' => false,
        'starting_date' => nil,
        'technical_id' => technical_id
      }
    end
  end
end
