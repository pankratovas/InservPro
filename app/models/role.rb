class Role < ApplicationRecord
  has_many  :users
  #serialize :permissions, JSON

end
