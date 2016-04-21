require 'virtual_incentives'
require 'webmock/rspec'

describe VirtualIncentives do
  let(:auth) {
    {
      user: 'test',
      password: 'test'
    }
  }

  after do
    VirtualIncentives.auth  = nil
    VirtualIncentives.auths = nil
  end

  it 'errors without auth' do
    expect{
      VirtualIncentives.orders
    }.to raise_error 'you must set an auth token at application boot'
  end

  it 'errors without auth, but auths set' do
    VirtualIncentives.auths = {default: auth}

    expect{
      VirtualIncentives.orders
    }.to raise_error 'you must init a new API instance with the auth you want to use'
  end

  it 'errors for unregistered auth' do
    VirtualIncentives.auths = {default: auth}

    expect{
      VirtualIncentives.new(auth: :foo).orders
    }.to raise_error KeyError, 'key not found: :foo'
  end

  it 'errors when both auth and auths are set' do
    VirtualIncentives.auth  = auth
    VirtualIncentives.auths = {default: auth}

    expect{
      VirtualIncentives.orders
    }.to raise_error "auth and auths can't both be set"

    expect{
      VirtualIncentives.new(auth: :default).orders
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
          stub_request(:post, "https://test:test@rest.virtualincentives.com/v3/json/order").
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
          stub_request(:get, 'https://test:test@rest.virtualincentives.com/v3/json/order/24681234').
            to_return(status: 200, body: '{"order":{"programid":"26490","clientid":"56258125","number":"24681234","status":"completed","accounts":[{"id":"85425","firstname":"John","lastname":"Doe","email":"john.doe@example.com","sku":"UVC-V-A06","amount":"10.00","udf1":"","udf2":"","link":"https://www.virtualrewardcenter.com/Landing.aspx?id=85425&sid=b173b47f-228c-4a97-8d68-e5835ca4ac66"},{"id":"85426","firstname":"Jane","lastname":"Doe","email":"jane.doe@example.com","sku":"UVC-V-A06","amount":"25.00","udf1":"","udf2":"","link":"https://www.virtualrewardcenter.com/Landing.aspx?id=85426&sid=1c2ce48f-8e27-43a4-948a-e4a05e612dab"}]}}')
          res = api.order('24681234')
          expect(res['order']['programid']).to eql '26490'
          expect(res['order']['clientid']).to eql '56258125'
          expect(res['order']['number']).to eql '24681234'
        end
      end

      describe '#orders' do
        it 'lists all orders' do
          stub_request(:post, "https://test:test@rest.virtualincentives.com/v3/json/order/list").
            to_return(status: 200, body: '{"orders":{"order":[{"programid":"26490","number":"24686669","clientid":"56258125","status":"completed"},{"programid":"26490","number":"24686670","clientid":"56258126","status":"completed"},{"programid":"26490","number":"24686671","clientid":"56258127","status":"completed"},{"programid":"26490","number":"24686672","clientid":"56258128","status":"pending"}]}}')
          res = api.orders({orders: {programid: '26490'}})
          expect(res['orders']['order'][0]['number']).to eql '24686669'
          expect(res['orders']['order'][1]['number']).to eql '24686670'
        end
      end
    end
  end
end
