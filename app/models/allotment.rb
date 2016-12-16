class Allotment < ActiveRecord::Base
  belongs_to :user
  belongs_to :place
  acts_as_list
end
