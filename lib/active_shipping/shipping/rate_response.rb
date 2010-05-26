module ActiveMerchant #:nodoc:
  module Shipping
    
    class RateResponse < Response
      
      attr_reader :rates
      
      def initialize(success, message, params = {}, options = {})
        @rates = Array(options[:estimates] || options[:rates] || options[:rate_estimates])
        super
      end
      
      def rates
        @rates.select { |rate| rate.rate_type ? !rate.rate_type.include?("LIST") : true }
      end
      
      alias_method :estimates, :rates
      alias_method :rate_estimates, :rates
      
      def list_rates
        @rates.select { |rate| rate.rate_type && rate.rate_type.include?("LIST") }
      end
      
    end
    
  end
end