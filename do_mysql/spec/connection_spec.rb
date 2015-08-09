# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/shared/connection_spec'
require 'cgi'
require 'stringio'


describe DataObjects::Mysql::Connection do

  before :all do
    @driver = CONFIG.scheme
    @user   = CONFIG.user
    @password = CONFIG.pass
    @host   = CONFIG.host
    @port   = CONFIG.port
    @database = CONFIG.database
    @ssl    = CONFIG.ssl
  end

    subject { connection }

    let(:connection) { described_class.new(uri) }

    after { connection.close }

    context 'should define a standard API' do
      let(:uri)   { 'mock://localhost'      }

      it { should respond_to(:dispose)        }
      it { should respond_to(:create_command) }

      its(:to_s)  { should == 'mock://localhost' }
    end

    describe 'initialization' do

      context 'with a connection uri as a Addressable::URI' do
        let(:uri)  { Addressable::URI::parse('mock://localhost/database') }

        it { should be_kind_of(DataObjects::Mock::Connection) }
        it { should be_kind_of(DataObjects::Pooling)          }

        its(:to_s) { should == 'mock://localhost/database' }
      end

      [
        'java:comp/env/jdbc/DataSource?driver=mock2',
        Addressable::URI.parse('java:comp/env/jdbc/DataSource?driver=mock2')
      ].each do |jndi_url|
        context 'should return the Connection specified by the scheme without pooling' do
          let(:uri)  { jndi_url }

          it { should be_kind_of(DataObjects::Mock2::Connection) }
          it { should_not be_kind_of(DataObjects::Pooling)       }
        end
      end

      %w(
      jdbc:mock:memory::
      jdbc:mock://host/database
      jdbc:mock://host:6969/database
      jdbc:mock:thin:host:database
      jdbc:mock:thin:@host.domain.com:6969:database
      jdbc:mock://server:6969/database;property=value;
      jdbc:mock://[1111:2222:3333:4444:5555:6666:7777:8888]/database
    ).each do |jdbc_url|
        context "with JDBC URL '#{jdbc_url}'" do
          let(:uri)  { jdbc_url }

          it { should be_kind_of(DataObjects::Mock::Connection) }
        end
      end

    end



  if DataObjectsSpecHelpers.test_environment_supports_ssl?

    describe 'connecting with SSL' do

      it 'should raise an error when passed ssl=true' do
        lambda { DataObjects::Connection.new("#{CONFIG.uri}?ssl=true") }.
          should raise_error(ArgumentError)
      end

      it 'should raise an error when passed a nonexistent client certificate' do
        lambda { DataObjects::Connection.new("#{CONFIG.uri}?ssl[client_cert]=nonexistent") }.
          should raise_error(ArgumentError)
      end

      it 'should raise an error when passed a nonexistent client key' do
        lambda { DataObjects::Connection.new("#{CONFIG.uri}?ssl[client_key]=nonexistent") }.
          should raise_error(ArgumentError)
      end

      it 'should raise an error when passed a nonexistent ca certificate' do
        lambda { DataObjects::Connection.new("#{CONFIG.uri}?ssl[ca_cert]=nonexistent") }.
          should raise_error(ArgumentError)
      end

      it 'should connect with a specified SSL cipher' do
        DataObjects::Connection.new("#{CONFIG.uri}?#{CONFIG.ssl}&ssl[cipher]=#{SSLHelpers::CONFIG.cipher}").
          ssl_cipher.should == SSLHelpers::CONFIG.cipher
      end

      it 'should raise an error with an invalid SSL cipher' do
        lambda { DataObjects::Connection.new("#{CONFIG.uri}?#{CONFIG.ssl}&ssl[cipher]=invalid") }.
          should raise_error
      end

    end

  end

end

