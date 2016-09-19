module Seko
  class Order

    CANCEL_CODES = {
      '001' => 'Customer Request',
      '002' => 'Order Delayed',
      '003' => 'Duplicate',
      '004' => 'Item not available',
      '005' => 'Cannot ship to address',
      '006' => 'Other'
    }

    def self.websubmit(attributes)
      build_request(attributes, "Web")
    end

    def self.submit(attributes)
      build_request(attributes)
    end

    def self.build_request(attributes, type = nil)
      formatted = format(attributes, type)
      formatted["Request"].merge!(company(attributes[:company])) if attributes[:company]
      formatted
    end

    def self.format(order, order_prefix = nil)
      {
        "Request" => {
          "DeliveryDetails" => address(order[:shipping_address], order[:email]),
          "List" => {
            "SalesOrderLineItem" => line_items(order)
          },
          "SalesOrderHeader" => { "DCCode" => order[:warehouse] },
          "#{order_prefix}SalesOrder" => {
            "SalesOrderDate"   => order[:date],
            "SalesOrderNumber" => order[:number]
          }.merge(courier_attributes(order))
        }
      }
    end

    def self.courier_attributes(order)
      if has_courier?(order)
        {
          "CourierName"      => order[:shipping_carrier],
          "CourierService"   => order[:shipping_method]
        }
      else
        {}
      end
    end

    def self.has_courier?(order)
      order[:shipping_carrier] != nil &&
      order[:shipping_carrier] != 'N/A'
    end

    def self.address(address, email)
      {
        "City"         => address[:city],
        "CountryCode"  => address[:country],
        "County"       => address[:state],
        "EmailAddress" => email,
        "FirstName"    => address[:first_name],
        "LastName"     => address[:last_name],
        "Line1"        => address[:address1],
        "Line2"        => address[:address2],
        "PhoneNumber"  => address[:phone],
        "PostcodeZip"  => address[:zipcode].empty? ? '-----' : address[:zipcode]
      }
    end

    def self.line_items(order)
      order[:line_items].collect.with_index do |line_item, index|
        {
          "LineNumber"   => index + 1,
          "ProductCode"  => line_item[:sku],
          "Quantity"     => line_item[:quantity],
          "UnitPrice"    => line_item[:price],
          "CurrencyCode" => order[:currency],
          "VAT"          => line_item[:vat] || 0
        }
      end
    end

    def self.company(company)
      {
        "ShipToCompany" => {
          "CompanyCode"        => company[:code],
          "CompanyDescription" => company[:description]
        }
      }
    end

  end
end
