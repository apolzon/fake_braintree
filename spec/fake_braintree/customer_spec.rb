require 'spec_helper'

describe "Braintree::Customer.create" do
  after { FakeBraintree.verify_all_cards = false }

  it "successfully creates a customer" do
    result = Braintree::Customer.create(:credit_card => { :number => TEST_CC_NUMBER,
                                                          :expiration_date => expiration_date })
    result.should be_success
  end

  it "creates a customer using an expiration month and year" do
    result = Braintree::Customer.create(:credit_card => { :number => TEST_CC_NUMBER,
                                                          :expiration_month => expiration_month,
                                                          :expiration_year => expiration_year })
    result.should be_success
  end

  it "records the billing address" do
    result = create_customer(
      :billing_address => {
        :street_address => "1 E Main St",
        :extended_address => "Suite 3",
        :locality => "Chicago",
        :region => "Illinois",
        :postal_code => "60622",
        :country_code_alpha2 => "US"
      }
    )

    billing_address = result.customer.credit_cards[0].billing_address

    billing_address.street_address.should == "1 E Main St"
    billing_address.postal_code.should == "60622"
  end

  context "when passed :verify_card => true" do
    it "accepts valid cards" do
      create_customer(:options => { :verify_card => true }).should be_success
    end

    it "rejects invalid cards" do
      create_customer_with_invalid_card(:options => { :verify_card => true }).should_not be_success
    end
  end

  context "when FakeBraintree.verify_all_cards == true" do
    before { FakeBraintree.verify_all_cards! }

    it "accepts valid cards" do
      create_customer.should be_success
    end

    it "rejects invalid cards" do
      create_customer_with_invalid_card.should_not be_success
    end
  end

  def create_customer(options = {})
    options[:number] ||= TEST_CC_NUMBER
    options[:expiration_date] ||= expiration_date
    Braintree::Customer.create(:credit_card => options)
  end

  def create_customer_with_invalid_card(options = {})
    options[:number] = '123456'
    options[:expiration_date] ||= expiration_date
    create_customer(options)
  end

  let(:expiration_month) { "04" }
  let(:expiration_year)  { "2016" }
  let(:expiration_date)  { [expiration_month, expiration_year].join("/") }
end

describe "Braintree::Customer.find" do
  let(:expiration_date) { "04/2016" }

  def create_customer(options)
    Braintree::Customer.create(:credit_card => options)
  end

  it "successfully finds a customer" do
    result = Braintree::Customer.create(:first_name => "Bob", :last_name => "Smith")

    Braintree::Customer.find(result.customer.id).first_name.should == "Bob"
  end

  it "raises an error for a nonexistent customer" do
    lambda { Braintree::Customer.find("foo") }.should raise_error(Braintree::NotFoundError)
  end
end