module ActiveMerchant #:nodoc:
  module Shipping #:nodoc:
  
    class RateEstimate
      attr_reader :origin         # Location objects
      attr_reader :destination  
      attr_reader :package_rates  # array of hashes in the form of {:package => <Package>, :rate => 500}
      attr_reader :carrier        # Carrier.name ('USPS', 'FedEx', etc.)
      attr_reader :service_name   # name of service ("First Class Ground", etc.)
      attr_reader :service_code
      attr_reader :currency       # 'USD', 'CAD', etc.
                                  # http://en.wikipedia.org/wiki/ISO_4217
      attr_reader :delivery_date  # Usually only available for express shipments
      attr_reader :rate_type      # PAYOR_ACCOUNT_PACKAGE PAYOR_ACCOUNT_SHIPMENT PAYOR_LIST_PACKAGE PAYOR_LIST_SHIPMENT PAYOR_RETAIL_PACKAGE PAYOR_RETAIL_SHIPMENT RATED_ACCOUNT_PACKAGE RATED_ACCOUNT_SHIPMENT RATED_LIST_PACKAGE RATED_LIST_SHIPMENT RATED_RETAIL_PACKAGE RATED_RETAIL_SHIPMENT
        
      def initialize(origin, destination, carrier, service_name, options={})
        @origin, @destination, @carrier, @service_name = origin, destination, carrier, service_name
        @service_code = options[:service_code]
        if options[:package_rates]
          @package_rates = options[:package_rates].map {|p| p.update({:rate => Package.cents_from(p[:rate])}) }
        else
          @package_rates = Array(options[:packages]).map {|p| {:package => p}}
        end
        @total_price = Package.cents_from(options[:total_price])
        @currency = options[:currency]
        @delivery_date = options[:delivery_date]
        @rate_type = options[:rate_type]
      end
      
      def total_price
        begin
          @total_price || @package_rates.sum {|p| p[:rate]}
        rescue NoMethodError
          raise ArgumentError.new("RateEstimate must have a total_price set, or have a full set of valid package rates.")
        end
      end
      alias_method :price, :total_price
      
      def add(package,rate=nil)
        cents = Package.cents_from(rate)
        raise ArgumentError.new("New packages must have valid rate information since this RateEstimate has no total_price set.") if cents.nil? and total_price.nil?
        @package_rates << {:package => package, :rate => cents}
        self
      end
      
      def packages
        package_rates.map {|p| p[:package]}
      end
      
      def package_count
        package_rates.length
      end
      
    end
  end
end
