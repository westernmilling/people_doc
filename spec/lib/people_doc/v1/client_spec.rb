# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PeopleDoc::V1::Client do
  RSpec.shared_context 'invalid API key' do
    let(:response) do
      {
        status: 403,
        body: 'Auth Token invalid'
      }
    end
  end

  RSpec.shared_examples 'fails with PeopleDoc::Unauthorized' do
    it 'fails with PeopleDoc::Unauthorized' do
      expect { subject }
        .to raise_error(PeopleDoc::Unauthorized, 'Auth Token invalid')
    end
  end

  let(:api_key) { SecureRandom.uuid }
  let(:base_url) { 'https://api.test.us.people-doc.com' }
  let(:host_uri) { URI.parse(base_url) }
  let(:instance) do
    # These details don't really matter as we're going to mock the responses.
    described_class.new(
      api_key: api_key,
      base_url: base_url,
      logger: logger
    )
  end
  let(:logger) { spy }

  describe 'get an employee' do
    subject do
      instance.get("employees/#{employee_number}")
    end

    let(:employee_number) { Faker::Lorem.unique.characters(9).upcase }

    before do
      stub_request(:get, "#{base_url}/api/v1/employees/#{employee_number}")
        .with(
          headers: {
            'Accept' => 'application/json',
            'X-API-KEY' => api_key,
            'Content-Type' => 'application/json',
            'Host' => host_uri.host,
            'User-Agent' => 'PeopleDoc::V1::Client'
          }
        )
        .to_return(response)
    end

    context 'when the API Key is not valid' do
      include_context 'invalid API key'
      include_examples 'fails with PeopleDoc::Unauthorized'
    end
    # context 'when the API Key is not valid' do
    #   let(:response) do
    #     {
    #       status: 403,
    #       body: 'Auth Token invalid'
    #     }
    #   end
    #
    #   it 'fails with PeopleDoc::Unauthorized' do
    #     expect { subject }
    #       .to raise_error(PeopleDoc::Unauthorized, 'Auth Token invalid')
    #   end
    # end

    context 'when the employee exists' do
      let(:response) do
        {
          status: 200,
          headers: {
            'Content-Type' => 'application/json'
          },
          body: {
            gone: false,
            electronic_payslips_opt_out_origin: nil,
            filters: {
              worker_category: '',
              Manager_1: '',
              Manager_2: '',
              Manager_3: '',
              Manager_4: '',
              Manager_5: '',
              Manager_6: '',
              Manager_7: '',
              Manager_8: '',
              Manager_9: ''
            },
            disable_elec_distribution: false,
            disable_paper_distribution: false,
            maiden_name: '',
            mobile_phone_number: '',
            address1: '',
            email: employee_data[:email],
            zip_code: '',
            phone_number: '',
            registration_references: [
              {
                active: true,
                registration_number: employee_data[:technical_id],
                organization_code: employee_data[:organization_code]
              }
            ],
            firstname: employee_data[:first_name],
            city: '',
            lastname: employee_data[:last_name],
            address2: '',
            address3: '',
            dob: nil,
            country: '',
            electronic_payslips_opt_out_date: nil,
            electronic_payslips_opted_out: false,
            disable_vault: false,
            starting_date: nil,
            technical_id: employee_data[:technical_id]
          }.to_json
        }
      end
      let(:employee_data) do
        build(:employee_data, technical_id: employee_number)
      end

      it 'returns the employee details' do
        expect(subject).to include(
          'email' => employee_data[:email],
          'firstname' => employee_data[:first_name],
          'lastname' => employee_data[:last_name],
          'technical_id' => employee_data[:technical_id],
          'registration_references' => [
            {
              'active' => true,
              'registration_number' => employee_data[:technical_id],
              'organization_code' => employee_data[:organization_code]
            }
          ]
        )
      end
    end

    context 'when the employee does not exist' do
      let(:response) do
        {
          status: 404,
          body: {
            message: 'not found'
          }.to_json
        }
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe 'post a company document' do
    subject do
      instance.post_file('enterprise/documents', file, data)
    end

    let(:file) { double }
    let(:data) { double }

    before do
      stub_request(:post, "#{base_url}/api/v1/enterprise/documents/")
        .with(
          # body: nil, # No body mock as this won't work with multipart
          headers: {
            'Accept' => 'multipart/form-data',
            'X-API-KEY' => api_key,
            'Host' => host_uri.host,
            'User-Agent' => 'PeopleDoc::V1::Client'
          }
        )
        .to_return(response)
    end

    context 'when the API Key is not valid' do
      include_context 'invalid API key'
      include_examples 'fails with PeopleDoc::Unauthorized'
    end

    context 'when the details are valid' do
      let(:new_id) { 10_000 + rand(1_000) }
      let(:response) do
        {
          status: 201,
          body: { id: new_id }.to_json,
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
          }
        }
      end

      it 'returns the document id' do
        expect(subject).to include('id' => new_id)
      end
    end

    context 'when the request is not valid' do
      let(:response) do
        {
          status: 400,
          body: {
            message: 'Invalid param document_type_code',
            code: '1409',
            success: false
          }.to_json,
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
          }
        }
      end

      it 'fails with PeopleDoc::BadRequest' do
        expect { subject }
          .to raise_error(
            PeopleDoc::BadRequest, 'Invalid param document_type_code'
          )
      end
    end
  end

  describe 'post employee details' do
    subject do
      instance.post('employees', employee_data)
    end

    before do
      stub_request(:post, "#{base_url}/api/v1/employees/")
        .with(
          body: employee_data.to_json,
          headers: {
            'Accept' => 'application/json',
            'X-API-KEY' => api_key,
            'Content-Type' => 'application/json',
            'Host' => host_uri.host,
            'User-Agent' => 'PeopleDoc::V1::Client'
          }
        )
        .to_return(response)
    end

    context 'when the API Key is not valid' do
      include_context 'invalid API key'
      include_examples 'fails with PeopleDoc::Unauthorized'
    end

    context 'when the request is not valid' do
      let(:employee_data) { {} }
      let(:response) do
        {
          status: 400,
          body: {
            errors: [
              { msg: 'technical_id is required', code: '1400' }
            ]
          }.to_json,
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
          }
        }
      end

      it 'fails with PeopleDoc::BadRequest' do
        expect { subject }
          .to raise_error(PeopleDoc::BadRequest, 'technical_id is required')
      end
    end

    context 'when the request not valid' do
      let(:employee_data) { build(:employee_data) }
      let(:response) do
        {
          status: 202,
          body: {
            technical_id: employee_data[:technical_id]
          }.to_json,
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
          }
        }
      end

      it 'returns the technical id' do
        expect(subject).to eq('technical_id' => employee_data[:technical_id])
      end
    end
  end
end
