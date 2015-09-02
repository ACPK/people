require 'spec_helper'

describe Api::ApiController do
  render_views

  controller(Api::ApiController) do
    def index
      render text: 'nothing'
    end
  end

  describe '#authenticate_api' do

    context 'with valid token' do
      it 'will not call render' do
        get :index, token: AppConfig.api_token
        expect(response.body).to eq('nothing')
      end
    end

    context 'with invalid token' do
      it 'calls render with 403 status' do
        get :index, token: 'whatever'
        expect(response.status).to eq(403)
      end
    end
  end
end
