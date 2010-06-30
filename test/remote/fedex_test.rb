require 'test_helper'

class FedExTest < Test::Unit::TestCase

  def setup
    @packages  = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier   = FedEx.new(fixtures(:fedex).merge(:test => true))
  end
    
  def _test_valid_credentials
    assert @carrier.valid_credentials?
  end
    
  def test_us_to_canada
    response = nil
    assert_nothing_raised do
      response = @carrier.find_rates(
                   @locations[:beverly_hills],
                   @locations[:ottawa],
                   @packages.values_at(:wii)
                 )
      assert !response.rates.blank?
      response.rates.each do |rate|
        assert_instance_of String, rate.service_name
        assert_instance_of Fixnum, rate.price
      end
    end
  end
  
  def test_zip_to_zip_fails
    begin
      @carrier.find_rates(
        Location.new(:zip => 40524),
        Location.new(:zip => 40515),
        @packages[:wii]
      )
    rescue ResponseError => e
      assert_match /country\s?code/i, e.message
      assert_match /(missing|invalid)/, e.message
    end
  end
  
  # FedEx requires a valid origin and destination postal code
  def test_rates_for_locations_with_only_zip_and_country  
    response = @carrier.find_rates(
                 @locations[:bare_beverly_hills],
                 @locations[:bare_ottawa],
                 @packages.values_at(:wii)
               )

    assert response.rates.size > 0
  end
  
  def test_rates_for_location_with_only_country_code
    begin
      response = @carrier.find_rates(
                   @locations[:bare_beverly_hills],
                   Location.new(:country => 'CA'),
                   @packages.values_at(:wii)
                 )
    rescue ResponseError => e
      assert_match /postal code/i, e.message
      assert_match /(missing|invalid)/i, e.message
    end
  end
  
  def test_rates_for_location_with_address
    response = @carrier.find_rates(
                 @locations[:beverly_hills],
                 @locations[:real_google_as_commercial],
                 @packages.values_at(:wii)
               )

    assert response.rates.size > 0
  end
  
  def test_invalid_recipient_country
    begin
      response = @carrier.find_rates(
                   @locations[:bare_beverly_hills],
                   Location.new(:country => 'JP', :zip => '108-8361'),
                   @packages.values_at(:wii)
                 )
    rescue ResponseError => e
      assert_match /postal code/i, e.message
      assert_match /(missing|invalid)/i, e.message
    end
  end
  
  def test_ottawa_to_beverly_hills
    response = nil
    assert_nothing_raised do
      response = @carrier.find_rates(
                   @locations[:ottawa],
                   @locations[:beverly_hills],
                   @packages.values_at(:book, :wii)
                 )
      assert !response.rates.blank?
      response.rates.each do |rate|
        assert_instance_of String, rate.service_name
        assert_instance_of Fixnum, rate.price
      end
    end
  end
  
  def test_ottawa_to_london
    response = nil
    assert_nothing_raised do
      response = @carrier.find_rates(
                   @locations[:ottawa],
                   @locations[:london],
                   @packages.values_at(:book, :wii)
                 )
      assert !response.rates.blank?
      response.rates.each do |rate|
        assert_instance_of String, rate.service_name
        assert_instance_of Fixnum, rate.price
      end
    end
  end
  
  def test_beverly_hills_to_london
    response = nil
    assert_nothing_raised do
      response = @carrier.find_rates(
                   @locations[:beverly_hills],
                   @locations[:london],
                   @packages.values_at(:book, :wii)
                 )
      assert !response.rates.blank?
      response.rates.each do |rate|
        assert_instance_of String, rate.service_name
        assert_instance_of Fixnum, rate.price
      end
    end
  end

  def test_tracking
    assert_nothing_raised do
      @carrier.find_tracking_info('077973360403984', :test => true)
    end
  end
  
  def test_delivery_date
    response = @carrier.find_rates(
                 @locations[:beverly_hills],
                 @locations[:ottawa],
                 @packages.values_at(:wii)
               )
    assert !response.rates.reject { |rate| rate.delivery_date.nil? }.empty?
  end

  def test_delivery_date_with_optional_date
    ship_time = Time.new()+(4*86400)
    ship_timestamp = ship_time.strftime("%Y-%m-%dT%H:%M:%S-07:00")
    response1 = @carrier.find_rates(
                 @locations[:beverly_hills],
                 @locations[:ottawa],
                 @packages.values_at(:wii)
               )
    
    response2 = @carrier.find_rates(
                 @locations[:beverly_hills],
                 @locations[:ottawa],
                 @packages.values_at(:wii),
                  :ship_timestamp => ship_timestamp
               )
    response1.rates.each do |rate|
        sn1 = rate.service_name
        dd1 = rate.delivery_date
        response2.rates.each do |rate2|
          sn2 = rate2.service_name
          dd2 = rate2.delivery_date
          if sn1==sn2 and dd1.acts_like?(:time) and dd2.acts_like?(:time)
            assert_not_equal dd1, dd2, 'ship_timestamp dos not work' 
          end
        end
    end
    
  end
  
  def test_calculating_cost
    response = @carrier.find_rates(
                 @locations[:beverly_hills],
                 @locations[:london],
                 @packages.values_at(:book, :wii)
               )
     response2 = @carrier.find_rates(
                @locations[:beverly_hills],
                @locations[:london],
                @packages.values_at(:book)
              )
    response3 = @carrier.find_rates(
                 @locations[:beverly_hills],
                 @locations[:london],
                 @packages.values_at(:wii)
               )
    response.rates.each do |rate|
      price[rate.service_name] = rate.price/100.0
    end
    response2.rates.each do |rate|
      price2[rate.service_name] = rate.price/100.0
    end
    response3.rates.each do |rate|
      price3[rate.service_name] = rate.price/100.0
    end
    response.rates.each do |rate|
      if price[rate.service_name] > price2[rate.service_name]+price3[rate.service_name]
        assert 'mps is not cheapper'
      end 
    end
  end 
          
  private

  def delivery_date(response)
    response.rates.sort_by(&:price).map { |rate| [rate.service_name, rate.delivery_date] }
  end
  
end