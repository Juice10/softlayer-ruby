#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  # This struct represents a configuration option that can be included in
  # a product order.  Strictly speaking the only information required for
  # the product order is the price_id, the rest of the information is provided
  # to make the object friendly to humans who may be searching for the
  # meaning of a given price_id.
  #
  # DEPRECATION WARNING: The following configuration option keys have been deprecated and
  # will be removed with the next major version: capacityRestrictionMaximum, capacityRestrictionMinimum,
  # capacityRestrictionType, hourlyRecurringFee, laborFee, oneTimeFee, recurringFee, requiredCoreCount, setupFee
  class ProductConfigurationOption < Struct.new(:capacity, :capacityRestrictionMaximum, :capacity_restriction_maximum,
     :capacityRestrictionMinimum, :capacity_restriction_minimum, :capacityRestrictionType, :capacity_restriction_type,
     :description, :hourlyRecurringFee, :hourly_recurring_fee, :laborFee, :labor_fee, :oneTimeFee, :one_time_fee,
     :price_id, :recurringFee, :recurring_fee, :requiredCoreCount, :required_core_count, :setupFee, :setup_fee, :units)
    # Is it evil, or just incongruous to give methods to a struct?

    def initialize(package_item_data, price_item_data)
      self.capacity    = package_item_data['capacity']
      self.description = package_item_data['description']
      self.units       = package_item_data['units']

      #DEPRECATION WARNING: All these are deprecated and will be removed with the next major version, pleace use keys below
      self.capacityRestrictionMaximum = price_item_data['capacityRestrictionMaximum'] ? price_item_data['capacityRestrictionMaximum'] : nil
      self.capacityRestrictionMinimum = price_item_data['capacityRestrictionMinimum'] ? price_item_data['capacityRestrictionMinimum'] : nil
      self.capacityRestrictionType    = price_item_data['capacityRestrictionType']    ? price_item_data['capacityRestrictionType']    : nil
      self.hourlyRecurringFee         = price_item_data['hourlyRecurringFee']         ? price_item_data['hourlyRecurringFee'].to_f    : 0.0
      self.laborFee                   = price_item_data['laborFee']                   ? price_item_data['laborFee'].to_f              : 0.0
      self.oneTimeFee                 = price_item_data['oneTimeFee']                 ? price_item_data['oneTimeFee'].to_f            : 0.0
      self.price_id                   = price_item_data['id']
      self.recurringFee               = price_item_data['recurringFee']               ? price_item_data['recurringFee'].to_f          : 0.0
      self.requiredCoreCount          = price_item_data['requiredCoreCount']          ? price_item_data['requiredCoreCount']          : nil
      self.setupFee                   = price_item_data['setupFee']                   ? price_item_data['setupFee'].to_f              : 0.0

      self.capacity_restriction_maximum = price_item_data['capacityRestrictionMaximum'] ? price_item_data['capacityRestrictionMaximum'] : nil
      self.capacity_restriction_minimum = price_item_data['capacityRestrictionMinimum'] ? price_item_data['capacityRestrictionMinimum'] : nil
      self.capacity_restriction_type    = price_item_data['capacityRestrictionType']    ? price_item_data['capacityRestrictionType']    : nil
      self.hourly_recurring_fee         = price_item_data['hourlyRecurringFee']         ? price_item_data['hourlyRecurringFee'].to_f    : 0.0
      self.labor_fee                    = price_item_data['laborFee']                   ? price_item_data['laborFee'].to_f              : 0.0
      self.one_time_fee                 = price_item_data['oneTimeFee']                 ? price_item_data['oneTimeFee'].to_f            : 0.0
      self.recurring_fee                = price_item_data['recurringFee']               ? price_item_data['recurringFee'].to_f          : 0.0
      self.required_core_count          = price_item_data['requiredCoreCount']          ? price_item_data['requiredCoreCount']          : nil
      self.setup_fee                    = price_item_data['setupFee']                   ? price_item_data['setupFee'].to_f              : 0.0
    end

    # returns true if the configuration option has no fees associated with it.
    def free?
      self.setupFee == 0 && self.laborFee == 0 && self.oneTimeFee == 0 && self.recurringFee == 0 && self.hourlyRecurringFee == 0
    end
  end

  # The goal of this class is to make it easy for scripts (and scripters) to
  # discover what product configuration options exist that can be added to a
  # product order.
  #
  # Instances of this class are created by and discovered in the context
  # of a ProductPackage object. There should not be a need to create instances
  # of this class directly.
  #
  # This class roughly represents entities in the +SoftLayer_Product_Item_Category+
  # service.
  class ProductItemCategory < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader: category_code
    # The categoryCode is a primary identifier for a particular
    # category.  It is a string like 'os' or 'ram'
    sl_attr :category_code, 'categoryCode'

    ##
    # :attr_reader:
    # The categoryCode is a primary identifier for a particular
    # category.  It is a string like 'os' or 'ram'
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of category_code
    # and will be removed in the next major release.
    sl_attr :categoryCode

    ##
    # :attr_reader:
    # The name of a category is a friendly, readable string
    sl_attr :name

    ##
    # Retrieve the product item configuration information
    # :call-seq:
    #   configuration_options(force_update=false)
    sl_dynamic_attr :configuration_options do |config_opts|
      config_opts.should_update? do
        # only retrieved once per instance
        @configuration_options == nil
      end

      config_opts.to_update do
        # This method assumes that the group and price item data was sent in
        # as part of the +network_hash+ used to initialize this object (as is done)
        # by the ProductPackage class. That class, in turn, gets its information
        # from SoftLayer_Product_Package::getCategories which does some complex
        # work on the back end to ensure the prices returned are correct.
        #
        # If this object was created in any other way, the configuration
        # options might be incorrect. So Caveat Emptor.
        #
        # Options are divided into groups (for convenience in the
        # web UI), but this code collapses the groups.
        self['groups'].collect do |group|
          group['prices'].sort{|lhs,rhs| lhs['sort'] <=> rhs['sort']}.collect do |price_item|
            ProductConfigurationOption.new(price_item['item'], price_item)
          end
        end.flatten # flatten out the individual group arrays.
      end
    end

    def service
      softlayer_client[:SoftLayer_Product_Item_Category].object_with_id(self.id)
    end

    ##
    # If the category has a single option (regardless of fees) this method will return
    # that option.  If the category has more than one option, this method will
    # return the first that it finds with no fees associated with it.
    #
    # If there are multiple options with no fees, it simply returns the first it finds
    #
    # Note that the option found may NOT be the same default option that is given
    # in the web-based ordering system.
    #
    # If there are multiple options, and all of them have associated fees, then this method
    # **will** return nil.
    #
    def default_option
      if configuration_options.count == 1
        configuration_options.first
      else
        configuration_options.find { |option| option.free? }
      end
    end

    # The ProductItemCategory class augments the base initialization by accepting
    # a boolean variable, +is_required+, which (when true) indicates that this category
    # is required for orders against the package that created it.
    def initialize(softlayer_client, network_hash, is_required)
      super(softlayer_client, network_hash)
      @is_required = is_required
    end

    # Returns true if this category is required in its package
    def required?()
      return @is_required
    end
  end
end
