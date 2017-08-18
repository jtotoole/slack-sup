require 'spec_helper'

describe SlackSup::Commands::Set, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:admin) { Fabricate(:user, team: team, user_name: 'username', is_admin: true) }
  context 'admin' do
    before do
      expect(User).to receive(:find_create_or_update_by_slack_id!).and_return(admin)
    end
    it 'gives help' do
      expect(message: "#{SlackRubyBot.config.user} set").to respond_with_slack_message(
        'Missing setting, eg. _set api off_.'
      )
    end
    context 'api' do
      it 'shows current value of API on' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "API for team #{team.name} is on!\n#{team.api_url}"
        )
      end
      it 'shows current value of API off' do
        team.update_attributes!(api: false)
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "API for team #{team.name} is off."
        )
      end
      it 'enables API' do
        expect(message: "#{SlackRubyBot.config.user} set api on").to respond_with_slack_message(
          "API for team #{team.name} is on!\n#{team.api_url}"
        )
        expect(team.reload.api).to be true
      end
      it 'disables API with set' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} set api off").to respond_with_slack_message(
          "API for team #{team.name} is off."
        )
        expect(team.reload.api).to be false
      end
      it 'disables API with unset' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} unset api").to respond_with_slack_message(
          "API for team #{team.name} is off."
        )
        expect(team.reload.api).to be false
      end
      context 'with API_URL' do
        before do
          ENV['API_URL'] = 'http://local.api'
        end
        after do
          ENV.delete 'API_URL'
        end
        it 'shows current value of API on with API URL' do
          team.update_attributes!(api: true)
          expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
            "API for team #{team.name} is on!\nhttp://local.api/teams/#{team.id}"
          )
        end
        it 'shows current value of API off without API URL' do
          team.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
            "API for team #{team.name} is off."
          )
        end
      end
    end
    context 'invalid' do
      it 'errors set' do
        expect(message: "#{SlackRubyBot.config.user} set invalid on").to respond_with_slack_message(
          'Invalid setting invalid, you can _set api on|off_.'
        )
      end
      it 'errors unset' do
        expect(message: "#{SlackRubyBot.config.user} unset invalid").to respond_with_slack_message(
          'Invalid setting invalid, you can _unset api_.'
        )
      end
    end
  end
  context 'not admin' do
    context 'api' do
      it 'cannot set api' do
        expect(message: "#{SlackRubyBot.config.user} set api true").to respond_with_slack_message(
          'Only a Slack team admin can do this, sorry.'
        )
      end
      it 'can see api value' do
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "API for team #{team.name} is on!\n#{team.api_url}"
        )
      end
    end
  end
end