# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_context 'valid token request' do
  let(:token_details) do
    {
      # Not a valid access token, but thats OK
      access_token: SecureRandom.uuid,
      expires_in: 3600,
      token_type: 'bearer'
    }
  end
  let(:token_response) do
    {
      status: 200,
      body: token_details.to_json,
      headers: {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }
    }
  end

  before do
    stub_request(
      :post,
      "#{base_url}/api/v2/client/tokens"
    ).to_return(token_response)
  end
end

RSpec.describe PeopleDoc::V2::Client do
  let(:application_id) { SecureRandom.uuid }
  let(:application_secret) { SecureRandom.uuid }
  let(:base_url) { 'https://apis.test.us.people-doc.com' }
  let(:client_id) { SecureRandom.uuid }
  let(:encoded_credentials) do
    PeopleDoc::V2::EncodedCredentials
      .new(application_id, application_secret)
      .call
  end
  let(:host_uri) { URI.parse(base_url) }
  let(:instance) do
    # These details don't really matter as we're going to mock the responses.
    described_class.new(
      application_id: application_id,
      application_secret: application_secret,
      base_url: base_url,
      client_id: client_id,
      logger: logger
    )
  end
  let(:logger) { spy }

  describe 'token' do
    subject do
      instance.token
    end

    before do
      stub_request(
        :post,
        "#{base_url}/api/v2/client/tokens"
      )
        .with(
          body: {
            client_id: client_id,
            grant_type: 'client_credentials',
            scope: 'client'
          },
          headers: {
            'Accept' => 'application/json',
            'Authorization' => "Basic #{encoded_credentials}",
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Host' => host_uri.host,
            'User-Agent' => 'PeopleDoc::V2::Client'
          }
        )
        .to_return(response)
    end

    context 'when the credentials are valid' do
      let(:response) do
        {
          status: 200,
          body: token_details.to_json,
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
          }
        }
      end
      let(:token_details) do
        {
          # Not a valid access token, but thats OK
          access_token: SecureRandom.uuid,
          expires_in: 3600,
          token_type: 'bearer'
        }
      end

      it 'returns a token' do
        expect(subject).to have_attributes(
          access_token: token_details[:access_token],
          expires_in: token_details[:expires_in],
          token_type: token_details[:token_type]
        )
      end
    end

    context 'when the application details are not valid' do
      let(:response) do
        {
          status: 401,
          body: {
            error_description: 'Client authentication failed.',
            error: 'invalid_client'
          }.to_json,
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
          }
        }
      end

      it 'fails with PeopleDoc::Unauthorized' do
        expect { subject }
          .to raise_error(
            PeopleDoc::Unauthorized,
            'invalid_client: Client authentication failed.'
          )
      end
    end

    context 'when the client id is not valid' do
      let(:response) do
        {
          status: 400,
          body: {
            error_description: 'The request is invalid',
            error: 'invalid_request'
          }.to_json,
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
          }
        }
      end

      it 'fails with PeopleDoc::BadRequest' do
        expect { subject }
          .to raise_error(PeopleDoc::BadRequest, 'The request is invalid')
      end
    end
  end

  describe 'get an organization' do
    include_context 'valid token request'

    subject do
      instance.get("organizations/#{organization_data[:id]}")
    end

    let(:organization_data) { build(:organization_data) }

    before do
      stub_request(
        :get,
        "#{base_url}/api/v2/client/organizations/#{organization_data[:id]}"
      )
        .with(
          headers: {
            'Accept' => 'application/json',
            'Authorization' => "Bearer #{token_details[:access_token]}",
            'Content-Type' => 'application/json',
            'Host' => host_uri.host,
            'User-Agent' => 'PeopleDoc::V2::Client'
          }
        )
        .to_return(response)
    end

    context 'when the token is not valid' do
      let(:response) do
        {
          status: 401,
          body: {
            message: 'Token is invalid.',
            code: 'invalid_token'
          }.to_json,
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
          }
        }
      end

      # This probably wouldn't happen unless we were caching the token across
      # multiple requests or a process task was really long running and the
      # token expired.
      it 'fails with PeopleDoc::Unauthorized' do
        expect { subject }
          .to raise_error(
            PeopleDoc::Unauthorized, 'invalid_token: Token is invalid.'
          )
      end
    end

    context 'when the token is valid' do
      let(:response) do
        {
          status: 200,
          body: organization_data.to_json,
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
          }
        }
      end

      it 'returns the organization details' do
        expect(subject).to eq organization_data
      end
    end
  end

  describe 'put an organization' do
    include_context 'valid token request'

    subject do
      instance.put("organizations/#{organization_data[:id]}", organization_data)
    end

    let(:organization_data) do
      build(
        :organization_data,
        created_at: Date.today.next_month,
        updated_at: Date.today.next_day(7)
      )
    end
    let(:response) do
      {
        status: 200,
        body: organization_data.merge('updated_at' => updated_at).to_json,
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }
      }
    end
    let(:updated_at) { Time. now.iso8601 }

    before do
      stub_request(
        :put,
        "#{base_url}/api/v2/client/organizations/#{organization_data[:id]}"
      )
        .with(
          body: {
          },
          headers: {
            'Accept' => 'application/json',
            'Authorization' => "Bearer #{token_details[:access_token]}",
            'Content-Type' => 'application/json',
            'Host' => host_uri.host,
            'User-Agent' => 'PeopleDoc::V2::Client'
          }
        )
        .to_return(response)
    end

    it 'returns the updated organization details' do
      expect(subject)
        .to eq organization_data.merge('updated_at' => updated_at)
    end
  end
end
