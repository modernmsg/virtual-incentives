# coding: utf-8
require 'virtual_incentives'
require 'webmock/rspec'

describe VirtualIncentives do
  let(:auth) {
    {
      user: 'test',
      password: 'test'
    }
  }
  let(:programid) {
    'testid'
  }

  after do
    VirtualIncentives.auth  = nil
    VirtualIncentives.auths = nil
  end

  it 'errors without auth' do
    expect{
      VirtualIncentives.orders programid
    }.to raise_error 'you must set an auth token at application boot'
  end

  it 'errors without auth, but auths set' do
    VirtualIncentives.auths = {default: auth}

    expect{
      VirtualIncentives.orders programid
    }.to raise_error 'you must init a new API instance with the auth you want to use'
  end

  it 'errors for unregistered auth' do
    VirtualIncentives.auths = {default: auth}

    expect{
      VirtualIncentives.new(auth: :foo).orders programid
    }.to raise_error KeyError, 'key not found: :foo'
  end

  it 'errors when both auth and auths are set' do
    VirtualIncentives.auth  = auth
    VirtualIncentives.auths = {default: auth}

    expect{
      VirtualIncentives.orders programid
    }.to raise_error "auth and auths can't both be set"

    expect{
      VirtualIncentives.new(auth: :default).orders programid
    }.to raise_error "auth and auths can't both be set"
  end

  it '.each_auth' do
    VirtualIncentives.auths = {default: auth, custom: 'foo'}

    times_called = 0

    VirtualIncentives.each_auth do |api|
      times_called += 1

      expect(api).to be_an_instance_of VirtualIncentives
      expect([auth, 'foo']).to include api.auth
    end

    expect(times_called).to eq 2
  end

  [:class, :instance].each do |variant|
    describe "(#{variant})" do
      before do |example|
        if variant == :class
          VirtualIncentives.auth = example.metadata[:invalid_auth] ? 'notavalidtoken' : auth
        else
          VirtualIncentives.auths = {default: auth}
          VirtualIncentives.auths.merge! invalid: 'notavalidtoken' if example.metadata[:invalid_auth]
        end
      end

      let :api do |example|
        if variant == :class
          VirtualIncentives
        else
          auth = example.metadata[:invalid_auth] ? :invalid : :default
          VirtualIncentives.new auth: auth
        end
      end

      describe '#place_order' do
        it 'should place an order' do
          stub_request(:post, "https://test:test@rest.virtualincentives.com/v4/json/orders").
            to_return(status: 200, body: '{"order":{"programid":"26490","clientid":"56258125","number":"24681234","status":"completed","accounts":[{"id":"85425","firstname":"Participant","lastname":"Participant","email":"support@virtualrewardcenter.com","sku":"UVC-V-A06","amount":"10.00","link":"https://www.virtualrewardcenter.com/Landing.aspx?id=85425&sid=b173b47f-228c-4a97-8d68-e5835ca4ac66"}]}}')
          res = api.place_order({ order: { programid:"26490",
                                           clientid: "56258125",
                                           accounts:[
                                             {
                                               firstname:"Participant",
                                               lastname:"Participant",
                                               email:"support@virtualrewardcenter.com",
                                               sku:"UVC-V-A06",
                                               amount:"10.00"
                                             }]
                                         }
                                })
          expect(res['order']['programid']).to eql '26490'
          expect(res['order']['clientid']).to eql '56258125'
          expect(res['order']['status']).to eql 'completed'
        end
      end

      describe '#order' do
        it 'should gather order information' do
          stub_request(:get, 'https://test:test@rest.virtualincentives.com/v4/json/orders/24681234').
            to_return(status: 200, body: '{"order":{"programid":"26490","clientid":"56258125","number":"24681234","status":"completed","accounts":[{"id":"85425","firstname":"John","lastname":"Doe","email":"john.doe@example.com","sku":"UVC-V-A06","amount":"10.00","udf1":"","udf2":"","link":"https://www.virtualrewardcenter.com/Landing.aspx?id=85425&sid=b173b47f-228c-4a97-8d68-e5835ca4ac66"},{"id":"85426","firstname":"Jane","lastname":"Doe","email":"jane.doe@example.com","sku":"UVC-V-A06","amount":"25.00","udf1":"","udf2":"","link":"https://www.virtualrewardcenter.com/Landing.aspx?id=85426&sid=1c2ce48f-8e27-43a4-948a-e4a05e612dab"}]}}')
          res = api.order('24681234')
          expect(res['order']['programid']).to eql '26490'
          expect(res['order']['clientid']).to eql '56258125'
          expect(res['order']['number']).to eql '24681234'
        end
      end

      describe '#orders' do
        it 'lists all orders' do
          stub_request(:get, "https://test:test@rest.virtualincentives.com/v4/json/orders").
            to_return(status: 200, body: '{"orders":{"order":[{"programid":"26490","number":"24686669","clientid":"56258125","status":"completed"},{"programid":"26490","number":"24686670","clientid":"56258126","status":"completed"},{"programid":"26490","number":"24686671","clientid":"56258127","status":"completed"},{"programid":"26490","number":"24686672","clientid":"56258128","status":"pending"}]}}')
          res = api.orders
          expect(res['orders']['order'][0]['number']).to eql '24686669'
          expect(res['orders']['order'][1]['number']).to eql '24686670'
        end
      end

      describe '#product' do
        it 'should gather product information' do
          stub_request(:get, 'https://test:test@rest.virtualincentives.com/v4/json/products/UVC-V-A03').
            to_return(status: 200, body: '{"product":{"name": " Virtual Visa® Reward (US), 3-Month","sku": "UVC-V-A03","currency": "USD","denomination": {"range":[{"min": 5,"max": 2000}]},"base-url": "","redemptions": []}}')
          res = api.product('UVC-V-A03')
          expect(res['product']['name']).to eql ' Virtual Visa® Reward (US), 3-Month'
          expect(res['product']['sku']).to eql 'UVC-V-A03'
        end
      end

      describe '#product_faceplate' do
        it 'should gather face plate' do
          stub_request(:get, 'https://test:test@rest.virtualincentives.com/v4/json/products/UVC-V-A03/faceplate').
            to_return(status: 200, body: '{"product":{"faceplate":"https//www.virtualrewardcenter.com/images/cards/Virtual_Visa.png"}}')
          res = api.product_faceplate('UVC-V-A03')
          expect(res['product']['faceplate']).to eql 'https//www.virtualrewardcenter.com/images/cards/Virtual_Visa.png'
        end
      end

      describe '#product_marketing' do
        it 'should gather product marketing information' do
          stub_request(:get, 'https://test:test@rest.virtualincentives.com/v4/json/products/UVC-V-A03/marketing').
            to_return(status: 200, body: '{"product": {"marketing": "The Visa® Reward Card can be used to buy what you want, when you want it. Because it is so flexible and convenient, the Visa Reward Card makes it easy to treat yourself to something special or to help cover your everyday expenses. The decision is yours."}}')
          res = api.product_marketing('UVC-V-A03')
          expect(res['product']['marketing']).to eql 'The Visa® Reward Card can be used to buy what you want, when you want it. Because it is so flexible and convenient, the Visa Reward Card makes it easy to treat yourself to something special or to help cover your everyday expenses. The decision is yours.'
        end
      end

      describe '#product_terms' do
        it 'should gather product terms' do
          stub_request(:get, 'https://test:test@rest.virtualincentives.com/v4/json/products/UVC-V-A03/terms').
            to_return(status: 200, body: '{"product": {"terms":"Cards are issued by Citibank, N.A. pursuant to a license from Visa U.S.A. Inc. and managed by Citi Prepaid Services. This card can be used everywhere Visa debit cards are accepted."}}')
          res = api.product_terms('UVC-V-A03')
          expect(res['product']['terms']).to eql 'Cards are issued by Citibank, N.A. pursuant to a license from Visa U.S.A. Inc. and managed by Citi Prepaid Services. This card can be used everywhere Visa debit cards are accepted.'
        end
      end

      describe '#products' do
        it 'should gather all products' do
          stub_request(:get, 'https://test:test@rest.virtualincentives.com/v4/json/products').
            to_return(status: 200, body: '{"products": [{"name": "Virtual Visa® Reward (US), 3-Month","sku": "UVC-V-A03","currency": "USD","denomination": {"range":[{"min": 5,"max": 2000}]},"base-url": "","redemptions": []},{"name": "Virtual Visa® Reward (US), 6-Month","sku": "UVC-V-A06","currency": "USD", "denomination": {"range": [{"min": 5,"max": 2000}]},"base-url": "","redemptions": []}]}')
          res = api.products
          expect(res['products'][0]['sku']).to eql 'UVC-V-A03'
          expect(res['products'][1]['sku']).to eql 'UVC-V-A06'
        end
      end

      describe '#balances' do
        it 'should gather balances' do
          stub_request(:get, 'https://test:test@rest.virtualincentives.com/v4/json/balances').
            to_return(status: 200, body: '{"balances":[{"balance":61.15,"currency": "USD","symbol": "$"},{"balance": 0.00,"currency": "CAD","symbol": "$"}]}')
          res = api.balances
          expect(res['balances'][0]['balance']).to eql 61.15
          expect(res['balances'][1]['balance']).to eql 0.00
        end
      end

      describe '#program_balances' do
        it 'should gather program balances' do
          stub_request(:get, 'https://test:test@rest.virtualincentives.com/v4/json/balances/programs').
            to_return(status: 200, body: '{"program": [{"name": " Survey Incentives","programid": 26209,"balance": -27.35,"currency": "USD","type": "Physical Reward"},{"name": "Loyalty Rewards","programid": 34307,"balance": 530.00,"currency": "USD","type": "Gift Cards"}]}')
          res = api.program_balances
          expect(res['program'][0]['balance']).to eql(-27.35)
          expect(res['program'][1]['balance']).to eql(530.00)
        end
      end

      describe '#program_products' do
        it 'should gather program products' do
          stub_request(:get, 'https://test:test@rest.virtualincentives.com/v4/json/programs/1/products').
            to_return(status: 200, body: '{"products": [{"name": " Virtual Visa® Reward (US), 3-Month","sku": "UVC-V-A03","currency": "USD","denomination": {"range": [{"min": 5,"max": 2000}]},"base-url": "","redemptions": []},{"name": " Virtual Visa® Reward (US), 6-Month","sku": "UVC-V-A06","currency": "USD","denomination": {"range": [{"min": 5,"max": 2000}]},"base-url": "","redemptions": []}]}')
          res = api.program_products('1')
          expect(res['products'][0]['sku']).to eql 'UVC-V-A03'
          expect(res['products'][1]['sku']).to eql 'UVC-V-A06'
        end
      end

      describe '#program_balance' do
        it 'should gather program balance' do
          stub_request(:get,'https://test:test@rest.virtualincentives.com/v4/json/balances/programs/26209').
            to_return(status: 200, body: '{"program": [{"name": "Survey Incentives","programid": 26209,"balance": -27.35,"currency": "USD","type": "Physical Reward"}]}')
          res = api.program_balance('26209')
          expect(res['program'][0]['programid']).to eql 26209
          expect(res['program'][0]['balance']).to eql(-27.35)
        end
      end

      describe '#program_product' do
        it 'should gather program product' do
          stub_request(:get,'https://test:test@rest.virtualincentives.com/v4/json/programs/26209/products/UVC-V-A03').
            to_return(status: 200, body: '{"product":{"name": " Virtual Visa® Reward (US), 3-Month","sku": "UVC-V-A03","currency": "USD","denomination": {"range": [{"min": 5,"max": 2000}]},"base-url": "","redemptions": []}}')
          res = api.program_product('26209', 'UVC-V-A03')
          expect(res['product']['sku']).to eql 'UVC-V-A03'
        end
      end
    end
  end
end
