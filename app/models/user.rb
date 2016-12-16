class User < ActiveRecord::Base
	has_many :allotment
	has_many :places
	
	geocoded_by :address   # can also be an IP address
	after_validation :geocode 
end
