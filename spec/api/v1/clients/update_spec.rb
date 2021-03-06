describe 'Client API' do
  describe 'PUT #update' do

    let!(:user) { create(:user) }
    let!(:user_token) { JWTWrapper.encode({ user_id: user.id } ) }

    let!(:client) { create(:client_user) }
    let!(:client_token) { JWTWrapper.encode({ user_id: client.id } ) }

    let!(:admin) { create(:admin_user) }
    let!(:admin_token) { JWTWrapper.encode({ user_id: admin.id } ) }

    let!(:client_item) {
      client_item = create(:client)
      client_item.users << client
      client_item
    }

    let!(:other_client) { create(:client) }

    let!(:updated_fields) {
      {
        client: {
          title: 'New title',
          full_name: 'New full name',
          tax_number: 'New tax number',
          description: 'New description'
        }
      }
    }

    let(:parsed_response) { JSON.parse(response.body) }

    it_behaves_like 'API authenticable'

    context 'authenticated' do

      context 'user with default role' do
        it 'return 403 status' do
          do_request(params: updated_fields, token: user_token)
          expect(response.status).to eq 403
        end
      end

      context 'user with client role' do
        it 'can update own record' do
          do_request(params: updated_fields, token: client_token)

          expect(response.status).to eq 200
          expect(parsed_response['id']).to eq(client_item.id)
          expect(parsed_response['title']).to eq(updated_fields[:client][:title])
          expect(parsed_response['full_name']).to eq(updated_fields[:client][:full_name])
          expect(parsed_response['tax_number']).to eq(updated_fields[:client][:tax_number])
          expect(parsed_response['description']).to eq(updated_fields[:client][:description])
        end

        it 'can not update other client' do
          do_request(params: updated_fields, token: client_token, client_id: other_client.id)
          expect(response.status).to eq 403
        end
      end

      context 'user with admin role' do
        it 'can update client attributes' do
          do_request(params: updated_fields, token: admin_token)

          expect(response.status).to eq 200
          expect(parsed_response['id']).to eq(client_item.id)
          expect(parsed_response['title']).to eq(updated_fields[:client][:title])
          expect(parsed_response['full_name']).to eq(updated_fields[:client][:full_name])
          expect(parsed_response['tax_number']).to eq(updated_fields[:client][:tax_number])
          expect(parsed_response['description']).to eq(updated_fields[:client][:description])
        end
      end
    end
  end

  def do_request(params: {}, token: '', client_id: client_item.id)
    headers = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{token}"
    }

    patch "/api/v1/clients/#{client_id}", params: { format: :json }.merge(params).to_json, headers: headers
  end
end